# Implementierungsplan: Rootful/Rootless/Swarm Unterstützung

## Übersicht

**Ziel:** Automatische Erkennung und Auswahl der passenden Docker-Compose-Datei basierend auf:
- Docker-Modus (rootful/rootless)
- Swarm-Status (aktiv/inaktiv)

**Ansatz:** Separate Dateien für jeden Modus - einfach und klar

---

## Entscheidungen ✅

### 1. Log-Verzeichnisse
**✅ Entscheidung: Option B** - Service-relativ (`./logs/`)
- Rootful: `/var/log/...`
- Rootless: `./logs/...`

### 2. Ports < 1024
**✅ Entscheidung: Option A** - CAP_NET_BIND_SERVICE
- Rootless kann Ports < 1024 nutzen wenn CAP gesetzt ist
- Traefik: `80:80`, `443:443` (beide Modi)
- Pi-hole: `53:53` (beide Modi)

### 3. Stack-Namen
**✅ Entscheidung:** `<category>-<service>`
- Beispiel: `gateway-management-traefik-crowdsec`
- Format: Kategorie + Bindestrich + Service-Name

### 4. Git-Ignore
**✅ Entscheidung:**
- Generierte Dateien: **NEIN** (keine generierten Dateien)
- Alle Dateien werden committed (docker-compose.yml, docker-compose.rootless.yml, docker-stack.yml)

### 5. Datei-Struktur
**✅ Entscheidung: Separate Dateien**
```
docker/
  service-name/
    docker-compose.yml          # Rootful (Standard)
    docker-compose.rootless.yml # Rootless-Variante
    docker-stack.yml            # Swarm
```

---

## Phase 1: Docker-Modus-Erkennung

### 1.1 Neue Datei: `docker-scripts/lib/core/docker-mode.sh`

**Zweck:** Docker-Modus-Erkennung und Helper-Funktionen

**Funktionen:**
```bash
# Hauptfunktion
detect_docker_mode()
# Gibt zurück: "rootful", "rootless", oder "swarm"

# Helper-Funktionen
is_docker_rootless()
is_docker_root()
is_swarm_active()
get_compose_file()  # Gibt passende Datei zurück
```

**Erkennungslogik:**
1. **Swarm prüfen:** `docker info 2>/dev/null | grep -q "Swarm: active"`
   - Wenn JA → `docker-stack.yml`
2. **Rootless prüfen:** `[ -S "$XDG_RUNTIME_DIR/docker.sock" ]`
   - Wenn JA → `docker-compose.rootless.yml`
3. **Root prüfen:** `[ -S "/var/run/docker.sock" ]` (Fallback)
   - Wenn JA → `docker-compose.yml`

**Implementierung:**
```bash
detect_docker_mode() {
    if is_swarm_active; then
        DOCKER_MODE="swarm"
        COMPOSE_FILE="docker-stack.yml"
    elif is_docker_rootless; then
        DOCKER_MODE="rootless"
        COMPOSE_FILE="docker-compose.rootless.yml"
    elif is_docker_root; then
        DOCKER_MODE="rootful"
        COMPOSE_FILE="docker-compose.yml"
    else
        DOCKER_MODE="unknown"
        COMPOSE_FILE="docker-compose.yml"  # Fallback
    fi
    
    export DOCKER_MODE
    export COMPOSE_FILE
}

is_swarm_active() {
    docker info 2>/dev/null | grep -q "Swarm: active"
}

is_docker_rootless() {
    [ -S "${XDG_RUNTIME_DIR}/docker.sock" ] 2>/dev/null
}

is_docker_root() {
    [ -S "/var/run/docker.sock" ] 2>/dev/null
}

get_compose_file() {
    local service_dir=$1
    detect_docker_mode
    
    # Prüfe ob Datei existiert
    if [ -f "$service_dir/$COMPOSE_FILE" ]; then
        echo "$COMPOSE_FILE"
        return 0
    fi
    
    # Fallback: docker-compose.yml
    if [ -f "$service_dir/docker-compose.yml" ]; then
        echo "docker-compose.yml"
        return 0
    fi
    
    return 1
}
```

---

## Phase 2: Integration in docker.sh

### 2.1 Anpassung: `docker-scripts/modules/services/docker.sh`

**Änderungen in `start_docker_container()`:**

```bash
start_docker_container() {
    local container=$1
    local docker_dir=$(get_docker_dir "$container")

    if [ -z "$docker_dir" ]; then
        print_status "Invalid container: $container" "error"
        return 1
    fi

    print_status "Starting $container" "info"

    # Check for update-env.sh
    if [ -f "$docker_dir/update-env.sh" ]; then
        print_status "Running environment updates..." "info"
        (cd "$docker_dir" && bash update-env.sh)
    fi

    # NEU: Docker-Modus erkennen und passende Datei wählen
    detect_docker_mode
    local compose_file=$(get_compose_file "$docker_dir")
    
    if [ -z "$compose_file" ]; then
        print_status "No compose file found for $container" "error"
        return 1
    fi
    
    print_status "Using $DOCKER_MODE mode with $compose_file" "info"

    if [ -d "$docker_dir" ]; then
        # NEU: Swarm vs Compose unterscheiden
        if [ "$DOCKER_MODE" = "swarm" ]; then
            local stack_name=$(get_stack_name "$container")
            (cd "$docker_dir" && docker stack deploy -c "$compose_file" "$stack_name")
        else
            (cd "$docker_dir" && docker compose -f "$compose_file" up -d)
        fi
        
        print_status "Container started successfully" "success"
        return 0
    else
        print_status "Container directory not found" "error"
        return 1
    fi
}
```

**Neue Funktion:**
```bash
get_stack_name() {
    local container=$1
    local category=$(get_container_category "$container")
    
    if [ -z "$category" ]; then
        echo "$container"  # Fallback
        return 1
    fi
    
    # Format: <category>-<service>
    echo "${category}-${container}"
}
```

**Anpassung in `restart_docker_container()`:**
```bash
restart_docker_container() {
    local container=$1
    local docker_dir=$(get_docker_dir "$container")

    if [ -z "$docker_dir" ]; then
        print_status "Invalid container: $container" "error"
        return 1
    fi

    detect_docker_mode
    local compose_file=$(get_compose_file "$docker_dir")
    
    if [ -z "$compose_file" ]; then
        print_status "No compose file found for $container" "error"
        return 1
    fi

    if [ -d "$docker_dir" ]; then
        print_status "Restarting $container" "info"
        
        if [ "$DOCKER_MODE" = "swarm" ]; then
            local stack_name=$(get_stack_name "$container")
            (cd "$docker_dir" && docker stack deploy -c "$compose_file" "$stack_name")
        else
            (cd "$docker_dir" && docker compose -f "$compose_file" up -d --force-recreate)
        fi
        
        print_status "Container restarted successfully" "success"
        return 0
    else
        print_status "Container directory not found" "error"
        return 1
    fi
}
```

---

## Phase 3: Services identifizieren & migrieren

### 3.1 Services die Migration benötigen

**Kritisch (Docker Socket + System-Pfade):**
1. ✅ **traefik-crowdsec** 
   - `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock` (rootless)
   - `/var/log/traefik` → `./logs/traefik` (rootless)
   - `/var/log/auth.log` → `./logs/auth.log` (rootless)
   - Ports bleiben gleich (CAP_NET_BIND_SERVICE)

2. ✅ **cloudflare-companion**
   - `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock` (rootless)

3. ✅ **portainer**
   - `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock` (rootless)

4. ✅ **watchtower**
   - `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock` (rootless)

**Optional (nur Ports < 1024):**
5. ⚠️ **pihole**
   - Port `53:53` bleibt gleich (CAP_NET_BIND_SERVICE)
   - Keine Änderung nötig wenn CAP gesetzt ist

**Nicht betroffen:**
- Services ohne Docker Socket
- Services ohne System-Pfade
- Services ohne Ports < 1024

---

## Phase 4: docker-compose.rootless.yml Erstellung

### 4.1 Migration-Schritte

**Für jeden betroffenen Service:**

1. **Kopieren:** `docker-compose.yml` → `docker-compose.rootless.yml`
2. **Anpassen:**
   ```yaml
   # Vorher (rootful):
   volumes:
     - /var/run/docker.sock:/var/run/docker.sock:ro
     - /var/log/traefik:/var/log/traefik
   ports:
     - "80:80"
     - "443:443"
   
   # Nachher (rootless):
   volumes:
     - ${XDG_RUNTIME_DIR}/docker.sock:/var/run/docker.sock:ro
     - ./logs/traefik:/var/log/traefik
   ports:
     - "80:80"    # Funktioniert mit CAP_NET_BIND_SERVICE
     - "443:443"
   ```

3. **Log-Verzeichnisse:** Erstelle `./logs/` Verzeichnisse für rootless

### 4.2 XDG_RUNTIME_DIR Voraussetzung

**Wichtig:** `${XDG_RUNTIME_DIR}` muss in der Shell-Umgebung exportiert sein!

**Mit NixOSControlCenter:**
- ✅ **Automatisch:** `XDG_RUNTIME_DIR` wird von NixOS-Config exportiert
- ✅ **Keine manuelle Konfiguration nötig**
- ✅ `${XDG_RUNTIME_DIR}/docker.sock` funktioniert direkt in docker-compose.rootless.yml

**Ohne NixOSControlCenter (andere Systeme):**
- ⚠️ **Manuell setzen:** Variable muss exportiert sein
- **Option 1:** In Shell-Config (`.bashrc` / `.zshrc`):
  ```bash
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
  ```
- **Option 2:** Vor docker compose Befehl:
  ```bash
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  docker compose -f docker-compose.rootless.yml up -d
  ```
- **Option 3:** In .env Datei (falls Docker Compose es nicht aus Shell liest):
  ```bash
  # .env Datei
  DOCKER_SOCKET_PATH=/run/user/1000/docker.sock
  ```
  ```yaml
  # docker-compose.rootless.yml
  volumes:
    - ${DOCKER_SOCKET_PATH}:/var/run/docker.sock:ro
  ```

**Prüfen ob Variable gesetzt ist:**
```bash
echo $XDG_RUNTIME_DIR
# Sollte zeigen: /run/user/1000 (oder ähnlich)
```

### 4.2 Spezielle Fälle

**traefik-crowdsec:**
- `crowdsec` Service: `/var/log/auth.log` → `./logs/auth.log`
- `traefik` Service: `/var/log/traefik` → `./logs/traefik`
- `ip-updater`: Keine Änderung (nur relative Pfade)

**pihole:**
- Port 53 bleibt gleich (CAP_NET_BIND_SERVICE)
- Keine Änderung nötig

---

## Phase 5: Log-Verzeichnisse

### 5.1 Rootless Log-Struktur

**Neue Verzeichnisse erstellen:**
```bash
# In init-homelab.sh oder separatem Script
if is_rootless; then
    # Für traefik-crowdsec
    mkdir -p "$DOCKER_BASE_DIR/gateway-management/traefik-crowdsec/logs/traefik"
    mkdir -p "$DOCKER_BASE_DIR/gateway-management/traefik-crowdsec/logs/auth"
    # ... weitere Services
fi
```

**Oder:** Automatisch beim ersten Start erstellen
```bash
# In docker.sh vor docker compose up
if [ "$DOCKER_MODE" = "rootless" ]; then
    # Erstelle Log-Verzeichnisse falls nötig
    create_log_directories "$docker_dir"
fi
```

---

## Phase 6: Integration in imports.sh

### 6.1 Neue Datei laden

**Anpassung: `docker-scripts/lib/core/imports.sh`**

```bash
# Core modules
CORE_MODULES=(
    "containers.sh"
    "path.sh"
    "docker-mode.sh"  # NEU
)
```

---

## Phase 7: Migration-Strategie

### 7.1 Schrittweise Migration

**Phase 7.1.1: Vorbereitung**
1. Neue Module erstellen (`docker-mode.sh`)
2. Integration in `docker.sh`
3. Integration in `imports.sh`
4. Testing mit einem Service (z.B. cloudflare-companion)

**Phase 7.1.2: Migration Services**
1. **cloudflare-companion** (einfachster Fall - nur Docker Socket)
2. **portainer** (einfach - nur Docker Socket)
3. **watchtower** (einfach - nur Docker Socket)
4. **traefik-crowdsec** (komplex - Docker Socket + Logs)
5. **pihole** (optional - nur Port, aber CAP_NET_BIND_SERVICE)

**Phase 7.1.3: Dokumentation**
- README aktualisieren
- Migration-Guide erstellen
- Troubleshooting-Section

### 7.2 Rückwärtskompatibilität

**Fallback-Mechanismus:**
```bash
get_compose_file() {
    # ... Erkennung ...
    
    # Wenn spezifische Datei nicht existiert, Fallback auf docker-compose.yml
    if [ -f "$service_dir/$COMPOSE_FILE" ]; then
        echo "$COMPOSE_FILE"
    elif [ -f "$service_dir/docker-compose.yml" ]; then
        echo "docker-compose.yml"  # Fallback
    else
        return 1
    fi
}
```

**Verhalten:**
- Service hat nur `docker-compose.yml` → funktioniert weiterhin
- Service hat `docker-compose.rootless.yml` → wird automatisch verwendet wenn rootless
- Service hat `docker-stack.yml` → wird automatisch verwendet wenn Swarm aktiv

---

## Phase 8: Testing-Plan

### 8.1 Test-Szenarien

**Test 1: Rootful Docker**
```bash
# Prüfen: docker-compose.yml wird verwendet
detect_docker_mode  # → "rootful"
get_compose_file "$docker_dir"  # → "docker-compose.yml"
# Container startet mit docker-compose.yml
```

**Test 2: Rootless Docker**
```bash
# Prüfen: docker-compose.rootless.yml wird verwendet
detect_docker_mode  # → "rootless"
get_compose_file "$docker_dir"  # → "docker-compose.rootless.yml"
# Container startet mit docker-compose.rootless.yml
```

**Test 3: Docker Swarm**
```bash
# Prüfen: docker-stack.yml wird verwendet
detect_docker_mode  # → "swarm"
get_compose_file "$docker_dir"  # → "docker-stack.yml"
# Stack wird deployed mit docker stack deploy
```

**Test 4: Service ohne rootless-Variante**
```bash
# Prüfen: Fallback auf docker-compose.yml
# Service hat nur docker-compose.yml
# Funktioniert weiterhin (rückwärtskompatibel)
```

### 8.2 Test-Services

1. **cloudflare-companion** (minimal, nur Docker Socket)
2. **portainer** (einfach, nur Docker Socket)
3. **traefik-crowdsec** (komplex, Docker Socket + Logs)

---

## Phase 9: Datei-Struktur (Final)

### 9.1 Neue Dateien

```
docker-scripts/
├── lib/
│   └── core/
│       └── docker-mode.sh          # NEU: Docker-Modus-Erkennung
└── modules/
    └── services/
        └── docker.sh                # ANGEPASST: Integration
```

### 9.2 Service-Struktur (Beispiel)

```
docker/
└── gateway-management/
    └── traefik-crowdsec/
        ├── docker-compose.yml          # Rootful
        ├── docker-compose.rootless.yml # Rootless (NEU)
        ├── docker-stack.yml            # Swarm (unverändert)
        ├── logs/                       # NEU: Für rootless
        │   ├── traefik/
        │   └── auth.log
        ├── traefik.env
        └── ...
```

---

## Phase 10: Implementierungs-Reihenfolge

### Schritt 1: Grundlagen (1-2 Stunden)
- [ ] `docker-mode.sh` erstellen
- [ ] Erkennungslogik implementieren
- [ ] `get_compose_file()` Funktion
- [ ] Testing der Erkennung

### Schritt 2: Integration (1-2 Stunden)
- [ ] `docker.sh` anpassen (`start_docker_container`)
- [ ] `docker.sh` anpassen (`restart_docker_container`)
- [ ] `get_stack_name()` Funktion
- [ ] Integration in `imports.sh`
- [ ] Fallback-Mechanismus

### Schritt 3: Migration - Einfache Services (2-3 Stunden)
- [ ] cloudflare-companion: `docker-compose.rootless.yml` erstellen
- [ ] portainer: `docker-compose.rootless.yml` erstellen
- [ ] watchtower: `docker-compose.rootless.yml` erstellen
- [ ] Testing

### Schritt 4: Migration - Komplexe Services (3-4 Stunden)
- [ ] traefik-crowdsec: `docker-compose.rootless.yml` erstellen
- [ ] Log-Verzeichnisse erstellen (`./logs/`)
- [ ] Testing

### Schritt 5: Optional - pihole (1 Stunde)
- [ ] Prüfen ob CAP_NET_BIND_SERVICE gesetzt ist
- [ ] Dokumentation aktualisieren

### Schritt 6: Dokumentation (1-2 Stunden)
- [ ] README aktualisieren
- [ ] Migration-Guide erstellen
- [ ] Troubleshooting-Section

**Gesamt: ~9-14 Stunden**

---

## Wichtige Unterschiede Rootful vs Rootless

### Docker Socket
- **Rootful:** `/var/run/docker.sock`
- **Rootless:** `${XDG_RUNTIME_DIR}/docker.sock` (z.B. `/run/user/1000/docker.sock`)

### Log-Pfade
- **Rootful:** `/var/log/...`
- **Rootless:** `./logs/...` (service-relativ)

### Ports < 1024
- **Beide:** Funktionieren mit `CAP_NET_BIND_SERVICE`
- **Rootless:** Braucht `sudo setcap cap_net_bind_service=+ep $(which rootlesskit)`

### PUID/PGID
- **Beide:** Identisch, keine Änderung nötig

---

## Erfolgs-Kriterien

✅ Docker-Modus wird automatisch erkannt  
✅ Passende Datei wird automatisch ausgewählt  
✅ Rootful/Rootless/Swarm funktionieren  
✅ Bestehende Services ohne rootless-Variante funktionieren weiter  
✅ Dokumentation ist vollständig  
✅ Migration ist einfach durchzuführen  

---

## Implementierungs-Reihenfolge (Kurzfassung)

### Schritt 1: Docker-Modus-Erkennung (Zuerst!)
- [ ] `docker-mode.sh` erstellen
- [ ] Integration in `imports.sh`
- [ ] Testing der Erkennung

### Schritt 2: Integration in docker.sh
- [ ] `docker.sh` anpassen
- [ ] `get_stack_name()` Funktion
- [ ] Testing

### Schritt 3: docker-compose.rootless.yml erstellen
- [ ] Nur für Services die es brauchen (siehe Status-Liste unten)
- [ ] Schrittweise: Einfache zuerst, dann komplexe

### Schritt 4: docker-stack.yml prüfen/ergänzen
- [ ] Prüfen welche bereits existieren
- [ ] Fehlende erstellen (falls nötig)

---

## Status-Liste: Was existiert, was fehlt

### ✅ docker-compose.yml (Rootful) - ALLE existieren
Alle Services haben bereits `docker-compose.yml`:
- ✅ adblocker-management/pihole
- ✅ companion-management/cloudflare
- ✅ dashboard-management/organizr
- ✅ games-management/pufferpanel
- ✅ gateway-management/ddns-updater
- ✅ gateway-management/traefik-crowdsec
- ✅ honeypot-management/tarpit
- ✅ media-management/jellyfin
- ✅ media-management/plex
- ✅ password-management/bitwarden
- ✅ storage-management/owncloud
- ✅ system-management/portainer
- ✅ system-management/watchtower
- ✅ url-management/yourls
- ✅ vpn-management/wireguard

### ⚠️ docker-stack.yml (Swarm) - Teilweise vorhanden

**✅ Existiert bereits:**
- ✅ adblocker-management/pihole/docker-stack.yml
- ✅ gateway-management/traefik-crowdsec/docker-stack.yml
- ✅ system-management/portainer/docker-stack.yml

**❌ Fehlt noch:**
- ❌ companion-management/cloudflare/docker-stack.yml (optional - nur wenn Swarm nötig)
- ❌ system-management/watchtower/docker-stack.yml (optional - nur wenn Swarm nötig)
- ❌ Alle anderen Services (nicht kritisch, nur wenn Swarm gewünscht)

### ❌ docker-compose.rootless.yml (Rootless) - ALLE fehlen

**Kritisch (müssen erstellt werden):**
- ❌ **companion-management/cloudflare/docker-compose.rootless.yml**
  - Grund: `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock`
  
- ❌ **gateway-management/traefik-crowdsec/docker-compose.rootless.yml**
  - Grund: `/var/run/docker.sock` + `/var/log/traefik` + `/var/log/auth.log`
  - Komplex: Log-Verzeichnisse + Docker Socket
  
- ❌ **system-management/portainer/docker-compose.rootless.yml**
  - Grund: `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock`
  
- ❌ **system-management/watchtower/docker-compose.rootless.yml**
  - Grund: `/var/run/docker.sock` → `${XDG_RUNTIME_DIR}/docker.sock`

**Optional (nur Ports < 1024, aber CAP_NET_BIND_SERVICE sollte reichen):**
- ⚠️ **adblocker-management/pihole/docker-compose.rootless.yml**
  - Grund: Port 53 (privileged port)
  - Aber: Mit CAP_NET_BIND_SERVICE sollte normale docker-compose.yml funktionieren
  - **Entscheidung:** Erstmal nicht nötig, nur wenn Probleme auftreten

**Nicht betroffen (keine Änderung nötig):**
- ✅ dashboard-management/organizr (kein Docker Socket, keine System-Pfade)
- ✅ games-management/pufferpanel (kein Docker Socket, keine System-Pfade)
- ✅ gateway-management/ddns-updater (kein Docker Socket, keine System-Pfade)
- ✅ honeypot-management/tarpit (kein Docker Socket, keine System-Pfade)
- ✅ media-management/jellyfin (kein Docker Socket, keine System-Pfade)
- ✅ media-management/plex (kein Docker Socket, keine System-Pfade)
- ✅ password-management/bitwarden (kein Docker Socket, keine System-Pfade)
- ✅ storage-management/owncloud (kein Docker Socket, keine System-Pfade)
- ✅ url-management/yourls (kein Docker Socket, keine System-Pfade)
- ✅ vpn-management/wireguard (kein Docker Socket, keine System-Pfade)

---

## Zusammenfassung

**Was zuerst gemacht wird:**
1. ✅ **Docker-Modus-Erkennung** (`docker-mode.sh`) - NEU erstellen
2. ✅ **Integration** (`docker.sh` anpassen) - ANPASSEN
3. ✅ **docker-compose.rootless.yml** - 4 Dateien NEU erstellen:
   - cloudflare-companion
   - traefik-crowdsec
   - portainer
   - watchtower

**Was bereits existiert:**
- ✅ Alle `docker-compose.yml` (rootful)
- ✅ 3x `docker-stack.yml` (pihole, traefik-crowdsec, portainer)

**Was optional ist:**
- ⚠️ Weitere `docker-stack.yml` (nur wenn Swarm für andere Services gewünscht)
- ⚠️ `pihole/docker-compose.rootless.yml` (nur wenn Port 53 Probleme macht)

---

## Nächste Schritte

1. **Review dieses Plans** ✅
2. **Mit Implementierung starten** (Schritt 1: docker-mode.sh)
3. **Iterativ testen** (jeder Schritt einzeln)
4. **Dokumentation parallel** (während Implementierung)

