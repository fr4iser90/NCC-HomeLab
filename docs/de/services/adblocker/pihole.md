# Pi-hole - DNS-based Ad Blocker

Pi-hole blockiert Werbung und Tracking auf DNS-Ebene für das gesamte Netzwerk.

## Übersicht

- **Image:** `pihole/pihole:latest`
- **Ports:** 53 (DNS TCP/UDP), 853 (DNS over TLS)
- **Netzwerk:** `proxy`

## Konfiguration

### Docker Compose

Siehe: `docker/adblocker-management/pihole/docker-compose.yml`

### Docker Swarm Stack

Siehe: `docker/adblocker-management/pihole/docker-stack.yml`

**Wichtig:** DNS Ports müssen `mode: host` verwenden (Routing Mesh funktioniert nicht für DNS)!

## Zugriff

- **Web UI:** `https://pihole.<deine-domain>` (mit admin-whitelist) - ⚠️ **NUR VPN/LAN**
- **DNS Server:** `Host-IP:53` (lokal im Netzwerk)

## Sicherheitsrisiko-Einschätzung

### Web UI (DNS)
- **Risiko:** ⚠️ **MITTEL** - DNS-Konfiguration, Query Logs, Whitelist/Blacklist
- **Schutz:** Admin Whitelist (nur VPN/LAN) + Rate Limiting
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt

### DNS Port 53
- **Risiko:** ✅ **NIEDRIG** - Nur lokal im Netzwerk
- **Schutz:** Kein externer Zugriff (nicht im Router forwardiert)
- **Empfehlung:** ✅ So lassen (nur lokal)

## Router Konfiguration

Setze Pi-hole als DNS Server in deinem Router:

1. Router Admin Panel öffnen
2. DNS Settings finden
3. Primary DNS: `<pi-hole-host-ip>`
4. Secondary DNS: `1.1.1.1` (Cloudflare) oder `8.8.8.8` (Google)

## Features

- ✅ DNS-basiertes Ad Blocking
- ✅ Web Interface für Verwaltung
- ✅ Query Logs
- ✅ Whitelist/Blacklist Management
- ✅ DNS over TLS (DoT)

## Daten

- **Config:** `./etc-pihole/`
- **DNSmasq Config:** `./etc-dnsmasq.d/`

## Troubleshooting

### DNS funktioniert nicht

```bash
# Container Logs
docker logs pihole

# DNS Test
dig @<pi-hole-ip> google.com
```

### Web UI nicht erreichbar

```bash
# Traefik Labels prüfen
docker inspect pihole | grep -A 20 Labels

# Netzwerk prüfen
docker network inspect proxy
```

## Weitere Informationen

- [Pi-hole Dokumentation](https://docs.pi-hole.net/)
- [Pi-hole GitHub](https://github.com/pi-hole/pi-hole)

