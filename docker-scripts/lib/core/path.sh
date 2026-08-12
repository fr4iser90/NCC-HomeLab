#!/bin/bash
# Prevent multiple sourcing
if [ -n "${_PATH_LOADED+x}" ]; then
    return 0
fi
_PATH_LOADED=1

# Resolve script path and set DOCKER_SCRIPTS_DIR
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
if [ -z "${SCRIPT_PATH}" ]; then
    echo "Error: Failed to resolve script path" >&2
    return 1
fi

DOCKER_SCRIPTS_DIR="$(dirname "$(dirname "$(dirname "${SCRIPT_PATH}")")")"
if [ -z "${DOCKER_SCRIPTS_DIR}" ]; then
    echo "Error: Failed to resolve Docker scripts directory" >&2
    return 1
fi

# Repo root = parent of docker-scripts (clone or NCC fetch layout)
REPO_ROOT="$(dirname "${DOCKER_SCRIPTS_DIR}")"

# Catalog: prefer in-repo, then ~/catalog (NCC fetch)
if [ -d "${REPO_ROOT}/catalog" ]; then
    DOCKER_BASE_DIR="${REPO_ROOT}/catalog"
elif [ -d "${HOME}/catalog" ]; then
    DOCKER_BASE_DIR="${HOME}/catalog"
else
    DOCKER_BASE_DIR="${REPO_ROOT}/catalog"
fi

PROFILES_DIR="${REPO_ROOT}/profiles"
BASE_DIR="${HOME}"

# Derived paths
DOCKER_LIB_DIR="${DOCKER_SCRIPTS_DIR}/lib"
DOCKER_MODULES_DIR="${DOCKER_SCRIPTS_DIR}/modules"

export REPO_ROOT
export PROFILES_DIR
export BASE_DIR
export DOCKER_SCRIPTS_DIR
export DOCKER_BASE_DIR
export DOCKER_LIB_DIR
export DOCKER_MODULES_DIR

# Resolve service directory: "jellyfin" or "media/jellyfin"
get_docker_dir() {
    local container=$1
    local category

    if [ -z "$container" ]; then
        print_status "Container name not provided" "error"
        return 1
    fi

    if [[ "$container" == */* ]]; then
        if [ -d "$DOCKER_BASE_DIR/$container" ]; then
            echo "$DOCKER_BASE_DIR/$container"
            return 0
        fi
        print_status "Service path not found: $DOCKER_BASE_DIR/$container" "error"
        return 1
    fi

    if [ -z "${MANAGEMENT_CATEGORIES[*]}" ]; then
        print_status "MANAGEMENT_CATEGORIES not defined" "error"
        return 1
    fi

    category=$(get_container_category "$container")
    if [ $? -eq 0 ]; then
        echo "$DOCKER_BASE_DIR/$category/$container"
        return 0
    fi

    print_status "Container $container not found" "error"
    return 1
}

# Short name from "media/jellyfin" → jellyfin
service_short_name() {
    local ref=$1
    echo "${ref##*/}"
}
