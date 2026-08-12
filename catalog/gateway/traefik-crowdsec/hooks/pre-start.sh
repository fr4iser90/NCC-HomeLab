#!/bin/bash
# Traefik + CrowdSec pre-start: collections + map installer DNS creds into traefik.env
source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

SERVICE_NAME="traefik-crowdsec"

print_header "Traefik/CrowdSec pre-start"

BASE_DIR=$(get_docker_dir "$SERVICE_NAME") || exit 1

chmod 600 "$BASE_DIR/traefik/acme_letsencrypt.json" "$BASE_DIR/traefik/tls_letsencrypt.json" 2>/dev/null || true

COLLECTIONS="crowdsecurity/traefik crowdsecurity/http-cve crowdsecurity/whitelist-good-actors crowdsecurity/postfix crowdsecurity/dovecot crowdsecurity/nginx"
update_env_file "$BASE_DIR" "crowdsec.env" "COLLECTIONS:$COLLECTIONS" || exit 1

# Traefik ACME DNS-01 expects CLOUDFLARE_* ; installer collects CF_*
traefik_values=()

if [ -n "${CF_TOKEN:-}" ]; then
    traefik_values+=("CLOUDFLARE_DNS_API_TOKEN:$CF_TOKEN")
fi
if [ -n "${CF_API_EMAIL:-}" ]; then
    traefik_values+=("CLOUDFLARE_EMAIL:$CF_API_EMAIL")
fi
if [ -n "${EMAIL:-}" ]; then
    traefik_values+=("EMAIL:$EMAIL")
elif [ -n "${CF_API_EMAIL:-}" ]; then
    # fallback: use Cloudflare account email for Let's Encrypt contact
    traefik_values+=("EMAIL:$CF_API_EMAIL")
fi

# Also pass through any already-exported CLOUDFLARE_*/AWS_/… vars
for var in $(env | grep -E '^(AWS_|CLOUDFLARE_|GOOGLE_|AZURE_|DO_)' | cut -d= -f1); do
    # avoid duplicating keys we already set
    case "$var" in
        CLOUDFLARE_DNS_API_TOKEN|CLOUDFLARE_EMAIL) continue ;;
    esac
    traefik_values+=("$var:${!var}")
done

if [ ${#traefik_values[@]} -gt 0 ]; then
    update_env_file "$BASE_DIR" "traefik.env" "${traefik_values[@]}" || exit 1
fi

le_email="${EMAIL:-${CF_API_EMAIL:-}}"
if [ -n "$le_email" ]; then
    update_conf_file "$BASE_DIR" "traefik/traefik.yml" "EMAIL:$le_email" || true
fi

print_status "Traefik/CrowdSec pre-start done" "success"
