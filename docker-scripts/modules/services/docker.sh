#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_DOCKER_SERVICE_LOADED+x}" ]; then
    return 0
fi
_DOCKER_SERVICE_LOADED=1

# ==============================================
# Docker Service Functions (start / stop / status / restart)
# ==============================================

create_log_directories() {
    local service_dir=$1

    if [ ! -f "$service_dir/docker-compose.rootless.yml" ]; then
        return 0
    fi

    if grep -q "\./logs" "$service_dir/docker-compose.rootless.yml" 2>/dev/null; then
        mkdir -p "$service_dir/logs/traefik" 2>/dev/null
        mkdir -p "$service_dir/logs" 2>/dev/null

        if grep -q "\./logs/auth\.log" "$service_dir/docker-compose.rootless.yml" 2>/dev/null; then
            touch "$service_dir/logs/auth.log" 2>/dev/null
            chmod 644 "$service_dir/logs/auth.log" 2>/dev/null || true
        fi

        chmod 755 "$service_dir/logs" 2>/dev/null || true
        chmod 755 "$service_dir/logs/traefik" 2>/dev/null || true
    fi
}

# Resolve service dir + compose context/file for day-2 ops
_service_compose_ctx() {
    local container=$1
    local docker_dir compose_ctx compose_file

    docker_dir=$(get_docker_dir "$container") || return 1
    compose_ctx=$(resolve_compose_context "$docker_dir")
    detect_docker_mode
    compose_file=$(get_compose_file "$compose_ctx") || return 1

    SERVICE_DIR="$docker_dir"
    COMPOSE_CTX="$compose_ctx"
    COMPOSE_FILE_NAME="$compose_file"
    export SERVICE_DIR COMPOSE_CTX COMPOSE_FILE_NAME
}

start_docker_container() {
    local container=$1
    local docker_dir
    local compose_ctx
    local compose_file

    docker_dir=$(get_docker_dir "$container")

    if [ -z "$docker_dir" ]; then
        print_status "Invalid container: $container" "error"
        return 1
    fi

    print_status "Starting $container" "info"

    apply_runtime_ids "$docker_dir" || {
        print_status "Failed to apply runtime IDs for $container" "error"
        return 1
    }

    run_pre_start_hook "$docker_dir" || {
        print_status "Failed pre-start hook for $container" "error"
        return 1
    }

    compose_ctx=$(resolve_compose_context "$docker_dir")
    detect_docker_mode
    compose_file=$(get_compose_file "$compose_ctx")

    if [ -z "$compose_file" ]; then
        print_status "No compose file found for $container (ctx=$compose_ctx)" "error"
        return 1
    fi

    print_status "Using $DOCKER_MODE mode with $compose_ctx/$compose_file" "info"

    if [ "$DOCKER_MODE" = "rootless" ]; then
        create_log_directories "$docker_dir"
    fi

    ensure_user_ids

    if [ "$DOCKER_MODE" = "swarm" ]; then
        local stack_name
        stack_name=$(get_stack_name "$container")
        if [ ! -f "$compose_ctx/docker-stack.yml" ] && [ "$compose_file" != "docker-stack.yml" ]; then
            print_status "Swarm active but no docker-stack.yml for $container — using $compose_file" "warn"
        fi
        (cd "$compose_ctx" && PUID="$USER_UID" PGID="$USER_GID" docker stack deploy -c "$compose_file" "$stack_name")
    else
        (cd "$compose_ctx" && PUID="$USER_UID" PGID="$USER_GID" docker compose -f "$compose_file" up -d)
    fi

    print_status "Container started successfully" "success"
    return 0
}

stop_docker_container() {
    local container=$1
    local stack_name

    _service_compose_ctx "$container" || return 1

    print_status "Stopping $container" "info"
    detect_docker_mode

    if [ "$DOCKER_MODE" = "swarm" ]; then
        stack_name=$(get_stack_name "$container")
        docker stack rm "$stack_name" 2>/dev/null || true
        print_status "Stack $stack_name removal requested" "success"
    else
        (cd "$COMPOSE_CTX" && docker compose -f "$COMPOSE_FILE_NAME" down) || return 1
        print_status "Stopped $container" "success"
    fi
    return 0
}

status_docker_container() {
    local container=$1
    local stack_name

    _service_compose_ctx "$container" || return 1
    detect_docker_mode

    echo "--- $container ($DOCKER_MODE) @ $COMPOSE_CTX/$COMPOSE_FILE_NAME ---"

    if [ "$DOCKER_MODE" = "swarm" ]; then
        stack_name=$(get_stack_name "$container")
        if docker stack ls --format '{{.Name}}' 2>/dev/null | grep -qx "$stack_name"; then
            docker stack services "$stack_name" 2>/dev/null || docker service ls --filter "label=com.docker.stack.namespace=$stack_name"
        else
            echo "(stack not deployed: $stack_name)"
        fi
    else
        (cd "$COMPOSE_CTX" && docker compose -f "$COMPOSE_FILE_NAME" ps) || true
    fi
    return 0
}

restart_docker_container() {
    local container=$1

    _service_compose_ctx "$container" || return 1
    detect_docker_mode
    ensure_user_ids

    print_status "Restarting $container" "info"

    if [ "$DOCKER_MODE" = "swarm" ]; then
        local stack_name
        stack_name=$(get_stack_name "$container")
        (cd "$COMPOSE_CTX" && PUID="$USER_UID" PGID="$USER_GID" docker stack deploy -c "$COMPOSE_FILE_NAME" "$stack_name") || return 1
    else
        (cd "$COMPOSE_CTX" && PUID="$USER_UID" PGID="$USER_GID" docker compose -f "$COMPOSE_FILE_NAME" up -d --force-recreate) || return 1
    fi

    print_status "Restarted $container" "success"
    return 0
}

# Apply op to a list of service refs (group/service or short name)
foreach_service_op() {
    local op=$1
    shift
    local entry rc=0

    for entry in "$@"; do
        [ -z "$entry" ] && continue
        case "$op" in
            start)   start_docker_container "$entry" || rc=1 ;;
            stop)    stop_docker_container "$entry" || rc=1 ;;
            status)  status_docker_container "$entry" || rc=1 ;;
            restart) restart_docker_container "$entry" || rc=1 ;;
            *)
                print_status "Unknown op: $op" "error"
                return 1
                ;;
        esac
    done
    return $rc
}
