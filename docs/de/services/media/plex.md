# Plex - Media Server

Plex ist ein Media Server für deine Filme, Serien und Musik mit vielen Client-Apps.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `plexinc/pms-docker:latest`
- **Ports:** 32400 (Web), 32469 (Discovery)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/media-management/plex/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/media-management/plex
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `plex.env` - Environment Variables
- `./plex/` - Plex Daten

## Features

- ✅ Film- und Serien-Streaming
- ✅ Musik-Streaming
- ✅ Live TV (mit Plex Pass)
- ✅ DVR (mit Plex Pass)
- ✅ Transcoding
- ✅ Viele Client Apps
- ✅ Remote Access

## Zugriff

- **Web UI:** `https://plex.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **Lokal:** `http://localhost:32400` (Port 32400 lokal)

## Sicherheitsrisiko-Einschätzung

### Web UI (DNS)
- **Risiko:** ⚠️ **MITTEL** - Media-Zugriff, User-Management, mögliche Transcoding-Last
- **Schutz:** Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt
- **Hinweis:** Plex Remote Access funktioniert über Plex-Server (nicht über Traefik)

### Lokale Ports (32400+)
- **Risiko:** ✅ **NIEDRIG** - Nur lokal im Netzwerk
- **Schutz:** Kein externer Zugriff (nicht im Router forwardiert)
- **Empfehlung:** ✅ So lassen (nur lokal für Discovery/DLNA)

## Traefik Konfiguration

Plex wird über Traefik erreichbar gemacht. Labels müssen in `docker-compose.yml` konfiguriert sein.

## Konfiguration

### Plex Claim Token

Für Remote Access benötigst du einen Claim Token:
```bash
./update-claim-token.sh
```

Oder manuell:
1. Gehe zu https://www.plex.tv/claim
2. Kopiere Token
3. Setze in `plex.env`: `PLEX_CLAIM=<token>`

### Volumes

- **Config:** `./plex/` - Plex Konfiguration und Datenbank

## Erste Einrichtung

1. Öffne `https://plex.<deine-domain>`
2. Erstelle Plex Account (oder nutze bestehenden)
3. Füge Media Libraries hinzu
4. Scanne Libraries
5. Installiere Client Apps

## Plex Pass Features

Mit Plex Pass (kostenpflichtig):
- Hardware Transcoding
- Live TV & DVR
- Mobile Sync
- Premium Music Features

## Troubleshooting

### Plex startet nicht

```bash
# Logs prüfen
docker logs plex

# Claim Token prüfen
cat plex.env | grep PLEX_CLAIM
```

### Remote Access funktioniert nicht

```bash
# Claim Token aktualisieren
./update-claim-token.sh

# Port Forwarding prüfen
# Plex braucht Port 32400
```

### Media wird nicht gefunden

```bash
# Volume Mounts prüfen
docker inspect plex | grep -A 10 Mounts

# Permissions prüfen
ls -la ./plex/
```

## Weitere Informationen

- [Plex Dokumentation](https://support.plex.tv/)
- [Plex Server Setup](https://support.plex.tv/articles/200289506-getting-started/)

