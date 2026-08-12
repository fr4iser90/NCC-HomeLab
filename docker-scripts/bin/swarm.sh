#!/bin/bash

# Homelab Swarm helpers (not for compute profiles).
#
# Usage:
#   ./swarm.sh init [--advertise-addr IP]
#   ./swarm.sh join-token [worker|manager]
#   ./swarm.sh join --token TOKEN HOST[:PORT]
#   ./swarm.sh status
#   ./swarm.sh leave [--force]
#   ./swarm.sh deploy --profile homelab-core [--profile homelab-media]
#   ./swarm.sh remove --profile homelab-core
#
# deploy uses docker-stack.yml per service (rootful Swarm). Compute profiles are rejected.

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOCKER_SCRIPTS_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"

if [ ! -f "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh" ]; then
    echo "Error: invalid docker-scripts layout"
    exit 1
fi

source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  init [--advertise-addr IP]     Initialize swarm manager on this node
  join-token [worker|manager]    Print join token (default: worker)
  join --token TOKEN HOST[:PORT] Join this node to an existing swarm
  status                         Show swarm nodes + stacks
  leave [--force]                Leave swarm
  deploy -p PROFILE...           Deploy homelab profile stacks (docker-stack.yml)
  remove -p PROFILE...           Remove stacks for profile services

Homelab only — compute-* profiles are not supported here.
EOF
}

ensure_not_compute_profile() {
    local name family
    for name in "$@"; do
        family=$(profile_get_field "$(profile_file "$name")" "family")
        if [ "$family" = "compute" ]; then
            print_status "Refuse compute profile '$name' — use init-compute / stacks.sh on single node" "error"
            return 1
        fi
    done
    return 0
}

ensure_homelab_stacks() {
    local svc dir
    for svc in "${PROFILE_SERVICES[@]}"; do
        dir=$(get_docker_dir "$svc") || return 1
        if [[ "$svc" == compute/* ]] || [[ "$dir" == */compute/* ]]; then
            print_status "Skip/refuse compute path in swarm deploy: $svc" "error"
            return 1
        fi
        if [ ! -f "$dir/docker-stack.yml" ]; then
            print_status "Missing docker-stack.yml for $svc" "error"
            return 1
        fi
    done
    return 0
}

cmd_init() {
    local advertise=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --advertise-addr)
                shift
                advertise=$1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if is_swarm_active; then
        print_status "Swarm already active" "info"
        docker node ls
        return 0
    fi

    print_header "Swarm init"
    if [ -n "$advertise" ]; then
        docker swarm init --advertise-addr "$advertise"
    else
        docker swarm init
    fi
    print_status "Manager ready — use: $(basename "$0") join-token worker" "success"
}

cmd_join_token() {
    local role=${1:-worker}
    if ! is_swarm_active; then
        print_status "Swarm not active on this node" "error"
        return 1
    fi
    docker swarm join-token "$role"
}

cmd_join() {
    local token="" host=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --token)
                shift
                token=$1
                shift
                ;;
            *)
                host=$1
                shift
                ;;
        esac
    done
    if [ -z "$token" ] || [ -z "$host" ]; then
        echo "Usage: join --token TOKEN HOST[:PORT]"
        return 1
    fi
    [[ "$host" == *:* ]] || host="${host}:2377"
    print_header "Swarm join"
    docker swarm join --token "$token" "$host"
}

cmd_status() {
    print_header "Swarm status"
    if ! is_swarm_active; then
        print_status "Swarm inactive on this node" "warn"
        return 0
    fi
    echo "## Nodes"
    docker node ls
    echo
    echo "## Stacks"
    docker stack ls
    echo
    echo "## Services"
    docker service ls
}

cmd_leave() {
    local force=0
    [ "${1:-}" = "--force" ] && force=1
    print_header "Swarm leave"
    if [ "$force" -eq 1 ]; then
        docker swarm leave --force
    else
        docker swarm leave
    fi
}

cmd_deploy() {
    local profiles=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --profile|-p)
                shift
                profiles+=("$1")
                shift
                ;;
            *)
                echo "Unknown arg: $1"
                return 1
                ;;
        esac
    done
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "Need --profile NAME"
        return 1
    fi

    ensure_not_compute_profile "${profiles[@]}" || return 1
    load_profiles "${profiles[@]}" || return 1
    ensure_homelab_stacks || return 1

    if ! is_swarm_active; then
        print_status "Swarm not active — run: $(basename "$0") init" "error"
        return 1
    fi

    # Prefer stack files even if detect_docker_mode would pick compose
    export DOCKER_MODE=swarm
    export COMPOSE_FILE=docker-stack.yml

    print_header "Swarm deploy"
    print_status "Profiles: ${SELECTED_PROFILES[*]}" "info"
    get_user_info >/dev/null 2>&1 || true

    local svc dir stack_name
    for svc in "${PROFILE_SERVICES[@]}"; do
        dir=$(get_docker_dir "$svc") || return 1
        stack_name=$(get_stack_name "$svc")
        print_status "Deploying $svc → stack $stack_name" "info"
        apply_runtime_ids "$dir" || return 1
        # Hooks optional on re-deploy; skip interactive by default unless NCC_SWARM_HOOKS=1
        if [ "${NCC_SWARM_HOOKS:-0}" = "1" ]; then
            run_pre_start_hook "$dir" || return 1
        fi
        ensure_user_ids
        (cd "$dir" && PUID="$USER_UID" PGID="$USER_GID" docker stack deploy -c docker-stack.yml "$stack_name") || return 1
    done
    print_status "Deploy complete" "success"
    docker stack ls
}

cmd_remove() {
    local profiles=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --profile|-p)
                shift
                profiles+=("$1")
                shift
                ;;
            *)
                echo "Unknown arg: $1"
                return 1
                ;;
        esac
    done
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "Need --profile NAME"
        return 1
    fi

    ensure_not_compute_profile "${profiles[@]}" || return 1
    load_profiles "${profiles[@]}" || return 1

    print_header "Swarm remove"
    local svc stack_name
    for svc in "${PROFILE_SERVICES[@]}"; do
        stack_name=$(get_stack_name "$svc")
        print_status "Removing stack $stack_name" "info"
        docker stack rm "$stack_name" 2>/dev/null || true
    done
    print_status "Remove requested" "success"
}

CMD=${1:-}
shift || true

case "$CMD" in
    init)       cmd_init "$@" ;;
    join-token) cmd_join_token "$@" ;;
    join)       cmd_join "$@" ;;
    status)     cmd_status "$@" ;;
    leave)      cmd_leave "$@" ;;
    deploy)     cmd_deploy "$@" ;;
    remove)     cmd_remove "$@" ;;
    -h|--help|help|"")
        usage
        [ -n "$CMD" ] && [ "$CMD" != "-h" ] && [ "$CMD" != "--help" ] && [ "$CMD" != "help" ] && exit 1
        exit 0
        ;;
    *)
        echo "Unknown command: $CMD"
        usage
        exit 1
        ;;
esac
