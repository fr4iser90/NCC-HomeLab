# Portainer - Docker Management UI

Portainer bietet eine benutzerfreundliche Web-UI zur Verwaltung von Docker Containern, Images, Volumes und Netzwerken.

## Übersicht

- **Image:** `portainer/portainer-ce:latest`
- **Port:** 9000 (intern)
- **Netzwerk:** `proxy`

## Konfiguration

### Docker Compose

Siehe: `docker/system-management/portainer/docker-compose.yml`

### Docker Swarm Stack

Siehe: `docker/system-management/portainer/docker-stack.yml`

**Wichtig:** Portainer sollte auf einem Manager Node laufen (für Swarm Management)!

## Zugriff

- **Web UI:** `https://portainer.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**

## Sicherheitsrisiko-Einschätzung

- **Risiko:** ⚠️ **HOCH** - Vollzugriff auf Docker (Container, Images, Volumes, Netzwerke)
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt
- **Alternative:** Nur lokal über Port 9000 (ohne Traefik Label)

## Features

- ✅ Container Management
- ✅ Image Management
- ✅ Volume Management
- ✅ Network Management
- ✅ Docker Swarm Support
- ✅ Stack Deployment
- ✅ Service Management

## Erste Einrichtung

1. Öffne Portainer Web UI
2. Erstelle Admin Account
3. Wähle "Docker" Environment
4. Verbinde mit Docker Socket

## Docker Swarm

Portainer kann Docker Swarm Clusters verwalten:

1. In Portainer: Environments → Add Environment
2. Wähle "Docker Swarm"
3. Füge Manager Node IP hinzu
4. Verbinde

## Sicherheit

- ✅ Basic Auth über Traefik
- ✅ Admin Whitelist (nur VPN/LAN)
- ✅ Sticky Sessions

## Daten

- **Data:** `./data/`

## Troubleshooting

### Portainer startet nicht

```bash
# Logs prüfen
docker logs portainer

# Docker Socket prüfen
ls -la /var/run/docker.sock
```

### Swarm nicht sichtbar

```bash
# Swarm Status prüfen
docker node ls

# Portainer auf Manager Node deployen
```

## Weitere Informationen

- [Portainer Dokumentation](https://docs.portainer.io/)
- [Portainer GitHub](https://github.com/portainer/portainer)

