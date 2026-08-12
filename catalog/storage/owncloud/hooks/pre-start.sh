#!/bin/bash
# OwnCloud MySQL password + domain
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="owncloud"
ENV_FILE="mysql.env"

print_header "OwnCloud pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1
validate_domain || exit 1

MYSQL_ROOT_PASSWORD=$(generate_auto_password) || exit 1
store_service_credentials "$SERVICE_NAME" "mysql_root" "$MYSQL_ROOT_PASSWORD"

update_env_file "$BASE_DIR" "$ENV_FILE" \
    "MYSQL_ROOT_PASSWORD:$MYSQL_ROOT_PASSWORD" \
    "APACHE_SERVER_NAME:$DOMAIN" || exit 1

print_status "OwnCloud environment configured" "success"
