# Tarpit - Security Honeypot

Tarpit is a security honeypot that detects attacks and slows down attackers.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `tarampampam/tarpit:latest`
- **Ports:** 22 (SSH Honeypot), 80 (HTTP Honeypot)
- **Network:** `proxy` (optional)
- **Configuration:** `docker/honeypot-management/tarpit/`

## Docker Configuration

### Docker Compose

```bash
cd docker/honeypot-management/tarpit
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition
- `grafana.env` - Grafana configuration (optional)
- `prometheus.yml` - Prometheus configuration (optional)

## Features

- ✅ SSH honeypot
- ✅ HTTP honeypot
- ✅ Attacker slowdown (Tarpit)
- ✅ Logging & monitoring
- ✅ Prometheus integration
- ✅ Grafana dashboards

## Access

- **SSH Honeypot:** Port 2222 (local, not port 22!)
- **HTTP Honeypot:** Port 80 (local, not public!)
- **Prometheus:** `127.0.0.1:2112` (local only)
- **Grafana:** `https://grafana.<your-domain>` (with admin-whitelist, if configured) - ⚠️ **ONLY VPN/LAN**

## Security Risk Assessment

### Honeypot Ports (2222, 80)
- **Risk:** ✅ **LOW** - Should run on separate ports, not public
- **Protection:** Isolated from real services
- **Recommendation:** ✅ **ONLY local, DO NOT forward in router!**
- **Important:** ⚠️ Should NOT run on port 22/80 (conflict with real services)

### Prometheus (local)
- **Risk:** ✅ **LOW** - Only local (127.0.0.1)
- **Protection:** No external access
- **Recommendation:** ✅ Keep as is (local only)

### Grafana (DNS, if configured)
- **Risk:** ⚠️ **MEDIUM** - Monitoring data, possible sensitive information
- **Protection:** Basic Auth + Admin Whitelist (only VPN/LAN)
- **Recommendation:** ⚠️ **ONLY accessible via VPN/LAN!**

## Configuration

### Port Forwarding

**IMPORTANT:** Tarpit should run on separate ports, not on the real ports!

```yaml
ports:
  - "2222:22"  # SSH Honeypot (not port 22!)
  - "8080:80"  # HTTP Honeypot (not port 80!)
```

### Monitoring

Tarpit can be integrated with Prometheus and Grafana:
- **Prometheus:** Collect metrics
- **Grafana:** Visualize dashboards

## Security

- ✅ Isolated from real services
- ✅ Detects attacks
- ✅ Slows down attackers
- ⚠️ Should run on separate ports!

## Troubleshooting

### Tarpit Won't Start

```bash
# Check logs
docker logs tarpit

# Check ports
docker ps | grep tarpit
```

### No Metrics in Prometheus

```bash
# Check Prometheus config
cat prometheus.yml

# Prometheus logs
docker logs prometheus
```

## Further Information

- [Tarpit GitHub](https://github.com/tarampampam/tarpit)

