# Traefik - Reverse Proxy

Traefik ist der Reverse Proxy für das NCC-HomeLab Setup. Er übernimmt SSL/TLS Termination, Routing und Load Balancing.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `traefik:v3.1.0`
- **Ports:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Netzwerke:** `proxy`, `crowdsec`
- **Konfiguration:** `docker/gateway-management/traefik-crowdsec/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/gateway-management/traefik-crowdsec
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `traefik.env` - Environment Variables
- `traefik/traefik.yml` - Traefik Konfiguration
- `traefik/dynamic-conf/` - Dynamische Konfiguration

### Docker Swarm Stack

```bash
docker stack deploy -c docker-stack.yml gateway
```

**Wichtig:** Für Swarm wird Shared Storage (NFS) für ACME-Zertifikate empfohlen!

## Features

- ✅ Automatische SSL-Zertifikate (Let's Encrypt)
- ✅ Docker Provider (automatisches Service Discovery)
- ✅ CrowdSec Integration (Security)
- ✅ Rate Limiting
- ✅ Admin Whitelist
- ✅ Security Headers

## Zugriff

- **HTTP/HTTPS:** Port 80/443 (öffentlich) - Reverse Proxy für alle Services
- **Dashboard:** `https://traefik.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN** - ✅ **AKTIV**
- **API (lokal):** `http://localhost:8080/api/rawdata` - Nur lokal (127.0.0.1:8080, nicht von außen erreichbar)

## Sicherheitsrisiko-Einschätzung

### Port 80/443 (öffentlich)
- **Risiko:** ✅ **NIEDRIG** - Reverse Proxy, keine direkten Daten
- **Schutz:** CrowdSec, Rate Limiting, Security Headers
- **Empfehlung:** ✅ Öffentlich freigeben (notwendig für Services)

### Traefik Dashboard (DNS)
- **Status:** ✅ **AKTIV** - Erreichbar über `https://traefik.<deine-domain>`
- **Risiko:** ⚠️ **HOCH** - Zeigt alle Services, Konfiguration, Logs
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt
- **Hinweis:** Dashboard ist aktiviert (`traefik.enable=true`), der veraltete Kommentar in docker-compose.yml ist falsch

### API (lokal)
- **Status:** ✅ **AKTIV** - Nur lokal erreichbar
- **Port:** `127.0.0.1:8080:8080` - Nur auf dem Server selbst
- **Risiko:** ✅ **NIEDRIG** - Kein externer Zugriff möglich
- **Schutz:** Port-Binding auf 127.0.0.1 (nicht 0.0.0.0)
- **Empfehlung:** ✅ So lassen (nur lokal) - Perfekt so!

## Labels für Services

Services werden über Docker Labels konfiguriert:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.<service>.rule=Host(`<service>.<domain>`)"
  - "traefik.http.routers.<service>.tls=true"
  - "traefik.http.routers.<service>.tls.certresolver=http_resolver"
  - "traefik.http.services.<service>.loadbalancer.server.port=<port>"
```

## Middlewares

Verfügbare Middlewares:

- `default@file` - Standard Security Headers
- `traefikAuth@file` - Basic Auth
- `admin-whitelist@file` - IP Whitelist
- `rate-limit@docker` - Rate Limiting
- `security-headers@docker` - Erweiterte Security Headers

## ACME / Let's Encrypt

Zertifikate werden automatisch erstellt und erneuert.

**Storage:** `./traefik/acme_letsencrypt.json`

**Für Swarm:** Shared Storage (NFS) empfohlen!

## Troubleshooting

### Zertifikate werden nicht erstellt

```bash
# Logs prüfen
docker logs traefik

# ACME Datei prüfen
cat ./traefik/acme_letsencrypt.json
```

### Service wird nicht erkannt

```bash
# Labels prüfen
docker inspect <container-name> | grep -A 20 Labels

# Netzwerk prüfen
docker network inspect proxy
```

## Weitere Informationen

- [Traefik Dokumentation](https://doc.traefik.io/traefik/)
- [Docker Provider](https://doc.traefik.io/traefik/routing/providers/docker/)

