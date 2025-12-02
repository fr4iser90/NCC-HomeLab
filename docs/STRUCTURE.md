# Dokumentations-Struktur

## Übersicht

Die Dokumentation ist zweisprachig (Deutsch/English) und nach Themen organisiert.

```
docs/
├── README.md                    # Haupt-Übersicht
├── STRUCTURE.md                 # Diese Datei
│
├── de/                          # Deutsche Dokumentation
│   ├── README.md                # Inhaltsverzeichnis
│   │
│   ├── guides/                  # Umfassende Guides
│   │   ├── README.md
│   │   ├── docker-swarm.md
│   │   ├── rootless-docker.md
│   │   ├── migration.md
│   │   └── overview.md
│   │
│   ├── services/                # Service-Dokumentation
│   │   ├── gateway/
│   │   │   ├── README.md
│   │   │   ├── traefik.md
│   │   │   ├── crowdsec.md
│   │   │   └── ddns-updater.md
│   │   ├── media/
│   │   │   ├── README.md
│   │   │   ├── jellyfin.md
│   │   │   └── plex.md
│   │   ├── system/
│   │   │   ├── README.md
│   │   │   ├── portainer.md
│   │   │   └── watchtower.md
│   │   ├── password/
│   │   │   └── bitwarden.md
│   │   ├── storage/
│   │   │   └── owncloud.md
│   │   ├── adblocker/
│   │   │   └── pihole.md
│   │   ├── vpn/
│   │   │   └── wireguard.md
│   │   └── honeypot/
│   │       └── tarpit.md
│   │
│   ├── tutorials/               # Schritt-für-Schritt Anleitungen
│   │   ├── initial-setup.md
│   │   └── service-deployment.md
│   │
│   └── reference/               # Referenz & Cheatsheets
│       └── quick-reference.md
│
└── en/                          # English Documentation
    └── (gleiche Struktur)
```

## Kategorien

### Guides (`guides/`)
Umfassende Guides zu wichtigen Themen:
- **docker-swarm.md** - Kompletter Docker Swarm Guide
- **rootless-docker.md** - Kompletter Rootless Docker Guide
- **migration.md** - Migration zu Swarm
- **overview.md** - Übersicht über beide Themen

### Services (`services/`)
Service-spezifische Dokumentation, organisiert nach Kategorien:
- **gateway/** - Traefik, CrowdSec, DDNS
- **media/** - Jellyfin, Plex
- **system/** - Portainer, Watchtower
- **password/** - Bitwarden
- **storage/** - OwnCloud
- **adblocker/** - Pi-hole
- **vpn/** - WireGuard
- **honeypot/** - Tarpit

### Tutorials (`tutorials/`)
Schritt-für-Schritt Anleitungen:
- **initial-setup.md** - Erste Einrichtung
- **service-deployment.md** - Services deployen

### Reference (`reference/`)
Schnellreferenzen:
- **quick-reference.md** - Commands & Cheatsheet

## Naming Conventions

### Dateinamen
- **Kleinbuchstaben** mit Bindestrichen: `docker-swarm.md`
- **Keine Leerzeichen**: `service-deployment.md` nicht `service deployment.md`
- **Beschreibend**: `traefik.md` nicht `t.md`

### Verzeichnisse
- **Kleinbuchstaben**: `services/`, `guides/`
- **Kategorien**: `gateway/`, `media/`, `system/`

## Hinzufügen neuer Dokumentation

### Neue Service-Dokumentation

1. Erstelle Datei in passender Kategorie:
   ```bash
   docs/de/services/<kategorie>/<service>.md
   ```

2. Füge Link in Kategorie-README hinzu:
   ```markdown
   - [Service Name](./service.md) - Beschreibung
   ```

3. Füge Link in Haupt-README hinzu:
   ```markdown
   - [Service Name](./services/<kategorie>/service.md)
   ```

### Neuer Guide

1. Erstelle Datei in `guides/`:
   ```bash
   docs/de/guides/<guide-name>.md
   ```

2. Füge Link in `guides/README.md` hinzu

### Neues Tutorial

1. Erstelle Datei in `tutorials/`:
   ```bash
   docs/de/tutorials/<tutorial-name>.md
   ```

2. Füge Link in Haupt-README hinzu

## Template für Service-Dokumentation

```markdown
# Service Name

Kurze Beschreibung des Services.

## Übersicht

- **Image:** `image:tag`
- **Ports:** Port-Liste
- **Netzwerk:** `network-name`

## Konfiguration

### Docker Compose

Siehe: `docker/<kategorie>/<service>/docker-compose.yml`

### Docker Swarm Stack

Siehe: `docker/<kategorie>/<service>/docker-stack.yml`

## Zugriff

- **Web UI:** `https://service.<domain>`

## Features

- ✅ Feature 1
- ✅ Feature 2

## Troubleshooting

### Problem

```bash
# Lösung
```

## Weitere Informationen

- [Offizielle Dokumentation](https://...)
```

## Übersetzung

Für neue Dokumentation:

1. Erstelle zuerst deutsche Version in `docs/de/`
2. Übersetze dann nach `docs/en/`
3. Halte Struktur identisch
4. Links müssen angepasst werden (de → en)

## Best Practices

1. **Konsistenz** - Nutze gleiche Struktur für ähnliche Services
2. **Links** - Verlinke zu verwandten Dokumenten
3. **Code-Beispiele** - Teste alle Beispiele
4. **Aktualität** - Halte Dokumentation aktuell
5. **Klare Sprache** - Schreibe klar und verständlich

