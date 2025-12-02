# Yourls - URL Shortener

Yourls (Your Own URL Shortener) is a self-hosted URL shortener for your own short links.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `yourls:latest`
- **Port:** 80 (internal)
- **Network:** `proxy`
- **Database:** MySQL
- **Configuration:** `docker/url-management/yourls/`

## Docker Configuration

### Docker Compose

```bash
cd docker/url-management/yourls
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `mysql.env` - MySQL database configuration
- `./data/` - MySQL data

## Features

- ✅ URL shortening
- ✅ Custom short links
- ✅ Link statistics
- ✅ QR-code generation
- ✅ API support
- ✅ MySQL backend

## Access

- **Web UI:** `https://link.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **API:** `https://link.<your-domain>/yourls-api.php` (with admin-whitelist)

## Security Risk Assessment

- **Risk:** ⚠️ **LOW-MEDIUM** - Link management, statistics
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN) + Rate Limiting
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware
- **Note:** Short links are publicly accessible (via redirect), but admin interface is protected

## Traefik Configuration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.yourls.rule=Host(`link.${DOMAIN}`)"
  - "traefik.http.routers.yourls.tls=true"
  - "traefik.http.services.yourls.loadbalancer.server.port=80"
```

**Security:**
- Basic Auth enabled
- Admin Whitelist enabled
- Rate Limiting enabled

## Configuration

### MySQL Database

Yourls uses MySQL as backend:
- **Config:** `mysql.env` - Database credentials
- **Volume:** `./data/` - MySQL data

### First-time Setup

1. Open `https://link.<your-domain>`
2. Create admin account
3. Configure API keys (optional)
4. Start shortening links

## API Usage

```bash
# Shorten link
curl "https://link.<your-domain>/yourls-api.php?signature=<api-key>&action=shorturl&url=<url>"

# Link statistics
curl "https://link.<your-domain>/yourls-api.php?signature=<api-key>&action=stats&shorturl=<short>"
```

## Troubleshooting

### Yourls Won't Start

```bash
# Check logs
docker logs yoURLs

# Check MySQL
docker logs yourls-db
```

### Database Connection Failed

```bash
# Check MySQL credentials
cat mysql.env

# MySQL container status
docker ps | grep yourls-db
```

## Further Information

- [Yourls Documentation](https://yourls.org/)
- [Yourls GitHub](https://github.com/YOURLS/YOURLS)

