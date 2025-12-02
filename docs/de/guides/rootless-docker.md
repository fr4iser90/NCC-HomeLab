# Rootless Docker - Kompletter Guide

## Was ist Rootless Docker?

**Rootless Docker** bedeutet, dass Docker ohne Root-Rechte läuft. Stattdessen verwendet es:
- **User Namespaces** (UID/GID Mapping)
- **RootlessKit** (Port-Forwarding ohne Root)
- **slirp4netns** oder **VPNKit** (Netzwerk ohne Root)

---

## Warum Rootless Docker?

### Vorteile
- ✅ **Sicherheit**: Container laufen nicht als Root → weniger Angriffsfläche
- ✅ **Isolation**: Selbst wenn Container kompromittiert wird, hat er keine Root-Rechte auf dem Host
- ✅ **Compliance**: Erfüllt viele Security-Best-Practices
- ✅ **Multi-User**: Mehrere Benutzer können Docker parallel nutzen

### Nachteile
- ⚠️ **Ports < 1024**: Brauchen spezielle Konfiguration (CAP_NET_BIND_SERVICE oder RootlessKit)
- ⚠️ **Performance**: Leicht langsamer (User Namespace Overhead)
- ⚠️ **Kompatibilität**: Nicht alle Features funktionieren (z.B. einige Storage-Drivers)

---

## Wie funktioniert Rootless Docker?

### 1. User Namespace Mapping

**Das Problem:** Container brauchen Root (UID 0) intern, aber sollen nicht Root auf dem Host sein.

**Die Lösung:** User Namespace Mapping

```
Host System:                    Container sieht:
UID 1000 (dein User)    →       UID 0 (root im Container)
UID 100000              →       UID 1
UID 100001              →       UID 2
...
```

**Beispiel:**
- Dein User auf Host: `fr4iser` (UID 1000)
- Container läuft als "root" (UID 0) **innerhalb** des Containers
- Auf dem Host läuft der Prozess als UID 1000 (dein User)
- Docker mapped: Container-UID 0 → Host-UID 1000

### 2. Netzwerk ohne Root

**Normales Docker (mit Root):**
- Docker erstellt Bridge-Netzwerke direkt
- Binden an Port 80/443 funktioniert direkt

**Rootless Docker:**
- Verwendet **slirp4netns** oder **VPNKit**
- Port-Forwarding über **RootlessKit**
- Ports < 1024 werden über RootlessKit gemapped

**Beispiel Port-Mapping:**
```
Container Port 80  →  RootlessKit  →  Host Port 8080 (oder höher)
```

Oder mit **CAP_NET_BIND_SERVICE**:
```bash
# Setze Capability für Ports < 1024
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)
```

---

## Wie bekommt ein Reverse Proxy (Traefik) Rechte in Rootless Docker?

### Problem 1: Port 80/443 binden

#### Option A: RootlessKit Port-Forwarding (Standard)

Traefik bindet intern an Port 80/443, RootlessKit mapped es:

```yaml
# docker-compose.yml
services:
  traefik:
    ports:
      - "8080:80"   # Host:Container
      - "8443:443"
```

**Router/NAT:** Forwarde 80/443 → Host:8080/8443

#### Option B: CAP_NET_BIND_SERVICE (Ports < 1024 direkt)

```bash
# Installiere rootlesskit mit Capability
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Jetzt kann Traefik direkt an 80/443 binden
services:
  traefik:
    ports:
      - "80:80"
      - "443:443"
```

#### Option C: iptables/Forwarding (erfordert Root für Setup)

```bash
# Einmalig als Root:
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
```

### Problem 2: Docker Socket Zugriff

**Normales Docker:**
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Rootless Docker:**
```yaml
volumes:
  - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
  # Oder:
  - ~/.local/share/docker/run/docker.sock:/var/run/docker.sock:ro
```

**Wichtig:** Der Socket gehört deinem User, nicht Root!

**Socket-Pfad finden:**
```bash
# Aktueller Socket-Pfad
echo $XDG_RUNTIME_DIR/docker.sock

# Oder
ls -la ~/.local/share/docker/run/docker.sock
```

### Problem 3: Log-Zugriff

**Normales Docker:**
```yaml
volumes:
  - /var/log/traefik:/var/log/traefik
```

**Rootless Docker:**
```yaml
volumes:
  - ~/docker-logs/traefik:/var/log/traefik
  # Oder mit Berechtigungen:
  - ./logs/traefik:/var/log/traefik
```

**Berechtigungen setzen:**
```bash
mkdir -p ~/docker-logs/traefik
chmod 755 ~/docker-logs/traefik
```

---

## Rootless Docker Setup - Schritt für Schritt

### Schritt 1: Rootless Docker installieren

```bash
# Methode 1: Offizielles Rootless Install Script
curl -fsSL https://get.docker.com/rootless | sh

# Nach Installation:
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# Prüfen ob es funktioniert
docker --version
docker ps
```

**Alternative: Podman (rootless by default)**
```bash
# Podman ist eine Docker-Alternative, die standardmäßig rootless läuft
# Keine zusätzliche Konfiguration nötig
podman --version
```

### Schritt 2: Environment Variables permanent setzen

**Für deine Shell (.bashrc / .zshrc):**
```bash
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

**Oder für Systemd User Service:**
```bash
# Wird automatisch gesetzt wenn Docker als Systemd Service läuft
```

### Schritt 3: Systemd Service (optional, für Auto-Start)

```bash
# Rootless Docker als Systemd User Service
systemctl --user enable docker
systemctl --user start docker

# Status prüfen
systemctl --user status docker
```

### Schritt 4: Ports < 1024 aktivieren (optional)

```bash
# Prüfe ob rootlesskit installiert ist
which rootlesskit

# Setze Capability für Ports < 1024
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Prüfen
getcap $(which rootlesskit)
# Sollte zeigen: cap_net_bind_service=ep

# Oder: Nutze höhere Ports (8080/8443) und forwarde im Router
```

### Schritt 5: Docker Compose anpassen

**Vorher (Root Docker):**
```yaml
services:
  traefik:
    container_name: traefik
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log/traefik:/var/log/traefik
```

**Nachher (Rootless Docker):**
```yaml
services:
  traefik:
    # container_name kann bleiben (docker-compose erlaubt es)
    ports:
      - "8080:80"    # Oder 80:80 wenn CAP_NET_BIND_SERVICE gesetzt
      - "8443:443"   # Oder 443:443 wenn CAP_NET_BIND_SERVICE gesetzt
    volumes:
      - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
      - ./logs/traefik:/var/log/traefik
    # Wichtig: User Namespace bleibt automatisch aktiv
```

**Wichtig:** `$XDG_RUNTIME_DIR` wird von Docker Compose nicht automatisch expandiert!

**Lösung:**
```bash
# In docker-compose.yml verwende den vollständigen Pfad:
# Oder setze es als Environment Variable
export XDG_RUNTIME_DIR=/run/user/$(id -u)
docker-compose up -d
```

**Oder in docker-compose.yml:**
```yaml
services:
  traefik:
    volumes:
      # Verwende den vollständigen Pfad
      - /run/user/1000/docker.sock:/var/run/docker.sock:ro
      # Oder nutze .env Datei
      - ${DOCKER_SOCKET_PATH}:/var/run/docker.sock:ro
```

**In .env Datei:**
```bash
DOCKER_SOCKET_PATH=/run/user/1000/docker.sock
```

### Schritt 6: Netzwerke anpassen

**Rootless Docker verwendet andere Netzwerk-Bereiche:**

```yaml
networks:
  proxy:
    driver: bridge
    ipam:
      config:
        - subnet: 172.40.0.0/16  # Kann bleiben, wird gemapped
```

**Wichtig:** Externe Netzwerke müssen vorher erstellt werden:
```bash
docker network create proxy
```

**Netzwerke prüfen:**
```bash
docker network ls
docker network inspect proxy
```

---

## Praktische Beispiele

### Beispiel 1: Traefik mit Rootless Docker

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.1.0
    ports:
      - "8080:80"    # Höhere Ports
      - "8443:443"
    volumes:
      - /run/user/1000/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/traefik.yml:ro
      - ./traefik/acme:/traefik
      - ./logs/traefik:/var/log/traefik
    networks:
      - proxy
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

networks:
  proxy:
    external: true
```

**Router/NAT Konfiguration:**
- Forwarde Port 80 → Host:8080
- Forwarde Port 443 → Host:8443

### Beispiel 2: Pi-hole mit Rootless Docker

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  pihole:
    image: pihole/pihole:latest
    ports:
      - "5353:53/tcp"    # Höhere Ports für DNS
      - "5353:53/udp"
    volumes:
      - ./pihole-data:/etc/pihole
      - ./pihole-dnsmasq:/etc/dnsmasq.d
    networks:
      - proxy
    restart: unless-stopped
```

**Router DNS Konfiguration:**
- Setze DNS Server auf Host-IP:5353

---

## Troubleshooting

### Problem: Docker Socket nicht gefunden

```bash
# Prüfe Socket-Pfad
echo $XDG_RUNTIME_DIR
ls -la $XDG_RUNTIME_DIR/docker.sock

# Falls nicht vorhanden:
ls -la ~/.local/share/docker/run/docker.sock

# Docker neu starten
systemctl --user restart docker
```

### Problem: Ports < 1024 funktionieren nicht

```bash
# Prüfe rootlesskit Capability
getcap $(which rootlesskit)

# Falls nicht gesetzt:
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Oder: Nutze höhere Ports
```

### Problem: Netzwerk funktioniert nicht

```bash
# Prüfe Netzwerke
docker network ls
docker network inspect proxy

# Netzwerk neu erstellen
docker network rm proxy
docker network create proxy
```

### Problem: Permission Denied

```bash
# Prüfe Berechtigungen
ls -la ~/docker-logs/
chmod 755 ~/docker-logs/

# Prüfe User
whoami
id
```

### Problem: Container startet nicht

```bash
# Docker Logs
journalctl --user -u docker -f

# Container Logs
docker logs <container-name>

# Prüfe Environment
echo $DOCKER_HOST
echo $PATH
```

---

## Rootless Docker - Praktische Checkliste

- [ ] Rootless Docker installiert (`docker --version` prüfen)
- [ ] `DOCKER_HOST` Environment Variable gesetzt
- [ ] `PATH` enthält `$HOME/bin`
- [ ] Ports konfiguriert (8080/8443 oder CAP_NET_BIND_SERVICE)
- [ ] Docker Socket Pfad angepasst (`$XDG_RUNTIME_DIR/docker.sock`)
- [ ] Log-Verzeichnisse in User-Space verschoben
- [ ] Netzwerke erstellt (`docker network create`)
- [ ] Router/NAT Port-Forwarding angepasst (falls nötig)
- [ ] Systemd Service aktiviert (optional)
- [ ] Environment Variables in .bashrc/.zshrc gesetzt
- [ ] Alle docker-compose.yml Dateien angepasst

---

## Vergleich: Root vs Rootless Docker

| Feature | Root Docker | Rootless Docker |
|---------|-------------|-----------------|
| Installation | `sudo apt install docker.io` | `curl ... \| sh` (User-Space) |
| Socket | `/var/run/docker.sock` | `$XDG_RUNTIME_DIR/docker.sock` |
| Ports < 1024 | ✅ Direkt | ⚠️ CAP_NET_BIND_SERVICE oder höhere Ports |
| Logs | `/var/log/` | `~/docker-logs/` oder `./logs/` |
| Netzwerk | Bridge direkt | slirp4netns/VPNKit |
| Performance | ✅ Schnell | ⚠️ Leicht langsamer |
| Sicherheit | ⚠️ Root-Rechte | ✅ User-Rechte |
| Multi-User | ❌ Schwierig | ✅ Einfach |

---

## Best Practices

1. **Nutze höhere Ports** (8080/8443) statt CAP_NET_BIND_SERVICE wenn möglich
2. **Logs in User-Space** speichern (`~/docker-logs/` oder `./logs/`)
3. **Environment Variables** permanent setzen (.bashrc/.zshrc)
4. **Systemd Service** für Auto-Start aktivieren
5. **Backup** deiner Konfigurationen
6. **Teste** in VM/Test-Environment zuerst

---

## Nützliche Links

- [Docker Rootless Docs](https://docs.docker.com/engine/security/rootless/)
- [RootlessKit GitHub](https://github.com/rootless-containers/rootlesskit)
- [Podman Docs](https://podman.io/) (Alternative zu Docker, rootless by default)

---

## Zusammenfassung

**Rootless Docker** ist eine sichere Alternative zu normalem Docker:
- ✅ Läuft ohne Root-Rechte
- ✅ Bessere Isolation
- ⚠️ Etwas mehr Konfiguration nötig
- ⚠️ Ports < 1024 brauchen Setup
- ✅ Perfekt für Homelab und Multi-User-Umgebungen

**Empfehlung:** Teste es zuerst in einer VM, dann migriere Schritt für Schritt.

---

**Viel Erfolg mit Rootless Docker! 🔒**

