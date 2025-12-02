# Tarpit - Security Honeypot

Tarpit ist ein Security Honeypot, der Angriffe erkennt und Angreifer verlangsamt.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `tarampampam/tarpit:latest`
- **Ports:** 22 (SSH Honeypot), 80 (HTTP Honeypot)
- **Netzwerk:** `proxy` (optional)
- **Konfiguration:** `docker/honeypot-management/tarpit/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/honeypot-management/tarpit
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition
- `grafana.env` - Grafana Konfiguration (optional)
- `prometheus.yml` - Prometheus Konfiguration (optional)

## Features

- ✅ SSH Honeypot
- ✅ HTTP Honeypot
- ✅ Angreifer-Verlangsamung (Tarpit)
- ✅ Logging & Monitoring
- ✅ Prometheus Integration
- ✅ Grafana Dashboards

## Zugriff

- **SSH Honeypot:** Port 2222 (lokal, nicht Port 22!)
- **HTTP Honeypot:** Port 80 (lokal, nicht öffentlich!)
- **Prometheus:** `127.0.0.1:2112` (nur lokal)
- **Grafana:** `https://grafana.<deine-domain>` (mit admin-whitelist, falls konfiguriert) - ⚠️ **NUR VPN/LAN**

## Sicherheitsrisiko-Einschätzung

### Honeypot Ports (2222, 80)
- **Risiko:** ✅ **NIEDRIG** - Sollte auf separaten Ports laufen, nicht öffentlich
- **Schutz:** Isoliert von echten Services
- **Empfehlung:** ✅ **NUR lokal, NICHT im Router forwardieren!**
- **Wichtig:** ⚠️ Sollte NICHT auf Port 22/80 laufen (Konflikt mit echten Services)

### Prometheus (lokal)
- **Risiko:** ✅ **NIEDRIG** - Nur lokal (127.0.0.1)
- **Schutz:** Kein externer Zugriff
- **Empfehlung:** ✅ So lassen (nur lokal)

### Grafana (DNS, falls konfiguriert)
- **Risiko:** ⚠️ **MITTEL** - Monitoring-Daten, mögliche Sensitive Informationen
- **Schutz:** Basic Auth + Admin Whitelist (nur VPN/LAN)
- **Empfehlung:** ⚠️ **NUR über VPN/LAN zugänglich machen!**

## Konfiguration

### Port Forwarding

**WICHTIG:** Tarpit sollte auf separaten Ports laufen, nicht auf den echten Ports!

```yaml
ports:
  - "2222:22"  # SSH Honeypot (nicht Port 22!)
  - "8080:80"  # HTTP Honeypot (nicht Port 80!)
```

### Monitoring

Tarpit kann mit Prometheus und Grafana integriert werden:
- **Prometheus:** Metriken sammeln
- **Grafana:** Dashboards visualisieren

## Sicherheit

- ✅ Isoliert von echten Services
- ✅ Erkennt Angriffe
- ✅ Verlangsamt Angreifer
- ⚠️ Sollte auf separaten Ports laufen!

## Troubleshooting

### Tarpit startet nicht

```bash
# Logs prüfen
docker logs tarpit

# Ports prüfen
docker ps | grep tarpit
```

### Keine Metriken in Prometheus

```bash
# Prometheus Config prüfen
cat prometheus.yml

# Prometheus Logs
docker logs prometheus
```

## Weitere Informationen

- [Tarpit GitHub](https://github.com/tarampampam/tarpit)

