# WireGuard - VPN Server

WireGuard ist ein moderner, schneller VPN-Server für sicheren Remote-Zugriff.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `linuxserver/wireguard:latest`
- **Ports:** 51820/UDP (VPN), 51821 (Web UI, optional)
- **Netzwerk:** `proxy` (für Web UI)
- **Konfiguration:** `docker/vpn-management/wireguard/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/vpn-management/wireguard
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `wireguard.env` - Environment Variables
- `./wireguard/` - WireGuard Konfiguration

## Features

- ✅ Moderne VPN-Technologie
- ✅ Schnelle Verbindungen
- ✅ Niedrige Latenz
- ✅ Web UI (optional)
- ✅ QR-Code für Mobile Setup

## Zugriff

- **VPN:** `udp://<server-ip>:51820` (öffentlich) - ✅ Für VPN nötig
- **Web UI:** `https://wireguard.<deine-domain>` (mit admin-whitelist, falls konfiguriert) - ⚠️ **NUR VPN/LAN**

## Sicherheitsrisiko-Einschätzung

### VPN Port (51820/UDP)
- **Risiko:** ✅ **NIEDRIG** - Moderne Verschlüsselung, für VPN notwendig
- **Schutz:** WireGuard Verschlüsselung, Perfect Forward Secrecy
- **Empfehlung:** ✅ Öffentlich freigeben (notwendig für VPN)

### Web UI (DNS, falls konfiguriert)
- **Risiko:** ⚠️ **HOCH** - Client-Management, Konfiguration
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**
- **Aktuelle Konfiguration:** Mit `admin-whitelist@file` Middleware geschützt

## Konfiguration

### Port Forwarding

Im Router forwarden:
- **Port 51820/UDP** → `<server-ip>:51820`

### Client-Konfiguration

1. Öffne WireGuard Web UI (falls aktiviert)
2. Erstelle neuen Client
3. Lade Konfiguration herunter
4. Importiere in WireGuard Client
5. Oder scanne QR-Code (Mobile)

### Environment Variables

Wichtige Variablen in `wireguard.env`:
- `PEERS` - Anzahl der Clients
- `SERVERURL` - Öffentliche Server-URL
- `SERVERPORT` - VPN Port (51820)

## Erste Einrichtung

1. Starte Container
2. Prüfe Logs für Server Public Key
3. Erstelle Clients (Web UI oder manuell)
4. Konfiguriere Router Port-Forward
5. Teste Verbindung

## Sicherheit

- ✅ Moderne Verschlüsselung
- ✅ Perfect Forward Secrecy
- ✅ Minimaler Code (sicherer)
- ✅ Web UI nur über VPN/LAN (empfohlen)

## Troubleshooting

### VPN verbindet nicht

```bash
# Container Status
docker ps | grep wireguard

# Logs prüfen
docker logs wireguard

# Port prüfen
sudo netstat -ulnp | grep 51820
```

### Port Forwarding funktioniert nicht

```bash
# Router Port-Forward prüfen
# Muss Port 51820/UDP forwarden

# Firewall prüfen
sudo ufw status
```

### Client kann nicht verbinden

```bash
# Server Public Key prüfen
docker logs wireguard | grep "Public Key"

# Client Config prüfen
# Muss Server Public Key enthalten
```

## Weitere Informationen

- [WireGuard Dokumentation](https://www.wireguard.com/)
- [LinuxServer WireGuard](https://github.com/linuxserver/docker-wireguard)

