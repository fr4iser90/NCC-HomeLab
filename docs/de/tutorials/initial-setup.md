# Initial Setup - Erste Einrichtung

Diese Anleitung beschreibt die erste Einrichtung des NCC-HomeLab mit dem automatisierten Setup-Script.

## Voraussetzungen

- [ ] Linux-System (getestet auf NixOS)
- [ ] Docker installiert
- [ ] Docker Compose installiert
- [ ] User in der `docker` Gruppe
- [ ] Domain Name (optional, aber empfohlen)
- [ ] DNS Provider Zugangsdaten (für Let's Encrypt)

## Automatisiertes Setup

Das Setup erfolgt über das `init-homelab.sh` Script:

```bash
bash ./docker-scripts/bin/init-homelab.sh
```

### Was das Script macht

1. **Domain Konfiguration** - Domain Name und DNS Provider Setup
2. **Email Setup** - Email für Let's Encrypt Zertifikate
3. **Service Auswahl** - Interaktive Auswahl der Services
4. **Credentials Konfiguration** - Automatische oder manuelle Credential-Generierung
5. **Gateway Setup** - Traefik, CrowdSec, DDNS Konfiguration
6. **Service Initialisierung** - Alle ausgewählten Services werden konfiguriert
7. **Port Forwarding Info** - Hinweise für Router-Konfiguration

### Manuelles Setup

Falls du das Script nicht nutzen möchtest, siehe:
- [Service Deployment](./service-deployment.md) - Manuelles Deployen von Services
- [Service Dokumentation](../services/) - Konfiguration einzelner Services

## Nach dem Setup

### Services prüfen

```bash
docker ps
docker-compose -f docker/gateway-management/traefik-crowdsec/docker-compose.yml ps
```

### Router Konfiguration

Das Script zeigt dir die benötigten Port-Forwards. Typischerweise:
- Port 80 → `<server-ip>:80`
- Port 443 → `<server-ip>:443`

### Zugriff auf Services

Nach dem Setup sind Services erreichbar unter:

**Öffentlich (ohne admin-whitelist):**
- Bitwarden Sync: `https://bw.<deine-domain>` - ✅ Öffentlich (für Sync nötig, nur `default@file`)
- PufferPanel: `https://pufferpanel.<deine-domain>` - ⚠️ **ÖFFENTLICH** - Nur `default@file`, **KEINE admin-whitelist!**

**NUR über VPN/LAN (mit admin-whitelist geschützt):**
- Traefik Dashboard: `https://traefik.<deine-domain>` - ⚠️ **HOCHES RISIKO** - Zeigt alle Services - ✅ **AKTIV**
- Portainer Dashboard: `https://portainer.<deine-domain>` - ⚠️ **HOCHES RISIKO** - Vollzugriff auf Docker
- Pi-hole Web UI: `https://pihole.<deine-domain>` - ⚠️ **MITTELES RISIKO** - DNS-Konfiguration
- Jellyfin: `https://jellyfin.<deine-domain>` - ⚠️ **MITTELES RISIKO** - Media-Zugriff
- Plex: `https://plex.<deine-domain>` - ⚠️ **MITTELES RISIKO** - Media-Zugriff
- Organizr: `https://organizr.<deine-domain>` - ⚠️ **MITTELES RISIKO** - Service-Übersicht
- Yourls: `https://link.<deine-domain>` - ⚠️ **NIEDRIGES RISIKO** - Link-Management
- OwnCloud: `https://owncloud.<deine-domain>` - ⚠️ **MITTELES RISIKO** - File Storage
- Bitwarden Admin: `https://bw.<deine-domain>/admin` - ⚠️ **HOCHES RISIKO** - Server-Administration
- WireGuard UI: `https://wireguard-ui.<deine-domain>` - ⚠️ **HOCHES RISIKO** - VPN-Management

**Lokal (nur auf dem Server, 127.0.0.1):**
- Traefik API: `http://localhost:8080` - Nur lokal erreichbar (127.0.0.1:8080)

**Lokal (nur im Netzwerk):**
- Organizr: `http://localhost:8003`

> **Wichtig:** 
> - Die meisten Admin-Interfaces sind mit `admin-whitelist@file` geschützt (nur VPN/LAN)
> - **PufferPanel** hat KEINE admin-whitelist - sollte hinzugefügt werden!
> - Falls du Services öffentlich machen willst, entferne die `admin-whitelist@file` Middleware - **NICHT EMPFOHLEN!** 

## Nächste Schritte

- [Service Deployment Tutorial](./service-deployment.md) - Weitere Services hinzufügen
- [Docker Swarm Guide](../guides/docker-swarm.md) - Migration zu Swarm
- [Service Dokumentation](../services/) - Service-spezifische Konfiguration

