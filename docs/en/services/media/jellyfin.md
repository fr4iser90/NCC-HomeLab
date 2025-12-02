# Jellyfin - Media Server

Jellyfin is an open-source media server for your movies, TV shows, and music.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `lscr.io/linuxserver/jellyfin:latest`
- **Ports:** 8096 (HTTP), 8920 (HTTPS), 7359/UDP (Discovery), 1900/UDP (DLNA)
- **Network:** `proxy`
- **Configuration:** `docker/media-management/jellyfin/`

## Docker Configuration

### Docker Compose

```bash
cd docker/media-management/jellyfin
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `jellyfin.env` - Environment variables
- `jellyfin/library/` - Configuration
- `jellyfin/tvseries/` - TV shows
- `jellyfin/movies/` - Movies

## Features

- ✅ Movie and TV show streaming
- ✅ Music streaming
- ✅ Live TV (with tuner)
- ✅ DLNA support
- ✅ Transcoding
- ✅ Multi-user support
- ✅ Mobile apps

## Access

- **Web UI:** `https://jellyfin.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **Local:** `http://localhost:8096` (Port 8096, 8920 local)

## Security Risk Assessment

### Web UI (DNS)
- **Risk:** ⚠️ **MEDIUM** - Media access, user management, possible transcoding load
- **Protection:** Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware

### Local Ports (8096, 8920)
- **Risk:** ✅ **LOW** - Only local in network
- **Protection:** No external access (not forwarded in router)
- **Recommendation:** ✅ Keep as is (local only for DLNA/Discovery)

## Traefik Configuration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${DOMAIN}`)"
  - "traefik.http.routers.jellyfin.tls=true"
  - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
  - "traefik.http.services.jellyfin.loadbalancer.sticky.cookie.httpOnly=true"
```

**Important:** Sticky sessions are enabled for better streaming!

## Configuration

### Media Libraries

After first start:
1. Open Jellyfin web UI
2. Go to Settings → Libraries
3. Add libraries:
   - Movies: `/data/movies`
   - TV Shows: `/data/tvshows`

### Volumes

- **Config:** `./jellyfin/library/` - Jellyfin configuration
- **Movies:** `./jellyfin/movies/` - Movie folder
- **TV Series:** `./jellyfin/tvseries/` - TV show folder

### Hardware Transcoding

For hardware transcoding (GPU):
```yaml
devices:
  - /dev/dri:/dev/dri  # Intel QuickSync / AMD
```

## First-time Setup

1. Open `https://jellyfin.<your-domain>`
2. Create admin account
3. Add media libraries
4. Scan libraries
5. Install client apps (optional)

## Security

- ✅ Admin whitelist (only VPN/LAN)
- ✅ HTTPS via Traefik
- ✅ Sticky sessions

## Troubleshooting

### Jellyfin Won't Start

```bash
# Check logs
docker logs jellyfin

# Check permissions
ls -la ./jellyfin/
```

### Media Not Found

```bash
# Check volume mounts
docker inspect jellyfin | grep -A 10 Mounts

# Check files
ls -la ./jellyfin/movies/
```

### Transcoding Not Working

```bash
# Check hardware
docker exec jellyfin ls -la /dev/dri/

# Check transcoding settings in Jellyfin UI
```

## Further Information

- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [Jellyfin GitHub](https://github.com/jellyfin/jellyfin)

