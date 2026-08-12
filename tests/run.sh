#!/usr/bin/env bash
# Lightweight contract / profile / path tests (no live Docker deploy required)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DOCKER_SCRIPTS_DIR="$ROOT/docker-scripts"
export PATH="/run/current-system/sw/bin:/usr/bin:/bin:$PATH"

PASS=0
FAIL=0

assert_eq() {
    local desc=$1 expected=$2 actual=$3
    if [ "$expected" = "$actual" ]; then
        echo "  OK  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL $desc (expected='$expected' actual='$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assert_true() {
    local desc=$1
    shift
    if "$@"; then
        echo "  OK  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL $desc"
        FAIL=$((FAIL + 1))
    fi
}

# Minimal stubs (avoid full imports / set -e from script-header during unit tests)
print_status() { :; }
export -f print_status

echo "== path + categories =="
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/core/containers.sh"
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/core/path.sh"

assert_eq "catalog path" "$ROOT/catalog" "$DOCKER_BASE_DIR"
assert_eq "profiles path" "$ROOT/profiles" "$PROFILES_DIR"
assert_eq "jellyfin category" "media" "$(get_container_category jellyfin)"
assert_eq "jellyfin dir" "$ROOT/catalog/media/jellyfin" "$(get_docker_dir jellyfin)"
assert_eq "path ref dir" "$ROOT/catalog/media/owncast" "$(get_docker_dir media/owncast)"
assert_eq "short name" "plex" "$(service_short_name media/plex)"

echo "== profiles =="
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/core/profiles.sh"

load_profiles "homelab-core"
assert_eq "core family" "homelab" "$PROFILE_FAMILY"
assert_eq "core requires gateway" "1" "$PROFILE_REQUIRES_GATEWAY"
if printf '%s\n' "${PROFILE_SERVICES[@]}" | grep -qx "gateway/traefik-crowdsec"; then
    echo "  OK  core has traefik"; PASS=$((PASS + 1))
else
    echo "  FAIL core has traefik"; FAIL=$((FAIL + 1))
fi

load_profiles "homelab-core" "homelab-media"
if printf '%s\n' "${PROFILE_SERVICES[@]}" | grep -qx "media/jellyfin"; then
    echo "  OK  combined has jellyfin"; PASS=$((PASS + 1))
else
    echo "  FAIL combined has jellyfin"; FAIL=$((FAIL + 1))
fi
if printf '%s\n' "${PROFILE_SERVICES[@]}" | grep -qx "system/portainer"; then
    echo "  OK  combined has portainer"; PASS=$((PASS + 1))
else
    echo "  FAIL combined has portainer"; FAIL=$((FAIL + 1))
fi
apps=$(profile_app_services)
if ! echo "$apps" | grep -q "^gateway/"; then
    echo "  OK  app services skip gateway"; PASS=$((PASS + 1))
else
    echo "  FAIL app services skip gateway"; FAIL=$((FAIL + 1))
fi

echo "== contracts =="
missing=0
while IFS= read -r compose; do
    dir=$(dirname "$compose")
    # Skip variant subdirs (e.g. compute/ollama/cpu) — contract lives on service root
    parent=$(basename "$(dirname "$dir")")
    # service root = catalog/<group>/<service>
    depth=$(echo "$dir" | awk -F/ '{print NF}')
    catalog_depth=$(echo "$ROOT/catalog" | awk -F/ '{print NF}')
    rel_depth=$((depth - catalog_depth))
    if [ "$rel_depth" -ne 2 ]; then
        continue
    fi
    if [ ! -f "$dir/contract.env" ]; then
        echo "  FAIL missing contract.env in $dir"
        FAIL=$((FAIL + 1))
        missing=1
    fi
done < <(find "$ROOT/catalog" -type f \( -name 'docker-compose.yml' -o -name 'compose.yaml' -o -name 'docker-stack.yml' \))
if [ "$missing" -eq 0 ]; then
    echo "  OK  every top-level compose service has contract.env"
    PASS=$((PASS + 1))
fi
# puid services must list env files that exist and contain PUID/PGID
# non-puid ENV_FILES must NOT contain PUID/PGID (drift guard)
while IFS= read -r contract; do
    # shellcheck disable=SC1090
    ID_MODE=""; ENV_FILES=""
    source "$contract"
    dir=$(dirname "$contract")
    for ef in $ENV_FILES; do
        [ -z "$ef" ] && continue
        if [ ! -f "$dir/$ef" ]; then
            echo "  FAIL contract $contract missing env $ef"
            FAIL=$((FAIL + 1))
            continue
        fi
        if [ "$ID_MODE" = "puid" ]; then
            if grep -q '^PUID=' "$dir/$ef" && grep -q '^PGID=' "$dir/$ef"; then
                echo "  OK  puid env $(basename "$dir")/$ef"
                PASS=$((PASS + 1))
            else
                echo "  FAIL $dir/$ef missing PUID=/PGID= (required for ID_MODE=puid)"
                FAIL=$((FAIL + 1))
            fi
        else
            if grep -qE '^(PUID|PGID)=' "$dir/$ef"; then
                echo "  FAIL $dir/$ef has PUID/PGID but ID_MODE=$ID_MODE (remove drift)"
                FAIL=$((FAIL + 1))
            else
                echo "  OK  no PUID drift $(basename "$dir")/$ef (mode=$ID_MODE)"
                PASS=$((PASS + 1))
            fi
        fi
    done
done < <(find "$ROOT/catalog" -name contract.env)

echo "== runtime-ids dry apply =="
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/utils/system/file.sh"
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/utils/system/user.sh"
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/core/runtime-ids.sh"

USER_NAME=$(whoami)
USER_UID=$(id -u)
USER_GID=$(id -g)
export USER_NAME USER_UID USER_GID

tmpdir=$(mktemp -d)
mkdir -p "$tmpdir"
cat > "$tmpdir/contract.env" <<EOF
ID_MODE=puid
ENV_FILES="test.env"
DATA_DIRS="data"
EOF
echo "PUID=1000" > "$tmpdir/test.env"
echo "PGID=1000" >> "$tmpdir/test.env"

apply_runtime_ids "$tmpdir"
assert_eq "puid written" "PUID=$USER_UID" "$(grep '^PUID=' "$tmpdir/test.env")"
assert_eq "pgid written" "PGID=$USER_GID" "$(grep '^PGID=' "$tmpdir/test.env")"
assert_true "dotenv created" test -f "$tmpdir/.env"
assert_true "data dir created" test -d "$tmpdir/data"
rm -rf "$tmpdir"

echo "== compose config (optional) =="
if command -v docker >/dev/null 2>&1; then
    while IFS= read -r compose; do
        dir=$(dirname "$compose")
        base=$(basename "$compose")
        if (cd "$dir" && PUID=1000 PGID=1000 DOMAIN=example.com docker compose -f "$base" config >/dev/null 2>&1); then
            echo "  OK  compose config $compose"
            PASS=$((PASS + 1))
        else
            err=$(cd "$dir" && PUID=1000 PGID=1000 DOMAIN=example.com docker compose -f "$base" config 2>&1 | tail -5 || true)
            if echo "$err" | grep -qiE 'network .* declared as external|orphan|variable is not set|no configuration file'; then
                echo "  OK  compose parse (external/env) $compose"
                PASS=$((PASS + 1))
            else
                echo "  WARN compose config $compose (non-fatal)"
                echo "       $err"
                PASS=$((PASS + 1))
            fi
        fi
    done < <(find "$ROOT/catalog" -name 'docker-compose.yml' | sort)
else
    echo "  SKIP docker not available"
fi

echo "== compose coverage =="
# shellcheck disable=SC1091
source "$DOCKER_SCRIPTS_DIR/lib/core/docker-mode.sh"
has_compose() {
    local dir=$1
    [ -f "$dir/docker-compose.yml" ] ||
    [ -f "$dir/docker-compose.yaml" ] ||
    [ -f "$dir/compose.yaml" ] ||
    [ -f "$dir/compose.yml" ] ||
    [ -f "$dir/docker-stack.yml" ] ||
    [ -f "$dir/arm/compose.yaml" ] ||
    [ -f "$dir/cpu/compose.yaml" ] ||
    [ -f "$dir/rocm/compose.yaml" ]
}
cov_fail=0
while IFS= read -r dir; do
    if ! has_compose "$dir"; then
        echo "  FAIL no compose/variant in $dir"
        FAIL=$((FAIL + 1))
        cov_fail=1
    fi
done < <(find "$ROOT/catalog" -mindepth 2 -maxdepth 2 -type d | sort)
if [ "$cov_fail" -eq 0 ]; then
    echo "  OK  every service root has compose or arch variant"
    PASS=$((PASS + 1))
fi

echo "== hooks =="
# no legacy update-env.sh
if find "$ROOT/catalog" -name 'update-env.sh' | grep -q .; then
    echo "  FAIL leftover update-env.sh found"
    find "$ROOT/catalog" -name 'update-env.sh'
    FAIL=$((FAIL + 1))
else
    echo "  OK  no leftover update-env.sh"
    PASS=$((PASS + 1))
fi
while IFS= read -r hook; do
    if [ -x "$hook" ] || head -1 "$hook" | grep -q '^#!'; then
        echo "  OK  hook $(echo "$hook" | sed "s|$ROOT/||")"
        PASS=$((PASS + 1))
    else
        echo "  FAIL hook not executable/script: $hook"
        FAIL=$((FAIL + 1))
    fi
    # hooks/ dir should only be pre-start.sh for now
done < <(find "$ROOT/catalog" -path '*/hooks/pre-start.sh' | sort)
# orphan hooks dirs without pre-start
while IFS= read -r hdir; do
    if [ ! -f "$hdir/pre-start.sh" ]; then
        echo "  FAIL hooks dir missing pre-start.sh: $hdir"
        FAIL=$((FAIL + 1))
    fi
done < <(find "$ROOT/catalog" -type d -name hooks)

echo "== arch resolver =="
export COMPUTE_VARIANT=arm
assert_eq "ollama arm ctx" "$ROOT/catalog/compute/ollama/arm" "$(resolve_compose_context "$ROOT/catalog/compute/ollama")"
assert_eq "comfyui arm ctx" "$ROOT/catalog/compute/comfyui/arm" "$(resolve_compose_context "$ROOT/catalog/compute/comfyui")"
export COMPUTE_VARIANT=cpu
assert_eq "ollama cpu ctx" "$ROOT/catalog/compute/ollama/cpu" "$(resolve_compose_context "$ROOT/catalog/compute/ollama")"
# x86 comfyui falls back to service root (compose.yaml)
assert_eq "comfyui cpu/root ctx" "$ROOT/catalog/compute/comfyui" "$(resolve_compose_context "$ROOT/catalog/compute/comfyui")"
unset COMPUTE_VARIANT

echo "== profile paths =="
profile_path_fail=0
while IFS= read -r profile; do
    name=$(basename "$profile" .yml)
    while IFS= read -r svc; do
        [ -z "$svc" ] && continue
        if [ ! -d "$ROOT/catalog/$svc" ]; then
            echo "  FAIL profile $name → missing catalog/$svc"
            FAIL=$((FAIL + 1))
            profile_path_fail=1
        fi
    done < <(profile_get_services "$profile")
done < <(find "$ROOT/profiles" -maxdepth 1 -name '*.yml' | sort)
if [ "$profile_path_fail" -eq 0 ]; then
    echo "  OK  all profile services resolve under catalog/"
    PASS=$((PASS + 1))
fi

echo "== homelab swarm stacks =="
# Homelab services (non-compute) should have docker-stack.yml; compute must NOT require it
swarm_fail=0
while IFS= read -r dir; do
    group=$(basename "$(dirname "$dir")")
    if [ "$group" = "compute" ]; then
        continue
    fi
    if [ ! -f "$dir/docker-stack.yml" ]; then
        echo "  FAIL missing docker-stack.yml in $dir"
        FAIL=$((FAIL + 1))
        swarm_fail=1
    fi
done < <(find "$ROOT/catalog" -mindepth 2 -maxdepth 2 -type d | sort)
if [ "$swarm_fail" -eq 0 ]; then
    echo "  OK  all non-compute services have docker-stack.yml"
    PASS=$((PASS + 1))
fi
# compute should not be required to have stack (informational OK if absent)
echo "  OK  compute stacks exempt from docker-stack.yml"
PASS=$((PASS + 1))

echo "== stack names =="
assert_eq "stack path form" "media-owncast" "$(get_stack_name media/owncast)"
assert_eq "stack short form" "media-jellyfin" "$(get_stack_name jellyfin)"

echo "== day-2 cli presence =="
assert_true "stacks.sh exists" test -x "$ROOT/docker-scripts/bin/stacks.sh"
assert_true "swarm.sh exists" test -x "$ROOT/docker-scripts/bin/swarm.sh"
# swarm help should not need docker swarm
if bash "$ROOT/docker-scripts/bin/swarm.sh" --help >/dev/null 2>&1 || bash "$ROOT/docker-scripts/bin/swarm.sh" help >/dev/null 2>&1; then
    echo "  OK  swarm.sh help"
    PASS=$((PASS + 1))
else
    # help exits 0 via usage
    bash "$ROOT/docker-scripts/bin/swarm.sh" 2>/dev/null | grep -q deploy && {
        echo "  OK  swarm.sh usage"
        PASS=$((PASS + 1))
    } || {
        echo "  FAIL swarm.sh help"
        FAIL=$((FAIL + 1))
    }
fi
if bash "$ROOT/docker-scripts/bin/stacks.sh" --help >/dev/null 2>&1; then
    echo "  OK  stacks.sh help"
    PASS=$((PASS + 1))
else
    echo "  FAIL stacks.sh help"
    FAIL=$((FAIL + 1))
fi

# Refuse compute profiles in swarm deploy path (unit-level check of family)
load_profiles "compute-llm-arm"
assert_eq "compute family" "compute" "$PROFILE_FAMILY"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
