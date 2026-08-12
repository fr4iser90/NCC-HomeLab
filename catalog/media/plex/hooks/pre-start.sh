#!/bin/bash
# Plex claim token
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="plex"
ENV_FILE="plex.env"

print_header "Plex pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

print_status "Open https://plex.${DOMAIN}/claim and copy the token" "info"
PLEX_CLAIM=$(prompt_input "PLEX_CLAIM token" $INPUT_TYPE_TOKEN) || exit 1

update_env_file "$BASE_DIR" "$ENV_FILE" "PLEX_CLAIM:$PLEX_CLAIM" || exit 1
print_status "Plex claim token configured" "success"
