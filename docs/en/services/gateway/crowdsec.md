# CrowdSec - Security & Threat Detection

CrowdSec is an open-source security engine that detects and blocks threats. It analyzes logs and automatically creates IP blacklists.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `crowdsecurity/crowdsec:latest`
- **Network:** `crowdsec`
- **Configuration:** `docker/gateway-management/traefik-crowdsec/`

## Docker Configuration

### Docker Compose

```bash
cd docker/gateway-management/traefik-crowdsec
docker-compose up -d crowdsec
```

**Files:**
- `docker-compose.yml` - Container definition
- `crowdsec.env` - Environment variables
- `crowdsec/config/` - CrowdSec configuration
- `crowdsec/data/` - CrowdSec data

### Integration with Traefik

CrowdSec is integrated with Traefik via the `traefik-crowdsec-bouncer`:

```yaml
traefik_crowdsec_bouncer:
  image: fbonalair/traefik-crowdsec-bouncer:latest
  env_file: traefik-crowdsec-bouncer.env
  networks:
    - crowdsec
```

## Features

- ✅ Automatic threat detection
- ✅ IP blacklisting
- ✅ Log analysis (Traefik, auth logs)
- ✅ Community-based threat database
- ✅ Traefik integration

## Configuration

### Log Sources

CrowdSec analyzes:
- `/var/log/traefik/` - Traefik access logs
- `/var/log/auth.log` - System auth logs

### Parsers & Scenarios

Configured in `crowdsec/config/`:
- **Parsers:** Log format parsers
- **Scenarios:** Threat detection rules
- **Collections:** Predefined rule sets

## Data

- **Config:** `./crowdsec/config/`
- **Data:** `./crowdsec/data/`
- **Logs:** System logs are mounted

## Troubleshooting

### CrowdSec Won't Start

```bash
# Check logs
docker logs crowdsec

# Check config
ls -la ./crowdsec/config/
```

### No Threats Detected

```bash
# CrowdSec status
docker exec crowdsec cscli metrics

# Check scenarios
docker exec crowdsec cscli scenarios list
```

### Bouncer Not Working

```bash
# Bouncer logs
docker logs traefik_crowdsec_bouncer

# Check connection
docker exec traefik_crowdsec_bouncer ping crowdsec
```

## Further Information

- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [Traefik Bouncer](https://github.com/fbonalair/traefik-crowdsec-bouncer)

