# Service Deployment - Services deployen

Anleitung zum Deployen von Services im NCC-HomeLab.

## Docker Compose (Standard)

### Service starten

```bash
cd docker/<category>/<service>
docker-compose up -d
```

### Service stoppen

```bash
docker-compose down
```

### Service Logs

```bash
docker-compose logs -f
```

## Docker Swarm (für HA)

### Stack deployen

```bash
cd docker/<category>/<service>
docker stack deploy -c docker-stack.yml <stack-name>
```

### Stack Status

```bash
docker stack services <stack-name>
docker stack ps <stack-name>
```

### Stack entfernen

```bash
docker stack rm <stack-name>
```

## Service Konfiguration

### Environment Variables

Die meisten Services nutzen `.env` Dateien:

```bash
# Beispiel: Traefik
cd docker/gateway-management/traefik-crowdsec
cat traefik.env
```

### Update Scripts

Viele Services haben Update-Scripts:

```bash
./update-traefik-env.sh
```

## Troubleshooting

### Service startet nicht

```bash
# Logs prüfen
docker logs <container-name>

# Compose Logs
docker-compose logs
```

### Netzwerk Probleme

```bash
# Netzwerk prüfen
docker network inspect proxy

# Container Netzwerk prüfen
docker inspect <container-name> | grep -A 10 Networks
```

### Ports nicht erreichbar

```bash
# Ports prüfen
docker ps | grep <service>

# Firewall prüfen
sudo ufw status
```

## Best Practices

1. **Traefik zuerst** - Alle anderen Services hängen davon ab
2. **Backup vor Updates** - Wichtige Daten sichern
3. **Logs prüfen** - Bei Problemen immer Logs anschauen
4. **Netzwerk prüfen** - Services müssen im `proxy` Netzwerk sein

## Weitere Informationen

- [Docker Swarm Guide](../guides/docker-swarm.md)
- [Service Dokumentation](../services/)

