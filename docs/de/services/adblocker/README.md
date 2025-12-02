# Adblocker Services

Adblocker Services blockieren Werbung und Tracking auf Netzwerk-Ebene.

## Services

- [Pi-hole](./pihole.md) - DNS-based Ad Blocker

## Übersicht

Pi-hole blockiert Werbung und Tracking für das gesamte Netzwerk über DNS-Filterung.

## Setup

1. Pi-hole deployen
2. Router DNS auf Pi-hole IP setzen
3. Web UI konfigurieren

## Wichtig

- DNS Ports müssen `mode: host` verwenden (Routing Mesh funktioniert nicht für DNS)
- Pi-hole sollte auf einem festen Node laufen (konsistente DNS)

