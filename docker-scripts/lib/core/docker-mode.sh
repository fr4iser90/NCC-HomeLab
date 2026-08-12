#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_DOCKER_MODE_LOADED+x}" ]; then
    return 0
fi
_DOCKER_MODE_LOADED=1

# ==============================================
# Docker Mode + arch variant detection
# ==============================================

is_swarm_active() {
    docker info 2>/dev/null | grep -q "Swarm: active"
}

is_docker_rootless() {
    [ -S "${XDG_RUNTIME_DIR}/docker.sock" ] 2>/dev/null
}

is_docker_root() {
    [ -S "/var/run/docker.sock" ] 2>/dev/null
}

detect_docker_mode() {
    if is_swarm_active; then
        DOCKER_MODE="swarm"
        COMPOSE_FILE="docker-stack.yml"
    elif is_docker_rootless; then
        DOCKER_MODE="rootless"
        COMPOSE_FILE="docker-compose.rootless.yml"
    elif is_docker_root; then
        DOCKER_MODE="rootful"
        COMPOSE_FILE="docker-compose.yml"
    else
        DOCKER_MODE="unknown"
        COMPOSE_FILE="docker-compose.yml"
        print_status "Could not detect Docker mode, using fallback: docker-compose.yml" "warn"
    fi

    export DOCKER_MODE
    export COMPOSE_FILE
}

# Host arch → variant folder name (override with COMPUTE_VARIANT=arm|cpu|rocm)
detect_compute_variant() {
    if [ -n "${COMPUTE_VARIANT:-}" ]; then
        echo "$COMPUTE_VARIANT"
        return 0
    fi
    case "$(uname -m)" in
        aarch64|arm64)
            echo "arm"
            ;;
        x86_64|amd64)
            if [ "${COMPUTE_GPU:-}" = "rocm" ]; then
                echo "rocm"
            else
                echo "cpu"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Resolve directory that contains the compose file (service root or arm/cpu/rocm)
resolve_compose_context() {
    local service_dir=$1
    local variant
    local candidate

    if [ -z "$service_dir" ] || [ ! -d "$service_dir" ]; then
        echo "$service_dir"
        return 1
    fi

    variant=$(detect_compute_variant)

    if [ -n "$variant" ]; then
        candidate="$service_dir/$variant"
        if [ -d "$candidate" ] && {
            [ -f "$candidate/compose.yaml" ] ||
            [ -f "$candidate/compose.yml" ] ||
            [ -f "$candidate/docker-compose.yml" ] ||
            [ -f "$candidate/docker-compose.yaml" ] ||
            [ -f "$candidate/docker-compose.rootless.yml" ] ||
            [ -f "$candidate/docker-stack.yml" ]
        }; then
            echo "$candidate"
            return 0
        fi
    fi

    # x86 fallback: prefer cpu/ if present when root has no compose
    if [ -d "$service_dir/cpu" ] && [ -f "$service_dir/cpu/compose.yaml" ]; then
        if [ ! -f "$service_dir/compose.yaml" ] && \
           [ ! -f "$service_dir/docker-compose.yml" ] && \
           [ ! -f "$service_dir/docker-compose.yaml" ]; then
            echo "$service_dir/cpu"
            return 0
        fi
    fi

    echo "$service_dir"
    return 0
}

# Returns compose filename inside a context dir (relative name only)
get_compose_file() {
    local service_dir=$1

    if [ -z "$service_dir" ]; then
        print_status "Service directory not provided" "error"
        return 1
    fi

    detect_docker_mode

    if [ -f "$service_dir/$COMPOSE_FILE" ]; then
        echo "$COMPOSE_FILE"
        return 0
    fi

    if [ -f "$service_dir/docker-compose.yml" ]; then
        echo "docker-compose.yml"
        return 0
    fi

    if [ -f "$service_dir/docker-compose.yaml" ]; then
        echo "docker-compose.yaml"
        return 0
    fi

    if [ -f "$service_dir/compose.yaml" ]; then
        echo "compose.yaml"
        return 0
    fi

    if [ -f "$service_dir/compose.yml" ]; then
        echo "compose.yml"
        return 0
    fi

    print_status "No compose file found in $service_dir" "error"
    return 1
}

get_stack_name() {
    local container=$1
    local category
    local short

    # Path form: media/owncast → media-owncast
    if [[ "$container" == */* ]]; then
        echo "${container%%/*}-${container##*/}"
        return 0
    fi

    if [ -z "${MANAGEMENT_CATEGORIES[*]}" ]; then
        if [ -f "${DOCKER_SCRIPTS_DIR}/lib/core/containers.sh" ]; then
            source "${DOCKER_SCRIPTS_DIR}/lib/core/containers.sh"
        fi
    fi

    category=$(get_container_category "$container")
    short="$container"

    if [ -z "$category" ]; then
        echo "$container"
        return 1
    fi

    echo "${category}-${short}"
}
