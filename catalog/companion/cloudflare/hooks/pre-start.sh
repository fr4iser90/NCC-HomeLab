#!/bin/bash
# Cloudflare companion credentials (no PUID)
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="cloudflare"
ENV_FILE="cloudflare-companion.env"

print_header "Cloudflare companion pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

if [ -z "${CF_API_EMAIL:-}" ] || [ -z "${CF_TOKEN:-}" ] || [ -z "${CF_ZONE_ID:-}" ]; then
    print_status "No Cloudflare credentials found — skipping" "warn"
    exit 0
fi

validate_domain || exit 1

if [[ ! "$CF_API_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    print_status "Invalid Cloudflare email — skipping" "warn"
    exit 0
fi
if [[ ${#CF_TOKEN} -lt 30 ]]; then
    print_status "Cloudflare API token seems too short — skipping" "warn"
    exit 0
fi
if [[ ! "$CF_ZONE_ID" =~ ^[a-f0-9]{32}$ ]]; then
    print_status "Invalid Cloudflare Zone ID — skipping" "warn"
    exit 0
fi

store_service_credentials "$SERVICE_NAME" "$CF_API_EMAIL" "$CF_TOKEN"

new_values=(
    "#CF_EMAIL:$CF_API_EMAIL"
    "#CF_API_KEY:$CF_API_KEY"
    "CF_TOKEN:$CF_TOKEN"
    "DOMAIN1_ZONE_ID:$CF_ZONE_ID"
    "TARGET_DOMAIN:$DOMAIN"
    "DOMAIN1:$DOMAIN"
)

update_env_file "$BASE_DIR" "$ENV_FILE" "${new_values[@]}" || exit 1

CHECK_SCRIPT="${BASE_DIR}/check-token.sh"
if [ -f "$CHECK_SCRIPT" ]; then
    chmod +x "$CHECK_SCRIPT"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "cloudflare-companion"; then
        bash "$CHECK_SCRIPT" || true
    fi
fi

print_status "Cloudflare companion configured" "success"
