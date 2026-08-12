#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"


source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

# Guard gegen mehrfaches Laden
if [ -n "${_SERVICES_INIT_LOADED+x}" ]; then
    return 0
fi
_SERVICES_INIT_LOADED=1

# Start a list of services (short name or group/service)
start_services_list() {
    local selection=$1
    local category service

    while IFS= read -r entry; do
        [ -z "$entry" ] && continue

        if [[ "$entry" == */* ]]; then
            category="${entry%%/*}"
            service="${entry#*/}"
        elif [[ "$entry" == *:* ]]; then
            category="${entry%%:*}"
            service="${entry#*:}"
            entry="${category}/${service}"
        else
            service="$entry"
            category=$(get_container_category "$service") || {
                print_status "Unknown service: $service" "error"
                return 1
            }
            entry="${category}/${service}"
        fi

        # Skip gateway — handled by initialize_gateway
        if [ "$category" = "gateway" ]; then
            continue
        fi

        print_status "Initializing $service..." "info"
        export SERVICE_NAME="$service"

        start_docker_container "$entry" || start_docker_container "$service" || {
            print_status "Failed to start $service" "error"
            return 1
        }

        print_status "$service initialized successfully" "success"
    done <<< "$selection"

    return 0
}

# Profile-driven service init (non-gateway)
initialize_services_from_profiles() {
    print_header "Profile Services Setup"

    local apps
    apps=$(profile_app_services)
    if [ -z "$apps" ]; then
        print_status "No application services in selected profiles" "info"
        return 0
    fi

    print_status "Services from profiles: $(echo "$apps" | tr '\n' ' ')" "info"
    start_services_list "$apps" || return 1

    if [ "${AUTO_SETUP:-0}" -eq 1 ]; then
        finalize_credentials_file
    fi

    print_status "Profile services initialized" "success"
    return 0
}

# Legacy FZF multi-select
initialize_services() {
    print_header "Optional Services Setup"

    if ! command -v fzf >/dev/null 2>&1; then
        print_status "FZF is not installed. Please install it first." "error"
        return 1
    fi

    local services=()
    for category in "${!MANAGEMENT_CATEGORIES[@]}"; do
        if [ "$category" != "gateway" ] && [ "$category" != "compute" ]; then
            for service in ${MANAGEMENT_CATEGORIES[$category]}; do
                services+=("$category:$service")
            done
        fi
    done

    print_status "Select services to install (SPACE to select, ENTER to confirm):" "info"

    preview_service() {
        local selection="$1"
        local category="${selection%%:*}"
        local service="${selection#*:}"
        local readme="${DOCKER_BASE_DIR}/${category}/${service}/README.md"
        local contract="${DOCKER_BASE_DIR}/${category}/${service}/contract.env"

        if [ -f "$readme" ]; then
            cat "$readme"
        else
            echo "Service: $service"
        fi
        if [ -f "$contract" ]; then
            echo
            echo "--- contract.env ---"
            cat "$contract"
        fi
    }
    export -f preview_service
    export DOCKER_BASE_DIR

    local selected
    selected=$(printf '%s\n' "${services[@]}" | fzf --multi \
        --header='Use SPACE to deselect services, ENTER to confirm' \
        --bind 'space:toggle+down' \
        --bind 'tab:toggle' \
        --bind 'ctrl-a:toggle-all' \
        --preview 'bash -c "preview_service {}"' \
        --preview-window="right:50%:wrap" \
        --pointer="▶" \
        --marker="✓" \
        --reverse \
        --bind 'start:select-all')

    if [ -z "$selected" ]; then
        print_status "No services selected" "warn"
        return 0
    fi

    start_services_list "$selected" || return 1

    if [ "${AUTO_SETUP:-0}" -eq 1 ]; then
        finalize_credentials_file
    fi

    print_status "All selected services have been initialized" "success"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    initialize_services
fi
