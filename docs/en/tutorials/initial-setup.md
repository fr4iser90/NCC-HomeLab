# Initial Setup - First-time Setup

This guide describes the first-time setup of NCC-HomeLab using the automated setup script.

## Prerequisites

- [ ] Linux system (tested on NixOS)
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] User in the `docker` group
- [ ] Domain name (optional, but recommended)
- [ ] DNS provider credentials (for Let's Encrypt)

## Automated Setup

Setup is done via the `init-homelab.sh` script:

```bash
bash ./docker-scripts/bin/init-homelab.sh
```

### What the Script Does

1. **Domain Configuration** - Domain name and DNS provider setup
2. **Email Setup** - Email for Let's Encrypt certificates
3. **Service Selection** - Interactive selection of services
4. **Credentials Configuration** - Automatic or manual credential generation
5. **Gateway Setup** - Traefik, CrowdSec, DDNS configuration
6. **Service Initialization** - All selected services are configured
7. **Port Forwarding Info** - Instructions for router configuration

### Manual Setup

If you don't want to use the script, see:
- [Service Deployment](./service-deployment.md) - Manual service deployment
- [Service Documentation](../services/) - Individual service configuration

## After Setup

### Check Services

```bash
docker ps
docker-compose -f docker/gateway-management/traefik-crowdsec/docker-compose.yml ps
```

### Router Configuration

The script shows you the required port forwards. Typically:
- Port 80 → `<server-ip>:80`
- Port 443 → `<server-ip>:443`

### Access to Services

After setup, services are accessible at:

**Public (without admin-whitelist):**
- Bitwarden Sync: `https://bw.<your-domain>` - ✅ Public (needed for sync, only `default@file`)
- PufferPanel: `https://pufferpanel.<your-domain>` - ⚠️ **PUBLIC** - Only `default@file`, **NO admin-whitelist!**

**ONLY via VPN/LAN (protected with admin-whitelist):**
- Traefik Dashboard: `https://traefik.<your-domain>` - ⚠️ **HIGH RISK** - Shows all services - ✅ **ACTIVE**
- Portainer Dashboard: `https://portainer.<your-domain>` - ⚠️ **HIGH RISK** - Full Docker access
- Pi-hole Web UI: `https://pihole.<your-domain>` - ⚠️ **MEDIUM RISK** - DNS configuration
- Jellyfin: `https://jellyfin.<your-domain>` - ⚠️ **MEDIUM RISK** - Media access
- Plex: `https://plex.<your-domain>` - ⚠️ **MEDIUM RISK** - Media access
- Organizr: `https://organizr.<your-domain>` - ⚠️ **MEDIUM RISK** - Service overview
- Yourls: `https://link.<your-domain>` - ⚠️ **LOW RISK** - Link management
- OwnCloud: `https://owncloud.<your-domain>` - ⚠️ **MEDIUM RISK** - File storage
- Bitwarden Admin: `https://bw.<your-domain>/admin` - ⚠️ **HIGH RISK** - Server administration
- WireGuard UI: `https://wireguard-ui.<your-domain>` - ⚠️ **HIGH RISK** - VPN management

**Local (only on server, 127.0.0.1):**
- Traefik API: `http://localhost:8080` - Only locally accessible (127.0.0.1:8080)

**Local (only in network):**
- Organizr: `http://localhost:8003`

> **Important:** 
> - Most admin interfaces are protected with `admin-whitelist@file` (only VPN/LAN)
> - **PufferPanel** has NO admin-whitelist - should be added!
> - If you want to make services public, remove the `admin-whitelist@file` middleware - **NOT RECOMMENDED!**

## Next Steps

- [Service Deployment Tutorial](./service-deployment.md) - Add more services
- [Docker Swarm Guide](../guides/docker-swarm.md) - Migration to Swarm
- [Service Documentation](../services/) - Service-specific configuration

