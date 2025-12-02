# Cloudflare Companion - DNS Management

Cloudflare Companion verwaltet automatisch DNS-Einträge in Cloudflare für Traefik Services.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `tiredofit/traefik-cloudflare-companion:latest`
- **Netzwerk:** Kein spezielles Netzwerk
- **Konfiguration:** `docker/companion-management/cloudflare/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/companion-management/cloudflare
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `cloudflare-companion.env` - Cloudflare API Credentials
- `./logs/` - Companion Logs

## Features

- ✅ Automatische DNS-Einträge
- ✅ Cloudflare Integration
- ✅ Traefik Service Discovery
- ✅ A Record Management
- ✅ CNAME Record Management

## Konfiguration

### Cloudflare API

Benötigt Cloudflare API Token oder Global API Key:

**In `cloudflare-companion.env`:**
```bash
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_KEY=your-api-key
# Oder:
CLOUDFLARE_API_TOKEN=your-api-token
```

### API Token erstellen

1. Gehe zu Cloudflare Dashboard
2. My Profile → API Tokens
3. Erstelle Token mit:
   - Zone DNS Edit Permissions
   - Zone Read Permissions

### Docker Socket

Companion benötigt Zugriff auf Docker Socket:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Funktionsweise

1. Companion überwacht Docker Events
2. Erkennt neue Traefik Services
3. Liest Traefik Labels
4. Erstellt/aktualisiert DNS-Einträge in Cloudflare

## Troubleshooting

### DNS-Einträge werden nicht erstellt

```bash
# Logs prüfen
docker logs cloudflare-companion

# API Credentials prüfen
cat cloudflare-companion.env

# API Test
./check-token.sh
```

### API Token ungültig

```bash
# Token neu erstellen in Cloudflare
# In cloudflare-companion.env aktualisieren
# Container neu starten
docker-compose restart
```

### Docker Socket Zugriff

```bash
# Socket prüfen
ls -la /var/run/docker.sock

# Permissions prüfen
docker ps  # Sollte funktionieren
```

## Weitere Informationen

- [Cloudflare Companion GitHub](https://github.com/tiredofit/docker-traefik-cloudflare-companion)
- [Cloudflare API Docs](https://developers.cloudflare.com/api/)

