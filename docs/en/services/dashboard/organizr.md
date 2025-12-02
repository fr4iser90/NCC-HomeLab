# Organizr - Dashboard

Organizr is an HTPC/Homelab services organizer with a beautiful dashboard.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `organizr/organizr:latest`
- **Ports:** 80 (internal), 8003 (local)
- **Network:** `proxy`
- **Configuration:** `docker/dashboard-management/organizr/`

## Docker Configuration

### Docker Compose

```bash
cd docker/dashboard-management/organizr
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `./data/` - Organizr configuration

## Features

- ✅ Unified dashboard for all services
- ✅ Tabbed interface
- ✅ Service status monitoring
- ✅ Bookmark management
- ✅ User management
- ✅ Theme support

## Access

- **Web UI:** `https://organizr.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **Local:** `http://localhost:8003` (Port 8003 local)

## Security Risk Assessment

### Web UI (DNS)
- **Risk:** ⚠️ **MEDIUM** - Overview of all services, possible credential exposure
- **Protection:** Admin Whitelist (only VPN/LAN) + Rate Limiting
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware

### Local Port (8003)
- **Risk:** ✅ **LOW** - Only local in network
- **Protection:** No external access (not forwarded in router)
- **Recommendation:** ✅ Keep as is (local only)

## Traefik Configuration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.organizr.rule=Host(`organizr.${DOMAIN}`)"
  - "traefik.http.routers.organizr.tls=true"
  - "traefik.http.services.organizr.loadbalancer.server.port=80"
```

**Security:**
- Admin whitelist enabled
- Rate limiting enabled

## Configuration

### Add Services

1. Open Organizr dashboard
2. Go to Settings → Tabs
3. Add new tabs:
   - Name, URL, Icon
   - Optional: Health check URL

### Data

- **Config:** `./data/` - Organizr configuration and database

## First-time Setup

1. Open `https://organizr.<your-domain>`
2. Create admin account
3. Add services/tabs
4. Configure themes (optional)

## Troubleshooting

### Organizr Won't Start

```bash
# Check logs
docker logs organizr

# Check permissions
ls -la ./data/
```

### Services Not Displayed

```bash
# Check tab configuration in Organizr UI
# Services must be added manually
```

## Further Information

- [Organizr GitHub](https://github.com/organizr/organizr)

