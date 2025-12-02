# PufferPanel - Game Server Management

PufferPanel is a web-based game server management panel.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `pufferpanel/pufferpanel:latest`
- **Ports:** 8080 (Web), 5657 (Daemon), 27015+ (Game Ports)
- **Network:** `proxy`
- **Configuration:** `docker/games-management/pufferpanel/`

## Docker Configuration

### Docker Compose

```bash
cd docker/games-management/pufferpanel
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `.env.pufferpanel` - Environment variables
- `./pufferpanel/data/` - PufferPanel data
- `./pufferpanel/config/` - PufferPanel configuration

## Features

- ✅ Game server management
- ✅ Web interface
- ✅ Multi-server support
- ✅ File manager
- ✅ Console access
- ✅ Resource monitoring

## Access

- **Web UI:** `https://pufferpanel.<your-domain>` (without admin-whitelist) - ⚠️ **RISK**
- **Daemon:** Port 5657 (internal)
- **Game Ports:** 27015+ (public, if forwarded)

## Security Risk Assessment

### Web UI (DNS)
- **Risk:** ⚠️ **MEDIUM-HIGH** - Game server management, possible RCE risks
- **Protection:** ⚠️ **NO admin-whitelist activated!** (only `default@file`)
- **Recommendation:** ⚠️ **Activate admin-whitelist or ONLY accessible via VPN/LAN!**
- **Current Configuration:** ⚠️ **NOT protected with admin-whitelist**

### Game Ports (27015+)
- **Risk:** ⚠️ **MEDIUM** - Game servers, possible exploits
- **Protection:** Game server security, firewall
- **Recommendation:** ⚠️ Only forward if needed, update regularly

## Traefik Configuration

### HTTP Router

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.pufferpanel.rule=Host(`pufferpanel.${DOMAIN}`)"
  - "traefik.http.services.pufferpanel.loadbalancer.server.port=8080"
```

### TCP Router (Daemon)

```yaml
labels:
  - "traefik.tcp.routers.pufferpanel-daemon.entrypoints=games"
  - "traefik.tcp.routers.pufferpanel-daemon.rule=HostSNI(`*`)"
  - "traefik.tcp.services.pufferpanel-daemon.loadbalancer.server.port=5657"
```

## Configuration

### Game Ports

PufferPanel needs ports for game servers:
```yaml
ports:
  - "27015:27015"  # SRCDS (CS:GO, TF2, etc.)
  - "25565:25565"  # Minecraft Java
  - "27065-27075:27065-27075"  # Port range
```

### Environment Variables

Important variables in `.env.pufferpanel`:
- Database configuration
- Admin credentials

### Data

- **Data:** `./pufferpanel/data/` - Server data
- **Config:** `./pufferpanel/config/` - PufferPanel configuration

## First-time Setup

1. Open `https://pufferpanel.<your-domain>`
2. Create admin account
3. Add game servers
4. Configure ports
5. Start servers

## Troubleshooting

### PufferPanel Won't Start

```bash
# Check logs
docker logs pufferpanel

# Check environment
cat .env.pufferpanel
```

### Game Server Won't Start

```bash
# Check ports
docker ps | grep pufferpanel

# Check port forwarding in router
```

### Daemon Not Reachable

```bash
# Check TCP router
docker inspect pufferpanel | grep -A 10 tcp

# Check Traefik TCP entrypoint
```

## Further Information

- [PufferPanel Documentation](https://docs.pufferpanel.com/)
- [PufferPanel GitHub](https://github.com/pufferpanel/pufferpanel)

