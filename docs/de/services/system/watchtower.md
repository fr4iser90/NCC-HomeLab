# Watchtower - Auto-Updates

Watchtower aktualisiert automatisch Docker Container auf die neuesten Images.

> **Hinweis:** Die Installation erfolgt über `init-homelab.sh`. Diese Dokumentation beschreibt die Docker-Konfiguration und Features.

## Übersicht

- **Image:** `containrrr/watchtower:latest`
- **Netzwerk:** Kein spezielles Netzwerk nötig
- **Konfiguration:** `docker/system-management/watchtower/`

## Docker-Konfiguration

### Docker Compose

```bash
cd docker/system-management/watchtower
docker-compose up -d
```

**Dateien:**
- `docker-compose.yml` - Container Definition

## Features

- ✅ Automatische Image-Updates
- ✅ Container Neustart nach Update
- ✅ Benachrichtigungen (optional)
- ✅ Update-Strategien konfigurierbar

## Konfiguration

### Update-Intervall

Standard: Alle 24 Stunden

Anpassen in `docker-compose.yml`:
```yaml
command: --interval 3600  # Alle 60 Minuten
```

### Update-Strategien

- **Standard:** Alle Container updaten
- **Labels:** Nur Container mit bestimmten Labels
- **Exclude:** Bestimmte Container ausschließen

### Container ausschließen

```yaml
# In docker-compose.yml des Services
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

## Sicherheit

- ✅ Prüft Images vor Update
- ✅ Kann auf Cleanup konfiguriert werden
- ⚠️ Teste Updates in Test-Environment zuerst!

## Troubleshooting

### Watchtower updated nicht

```bash
# Logs prüfen
docker logs watchtower

# Container Status
docker ps | grep watchtower
```

### Container wird nicht updated

```bash
# Labels prüfen
docker inspect <container> | grep watchtower

# Manuell updaten
docker-compose pull
docker-compose up -d
```

## Weitere Informationen

- [Watchtower GitHub](https://github.com/containrrr/watchtower)
- [Watchtower Dokumentation](https://containrrr.dev/watchtower/)

