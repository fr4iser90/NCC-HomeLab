# Plex - Media Server

Plex is a media server for your movies, TV shows, and music with many client apps.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `plexinc/pms-docker:latest`
- **Ports:** 32400 (Web), 32469 (Discovery)
- **Network:** `proxy`
- **Configuration:** `docker/media-management/plex/`

## Docker Configuration

### Docker Compose

```bash
cd docker/media-management/plex
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `plex.env` - Environment variables
- `./plex/` - Plex data

## Features

- ✅ Movie and TV show streaming
- ✅ Music streaming
- ✅ Live TV (with Plex Pass)
- ✅ DVR (with Plex Pass)
- ✅ Transcoding
- ✅ Many client apps
- ✅ Remote access

## Access

- **Web UI:** `https://plex.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **Local:** `http://localhost:32400` (Port 32400 local)

## Security Risk Assessment

### Web UI (DNS)
- **Risk:** ⚠️ **MEDIUM** - Media access, user management, possible transcoding load
- **Protection:** Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware
- **Note:** Plex remote access works via Plex server (not via Traefik)

### Local Ports (32400+)
- **Risk:** ✅ **LOW** - Only local in network
- **Protection:** No external access (not forwarded in router)
- **Recommendation:** ✅ Keep as is (local only for Discovery/DLNA)

## Traefik Configuration

Plex is made accessible via Traefik. Labels must be configured in `docker-compose.yml`.

## Configuration

### Plex Claim Token

For remote access, you need a claim token:
```bash
./update-claim-token.sh
```

Or manually:
1. Go to https://www.plex.tv/claim
2. Copy token
3. Set in `plex.env`: `PLEX_CLAIM=<token>`

### Volumes

- **Config:** `./plex/` - Plex configuration and database

## First-time Setup

1. Open `https://plex.<your-domain>`
2. Create Plex account (or use existing)
3. Add media libraries
4. Scan libraries
5. Install client apps

## Plex Pass Features

With Plex Pass (paid):
- Hardware transcoding
- Live TV & DVR
- Mobile sync
- Premium music features

## Troubleshooting

### Plex Won't Start

```bash
# Check logs
docker logs plex

# Check claim token
cat plex.env | grep PLEX_CLAIM
```

### Remote Access Not Working

```bash
# Update claim token
./update-claim-token.sh

# Check port forwarding
# Plex needs port 32400
```

### Media Not Found

```bash
# Check volume mounts
docker inspect plex | grep -A 10 Mounts

# Check permissions
ls -la ./plex/
```

## Further Information

- [Plex Documentation](https://support.plex.tv/)
- [Plex Server Setup](https://support.plex.tv/articles/200289506-getting-started/)

