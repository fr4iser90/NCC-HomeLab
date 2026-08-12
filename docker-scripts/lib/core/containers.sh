#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_CONTAINERS_LOADED+x}" ]; then
    return 0
fi
_CONTAINERS_LOADED=1

# Catalog groups → services (paths under catalog/<group>/<service>)
declare -gA MANAGEMENT_CATEGORIES=(
    ["url"]="yourls"
    ["honeypot"]="tarpit"
    ["media"]="plex jellyfin owncast"
    ["dashboard"]="organizr"
    ["adblocker"]="pihole"
    ["storage"]="owncloud"
    ["gateway"]="traefik-crowdsec ddns-updater"
    ["companion"]="cloudflare"
    ["password"]="bitwarden"
    ["vpn"]="wireguard"
    ["system"]="portainer watchtower"
    ["games"]="pufferpanel"
    ["compute"]="ollama llama-cpp opencode comfyui open-webui"
)

# Get container category
get_container_category() {
    local container="$1"
    
    for category in "${!MANAGEMENT_CATEGORIES[@]}"; do
        if [[ "${MANAGEMENT_CATEGORIES[$category]}" =~ $container ]]; then
            echo "$category"
            return 0
        fi
    done
    
    return 1
}
