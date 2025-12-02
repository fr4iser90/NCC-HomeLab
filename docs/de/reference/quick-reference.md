# Quick Reference: Rootless Docker & Docker Swarm

## Rootless Docker - Quick Facts

### Installation
```bash
curl -fsSL https://get.docker.com/rootless | sh
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

### Ports < 1024 aktivieren
```bash
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)
```

### Docker Socket Pfad
```yaml
# Statt: /var/run/docker.sock
volumes:
  - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
```

### Port Mapping
```yaml
# Option 1: Höhere Ports
ports:
  - "8080:80"
  - "8443:443"

# Option 2: Direkt (mit CAP_NET_BIND_SERVICE)
ports:
  - "80:80"
  - "443:443"
```

---

## Docker Swarm - Quick Commands

### Setup
```bash
# Swarm initialisieren
docker swarm init

# Node hinzufügen
docker swarm join --token <TOKEN> <IP>:2377

# Token holen
docker swarm join-token worker
docker swarm join-token manager
```

### Networks
```bash
# Overlay Network erstellen
docker network create --driver overlay --attachable proxy

# Netzwerke auflisten
docker network ls
```

### Stacks
```bash
# Stack deployen
docker stack deploy -c docker-stack.yml <name>

# Stack Status
docker stack ls
docker stack services <name>
docker stack ps <name>

# Stack entfernen
docker stack rm <name>
```

### Services
```bash
# Services auflisten
docker service ls

# Service Details
docker service ps <service-name>
docker service inspect <service-name>

# Service skalieren
docker service scale <service-name>=3

# Service updaten
docker service update --image <image>:<tag> <service-name>

# Service Logs
docker service logs <service-name> -f

# Service entfernen
docker service rm <service-name>
```

### Nodes
```bash
# Nodes auflisten
docker node ls

# Node Details
docker node inspect <node-name>

# Node drainen (Wartung)
docker node update --availability drain <node-name>

# Node aktivieren
docker node update --availability active <node-name>
```

---

## docker-compose.yml → docker-stack.yml Migration

### Entfernen
- ❌ `container_name: ...`
- ❌ `ipv4_address: ...` (in networks)
- ❌ `depends_on:` (nutze `deploy.placement.constraints`)

### Hinzufügen
- ✅ `deploy:` Section
- ✅ `ports:` mit `mode: ingress` (oder `mode: host` für DNS)
- ✅ Named Volumes (statt lokale Pfade)

### Beispiel

**Vorher:**
```yaml
services:
  traefik:
    container_name: traefik
    ports:
      - "80:80"
    networks:
      proxy:
        ipv4_address: 172.40.255.254
```

**Nachher:**
```yaml
services:
  traefik:
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: ingress
    networks:
      - proxy
    deploy:
      mode: global
      restart_policy:
        condition: on-failure
```

---

## Deploy Modes

### Global (ein Task pro Node)
```yaml
deploy:
  mode: global
```
**Für:** Traefik, Monitoring Agents

### Replicated (feste Anzahl)
```yaml
deploy:
  mode: replicated
  replicas: 3
```
**Für:** Web Apps, APIs

---

## Port Modes

### Ingress (Routing Mesh)
```yaml
ports:
  - target: 80
    published: 80
    mode: ingress
```
**Für:** HTTP/HTTPS Services (Traefik, Web Apps)

### Host (direkt)
```yaml
ports:
  - target: 53
    published: 53
    mode: host
```
**Für:** DNS, spezielle Netzwerk-Services

---

## Placement Constraints

```yaml
deploy:
  placement:
    constraints:
      - node.role == manager      # Nur Manager Nodes
      - node.hostname == node1     # Fester Node
      - node.labels.env == prod    # Custom Labels
```

**Node Labels setzen:**
```bash
docker node update --label-add env=prod <node-name>
```

---

## Shared Storage

### NFS Volume
```yaml
volumes:
  traefik-acme:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.local,rw
      device: ":/exports/traefik-acme"
```

### Local Volume (Node Constraint)
```yaml
volumes:
  data:
    driver: local
deploy:
  placement:
    constraints:
      - node.hostname == node1
```

---

## Firewall Ports

**Swarm benötigt:**
- `2377/tcp` - Swarm Management
- `7946/tcp` - Node Communication
- `7946/udp` - Node Communication
- `4789/udp` - Overlay Network (VXLAN)

**UFW:**
```bash
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp
```

---

## Troubleshooting

### Service startet nicht
```bash
docker service logs <service-name> -f
docker service ps <service-name> --no-trunc
```

### Netzwerk Probleme
```bash
docker network inspect proxy
docker service inspect <service-name> | grep -A 10 Networks
```

### Ports nicht erreichbar
```bash
docker service inspect <service-name> | grep -A 5 Ports
sudo ufw status
```

### Volume Probleme
```bash
docker volume ls
docker volume inspect <volume-name>
```

---

## Wichtige Unterschiede

| Feature | docker-compose | docker-stack |
|---------|---------------|--------------|
| Container Name | ✅ `container_name` | ❌ Nicht erlaubt |
| Networks | ✅ `external: true` | ✅ Funktioniert |
| Volumes | ✅ Lokale Pfade | ✅ Named Volumes |
| Ports | ✅ `80:80` | ✅ `mode: ingress` |
| Deploy | ❌ Nicht vorhanden | ✅ `deploy:` Section |
| Replicas | ❌ Nicht vorhanden | ✅ `replicas: 3` |
| Placement | ❌ Nicht vorhanden | ✅ `placement:` Constraints |
| IP Address | ✅ `ipv4_address` | ❌ Nicht erlaubt |

---

## Best Practices

1. **Traefik zuerst migrieren** (alle anderen hängen davon ab)
2. **Shared Storage** für Stateful Services (ACME, Datenbanken)
3. **Health Checks** für alle Services
4. **Node Constraints** für DNS (Pi-hole sollte konsistent laufen)
5. **Global Mode** für Traefik (ein pro Node für HA)
6. **Replicated Mode** für Web Apps (feste Anzahl)
7. **Host Mode** für DNS Ports (Routing Mesh funktioniert nicht gut)
8. **Backup** vor Migration!

---

## Nützliche Links

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Rootless Docker Docs](https://docs.docker.com/engine/security/rootless/)
- [Traefik Swarm Guide](https://doc.traefik.io/traefik/routing/providers/docker/#docker-swarm-mode)

---

**Viel Erfolg! 🚀**

