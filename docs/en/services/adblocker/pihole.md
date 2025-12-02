# Pi-hole - DNS-based Ad Blocker

Pi-hole blocks ads and tracking at the DNS level for the entire network.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `pihole/pihole:latest`
- **Ports:** 53 (DNS TCP/UDP), 853 (DNS over TLS)
- **Network:** `proxy`
- **Configuration:** `docker/adblocker-management/pihole/`

## Docker Configuration

### Docker Compose

```bash
cd docker/adblocker-management/pihole
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `pihole.env` - Environment variables
- `./etc-pihole/` - Pi-hole configuration
- `./etc-dnsmasq.d/` - DNSmasq configuration

### Docker Swarm Stack

```bash
docker stack deploy -c docker-stack.yml adblocker
```

**Important:** DNS ports must use `mode: host` (Routing Mesh doesn't work well for DNS)!

## Access

- **Web UI:** `https://pihole.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **DNS Server:** `Host-IP:53` (local in network)

## Security Risk Assessment

### Web UI (DNS)
- **Risk:** ⚠️ **MEDIUM** - DNS configuration, query logs, whitelist/blacklist
- **Protection:** Admin Whitelist (only VPN/LAN) + Rate Limiting
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware

### DNS Port 53
- **Risk:** ✅ **LOW** - Only local in network
- **Protection:** No external access (not forwarded in router)
- **Recommendation:** ✅ Keep as is (local only)

## Router Configuration

Set Pi-hole as DNS server in your router:

1. Open router admin panel
2. Find DNS settings
3. Primary DNS: `<pi-hole-host-ip>`
4. Secondary DNS: `1.1.1.1` (Cloudflare) or `8.8.8.8` (Google)

## Features

- ✅ DNS-based ad blocking
- ✅ Web interface for management
- ✅ Query logs
- ✅ Whitelist/blacklist management
- ✅ DNS over TLS (DoT)

## Data

- **Config:** `./etc-pihole/`
- **DNSmasq Config:** `./etc-dnsmasq.d/`

## Troubleshooting

### DNS Not Working

```bash
# Container logs
docker logs pihole

# DNS test
dig @<pi-hole-ip> google.com
```

### Web UI Not Reachable

```bash
# Check Traefik labels
docker inspect pihole | grep -A 20 Labels

# Check network
docker network inspect proxy
```

## Further Information

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole GitHub](https://github.com/pi-hole/pi-hole)

