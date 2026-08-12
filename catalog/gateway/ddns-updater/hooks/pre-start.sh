#!/bin/bash
# DDNS domain env + ddclient.conf (PUID via contract.env)
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="ddns-updater"
ENV_FILE="ddns-updater.env"
CONF_FILE="config/ddclient.conf"

print_header "DDNS updater pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

update_env_file "$BASE_DIR" "$ENV_FILE" "DOMAIN:$DOMAIN" || exit 1

if [ -f "$BASE_DIR/$ENV_FILE" ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' "$BASE_DIR/$ENV_FILE" | xargs) 2>/dev/null || true
fi
DOMAIN="${DOMAIN:-default-domain.com}"
CF_TOKEN="${CF_TOKEN:-default-cf-token}"
GANDIV5_PERSONAL_ACCESS_TOKEN="${GANDIV5_PERSONAL_ACCESS_TOKEN:-default-gandi-token}"
PORKBUN_API_KEY="${PORKBUN_API_KEY:-default-porkbun-api-key}"
PORKBUN_SECRET_API_KEY="${PORKBUN_SECRET_API_KEY:-default-porkbun-secret-api-key}"

validate_domain || exit 1

protocol_to_uncomment="${DNS_PROVIDER_CODE:-}"
if [ -z "$protocol_to_uncomment" ]; then
    print_status "DNS_PROVIDER_CODE not set — writing placeholders only" "warn"
fi

cp "$BASE_DIR/$CONF_FILE" "$BASE_DIR/$CONF_FILE.bak" 2>/dev/null || true

replace_placeholders_in_conf "$BASE_DIR" "$CONF_FILE" \
    "DOMAIN:$DOMAIN" \
    "CF_TOKEN:$CF_TOKEN" \
    "GANDIV5_PERSONAL_ACCESS_TOKEN:$GANDIV5_PERSONAL_ACCESS_TOKEN" \
    "PORKBUN_API_KEY:$PORKBUN_API_KEY" \
    "PORKBUN_SECRET_API_KEY:$PORKBUN_SECRET_API_KEY"

if [ -n "$protocol_to_uncomment" ]; then
    awk -v protocol="$protocol_to_uncomment" '
    BEGIN { start_block = 0; end_block = 0 }
    /^##/ {
        if (start_block && /## /) { end_block = 1 }
        if (end_block) exit
    }
    /^## / {
        if (start_block == 0 && tolower($0) ~ tolower(protocol)) { start_block = 1 }
    }
    {
        if (start_block && !end_block) {
            sub(/^##\s*/, "");
            sub(/^#\s*/, "");
        }
        print
    }
    ' "$BASE_DIR/$CONF_FILE" > "$BASE_DIR/$CONF_FILE.tmp"
    mv "$BASE_DIR/$CONF_FILE.tmp" "$BASE_DIR/$CONF_FILE"
fi

print_status "DDNS updater configured" "success"
