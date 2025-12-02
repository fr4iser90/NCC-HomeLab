# Sicherheitsübersicht - Services & Zugriffsmethoden

Diese Übersicht zeigt alle Services, ihre Zugriffsmethoden und Sicherheitsrisiko-Einschätzungen.

## Legende

- ✅ **NIEDRIGES RISIKO** - Kann öffentlich freigegeben werden
- ⚠️ **MITTELES RISIKO** - Sollte nur über VPN/LAN zugänglich sein
- ⚠️ **HOCHES RISIKO** - **MUSS** nur über VPN/LAN zugänglich sein

## Services nach Zugriffsmethode

### Öffentlich (Port 80/443)

| Service | Port | Risiko | Schutz | Empfehlung |
|---------|------|--------|--------|------------|
| **Traefik** | 80/443 | ✅ NIEDRIG | CrowdSec, Rate Limiting | ✅ Öffentlich (notwendig) |
| **Bitwarden Sync** | 443 (via Traefik) | ✅ NIEDRIG | Client-Verschlüsselung | ✅ Öffentlich (für Sync nötig) |

### Öffentlich (andere Ports)

| Service | Port | Risiko | Schutz | Empfehlung |
|---------|------|--------|--------|------------|
| **WireGuard VPN** | 51820/UDP | ✅ NIEDRIG | WireGuard Verschlüsselung | ✅ Öffentlich (für VPN nötig) |
| **PufferPanel Game Ports** | 27015+ | ⚠️ MITTEL | Game Server Security | ⚠️ Nur wenn nötig |

### DNS-Freigabe mit admin-whitelist (NUR VPN/LAN)

| Service | DNS | Risiko | Schutz | Status |
|---------|-----|--------|--------|--------|
| **Traefik Dashboard** | `traefik.domain` | ⚠️ **HOCH** | Basic Auth + Whitelist | ✅ Geschützt |
| **Portainer** | `portainer.domain` | ⚠️ **HOCH** | Basic Auth + Whitelist | ✅ Geschützt |
| **Pi-hole** | `pihole.domain` | ⚠️ MITTEL | Whitelist + Rate Limit | ✅ Geschützt |
| **Jellyfin** | `jellyfin.domain` | ⚠️ MITTEL | Whitelist | ✅ Geschützt |
| **Plex** | `plex.domain` | ⚠️ MITTEL | Whitelist | ✅ Geschützt |
| **Organizr** | `organizr.domain` | ⚠️ MITTEL | Whitelist + Rate Limit | ✅ Geschützt |
| **Yourls** | `link.domain` | ⚠️ NIEDRIG | Basic Auth + Whitelist | ✅ Geschützt |
| **OwnCloud** | `owncloud.domain` | ⚠️ MITTEL | Whitelist + Rate Limit | ✅ Geschützt |
| **WireGuard UI** | `wireguard.domain` | ⚠️ **HOCH** | Basic Auth + Whitelist | ✅ Geschützt |
| **Bitwarden Admin** | `bw.domain/admin` | ⚠️ **HOCH** | Basic Auth + Whitelist | ✅ Geschützt |

### DNS-Freigabe OHNE admin-whitelist (⚠️ ÖFFENTLICH!)

| Service | DNS | Risiko | Schutz | Status |
|---------|-----|--------|--------|--------|
| **Bitwarden Sync** | `bw.domain` | ✅ **NIEDRIG** | Nur `default@file` | ✅ Öffentlich (für Sync nötig) |
| **PufferPanel** | `pufferpanel.domain` | ⚠️ **MITTEL-HOCH** | Nur `default@file` | ⚠️ **ÖFFENTLICH - NICHT empfohlen!** |

> **⚠️ WICHTIG:** 
> - Bitwarden Sync ist bewusst öffentlich (für Mobile/Desktop Sync nötig)
> - PufferPanel sollte `admin-whitelist@file` Middleware hinzufügen!

### Nur lokal (127.0.0.1 oder lokale Ports)

| Service | Port | Risiko | Empfehlung |
|---------|------|--------|------------|
| **Traefik API** | 127.0.0.1:8080 | ✅ NIEDRIG | ✅ So lassen |
| **Organizr** | 8003 (lokal) | ✅ NIEDRIG | ✅ So lassen |
| **Jellyfin** | 8096, 8920 (lokal) | ✅ NIEDRIG | ✅ So lassen |
| **Plex** | 32400+ (lokal) | ✅ NIEDRIG | ✅ So lassen |
| **Pi-hole DNS** | 53 (lokal) | ✅ NIEDRIG | ✅ So lassen |
| **Tarpit Prometheus** | 127.0.0.1:2112 | ✅ NIEDRIG | ✅ So lassen |

## Sicherheitsempfehlungen

### ✅ Empfohlene Konfiguration

1. **Admin-Interfaces NUR über VPN/LAN**
   - Traefik Dashboard
   - Portainer
   - Alle Service-Admin-Panels

2. **Öffentlich nur was nötig ist**
   - Traefik (80/443) - Reverse Proxy
   - Bitwarden Sync - Für Mobile/Desktop Sync
   - WireGuard VPN - Für VPN-Zugriff

3. **Lokale Ports nicht forwardieren**
   - Organizr (8003)
   - Jellyfin/Plex Discovery Ports
   - Pi-hole DNS (53)

### ⚠️ Aktuelle Probleme

1. **PufferPanel** - Keine admin-whitelist aktiviert!
   - **Status:** Öffentlich erreichbar (nur `default@file`)
   - **Risiko:** Mittel-Hoch (Game Server Management)
   - **Lösung:** `admin-whitelist@file` Middleware in `docker-compose.yml` hinzufügen:
     ```yaml
     - "traefik.http.routers.pufferpanel.middlewares=default@file,admin-whitelist@file"
     ```

### 🔒 Best Practices

1. **Immer admin-whitelist für Admin-Interfaces**
2. **Basic Auth zusätzlich zu Whitelist**
3. **Rate Limiting aktivieren**
4. **Regelmäßige Updates**
5. **Monitoring aktivieren (CrowdSec)**

## admin-whitelist Konfiguration

Die `admin-whitelist` Middleware erlaubt nur Zugriff von:
- `192.168.0.0/16` (LAN)
- `10.8.0.0/24` (VPN)
- `172.16.0.0/12` (Docker Networks)
- `172.40.0.0/16` (Proxy Network)
- `172.41.0.0/16` (CrowdSec Network)
- Deine aktuelle öffentliche IP (automatisch aktualisiert)

## Services ohne Traefik (nur lokal)

- **CrowdSec** - Nur intern
- **DDNS Updater** - Nur intern
- **Cloudflare Companion** - Nur intern
- **Watchtower** - Nur intern

Diese Services haben keine Traefik Labels und sind nur intern erreichbar.

---

**Letzte Aktualisierung:** Basierend auf aktueller docker-compose.yml Konfiguration

