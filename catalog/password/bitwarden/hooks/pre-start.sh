#!/bin/bash
# Vaultwarden admin token + domain
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="bitwarden"
ENV_FILE="bitwarden.env"

print_header "Bitwarden pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1
validate_domain || exit 1

username="admin"
export CURRENT_USERNAME="$username"
admin_password=$(prompt_input "Bitwarden admin password" $INPUT_TYPE_PASSWORD) || exit 1
ADMIN_TOKEN=$(hash_password "$admin_password") || exit 1
ADMIN_TOKEN_ESCAPED=$(escape_for_sed "$ADMIN_TOKEN")

store_service_credentials "$SERVICE_NAME" "$username" "$admin_password"

update_env_file "$BASE_DIR" "$ENV_FILE" \
    "ADMIN_TOKEN:$ADMIN_TOKEN_ESCAPED" \
    "DOMAIN:https://bw.$DOMAIN" \
    "WEBSOCKET_ENABLED:true" || exit 1

print_status "Bitwarden environment configured" "success"
