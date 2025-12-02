# Jellyfin - Media Server

Jellyfin ist ein Open-Source Media Server für deine Filme, Serien und Musik.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `lscr.io/linuxserver/jellyfin:latest`
- **Ports:** 8096 (HTTP), 8920 (HTTPS), 7359/UDP (Discovery), 1900/UDP (DLNA)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/media-management/jellyfin/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/media-management/jellyfin
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `jellyfin.env` - Environment Variables
- `jellyfin/library/` - Konfiguration
- `jellyfin/tvseries/` - TV Serien
- `jellyfin/movies/` - Filme

## Features

- ✅ Film- und Serien-Streaming
- ✅ Musik-Streaming
- ✅ Live TV (mit Tuner)
- ✅ DLNA Support
- ✅ Transcoding
- ✅ Multi-User Support
- ✅ Mobile Apps

## Zugriff

- **Web UI:** `https://jellyfin.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **Lokal:** `http://localhost:8096` (Port 8096, 8920 lokal)

## Sicherheitsrisiko-Einschätzung

### Web UI (DNS)
- **Risiko:** ⚠️ **MITTEL** - Media-Zugriff, User-Management, mögliche Transcoding-Last
- **Schutz:** Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt

### Lokale Ports (8096, 8920)
- **Risiko:** ✅ **NIEDRIG** - Nur lokal im Netzwerk
- **Schutz:** Kein externer Zugriff (nicht im Router forwardiert)
- **Empfehlung:** ✅ So lassen (nur lokal für DLNA/Discovery)

## Traefik Konfiguration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${DOMAIN}`)"
  - "traefik.http.routers.jellyfin.tls=true"
  - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
  - "traefik.http.services.jellyfin.loadbalancer.sticky.cookie.httpOnly=true"
```

**Wichtig:** Sticky Sessions sind aktiviert für besseres Streaming!

## Konfiguration

### Media Libraries

Nach dem ersten Start:
1. Öffne Jellyfin Web UI
2. Gehe zu Settings → Libraries
3. Füge Libraries hinzu:
   - Movies: `/data/movies`
   - TV Shows: `/data/tvshows`

### Volumes

- **Config:** `./jellyfin/library/` - Jellyfin Konfiguration
- **Movies:** `./jellyfin/movies/` - Film-Ordner
- **TV Series:** `./jellyfin/tvseries/` - Serien-Ordner

### Hardware Transcoding

Für Hardware-Transcoding (GPU):
```yaml
devices:
  - /dev/dri:/dev/dri  # Intel QuickSync / AMD
```

## Erste Einrichtung

1. Öffne `https://jellyfin.<deine-domain>`
2. Erstelle Admin Account
3. Füge Media Libraries hinzu
4. Scanne Libraries
5. Installiere Client Apps (optional)

## Sicherheit

- ✅ Admin Whitelist (nur VPN/LAN)
- ✅ HTTPS über Traefik
- ✅ Sticky Sessions

## Troubleshooting

### Jellyfin startet nicht

```bash
# Logs prüfen
docker logs jellyfin

# Permissions prüfen
ls -la ./jellyfin/
```

### Media wird nicht gefunden

```bash
# Volume Mounts prüfen
docker inspect jellyfin | grep -A 10 Mounts

# Dateien prüfen
ls -la ./jellyfin/movies/
```

### Transcoding funktioniert nicht

```bash
# Hardware prüfen
docker exec jellyfin ls -la /dev/dri/

# Transcoding Settings in Jellyfin UI prüfen
```

## Weitere Informationen

- [Jellyfin Dokumentation](https://jellyfin.org/docs/)
- [Jellyfin GitHub](https://github.com/jellyfin/jellyfin)

