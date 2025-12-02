# Docker Swarm - Kompletter Guide

## Was ist Docker Swarm?

**Docker Swarm** ist die native Orchestrierung von Docker. Es verwandelt mehrere Docker-Hosts in einen **Cluster**.

### Konzepte
- **Manager Nodes**: Steuern den Cluster (Consensus über Raft)
- **Worker Nodes**: Führen Container aus
- **Services**: Container die als Service laufen (statt einzelne Container)
- **Stacks**: Mehrere Services zusammen (wie docker-compose, aber für Swarm)
- **Overlay Networks**: Netzwerke die über mehrere Nodes gehen
- **Routing Mesh**: Automatisches Load Balancing

---

## Warum Docker Swarm?

### Vorteile
- ✅ **Redundanz**: Services laufen auf mehreren Nodes
- ✅ **High Availability**: Ausfall einer Node = kein Problem
- ✅ **Load Balancing**: Automatisch über Routing Mesh
- ✅ **Rolling Updates**: Zero-Downtime Updates
- ✅ **Native Docker**: Keine zusätzliche Software nötig
- ✅ **Einfacher als Kubernetes**: Für Homelab perfekt

### Nachteile
- ⚠️ **Komplexität**: Mehr Konfiguration als docker-compose
- ⚠️ **Netzwerk**: Overlay Networks haben Overhead
- ⚠️ **Storage**: Shared Storage für Stateful Services nötig

---

## Docker Swarm - Architektur

```
┌─────────────────────────────────────────────────┐
│           Docker Swarm Cluster                   │
│                                                  │
│  ┌──────────────┐      ┌──────────────┐         │
│  │ Manager Node │      │ Manager Node │         │
│  │  (Leader)    │◄────►│  (Replica)   │         │
│  └──────┬───────┘      └──────┬───────┘         │
│         │                     │                  │
│         └─────────┬───────────┘                  │
│                   │                               │
│         ┌─────────▼───────────┐                  │
│         │   Worker Nodes      │                  │
│         │  ┌───┐  ┌───┐  ┌───┐│                  │
│         │  │ W1│  │ W2│  │ W3││                  │
│         │  └───┘  └───┘  └───┘│                  │
│         └─────────────────────┘                  │
│                                                  │
│  Services:                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Traefik  │  │ Jellyfin │  │ Pi-hole  │      │
│  │(3 tasks) │  │(2 tasks) │  │(1 task)  │      │
│  └──────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────┘
```

---

## Docker Swarm Setup - Schritt für Schritt

### Schritt 1: Swarm initialisieren

```bash
# Auf dem ersten Node (wird Manager)
docker swarm init

# Output zeigt dir einen Join-Token:
# Swarm initialized: current node (xxx) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#   docker swarm join --token SWMTKN-1-... <IP>:2377

# Prüfe Status
docker node ls
```

### Schritt 2: Weitere Nodes hinzufügen

```bash
# Auf anderen Nodes (als Worker)
docker swarm join --token <WORKER-TOKEN> <MANAGER-IP>:2377

# Oder als Manager (für HA)
docker swarm join-token manager
docker swarm join --token <MANAGER-TOKEN> <MANAGER-IP>:2377
```

**Token holen:**
```bash
# Worker Token
docker swarm join-token worker

# Manager Token
docker swarm join-token manager
```

### Schritt 3: Overlay Networks erstellen

```bash
# Erstelle Overlay Network (funktioniert über alle Nodes)
docker network create --driver overlay --attachable proxy
docker network create --driver overlay --attachable crowdsec

# Prüfen
docker network ls
# Sollte "overlay" als Driver zeigen
```

**Wichtig:** `--attachable` erlaubt auch normale Container (nicht nur Services) sich zu verbinden.

---

## Migration: docker-compose.yml → docker-stack.yml

### Unterschiede zwischen Compose und Stack

| Feature | docker-compose | docker-stack |
|---------|---------------|--------------|
| Container | `container_name` | ❌ Nicht erlaubt |
| Networks | `external: true` | ✅ Funktioniert |
| Volumes | Lokale Pfade | ✅ Funktioniert (aber shared storage besser) |
| Ports | `80:80` | ✅ Funktioniert (Routing Mesh) |
| Deploy | ❌ Nicht vorhanden | ✅ `deploy:` Section |
| Replicas | ❌ Nicht vorhanden | ✅ `replicas: 3` |
| Placement | ❌ Nicht vorhanden | ✅ `placement:` Constraints |
| IP Address | ✅ `ipv4_address` | ❌ Nicht erlaubt |

### Beispiel: Traefik Migration

**Vorher (docker-compose.yml):**
```yaml
services:
  traefik:
    container_name: traefik
    image: traefik:v3.1.0
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy
    restart: unless-stopped
```

**Nachher (docker-stack.yml):**
```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.1.0
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: ingress
      - target: 443
        published: 443
        protocol: tcp
        mode: ingress
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-acme:/traefik
    networks:
      - proxy
    deploy:
      mode: global  # Oder: replicas: 3
      placement:
        constraints:
          - node.role == manager  # Optional: nur auf Managers
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    # Labels bleiben gleich!
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

volumes:
  traefik-acme:
    driver: local

networks:
  proxy:
    external: true
```

**Wichtige Änderungen:**
1. ❌ `container_name` entfernt (Swarm vergibt Namen automatisch)
2. ✅ `ports:` Format geändert (mit `mode: ingress` für Routing Mesh)
3. ✅ `deploy:` Section hinzugefügt
4. ✅ `volumes:` als Named Volumes (für Shared Storage später)

---

## Deploy-Modi: Global vs Replicated

### Global Mode
```yaml
deploy:
  mode: global
```
- **Ein Task pro Node** (automatisch)
- Perfekt für: Traefik, Monitoring Agents
- Beispiel: 3 Nodes = 3 Traefik Tasks

### Replicated Mode
```yaml
deploy:
  mode: replicated
  replicas: 3
```
- **Feste Anzahl Tasks** (werden auf Nodes verteilt)
- Perfekt für: Web Apps, APIs
- Beispiel: 3 Replicas auf 5 Nodes = 3 Tasks irgendwo

---

## Routing Mesh - Wie funktioniert's?

**Routing Mesh** bedeutet: Jeder Node kann Anfragen für **jeden Service** entgegennehmen.

```
Internet Request → Node 1 (Port 80) → Swarm Routing Mesh → Traefik Task (irgendwo)
Internet Request → Node 2 (Port 80) → Swarm Routing Mesh → Traefik Task (irgendwo)
Internet Request → Node 3 (Port 80) → Swarm Routing Mesh → Traefik Task (irgendwo)
```

**Vorteil:** Du musst nicht wissen, auf welchem Node Traefik läuft!

**Router/NAT Konfiguration:**
- Forwarde Port 80/443 an **irgendeinen** Node (oder mehrere)
- Swarm leitet automatisch weiter

### Port Modes

#### Ingress Mode (Routing Mesh)
```yaml
ports:
  - target: 80
    published: 80
    mode: ingress
```
**Für:** HTTP/HTTPS Services (Traefik, Web Apps)

#### Host Mode (direkt)
```yaml
ports:
  - target: 53
    published: 53
    mode: host
```
**Für:** DNS, spezielle Netzwerk-Services (Pi-hole DNS)

---

## Shared Storage für Stateful Services

**Problem:** Services mit Daten (z.B. Traefik ACME, Datenbanken) brauchen persistenten Storage.

### Option 1: NFS (empfohlen für Homelab)
```yaml
volumes:
  traefik-acme:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.local,rw
      device: ":/exports/traefik-acme"
```

**NFS Server Setup:**
```bash
# Auf einem Node
sudo apt install nfs-kernel-server
sudo mkdir -p /exports/traefik-acme
sudo chown nobody:nogroup /exports/traefik-acme
echo "/exports/traefik-acme *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

**Auf allen Nodes (NFS Client):**
```bash
sudo apt install nfs-common
```

### Option 2: GlusterFS / Ceph
- Komplexer, aber sehr robust
- Für größere Setups

### Option 3: Node Constraints (einfach, aber kein HA)
```yaml
deploy:
  placement:
    constraints:
      - node.hostname == node1
```
- Service läuft immer auf Node1
- Wenn Node1 ausfällt → Service down

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
docker node update --label-add storage=ssd <node-name>
```

**Node Labels verwenden:**
```yaml
deploy:
  placement:
    constraints:
      - node.labels.storage == ssd
```

---

## Swarm Management Commands

### Services
```bash
# Services auflisten
docker service ls

# Service Details
docker service ps <service-name>
docker service inspect <service-name>

# Service Logs
docker service logs <service-name> -f

# Service skalieren
docker service scale <service-name>=5

# Service updaten (Rolling Update)
docker service update --image traefik:v3.2.0 <stack-name>_traefik

# Service entfernen
docker service rm <service-name>
```

### Stacks
```bash
# Stack deployen
docker stack deploy -c docker-stack.yml <stack-name>

# Stack Status
docker stack ls
docker stack services <stack-name>
docker stack ps <stack-name>

# Stack entfernen
docker stack rm <stack-name>
```

### Nodes
```bash
# Nodes auflisten
docker node ls

# Node Details
docker node inspect <node-name>

# Node drainen (für Wartung)
docker node update --availability drain <node-name>

# Node aktivieren
docker node update --availability active <node-name>

# Node Labels
docker node update --label-add <key>=<value> <node-name>
```

### Networks
```bash
# Netzwerke auflisten
docker network ls

# Netzwerk Details
docker network inspect proxy

# Netzwerk erstellen
docker network create --driver overlay --attachable proxy
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

**iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 4789 -j ACCEPT
```

---

## Praktische Beispiele

### Beispiel 1: Traefik als Global Service

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.1.0
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: ingress
      - target: 443
        published: 443
        protocol: tcp
        mode: ingress
    networks:
      - proxy
    deploy:
      mode: global  # Ein Traefik pro Node
      restart_policy:
        condition: on-failure
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-acme:/traefik
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

volumes:
  traefik-acme:
    driver: local

networks:
  proxy:
    external: true
```

### Beispiel 2: Pi-hole mit Host Mode für DNS

```yaml
version: '3.8'

services:
  pihole:
    image: pihole/pihole:latest
    networks:
      - proxy
    ports:
      # DNS Ports - Host Mode für DNS!
      - target: 53
        published: 53
        protocol: tcp
        mode: host
      - target: 53
        published: 53
        protocol: udp
        mode: host
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.hostname == node1  # DNS sollte konsistent laufen
    volumes:
      - pihole-data:/etc/pihole
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

volumes:
  pihole-data:
    driver: local

networks:
  proxy:
    external: true
```

### Beispiel 3: Web App mit Replicas

```yaml
version: '3.8'

services:
  webapp:
    image: nginx:latest
    networks:
      - proxy
    ports:
      - target: 80
        published: 8080
        protocol: tcp
        mode: ingress
    deploy:
      mode: replicated
      replicas: 3  # 3 Instanzen
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.webapp.rule=Host(`webapp.example.com`)"

networks:
  proxy:
    external: true
```

---

## Rolling Updates

**Automatisch bei Service Updates:**
```bash
docker service update --image traefik:v3.2.0 <stack-name>_traefik
```

**Konfigurieren in docker-stack.yml:**
```yaml
deploy:
  update_config:
    parallelism: 1        # Wie viele Tasks gleichzeitig updaten
    delay: 10s            # Wartezeit zwischen Updates
    failure_action: rollback  # Bei Fehler: Rollback
    monitor: 60s          # Health Check Zeit
```

**Rollback:**
```bash
docker service rollback <stack-name>_traefik
```

---

## Troubleshooting

### Problem: Service startet nicht
```bash
# Service Logs
docker service logs <service-name> -f

# Service Details
docker service ps <service-name> --no-trunc

# Node Logs
journalctl -u docker -f
```

### Problem: Netzwerk funktioniert nicht
```bash
# Netzwerk prüfen
docker network inspect proxy

# Service Netzwerk prüfen
docker service inspect <service-name> | grep -A 10 Networks
```

### Problem: Ports nicht erreichbar
```bash
# Routing Mesh prüfen
docker service inspect <service-name> | grep -A 5 Ports

# Firewall prüfen
sudo ufw status
sudo iptables -L -n
```

### Problem: Volumes nicht gefunden
```bash
# Volumes auflisten
docker volume ls

# Volume Details
docker volume inspect <volume-name>
```

### Problem: Node kann nicht joinen
```bash
# Prüfe Firewall
sudo ufw status

# Prüfe Netzwerk
ping <manager-ip>

# Prüfe Ports
telnet <manager-ip> 2377
```

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
9. **Mehrere Manager** für HA (ungerade Anzahl: 3, 5, 7)
10. **Monitoring** aktivieren

---

## Checkliste: Migration zu Swarm

- [ ] Firewall Ports geöffnet (2377, 7946, 4789)
- [ ] Swarm initialisiert (`docker swarm init`)
- [ ] Weitere Nodes hinzugefügt (optional)
- [ ] Overlay Networks erstellt (`proxy`, `crowdsec`, etc.)
- [ ] Shared Storage eingerichtet (NFS oder Node Constraints)
- [ ] Traefik Stack erstellt und deployed
- [ ] Traefik funktioniert (Routing Mesh testen)
- [ ] Andere Services migriert (docker-compose → docker-stack)
- [ ] `container_name` entfernt aus allen Services
- [ ] `deploy:` Section hinzugefügt
- [ ] Ports auf `mode: ingress` umgestellt (außer DNS → `mode: host`)
- [ ] `ipv4_address` entfernt (Swarm vergibt IPs)
- [ ] Labels überprüft (bleiben gleich)
- [ ] Volumes auf Named Volumes umgestellt (für Shared Storage)
- [ ] Router/NAT Port-Forwarding angepasst (an einen/mehrere Nodes)
- [ ] Health Checks getestet
- [ ] Rolling Updates getestet

---

## Zusammenfassung

**Docker Swarm** ist die native Orchestrierung von Docker:
- ✅ High Availability
- ✅ Automatisches Load Balancing (Routing Mesh)
- ✅ Rolling Updates
- ⚠️ Shared Storage für Stateful Services nötig
- ⚠️ Etwas komplexer als docker-compose
- ✅ Perfekt für Homelab

**Empfehlung:** Starte mit einem kleinen Cluster (2-3 Nodes), teste die Migration, dann erweitere.

---

## Nützliche Links

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Swarm Mode Tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

---

**Viel Erfolg mit Docker Swarm! 🚀**

