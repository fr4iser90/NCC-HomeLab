#!/bin/bash

# Homelab installer — applies one or more homelab profiles.
# Profiles:
#   homelab-core   gateway + companion + system (base; run this first / alone)
#   homelab-media  jellyfin/plex/owncast (additive; needs gateway from core)
#
# Usage:
#   ./init-homelab.sh
#   ./init-homelab.sh --profile homelab-core
#   ./init-homelab.sh --profile homelab-core --profile homelab-media

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DOCKER_SCRIPTS_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"

if [ ! -f "${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh" ]; then
    echo "Error: Script directory structure invalid"
    echo "Expected: ${DOCKER_SCRIPTS_DIR}/lib/core/imports.sh"
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
            echo "Profiles: homelab-core, homelab-media (combinable)"
            echo "Default: interactive (core | core+media | fzf)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

print_header "Homelab Setup"
get_user_info
get_homelab_domain
ask_credential_preference

if [ "$EUID" -eq 0 ]; then
    print_status "This script should NOT be run as root" "error"
    print_status "Please run as normal user who is member of the docker group" "info"
    exit 1
fi

if ! groups | grep -q docker; then
    print_status "Current user must be in the docker group" "error"
    print_status "Run: sudo usermod -aG docker $USER" "info"
    print_status "Then log out and back in" "info"
    exit 1
fi

INIT_USE_FZF=0
if [ ${#CLI_PROFILES[@]} -gt 0 ]; then
    load_profiles "${CLI_PROFILES[@]}" || exit 1
else
    prompt_homelab_profiles || exit 1
fi

if [ "${INIT_USE_FZF:-0}" -eq 0 ]; then
    print_status "Selected profiles: ${SELECTED_PROFILES[*]}" "info"
    print_status "Services: ${PROFILE_SERVICES[*]}" "info"
fi

print_header "Component Initialization"

print_status "Setting up permissions..." "info"
if ! setup_permissions; then
    print_status "Failed to set permissions" "error"
    exit 1
fi

print_header "Network Setup"
print_status "The following ports need to be forwarded in your router:" "info"
list_required_ports

if prompt_confirmation "Would you like to open your router configuration page now?"; then
    if ! find_router; then
        print_status "Could not open router page automatically" "warn"
        print_status "Please configure port forwarding manually" "info"
    else
        print_status "Please configure the listed ports in your router" "info"
        if prompt_confirmation "Continue when port forwarding is configured?"; then
            test_port_forwarding
        fi
    fi
fi

# Gateway when required (core, media, or fzf custom)
if [ "${PROFILE_REQUIRES_GATEWAY:-0}" -eq 1 ] || [ "${INIT_USE_FZF:-0}" -eq 1 ]; then
    if ! initialize_gateway; then
        print_status "Failed to initialize security infrastructure" "error"
        exit 1
    fi
fi

print_status "Initializing application services..." "info"
if [ "${INIT_USE_FZF:-0}" -eq 1 ]; then
    if ! initialize_services; then
        print_status "Failed to initialize docker services" "error"
        exit 1
    fi
else
    if ! initialize_services_from_profiles; then
        print_status "Failed to initialize profile services" "error"
        exit 1
    fi
fi

print_header "Setup Complete"
print_status "Homelab initialization completed successfully!" "success"
if [ ${#SELECTED_PROFILES[@]} -gt 0 ]; then
    print_status "Profiles applied: ${SELECTED_PROFILES[*]}" "info"
fi
