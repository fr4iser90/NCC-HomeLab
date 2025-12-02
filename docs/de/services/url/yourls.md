# Yourls - URL Shortener

Yourls (Your Own URL Shortener) ist ein Self-Hosted URL Shortener für deine eigenen kurzen Links.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `yourls:latest`
- **Port:** 80 (intern)
- **Netzwerk:** `proxy`
- **Datenbank:** MySQL
- **Konfiguration:** `docker/url-management/yourls/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/url-management/yourls
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `mysql.env` - MySQL Datenbank Konfiguration
- `./data/` - MySQL Daten

## Features

- ✅ URL Shortening
- ✅ Custom Short Links
- ✅ Link Statistics
- ✅ QR-Code Generation
- ✅ API Support
- ✅ MySQL Backend

## Zugriff

- **Web UI:** `https://link.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **API:** `https://link.<deine-domain>/yourls-api.php` (mit admin-whitelist)

## Sicherheitsrisiko-Einschätzung

- **Risiko:** ⚠️ **NIEDRIG-MITTEL** - Link-Management, Statistiken
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN) + Rate Limiting
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt
- **Hinweis:** Kurze Links sind öffentlich erreichbar (über Redirect), aber Admin-Interface ist geschützt

## Traefik Konfiguration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.yourls.rule=Host(`link.${DOMAIN}`)"
  - "traefik.http.routers.yourls.tls=true"
  - "traefik.http.services.yourls.loadbalancer.server.port=80"
```

**Sicherheit:**
- Basic Auth aktiviert
- Admin Whitelist aktiviert
- Rate Limiting aktiviert

## Konfiguration

### MySQL Datenbank

Yourls nutzt MySQL als Backend:
- **Config:** `mysql.env` - Datenbank Credentials
- **Volume:** `./data/` - MySQL Daten

### Erste Einrichtung

1. Öffne `https://link.<deine-domain>`
2. Erstelle Admin Account
3. Konfiguriere API Keys (optional)
4. Beginne Links zu kürzen

## API Nutzung

```bash
# Link kürzen
curl "https://link.<deine-domain>/yourls-api.php?signature=<api-key>&action=shorturl&url=<url>"

# Link Statistiken
curl "https://link.<deine-domain>/yourls-api.php?signature=<api-key>&action=stats&shorturl=<short>"
```

## Troubleshooting

### Yourls startet nicht

```bash
# Logs prüfen
docker logs yoURLs

# MySQL prüfen
docker logs yourls-db
```

### Datenbank-Verbindung fehlgeschlagen

```bash
# MySQL Credentials prüfen
cat mysql.env

# MySQL Container Status
docker ps | grep yourls-db
```

## Weitere Informationen

- [Yourls Dokumentation](https://yourls.org/)
- [Yourls GitHub](https://github.com/YOURLS/YOURLS)

