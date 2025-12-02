# OwnCloud - File Storage

OwnCloud ist eine Open-Source File Storage Lösung für deine Dateien.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `owncloud/server:latest`
- **Port:** 80 (intern)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/storage-management/owncloud/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/storage-management/owncloud
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `mysql.env` - MySQL Datenbank Konfiguration
- `./owncloud/` - OwnCloud Daten

## Features

- ✅ File Storage & Sync
- ✅ Web Interface
- ✅ Desktop Client
- ✅ Mobile Apps
- ✅ File Sharing
- ✅ Version Control
- ✅ MySQL Backend

## Zugriff

- **Web UI:** `https://owncloud.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **Desktop Client:** OwnCloud Desktop App
- **Mobile:** OwnCloud Mobile Apps

## Sicherheitsrisiko-Einschätzung

- **Risiko:** ⚠️ **MITTEL** - File Storage, mögliche sensible Daten
- **Schutz:** Admin Whitelist (nur VPN/LAN) + Rate Limiting
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt
- **Hinweis:** Für externen Zugriff VPN nutzen, nicht direkt öffentlich freigeben

## Traefik Konfiguration

OwnCloud wird über Traefik erreichbar gemacht. Labels müssen in `docker-compose.yml` konfiguriert sein.

## Konfiguration

### MySQL Datenbank

OwnCloud nutzt MySQL als Backend:
- **Config:** `mysql.env` - Datenbank Credentials
- **Volume:** MySQL Daten werden persistent gespeichert

### Daten

- **OwnCloud Data:** `./owncloud/` - Dateien und Konfiguration
- **MySQL Data:** MySQL Volume

## Erste Einrichtung

1. Öffne `https://owncloud.<deine-domain>`
2. Erstelle Admin Account
3. Installiere Desktop Client oder Mobile App
4. Verbinde mit Server

## Sicherheit

- ✅ HTTPS über Traefik
- ✅ Verschlüsselte Verbindungen
- ✅ Admin Whitelist (optional)

## Troubleshooting

### OwnCloud startet nicht

```bash
# Logs prüfen
docker logs owncloud

# MySQL prüfen
docker logs owncloud-mysql
```

### Datenbank-Verbindung fehlgeschlagen

```bash
# MySQL Credentials prüfen
cat mysql.env

# MySQL Container Status
docker ps | grep mysql
```

### Dateien werden nicht synchronisiert

```bash
# Permissions prüfen
ls -la ./owncloud/

# OwnCloud Logs
docker logs owncloud | grep -i error
```

## Weitere Informationen

- [OwnCloud Dokumentation](https://doc.owncloud.com/)
- [OwnCloud GitHub](https://github.com/owncloud/core)

