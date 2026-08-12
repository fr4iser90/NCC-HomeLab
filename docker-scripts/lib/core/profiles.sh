#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_PROFILES_LOADED+x}" ]; then
    return 0
fi
_PROFILES_LOADED=1

# Selected profile names (bash array)
SELECTED_PROFILES=()
# Flattened service refs group/service
PROFILE_SERVICES=()
PROFILE_REQUIRES_GATEWAY=0
PROFILE_FAMILY=""

list_available_profiles() {
    local dir="${PROFILES_DIR:-}"
    if [ ! -d "$dir" ]; then
        return 1
    fi
    find "$dir" -maxdepth 1 -type f -name '*.yml' -printf '%f\n' 2>/dev/null \
        | sed 's/\.yml$//' | sort
}

profile_file() {
    local name=$1
    echo "${PROFILES_DIR}/${name}.yml"
}

# Simple YAML helpers for our profile shape
profile_get_field() {
    local file=$1
    local key=$2
    grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

profile_get_services() {
    local file=$1
    awk '
        /^services:[[:space:]]*$/ { in_services=1; next }
        in_services && /^[^[:space:]#]/ { exit }
        in_services && /^[[:space:]]*-[[:space:]]+/ {
            sub(/^[[:space:]]*-[[:space:]]+/, "")
            gsub(/[[:space:]]+$/, "")
            if ($0 != "" && $0 != "[]") print
        }
    ' "$file"
}

profile_requires_gateway() {
    local file=$1
    local val
    val=$(profile_get_field "$file" "requiresGateway")
    [[ "$val" == "true" || "$val" == "yes" || "$val" == "1" ]]
}

load_profiles() {
    SELECTED_PROFILES=("$@")
    PROFILE_SERVICES=()
    PROFILE_REQUIRES_GATEWAY=0
    PROFILE_FAMILY=""

    if [ ${#SELECTED_PROFILES[@]} -eq 0 ]; then
        print_status "No profiles selected" "error"
        return 1
    fi

    local name file svc family
    declare -A seen=()

    for name in "${SELECTED_PROFILES[@]}"; do
        file=$(profile_file "$name")
        if [ ! -f "$file" ]; then
            print_status "Profile not found: $file" "error"
            return 1
        fi

        family=$(profile_get_field "$file" "family")
        if [ -z "$PROFILE_FAMILY" ]; then
            PROFILE_FAMILY="$family"
        elif [ -n "$family" ] && [ "$family" != "$PROFILE_FAMILY" ]; then
            print_status "Cannot mix profile families ($PROFILE_FAMILY vs $family)" "error"
            return 1
        fi

        if profile_requires_gateway "$file"; then
            PROFILE_REQUIRES_GATEWAY=1
        fi

        while IFS= read -r svc; do
            [ -z "$svc" ] && continue
            if [ -z "${seen[$svc]+x}" ]; then
                seen[$svc]=1
                PROFILE_SERVICES+=("$svc")
            fi
        done < <(profile_get_services "$file")
    done

    export PROFILE_REQUIRES_GATEWAY
    export PROFILE_FAMILY
    return 0
}

# Interactive: core / core+media / custom
prompt_homelab_profiles() {
    print_header "Homelab Profiles"
    print_status "init-homelab applies homelab profiles:" "info"
    print_status "  homelab-core  = gateway + companion + portainer/watchtower (base)" "info"
    print_status "  homelab-media = jellyfin/plex/owncast (needs core/gateway)" "info"
    echo
    echo "1) homelab-core only"
    echo "2) homelab-core + homelab-media"
    echo "3) Custom service picker (fzf)"
    echo
    local choice
    read -r -p "Enter choice [1/2/3] (default 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) load_profiles "homelab-core" ;;
        2) load_profiles "homelab-core" "homelab-media" ;;
        3)
            SELECTED_PROFILES=()
            PROFILE_SERVICES=()
            PROFILE_REQUIRES_GATEWAY=1
            PROFILE_FAMILY="homelab"
            export PROFILE_REQUIRES_GATEWAY PROFILE_FAMILY
            export INIT_USE_FZF=1
            return 0
            ;;
        *)
            print_status "Invalid choice" "error"
            return 1
            ;;
    esac
}

profile_has_gateway_services() {
    local svc
    for svc in "${PROFILE_SERVICES[@]}"; do
        case "$svc" in
            gateway/*) return 0 ;;
        esac
    done
    return 1
}

# Non-gateway services from loaded profiles
profile_app_services() {
    local svc
    for svc in "${PROFILE_SERVICES[@]}"; do
        case "$svc" in
            gateway/*) ;;
            *) echo "$svc" ;;
        esac
    done
}
