# Bitwarden (Vaultwarden) - Password Manager

Vaultwarden ist eine inoffizielle, kompatible Implementierung des Bitwarden Servers. Speichert Passwörter sicher verschlüsselt.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `vaultwarden/server:latest`
- **Port:** 80 (intern)
- **Netzwerk:** `proxy`
- **Konfiguration:** `docker/password-management/bitwarden/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/password-management/bitwarden
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `bitwarden.env` - Environment Variables
- `data/` - Verschlüsselte Datenbank

## Features

- ✅ Passwort-Synchronisation
- ✅ Zwei-Faktor-Authentifizierung (2FA)
- ✅ Secure Notes
- ✅ Credit Cards
- ✅ Identities
- ✅ Web Vault
- ✅ Browser Extensions
- ✅ Mobile Apps

## Zugriff

- **Web Vault:** `https://bw.<deine-domain>` (öffentlich) - ✅ Für Sync nötig
- **Admin Panel:** `https://bw.<deine-domain>/admin` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**

## Sicherheitsrisiko-Einschätzung

### Web Vault (öffentlich)
- **Risiko:** ✅ **NIEDRIG** - Verschlüsselt auf Client-Seite, für Sync nötig
- **Schutz:** Client-seitige Verschlüsselung, Rate Limiting
- **Empfehlung:** ✅ Öffentlich freigeben (für Sync notwendig)

### Admin Panel (VPN/LAN)
- **Risiko:** ⚠️ **HOCH** - Server-Administration, User-Management
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt

## Traefik Konfiguration

Bitwarden hat zwei Router:

1. **Admin Router** (`bw-admin`)
   - Pfad: `/admin`
   - Middlewares: Basic Auth + IP Whitelist
   - Nur für VPN/LAN

2. **Main Router** (`bw-secure`)
   - Haupt-Zugriff
   - Public erreichbar (für Sync)

3. **WebSocket Router** (`bitwarden-sock`)
   - Für Live-Updates
   - Port: 3012

## Konfiguration

### Environment Variables

Wichtige Variablen in `bitwarden.env`:
- `SIGNUPS_ALLOWED` - Neue Registrierungen erlauben
- `DOMAIN` - Domain für Bitwarden
- `ADMIN_TOKEN` - Admin Panel Token

### Daten

- **Database:** `./data/` (SQLite)
- **Attachments:** `./data/attachments/`
- **Icons:** `./data/icon_cache/`

## Erste Einrichtung

1. Öffne `https://bw.<deine-domain>`
2. Erstelle Account
3. Installiere Browser Extension oder Mobile App
4. Logge dich ein

## Sicherheit

- ✅ Verschlüsselung auf Client-Seite
- ✅ Admin Panel nur über VPN/LAN
- ✅ Rate Limiting aktiviert
- ✅ Sticky Sessions für bessere Sicherheit

## Troubleshooting

### Web Vault nicht erreichbar

```bash
# Container Status
docker ps | grep bitwarden

# Logs prüfen
docker logs bitwarden

# Traefik Labels prüfen
docker inspect bitwarden | grep -A 30 Labels
```

### Sync funktioniert nicht

```bash
# WebSocket Router prüfen
docker inspect bitwarden | grep -A 10 bitwarden-sock

# Netzwerk prüfen
docker network inspect proxy
```

### Admin Panel nicht erreichbar

```bash
# IP Whitelist prüfen
# Muss deine IP enthalten (VPN/LAN)

# Basic Auth prüfen
# Traefik Auth muss konfiguriert sein
```

## Weitere Informationen

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Bitwarden Clients](https://bitwarden.com/download/)

