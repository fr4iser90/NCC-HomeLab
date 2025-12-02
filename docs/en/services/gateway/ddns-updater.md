# DDNS Updater - Dynamic DNS

DDNS Updater automatically updates DNS records when your public IP address changes.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `qmcgaw/ddns-updater:latest`
- **Network:** `proxy` (optional)
- **Configuration:** `docker/gateway-management/ddns-updater/`

## Docker Configuration

### Docker Compose

```bash
cd docker/gateway-management/ddns-updater
docker-compose up -d
```

**Files:**
- `docker-compose.yaml` - Container definition
- `ddns-updater.env` - Environment variables
- `config/ddclient.conf` - DDNS provider configuration

## Features

- ✅ Automatic IP detection
- ✅ Multi-provider support (100+ DNS providers)
- ✅ Regular updates
- ✅ Web UI for status

## Configuration

### DNS Provider

Supported providers (examples):
- Cloudflare
- Gandi
- OVH
- DigitalOcean
- ... and 100+ more

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
# Update environment
./update-ddns-env.sh

# Update config
./update-ddns-config.sh
```

## Access

- **Web UI:** `http://localhost:8080` (if port is exposed)
- **Status:** Check via logs

## Troubleshooting

### IP Not Updated

```bash
# Check logs
docker logs ddns-updater

# Check config
cat config/ddclient.conf
```

### Provider Error

```bash
# Check API keys
cat ddns-updater.env

# Provider-specific logs
docker logs ddns-updater | grep -i error
```

## Further Information

- [DDNS Updater GitHub](https://github.com/qdm12/ddns-updater)
- [Supported Providers](https://github.com/qdm12/ddns-updater#supported-providers)

