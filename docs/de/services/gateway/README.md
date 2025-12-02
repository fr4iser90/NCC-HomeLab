# Gateway Services

Gateway Services sind die Basis des Homelab Setups. Sie übernehmen Routing, Security und DNS.

## Services

- [Traefik](./traefik.md) - Reverse Proxy & Load Balancer
- [CrowdSec](./crowdsec.md) - Security & Threat Detection
- [DDNS Updater](./ddns-updater.md) - Dynamic DNS Updates

## Abhängigkeiten

1. **Traefik** muss zuerst laufen (alle anderen Services hängen davon ab)
2. **CrowdSec** sollte mit Traefik zusammen laufen (Security)
3. **DDNS Updater** ist optional (nur bei dynamischer IP nötig)

## Setup Reihenfolge

1. Traefik deployen
2. CrowdSec deployen
3. DDNS Updater deployen (optional)

