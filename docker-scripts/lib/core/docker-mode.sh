#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_DOCKER_MODE_LOADED+x}" ]; then
    return 0
fi
_DOCKER_MODE_LOADED=1

# ==============================================
# Docker Mode Detection Functions
# ==============================================

# Prüft ob Docker Swarm aktiv ist
is_swarm_active() {
    docker info 2>/dev/null | grep -q "Swarm: active"
}

# Prüft ob Docker Rootless läuft
is_docker_rootless() {
    [ -S "${XDG_RUNTIME_DIR}/docker.sock" ] 2>/dev/null
}

# Prüft ob Docker Root (rootful) läuft
is_docker_root() {
    [ -S "/var/run/docker.sock" ] 2>/dev/null
}

# Erkennt den Docker-Modus und setzt entsprechende Variablen
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
        COMPOSE_FILE="docker-compose.yml"  # Fallback
        print_status "Could not detect Docker mode, using fallback: docker-compose.yml" "warn"
    fi
    
    export DOCKER_MODE
    export COMPOSE_FILE
}

# Gibt die passende Compose-Datei für einen Service zurück
get_compose_file() {
    local service_dir=$1
    
    if [ -z "$service_dir" ]; then
        print_status "Service directory not provided" "error"
        return 1
    fi
    
    # Erkenne Docker-Modus
    detect_docker_mode
    
    # Prüfe ob spezifische Datei existiert
    if [ -f "$service_dir/$COMPOSE_FILE" ]; then
        echo "$COMPOSE_FILE"
        return 0
    fi
    
    # Fallback: docker-compose.yml
    if [ -f "$service_dir/docker-compose.yml" ]; then
        print_status "Using fallback: docker-compose.yml (specific file not found)" "info"
        echo "docker-compose.yml"
        return 0
    fi
    
    print_status "No compose file found in $service_dir" "error"
    return 1
}

# Generiert Stack-Namen für Swarm
get_stack_name() {
    local container=$1
    local category
    
    # Lade containers.sh falls noch nicht geladen
    if [ -z "${MANAGEMENT_CATEGORIES[*]}" ]; then
        if [ -f "${DOCKER_SCRIPTS_DIR}/lib/core/containers.sh" ]; then
            source "${DOCKER_SCRIPTS_DIR}/lib/core/containers.sh"
        fi
    fi
    
    category=$(get_container_category "$container")
    
    if [ -z "$category" ]; then
        echo "$container"  # Fallback
        return 1
    fi
    
    # Format: <category>-<service>
    echo "${category}-${container}"
}

