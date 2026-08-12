#!/bin/bash

# Guard gegen mehrfaches Laden
if [ -n "${_HOOKS_LOADED+x}" ]; then
    return 0
fi
_HOOKS_LOADED=1

# Optional per-service setup: catalog/<group>/<service>/hooks/pre-start.sh
# Used for credentials, tokens, DNS config — NOT for PUID/PGID (see runtime-ids + contract.env).
run_pre_start_hook() {
    local service_dir=$1
    local hook="${service_dir}/hooks/pre-start.sh"

    if [ ! -f "$hook" ]; then
        return 0
    fi

    print_status "Running hooks/pre-start.sh in $(basename "$service_dir")..." "info"
    if ! bash "$hook"; then
        print_status "pre-start hook failed for $service_dir" "error"
        return 1
    fi
    return 0
}
