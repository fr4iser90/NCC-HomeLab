# Bitwarden (Vaultwarden) - Password Manager

Vaultwarden is an unofficial, compatible implementation of the Bitwarden server. Stores passwords securely encrypted.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `vaultwarden/server:latest`
- **Port:** 80 (internal)
- **Network:** `proxy`
- **Configuration:** `docker/password-management/bitwarden/`

## Docker Configuration

### Docker Compose

```bash
cd docker/password-management/bitwarden
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `bitwarden.env` - Environment variables
- `data/` - Encrypted database

## Features

- ✅ Password synchronization
- ✅ Two-factor authentication (2FA)
- ✅ Secure notes
- ✅ Credit cards
- ✅ Identities
- ✅ Web vault
- ✅ Browser extensions
- ✅ Mobile apps

## Access

- **Web Vault:** `https://bw.<your-domain>` (public) - ✅ Needed for sync
- **Admin Panel:** `https://bw.<your-domain>/admin` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**

## Security Risk Assessment

### Web Vault (public)
- **Risk:** ✅ **LOW** - Encrypted on client-side, needed for sync
- **Protection:** Client-side encryption, rate limiting
- **Recommendation:** ✅ Make public (necessary for sync)

### Admin Panel (VPN/LAN)
- **Risk:** ⚠️ **HIGH** - Server administration, user management
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware

## Traefik Configuration

Bitwarden has two routers:

1. **Admin Router** (`bw-admin`)
   - Path: `/admin`
   - Middlewares: Basic Auth + IP Whitelist
   - Only for VPN/LAN

2. **Main Router** (`bw-secure`)
   - Main access
   - Public accessible (for sync)

3. **WebSocket Router** (`bitwarden-sock`)
   - For live updates
   - Port: 3012

## Configuration

### Environment Variables

Important variables in `bitwarden.env`:
- `SIGNUPS_ALLOWED` - Allow new registrations
- `DOMAIN` - Domain for Bitwarden
- `ADMIN_TOKEN` - Admin panel token

### Data

- **Database:** `./data/` (SQLite)
- **Attachments:** `./data/attachments/`
- **Icons:** `./data/icon_cache/`

## First-time Setup

1. Open `https://bw.<your-domain>`
2. Create account
3. Install browser extension or mobile app
4. Log in

## Security

- ✅ Client-side encryption
- ✅ Admin panel only via VPN/LAN
- ✅ Rate limiting enabled
- ✅ Sticky sessions for better security

## Troubleshooting

### Web Vault Not Reachable

```bash
# Container status
docker ps | grep bitwarden

# Check logs
docker logs bitwarden

# Check Traefik labels
docker inspect bitwarden | grep -A 30 Labels
```

### Sync Not Working

```bash
# Check WebSocket router
docker inspect bitwarden | grep -A 10 bitwarden-sock

# Check network
docker network inspect proxy
```

### Admin Panel Not Reachable

```bash
# Check IP whitelist
# Must contain your IP (VPN/LAN)

# Check Basic Auth
# Traefik Auth must be configured
```

## Further Information

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Bitwarden Clients](https://bitwarden.com/download/)

