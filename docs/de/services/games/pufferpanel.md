# PufferPanel - Game Server Management

PufferPanel ist ein Web-basiertes Game Server Management Panel.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `pufferpanel/pufferpanel:latest`
- **Ports:** 8080 (Web), 5657 (Daemon), 27015+ (Game Ports)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/games-management/pufferpanel/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/games-management/pufferpanel
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `.env.pufferpanel` - Environment Variables
- `./pufferpanel/data/` - PufferPanel Daten
- `./pufferpanel/config/` - PufferPanel Konfiguration

## Features

- ✅ Game Server Management
- ✅ Web Interface
- ✅ Multi-Server Support
- ✅ File Manager
- ✅ Console Access
- ✅ Resource Monitoring

## Zugriff

- **Web UI:** `https://pufferpanel.<deine-domain>` (ohne admin-whitelist) - ⚠️ **RISIKO**
- **Daemon:** Port 5657 (intern)
- **Game Ports:** 27015+ (öffentlich, falls forwardiert)

## Sicherheitsrisiko-Einschätzung

### Web UI (DNS)
- **Risiko:** ⚠️ **MITTEL-HOCH** - Game Server Management, mögliche RCE-Risiken
- **Schutz:** ⚠️ **KEINE admin-whitelist aktiviert!** (nur `default@file`)
- **Empfehlung:** ⚠️ **admin-whitelist aktivieren oder NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** ⚠️ **NICHT mit admin-whitelist geschützt**

### Game Ports (27015+)
- **Risiko:** ⚠️ **MITTEL** - Game Server, mögliche Exploits
- **Schutz:** Game Server Security, Firewall
- **Empfehlung:** ⚠️ Nur forwarden wenn nötig, regelmäßig updaten

## Traefik Konfiguration

### HTTP Router

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.pufferpanel.rule=Host(`pufferpanel.${DOMAIN}`)"
  - "traefik.http.services.pufferpanel.loadbalancer.server.port=8080"
```

### TCP Router (Daemon)

```yaml
labels:
  - "traefik.tcp.routers.pufferpanel-daemon.entrypoints=games"
  - "traefik.tcp.routers.pufferpanel-daemon.rule=HostSNI(`*`)"
  - "traefik.tcp.services.pufferpanel-daemon.loadbalancer.server.port=5657"
```

## Konfiguration

### Game Ports

PufferPanel benötigt Ports für Game Server:
```yaml
ports:
  - "27015:27015"  # SRCDS (CS:GO, TF2, etc.)
  - "25565:25565"  # Minecraft Java
  - "27065-27075:27065-27075"  # Port Range
```

### Environment Variables

Wichtige Variablen in `.env.pufferpanel`:
- Datenbank Konfiguration
- Admin Credentials

### Daten

- **Data:** `./pufferpanel/data/` - Server Daten
- **Config:** `./pufferpanel/config/` - PufferPanel Konfiguration

## Erste Einrichtung

1. Öffne `https://pufferpanel.<deine-domain>`
2. Erstelle Admin Account
3. Füge Game Server hinzu
4. Konfiguriere Ports
5. Starte Server

## Troubleshooting

### PufferPanel startet nicht

```bash
# Logs prüfen
docker logs pufferpanel

# Environment prüfen
cat .env.pufferpanel
```

### Game Server startet nicht

```bash
# Ports prüfen
docker ps | grep pufferpanel

# Port Forwarding im Router prüfen
```

### Daemon nicht erreichbar

```bash
# TCP Router prüfen
docker inspect pufferpanel | grep -A 10 tcp

# Traefik TCP Entrypoint prüfen
```

## Weitere Informationen

- [PufferPanel Dokumentation](https://docs.pufferpanel.com/)
- [PufferPanel GitHub](https://github.com/pufferpanel/pufferpanel)

