#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_DOCKER_SERVICE_LOADED+x}" ]; then
    return 0
fi
_DOCKER_SERVICE_LOADED=1

# ==============================================
# Docker Service Functions
# ==============================================

# Erstellt Log-Verzeichnisse für rootless Docker
create_log_directories() {
    local service_dir=$1
    
    # Prüfe ob docker-compose.rootless.yml existiert
    if [ ! -f "$service_dir/docker-compose.rootless.yml" ]; then
        return 0  # Keine rootless-Variante, nichts zu tun
    fi
    
    # Erstelle logs Verzeichnis falls es in der compose-Datei verwendet wird
    if grep -q "\./logs" "$service_dir/docker-compose.rootless.yml" 2>/dev/null; then
        mkdir -p "$service_dir/logs/traefik" 2>/dev/null
        mkdir -p "$service_dir/logs" 2>/dev/null
        
        # Erstelle auth.log falls benötigt (für traefik-crowdsec)
        if grep -q "\./logs/auth\.log" "$service_dir/docker-compose.rootless.yml" 2>/dev/null; then
            touch "$service_dir/logs/auth.log" 2>/dev/null
            chmod 644 "$service_dir/logs/auth.log" 2>/dev/null || true
        fi
        
        # Setze Berechtigungen
        chmod 755 "$service_dir/logs" 2>/dev/null || true
        chmod 755 "$service_dir/logs/traefik" 2>/dev/null || true
    fi
}

start_docker_container() {
    local container=$1
    local docker_dir=$(get_docker_dir "$container")

    if [ -z "$docker_dir" ]; then
        print_status "Invalid container: $container" "error"
        return 1
    fi

    print_status "Starting $container" "info"

    # Check for update-env.sh
    if [ -f "$docker_dir/update-env.sh" ]; then
        print_status "Running environment updates..." "info"
        (cd "$docker_dir" && bash update-env.sh)
    fi

    # Docker-Modus erkennen und passende Datei wählen
    detect_docker_mode
    local compose_file=$(get_compose_file "$docker_dir")
    
    if [ -z "$compose_file" ]; then
        print_status "No compose file found for $container" "error"
        return 1
    fi
    
    print_status "Using $DOCKER_MODE mode with $compose_file" "info"

    # Erstelle Log-Verzeichnisse für rootless falls nötig
    if [ "$DOCKER_MODE" = "rootless" ]; then
        create_log_directories "$docker_dir"
    fi

    if [ -d "$docker_dir" ]; then
        # Swarm vs Compose unterscheiden
        if [ "$DOCKER_MODE" = "swarm" ]; then
            local stack_name=$(get_stack_name "$container")
            (cd "$docker_dir" && docker stack deploy -c "$compose_file" "$stack_name")
        else
            (cd "$docker_dir" && docker compose -f "$compose_file" up -d)
        fi
        
        print_status "Container started successfully" "success"
        return 0
    else
        print_status "Container directory not found" "error"
        return 1
    fi
}

restart_docker_container() {
    local container=$1
    local docker_dir=$(get_docker_dir "$container")

    if [ -z "$docker_dir" ]; then
        print_status "Invalid container: $container" "error"
        return 1
    fi

    # Docker-Modus erkennen und passende Datei wählen
    detect_docker_mode
    local compose_file=$(get_compose_file "$docker_dir")
    
    if [ -z "$compose_file" ]; then
        print_status "No compose file found for $container" "error"
        return 1
    fi

    if [ -d "$docker_dir" ]; then
        print_status "Restarting $container" "info"
        
        # Swarm vs Compose unterscheiden
        if [ "$DOCKER_MODE" = "swarm" ]; then
            local stack_name=$(get_stack_name "$container")
            (cd "$docker_dir" && docker stack deploy -c "$compose_file" "$stack_name")
        else
            (cd "$docker_dir" && docker compose -f "$compose_file" up -d --force-recreate)
        fi
        
        print_status "Container restarted successfully" "success"
        return 0
    else
        print_status "Container directory not found" "error"
        return 1
    fi
}