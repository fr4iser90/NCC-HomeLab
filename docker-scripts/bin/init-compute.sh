#!/bin/bash

# Compute installer — applies compute-* profiles (no Traefik/gateway).
#
# Usage:
#   ./init-compute.sh
#   ./init-compute.sh --profile compute-llm-arm
#   ./init-compute.sh --profile compute-llm-x86
#   COMPUTE_GPU=rocm ./init-compute.sh --profile compute-llm-x86
#   COMPUTE_VARIANT=arm ./init-compute.sh --profile compute-llm-arm

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOCKER_SCRIPTS_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"

if [ ! -f "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh" ]; then
    echo "Error: Script directory structure invalid"
    exit 1
fi

source "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"

CLI_PROFILES=()
while [ $# -gt 0 ]; do
    case "$1" in
        --profile|-p)
            shift
            [ -n "${1:-}" ] || { echo "Missing profile name"; exit 1; }
            CLI_PROFILES+=("$1")
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--profile NAME]..."
            echo "Profiles: compute-llm-arm, compute-llm-x86"
            echo "Overrides: COMPUTE_VARIANT=arm|cpu|rocm  COMPUTE_GPU=rocm"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

ensure_ai_network() {
    if ! command -v docker >/dev/null 2>&1; then
        print_status "docker not found" "error"
        return 1
    fi
    if docker network inspect ai-net >/dev/null 2>&1; then
        print_status "Network ai-net already exists" "info"
        return 0
    fi
    print_status "Creating docker network ai-net..." "info"
    docker network create ai-net
}

prompt_compute_profiles() {
    print_header "Compute Profiles"
    local arch
    arch=$(uname -m)
    print_status "Host arch: $arch" "info"
    echo
    echo "1) compute-llm-arm  (ollama + open-webui; aarch64)"
    echo "2) compute-llm-x86  (ollama + llama-cpp + opencode)"
    echo
    local choice default
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        default=1
    else
        default=2
    fi
    read -r -p "Enter choice [1/2] (default $default): " choice
    choice=${choice:-$default}
    case "$choice" in
        1) load_profiles "compute-llm-arm" ;;
        2) load_profiles "compute-llm-x86" ;;
        *) print_status "Invalid choice" "error"; return 1 ;;
    esac
}

print_header "Compute Setup"
get_user_info

if [ "$EUID" -eq 0 ]; then
    print_status "Do not run as root" "error"
    exit 1
fi

if ! groups | grep -q docker; then
    print_status "User must be in the docker group" "error"
    exit 1
fi

if [ ${#CLI_PROFILES[@]} -gt 0 ]; then
    load_profiles "${CLI_PROFILES[@]}" || exit 1
else
    prompt_compute_profiles || exit 1
fi

if [ "${PROFILE_FAMILY:-}" != "compute" ] && [ -n "${PROFILE_FAMILY:-}" ]; then
    print_status "Profile family is '$PROFILE_FAMILY' — use init-homelab for homelab profiles" "warn"
fi

print_status "Selected: ${SELECTED_PROFILES[*]}" "info"
print_status "Services: ${PROFILE_SERVICES[*]}" "info"
print_status "Compose variant: $(detect_compute_variant)" "info"

print_header "Permissions"
setup_permissions || exit 1

print_header "Network"
ensure_ai_network || exit 1

print_header "Services"
initialize_services_from_profiles || exit 1

print_header "Setup Complete"
print_status "Compute initialization completed" "success"
print_status "Profiles: ${SELECTED_PROFILES[*]}" "info"
