# Organizr - Dashboard

Organizr ist ein HTPC/Homelab Services Organizer mit einem schönen Dashboard.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `organizr/organizr:latest`
- **Ports:** 80 (intern), 8003 (lokal)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/dashboard-management/organizr/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/dashboard-management/organizr
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `./data/` - Organizr Konfiguration

## Features

- ✅ Unified Dashboard für alle Services
- ✅ Tabbed Interface
- ✅ Service Status Monitoring
- ✅ Bookmark Management
- ✅ User Management
- ✅ Theme Support

## Zugriff

- **Web UI:** `https://organizr.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **Lokal:** `http://localhost:8003` (Port 8003 lokal)

## Sicherheitsrisiko-Einschätzung

### Web UI (DNS)
- **Risiko:** ⚠️ **MITTEL** - Übersicht über alle Services, mögliche Credential-Exposition
- **Schutz:** Admin Whitelist (nur VPN/LAN) + Rate Limiting
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt

### Lokaler Port (8003)
- **Risiko:** ✅ **NIEDRIG** - Nur lokal im Netzwerk
- **Schutz:** Kein externer Zugriff (nicht im Router forwardiert)
- **Empfehlung:** ✅ So lassen (nur lokal)

## Traefik Konfiguration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.organizr.rule=Host(`organizr.${DOMAIN}`)"
  - "traefik.http.routers.organizr.tls=true"
  - "traefik.http.services.organizr.loadbalancer.server.port=80"
```

**Sicherheit:**
- Admin Whitelist aktiviert
- Rate Limiting aktiviert

## Konfiguration

### Services hinzufügen

1. Öffne Organizr Dashboard
2. Gehe zu Settings → Tabs
3. Füge neue Tabs hinzu:
   - Name, URL, Icon
   - Optional: Health Check URL

### Daten

- **Config:** `./data/` - Organizr Konfiguration und Datenbank

## Erste Einrichtung

1. Öffne `https://organizr.<deine-domain>`
2. Erstelle Admin Account
3. Füge Services/Tabs hinzu
4. Konfiguriere Themes (optional)

## Troubleshooting

### Organizr startet nicht

```bash
# Logs prüfen
docker logs organizr

# Permissions prüfen
ls -la ./data/
```

### Services werden nicht angezeigt

```bash
# Tab-Konfiguration in Organizr UI prüfen
# Services müssen manuell hinzugefügt werden
```

## Weitere Informationen

- [Organizr GitHub](https://github.com/organizr/organizr)

