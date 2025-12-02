# CrowdSec - Security & Threat Detection

CrowdSec ist ein Open-Source Security Engine, das Bedrohungen erkennt und blockiert. Es analysiert Logs und erstellt automatisch IP-Blacklists.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `crowdsecurity/crowdsec:latest`
- **Netzwerk:** `crowdsec`
- **Konfiguration:** `docker/gateway-management/traefik-crowdsec/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/gateway-management/traefik-crowdsec
docker-compose up -d crowdsec
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `crowdsec.env` - Environment Variables
- `crowdsec/config/` - CrowdSec Konfiguration
- `crowdsec/data/` - CrowdSec Daten

### Integration mit Traefik

CrowdSec wird über den `traefik-crowdsec-bouncer` mit Traefik integriert:

```yaml
traefik_crowdsec_bouncer:
  image: fbonalair/traefik-crowdsec-bouncer:latest
  env_file: traefik-crowdsec-bouncer.env
  networks:
    - crowdsec
```

## Features

- ✅ Automatische Bedrohungserkennung
- ✅ IP-Blacklisting
- ✅ Log-Analyse (Traefik, Auth-Logs)
- ✅ Community-basierte Bedrohungsdatenbank
- ✅ Traefik Integration

## Konfiguration

### Log-Quellen

CrowdSec analysiert:
- `/var/log/traefik/` - Traefik Access Logs
- `/var/log/auth.log` - System Auth Logs

### Parsers & Scenarios

Konfiguriert in `crowdsec/config/`:
- **Parsers:** Log-Format Parser
- **Scenarios:** Bedrohungserkennungs-Regeln
- **Collections:** Vordefinierte Regel-Sets

## Daten

- **Config:** `./crowdsec/config/`
- **Data:** `./crowdsec/data/`
- **Logs:** System Logs werden gemountet

## Troubleshooting

### CrowdSec startet nicht

```bash
# Logs prüfen
docker logs crowdsec

# Config prüfen
ls -la ./crowdsec/config/
```

### Keine Bedrohungen erkannt

```bash
# CrowdSec Status
docker exec crowdsec cscli metrics

# Scenarios prüfen
docker exec crowdsec cscli scenarios list
```

### Bouncer funktioniert nicht

```bash
# Bouncer Logs
docker logs traefik_crowdsec_bouncer

# Verbindung prüfen
docker exec traefik_crowdsec_bouncer ping crowdsec
```

## Weitere Informationen

- [CrowdSec Dokumentation](https://docs.crowdsec.net/)
- [Traefik Bouncer](https://github.com/fbonalair/traefik-crowdsec-bouncer)

