# Cloudflare Companion - DNS Management

Cloudflare Companion automatically manages DNS entries in Cloudflare for Traefik services.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `tiredofit/traefik-cloudflare-companion:latest`
- **Network:** No special network
- **Configuration:** `docker/companion-management/cloudflare/`

## Docker Configuration

### Docker Compose

```bash
cd docker/companion-management/cloudflare
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `cloudflare-companion.env` - Cloudflare API credentials
- `./logs/` - Companion logs

## Features

- ✅ Automatic DNS entries
- ✅ Cloudflare integration
- ✅ Traefik service discovery
- ✅ A record management
- ✅ CNAME record management

## Configuration

### Cloudflare API

Requires Cloudflare API token or Global API key:

**In `cloudflare-companion.env`:**
```bash
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_KEY=your-api-key
# Or:
CLOUDFLARE_API_TOKEN=your-api-token
```

### Create API Token

1. Go to Cloudflare Dashboard
2. My Profile → API Tokens
3. Create token with:
   - Zone DNS Edit permissions
   - Zone Read permissions

### Docker Socket

Companion needs access to Docker socket:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## How It Works

1. Companion monitors Docker events
2. Detects new Traefik services
3. Reads Traefik labels
4. Creates/updates DNS entries in Cloudflare

## Troubleshooting

### DNS Entries Not Created

```bash
# Check logs
docker logs cloudflare-companion

# Check API credentials
cat cloudflare-companion.env

# API test
./check-token.sh
```

### API Token Invalid

```bash
# Create new token in Cloudflare
# Update in cloudflare-companion.env
# Restart container
docker-compose restart
```

### Docker Socket Access

```bash
# Check socket
ls -la /var/run/docker.sock

# Check permissions
docker ps  # Should work
```

## Further Information

- [Cloudflare Companion GitHub](https://github.com/tiredofit/docker-traefik-cloudflare-companion)
- [Cloudflare API Docs](https://developers.cloudflare.com/api/)

