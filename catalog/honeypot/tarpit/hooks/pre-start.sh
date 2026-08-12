#!/bin/bash
# Grafana admin credentials for tarpit stack
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="tarpit"
ENV_FILE="grafana.env"

print_header "Tarpit/Grafana pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

username=$(prompt_input "Enter Grafana username" $INPUT_TYPE_USERNAME) || exit 1
password=$(prompt_input "Enter Grafana password" $INPUT_TYPE_PASSWORD) || exit 1

escaped_password=$(echo "$password" | sed 's/[\/&]/\\&/g')
escaped_username=$(echo "$username" | sed 's/[\/&]/\\&/g')

update_env_file "$BASE_DIR" "$ENV_FILE" \
    "GF_SECURITY_ADMIN_USER:$escaped_username" \
    "GF_SECURITY_ADMIN_PASSWORD:$escaped_password" || exit 1

store_service_credentials "$SERVICE_NAME" "$username" "$password"
print_status "Grafana credentials configured" "success"
