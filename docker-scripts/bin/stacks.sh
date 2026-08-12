#!/bin/bash

# Day-2 ops for catalog services / profiles
#
# Usage:
#   ./stacks.sh status [--profile NAME ...] [group/service ...]
#   ./stacks.sh stop    --profile homelab-core
#   ./stacks.sh restart media/jellyfin
#   ./stacks.sh start   --profile compute-llm-arm
#
# Notes:
#   start runs runtime-ids + optional hooks (same as init path).
#   Prefer init-homelab / init-compute for first-time setup.

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOCKER_SCRIPTS_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"

if [ ! -f "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh" ]; then
    echo "Error: invalid docker-scripts layout"
    exit 1
fi

source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") <status|stop|restart|start> [options] [services...]

Options:
  --profile, -p NAME   Load services from profiles/NAME.yml (repeatable)
  --help, -h

Examples:
  $(basename "$0") status --profile homelab-core
  $(basename "$0") stop media/jellyfin system/portainer
  $(basename "$0") restart --profile homelab-media
  $(basename "$0") start --profile compute-llm-arm
EOF
}

OP=""
CLI_PROFILES=()
SERVICES=()

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

OP=$1
shift

case "$OP" in
    status|stop|restart|start) ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown command: $OP"
        usage
        exit 1
        ;;
esac

while [ $# -gt 0 ]; do
    case "$1" in
        --profile|-p)
            shift
            [ -n "${1:-}" ] || { echo "Missing profile name"; exit 1; }
            CLI_PROFILES+=("$1")
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            SERVICES+=("$1")
            shift
            ;;
    esac
done

TARGETS=()

if [ ${#CLI_PROFILES[@]} -gt 0 ]; then
    load_profiles "${CLI_PROFILES[@]}" || exit 1
    for svc in "${PROFILE_SERVICES[@]}"; do
        TARGETS+=("$svc")
    done
    print_status "Profiles: ${SELECTED_PROFILES[*]}" "info"
fi

if [ ${#SERVICES[@]} -gt 0 ]; then
    for svc in "${SERVICES[@]}"; do
        TARGETS+=("$svc")
    done
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No services specified. Use --profile NAME and/or group/service args."
    usage
    exit 1
fi

# Deduplicate while preserving order
DEDUPED=()
declare -A seen=()
for svc in "${TARGETS[@]}"; do
    if [ -z "${seen[$svc]+x}" ]; then
        seen[$svc]=1
        DEDUPED+=("$svc")
    fi
done

print_header "stacks $OP"
detect_docker_mode
print_status "Docker mode: $DOCKER_MODE" "info"
print_status "Targets: ${DEDUPED[*]}" "info"

get_user_info >/dev/null 2>&1 || true

foreach_service_op "$OP" "${DEDUPED[@]}"
rc=$?

if [ $rc -eq 0 ]; then
    print_status "Done: $OP" "success"
else
    print_status "Completed with errors: $OP" "warn"
fi
exit $rc
