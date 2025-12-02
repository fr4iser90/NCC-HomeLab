# WireGuard - VPN Server

WireGuard is a modern, fast VPN server for secure remote access.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `linuxserver/wireguard:latest`
- **Ports:** 51820/UDP (VPN), 51821 (Web UI, optional)
- **Network:** `proxy` (for Web UI)
- **Configuration:** `docker/vpn-management/wireguard/`

## Docker Configuration

### Docker Compose

```bash
cd docker/vpn-management/wireguard
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `wireguard.env` - Environment variables
- `./wireguard/` - WireGuard configuration

## Features

- ✅ Modern VPN technology
- ✅ Fast connections
- ✅ Low latency
- ✅ Web UI (optional)
- ✅ QR-code for mobile setup

## Access

- **VPN:** `udp://<server-ip>:51820` (public) - ✅ Needed for VPN
- **Web UI:** `https://wireguard.<your-domain>` (with admin-whitelist, if configured) - ⚠️ **ONLY VPN/LAN**

## Security Risk Assessment

### VPN Port (51820/UDP)
- **Risk:** ✅ **LOW** - Modern encryption, necessary for VPN
- **Protection:** WireGuard encryption, Perfect Forward Secrecy
- **Recommendation:** ✅ Make public (necessary for VPN)

### Web UI (DNS, if configured)
- **Risk:** ⚠️ **HIGH** - Client management, configuration
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware

## Configuration

### Port Forwarding

In router forward:
- **Port 51820/UDP** → `<server-ip>:51820`

### Client Configuration

1. Open WireGuard web UI (if enabled)
2. Create new client
3. Download configuration
4. Import into WireGuard client
5. Or scan QR-code (mobile)

### Environment Variables

Important variables in `wireguard.env`:
- `PEERS` - Number of clients
- `SERVERURL` - Public server URL
- `SERVERPORT` - VPN port (51820)

## First-time Setup

1. Start container
2. Check logs for server public key
3. Create clients (Web UI or manually)
4. Configure router port forward
5. Test connection

## Security

- ✅ Modern encryption
- ✅ Perfect Forward Secrecy
- ✅ Minimal code (safer)
- ✅ Web UI only via VPN/LAN (recommended)

## Troubleshooting

### VPN Won't Connect

```bash
# Container status
docker ps | grep wireguard

# Check logs
docker logs wireguard

# Check port
sudo netstat -ulnp | grep 51820
```

### Port Forwarding Not Working

```bash
# Check router port forward
# Must forward port 51820/UDP

# Check firewall
sudo ufw status
```

### Client Can't Connect

```bash
# Check server public key
docker logs wireguard | grep "Public Key"

# Check client config
# Must contain server public key
```

## Further Information

- [WireGuard Documentation](https://www.wireguard.com/)
- [LinuxServer WireGuard](https://github.com/linuxserver/docker-wireguard)

