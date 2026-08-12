#!/bin/bash
# WireGuard UI credentials
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="wireguard"
ENV_FILE="wireguard.env"

print_header "WireGuard pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

username=$(prompt_input "WireGuard username" $INPUT_TYPE_USERNAME) || exit 1
export CURRENT_USERNAME="$username"
password=$(prompt_input "WireGuard password" $INPUT_TYPE_PASSWORD) || exit 1
store_service_credentials "$SERVICE_NAME" "$username" "$password"

escaped_password=$(echo "$password" | sed 's/[\/&]/\\&/g')
escaped_username=$(echo "$username" | sed 's/[\/&]/\\&/g')

update_env_file "$BASE_DIR" "$ENV_FILE" \
    "WGUI_USERNAME:$escaped_username" \
    "WGUI_PASSWORD:$escaped_password" \
    "WGUI_MANAGE_START:true" \
    "WGUI_MANAGE_RESTART:true" || exit 1

print_status "WireGuard credentials configured" "success"
