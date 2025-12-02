# DDNS Updater - Dynamic DNS

DDNS Updater aktualisiert automatisch DNS-Einträge bei wechselnder öffentlicher IP-Adresse.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `qmcgaw/ddns-updater:latest`
- **Netzwerk:** `proxy` (optional)
- **Konfiguration:** `docker/gateway-management/ddns-updater/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/gateway-management/ddns-updater
docker-compose up -d
```

**Dateien:**
- `docker-compose.yaml` - Container Definition
- `ddns-updater.env` - Environment Variables
- `config/ddclient.conf` - DDNS Provider Konfiguration

## Features

- ✅ Automatische IP-Erkennung
- ✅ Multi-Provider Support (100+ DNS Provider)
- ✅ Regelmäßige Updates
- ✅ Web UI für Status

## Konfiguration

### DNS Provider

Unterstützte Provider (Beispiele):
- Cloudflare
- Gandi
- OVH
- DigitalOcean
- ... und 100+ weitere

### Environment Variables

```bash
# In ddns-updater.env
DOMAINS=subdomain.example.com
PROVIDER=cloudflare
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_KEY=your-api-key
```

### Update Scripts

```bash
# Environment aktualisieren
./update-ddns-env.sh

# Config aktualisieren
./update-ddns-config.sh
```

## Zugriff

- **Web UI:** `http://localhost:8080` (falls Port freigegeben)
- **Status:** Über Logs prüfen

## Troubleshooting

### IP wird nicht aktualisiert

```bash
# Logs prüfen
docker logs ddns-updater

# Config prüfen
cat config/ddclient.conf
```

### Provider-Fehler

```bash
# API Keys prüfen
cat ddns-updater.env

# Provider-spezifische Logs
docker logs ddns-updater | grep -i error
```

## Weitere Informationen

- [DDNS Updater GitHub](https://github.com/qdm12/ddns-updater)
- [Supported Providers](https://github.com/qdm12/ddns-updater#supported-providers)

