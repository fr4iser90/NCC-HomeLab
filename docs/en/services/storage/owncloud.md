# OwnCloud - File Storage

OwnCloud is an open-source file storage solution for your files.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `owncloud/server:latest`
- **Port:** 80 (internal)
- **Network:** `proxy`
- **Configuration:** `docker/storage-management/owncloud/`

## Docker Configuration

### Docker Compose

```bash
cd docker/storage-management/owncloud
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `mysql.env` - MySQL database configuration
- `./owncloud/` - OwnCloud data

## Features

- ✅ File storage & sync
- ✅ Web interface
- ✅ Desktop client
- ✅ Mobile apps
- ✅ File sharing
- ✅ Version control
- ✅ MySQL backend

## Access

- **Web UI:** `https://owncloud.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN**
- **Desktop Client:** OwnCloud desktop app
- **Mobile:** OwnCloud mobile apps

## Security Risk Assessment

- **Risk:** ⚠️ **MEDIUM** - File storage, possible sensitive data
- **Protection:** Admin Whitelist (only VPN/LAN) + Rate Limiting
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware
- **Note:** For external access use VPN, don't make it directly public

## Traefik Configuration

OwnCloud is made accessible via Traefik. Labels must be configured in `docker-compose.yml`.

## Configuration

### MySQL Database

OwnCloud uses MySQL as backend:
- **Config:** `mysql.env` - Database credentials
- **Volume:** MySQL data is stored persistently

### Data

- **OwnCloud Data:** `./owncloud/` - Files and configuration
- **MySQL Data:** MySQL volume

## First-time Setup

1. Open `https://owncloud.<your-domain>`
2. Create admin account
3. Install desktop client or mobile app
4. Connect to server

## Security

- ✅ HTTPS via Traefik
- ✅ Encrypted connections
- ✅ Admin whitelist (optional)

## Troubleshooting

### OwnCloud Won't Start

```bash
# Check logs
docker logs owncloud

# Check MySQL
docker logs owncloud-mysql
```

### Database Connection Failed

```bash
# Check MySQL credentials
cat mysql.env

# MySQL container status
docker ps | grep mysql
```

### Files Not Syncing

```bash
# Check permissions
ls -la ./owncloud/

# OwnCloud logs
docker logs owncloud | grep -i error
```

## Further Information

- [OwnCloud Documentation](https://doc.owncloud.com/)
- [OwnCloud GitHub](https://github.com/owncloud/core)

