# Portainer - Docker Management UI

Portainer provides a user-friendly web UI for managing Docker containers, images, volumes, and networks.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `portainer/portainer-ce:latest`
- **Port:** 9000 (internal)
- **Network:** `proxy`
- **Configuration:** `docker/system-management/portainer/`

## Docker Configuration

### Docker Compose

```bash
cd docker/system-management/portainer
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `./data/` - Portainer data

### Docker Swarm Stack

```bash
docker stack deploy -c docker-stack.yml system
```

**Important:** Portainer should run on a manager node (for Swarm management)!

## Access

- **Web UI:** `https://portainer.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**

## Security Risk Assessment

- **Risk:** ⚠️ **HIGH** - Full access to Docker (containers, images, volumes, networks)
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware
- **Alternative:** Local only via port 9000 (without Traefik label)

## Features

- ✅ Container management
- ✅ Image management
- ✅ Volume management
- ✅ Network management
- ✅ Docker Swarm support
- ✅ Stack deployment
- ✅ Service management

## First-time Setup

1. Open Portainer web UI
2. Create admin account
3. Select "Docker" environment
4. Connect to Docker socket

## Docker Swarm

Portainer can manage Docker Swarm clusters:

1. In Portainer: Environments → Add Environment
2. Select "Docker Swarm"
3. Add manager node IP
4. Connect

## Security

- ✅ Basic Auth via Traefik
- ✅ Admin whitelist (only VPN/LAN)
- ✅ Sticky sessions

## Data

- **Data:** `./data/`

## Troubleshooting

### Portainer Won't Start

```bash
# Check logs
docker logs portainer

# Check Docker socket
ls -la /var/run/docker.sock
```

### Swarm Not Visible

```bash
# Check Swarm status
docker node ls

# Deploy Portainer on manager node
```

## Further Information

- [Portainer Documentation](https://docs.portainer.io/)
- [Portainer GitHub](https://github.com/portainer/portainer)

