# Traefik - Reverse Proxy

Traefik is the reverse proxy for the NCC-HomeLab setup. It handles SSL/TLS termination, routing, and load balancing.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `traefik:v3.1.0`
- **Ports:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Networks:** `proxy`, `crowdsec`
- **Configuration:** `docker/gateway-management/traefik-crowdsec/`

## Docker Configuration

### Docker Compose

```bash
cd docker/gateway-management/traefik-crowdsec
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `traefik.env` - Environment variables
- `traefik/traefik.yml` - Traefik configuration
- `traefik/dynamic-conf/` - Dynamic configuration

### Docker Swarm Stack

```bash
docker stack deploy -c docker-stack.yml gateway
```

**Important:** For Swarm, shared storage (NFS) is recommended for ACME certificates!

## Features

- ✅ Automatic SSL certificates (Let's Encrypt)
- ✅ Docker provider (automatic service discovery)
- ✅ CrowdSec integration (security)
- ✅ Rate limiting
- ✅ Admin whitelist
- ✅ Security headers

## Access

- **HTTP/HTTPS:** Port 80/443 (public) - Reverse proxy for all services
- **Dashboard:** `https://traefik.<your-domain>` (with admin-whitelist) - ⚠️ **ONLY VPN/LAN** - ✅ **ACTIVE**
- **API (local):** `http://localhost:8080/api/rawdata` - Local only (127.0.0.1:8080, not accessible from outside)

## Security Risk Assessment

### Port 80/443 (public)
- **Risk:** ✅ **LOW** - Reverse proxy, no direct data
- **Protection:** CrowdSec, rate limiting, security headers
- **Recommendation:** ✅ Make public (necessary for services)

### Traefik Dashboard (DNS)
- **Status:** ✅ **ACTIVE** - Accessible via `https://traefik.<your-domain>`
- **Risk:** ⚠️ **HIGH** - Shows all services, configuration, logs
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**
- **Current Configuration:** Protected with `admin-whitelist@file` middleware
- **Note:** Dashboard is enabled (`traefik.enable=true`), the outdated comment in docker-compose.yml is wrong

### API (local)
- **Status:** ✅ **ACTIVE** - Only locally accessible
- **Port:** `127.0.0.1:8080:8080` - Only on the server itself
- **Risk:** ✅ **LOW** - No external access possible
- **Protection:** Port binding on 127.0.0.1 (not 0.0.0.0)
- **Recommendation:** ✅ Keep as is (local only) - Perfect!

## Labels for Services

Services are configured via Docker labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy"
  - "traefik.http.routers.<service>.rule=Host(`<service>.<domain>`)"
  - "traefik.http.routers.<service>.tls=true"
  - "traefik.http.routers.<service>.tls.certresolver=http_resolver"
  - "traefik.http.services.<service>.loadbalancer.server.port=<port>"
```

## Middlewares

Available middlewares:

- `default@file` - Standard security headers
- `traefikAuth@file` - Basic Auth
- `admin-whitelist@file` - IP whitelist
- `rate-limit@docker` - Rate limiting
- `security-headers@docker` - Extended security headers

## ACME / Let's Encrypt

Certificates are automatically created and renewed.

**Storage:** `./traefik/acme_letsencrypt.json`

**For Swarm:** Shared storage (NFS) recommended!

## Troubleshooting

### Certificates Not Created

```bash
# Check logs
docker logs traefik

# Check ACME file
cat ./traefik/acme_letsencrypt.json
```

### Service Not Detected

```bash
# Check labels
docker inspect <container-name> | grep -A 20 Labels

# Check network
docker network inspect proxy
```

## Further Information

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Provider](https://doc.traefik.io/traefik/routing/providers/docker/)

