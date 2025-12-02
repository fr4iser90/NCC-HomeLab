# Honeypot Services

Honeypot Services erkennen Angriffe und verlangsamen Angreifer.

## Services

- [Tarpit](./tarpit.md) - Security Honeypot

## Übersicht

Tarpit ist ein Security Honeypot, der Angriffe erkennt und Angreifer verlangsamt.

## Features

- SSH Honeypot
- HTTP Honeypot
- Angreifer-Verlangsamung
- Logging & Monitoring

## Setup

1. Tarpit deployen
2. Ports konfigurieren (nicht auf echten Ports!)
3. Monitoring einrichten (optional)

## Wichtig

- ⚠️ Sollte auf separaten Ports laufen (nicht Port 22/80!)
- Isoliert von echten Services halten
- Monitoring mit Prometheus/Grafana möglich

