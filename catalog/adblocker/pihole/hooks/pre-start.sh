#!/bin/bash
# Service-specific pre-start: Pi-hole web password
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="pihole"
ENV_FILE="pihole.env"

print_header "Pi-hole pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

WEBPASSWORD=$(generate_auto_password) || exit 1
store_service_credentials "$SERVICE_NAME" "admin" "$WEBPASSWORD"

update_env_file "$BASE_DIR" "$ENV_FILE" "WEBPASSWORD:$WEBPASSWORD" || exit 1
print_status "Pi-hole web password configured" "success"
