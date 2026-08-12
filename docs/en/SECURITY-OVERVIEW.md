# Security Overview - Services & Access Methods

This overview shows all services, their access methods, and security risk assessments.

## Legend

- ✅ **LOW RISK** - Can be made public
- ⚠️ **MEDIUM RISK** - Should only be accessible via VPN/LAN
- ⚠️ **HIGH RISK** - **MUST** only be accessible via VPN/LAN

## Services by Access Method

### Public (Port 80/443)

| Service | Port | Risk | Protection | Recommendation |
|---------|------|------|------------|----------------|
| **Traefik** | 80/443 | ✅ LOW | CrowdSec, Rate Limiting | ✅ Public (necessary) |
| **Bitwarden Sync** | 443 (via Traefik) | ✅ LOW | Client-side encryption | ✅ Public (needed for sync) |

### Public (Other Ports)

| Service | Port | Risk | Protection | Recommendation |
|---------|------|------|------------|----------------|
| **WireGuard VPN** | 51820/UDP | ✅ LOW | WireGuard encryption | ✅ Public (needed for VPN) |
| **PufferPanel Game Ports** | 27015+ | ⚠️ MEDIUM | Game Server Security | ⚠️ Only if needed |

### Admin UIs — Traefik/DNS OFF by default (VPN/LAN preferred)

| Service | DNS | Risk | Protection | Status |
|---------|-----|------|------------|--------|
| **Traefik Dashboard** | `traefik.domain` | ⚠️ **HIGH** | Routers commented out; API on `127.0.0.1:8080` | ✅ Unexposed by default |
| **Portainer** | `portainer.domain` | ⚠️ **HIGH** | `traefik.enable=false` | ✅ Unexposed by default |
| **WireGuard UI** | `wireguard-ui.domain` | ⚠️ **HIGH** | `traefik.enable=false` (UDP 51820 stays public) | ✅ Unexposed by default |
| **PufferPanel** | `pufferpanel.domain` | ⚠️ **HIGH** | `traefik.enable=false` (game ports stay published) | ✅ Unexposed by default |
| **Grafana / Prometheus** | `grafana` / `prometheus.domain` | ⚠️ **HIGH** | `traefik.enable=false` | ✅ Unexposed by default |

Optional: set `enable=true` (or uncomment Traefik dashboard routers) **only** with Auth + `admin-whitelist`.

### DNS Access with admin-whitelist (ONLY VPN/LAN)

| Service | DNS | Risk | Protection | Status |
|---------|-----|------|------------|--------|
| **Pi-hole** | `pihole.domain` | ⚠️ MEDIUM | Whitelist + Rate Limit | ✅ Protected |
| **Jellyfin** | `jellyfin.domain` | ⚠️ MEDIUM | Whitelist | ✅ Protected |
| **Plex** | `plex.domain` | ⚠️ MEDIUM | Whitelist | ✅ Protected |
| **Organizr** | `organizr.domain` | ⚠️ MEDIUM | Whitelist + Rate Limit | ✅ Protected |
| **Yourls** | `link.domain` | ⚠️ LOW | Basic Auth + Whitelist | ✅ Protected |
| **OwnCloud** | `owncloud.domain` | ⚠️ MEDIUM | Whitelist + Rate Limit | ✅ Protected |
| **Bitwarden Admin** | `bw.domain/admin` | ⚠️ **HIGH** | Basic Auth + Whitelist | ✅ Protected |

### DNS Access WITHOUT admin-whitelist (⚠️ PUBLIC!)

| Service | DNS | Risk | Protection | Status |
|---------|-----|------|------------|--------|
| **Bitwarden Sync** | `bw.domain` | ✅ **LOW** | Only `default@file` | ✅ Public (needed for sync) |

> **⚠️ IMPORTANT:** Bitwarden Sync is intentionally public (needed for Mobile/Desktop sync).

### Local Only (127.0.0.1 or local ports)

| Service | Port | Risk | Recommendation |
|---------|------|------|----------------|
| **Traefik API** | 127.0.0.1:8080 | ✅ LOW | ✅ Keep as is |
| **Organizr** | 8003 (local) | ✅ LOW | ✅ Keep as is |
| **Jellyfin** | 8096, 8920 (local) | ✅ LOW | ✅ Keep as is |
| **Plex** | 32400+ (local) | ✅ LOW | ✅ Keep as is |
| **Pi-hole DNS** | 53 (local) | ✅ LOW | ✅ Keep as is |
| **Tarpit Prometheus** | 127.0.0.1:2112 | ✅ LOW | ✅ Keep as is |

## Security Recommendations

### ✅ Recommended Configuration

1. **Admin Interfaces ONLY via VPN/LAN**
   - Traefik Dashboard, Portainer, WireGuard UI, PufferPanel, Grafana/Prometheus (**default: no public DNS**)
   - All other service admin panels behind whitelist

2. **Public only what's necessary**
   - Traefik (80/443) - Reverse Proxy
   - Bitwarden Sync - For Mobile/Desktop Sync
   - WireGuard VPN - For VPN access

3. **Don't forward local ports**
   - Organizr (8003)
   - Jellyfin/Plex Discovery Ports
   - Pi-hole DNS (53)

### 🔒 Best Practices

1. **Always admin-whitelist for Admin Interfaces**
2. **Basic Auth in addition to Whitelist**
3. **Enable Rate Limiting**
4. **Regular Updates**
5. **Enable Monitoring (CrowdSec)**

## admin-whitelist Configuration

The `admin-whitelist` middleware only allows access from:
- `192.168.0.0/16` (LAN)
- `10.8.0.0/24` (VPN)
- `172.16.0.0/12` (Docker Networks)
- `172.40.0.0/16` (Proxy Network)
- `172.41.0.0/16` (CrowdSec Network)
- Your current public IP (automatically updated)

## Services without Traefik (local only)

- **CrowdSec** - Internal only
- **DDNS Updater** - Internal only
- **Cloudflare Companion** - Internal only
- **Watchtower** - Internal only

These services have no Traefik labels and are only internally accessible.

---

**Last Updated:** Based on current docker-compose.yml configuration

