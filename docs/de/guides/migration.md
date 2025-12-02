# Docker Swarm Migration - Schritt-für-Schritt Anleitung

## Voraussetzungen

- [ ] Docker installiert auf allen Nodes
- [ ] Alle Nodes können sich gegenseitig erreichen (Port 2377, 7946, 4789)
- [ ] Firewall konfiguriert (siehe unten)
- [ ] Backup deiner aktuellen docker-compose.yml Dateien

---

## Schritt 1: Firewall Ports öffnen

**Auf allen Nodes:**

```bash
# Swarm Management
sudo ufw allow 2377/tcp

# Swarm Node Communication
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp

# Overlay Network (VXLAN)
sudo ufw allow 4789/udp

# Optional: SSH
sudo ufw allow 22/tcp
```

**Oder mit iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 4789 -j ACCEPT
```

---

## Schritt 2: Swarm initialisieren

**Auf dem ersten Node (wird Manager):**

```bash
# Swarm initialisieren
docker swarm init

# Output zeigt dir:
# Swarm initialized: current node (xxx) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#   docker swarm join --token SWMTKN-1-xxx <IP>:2377
#
# To add a manager to this swarm, run:
#   docker swarm join-token manager
```

**Token speichern:**
```bash
# Worker Token
docker swarm join-token worker

# Manager Token (für HA)
docker swarm join-token manager
```

**Status prüfen:**
```bash
docker node ls
# Sollte zeigen: * Leader (wenn du der erste Manager bist)
```

---

## Schritt 3: Weitere Nodes hinzufügen

**Auf anderen Nodes (als Worker):**

```bash
docker swarm join --token <WORKER-TOKEN> <MANAGER-IP>:2377
```

**Als Manager (für High Availability):**

```bash
docker swarm join --token <MANAGER-TOKEN> <MANAGER-IP>:2377
```

**Auf dem Manager prüfen:**
```bash
docker node ls
# Sollte jetzt alle Nodes zeigen
```

---

## Schritt 4: Overlay Networks erstellen

**Auf einem Manager Node:**

```bash
# Proxy Network (für Traefik)
docker network create --driver overlay --attachable proxy

# CrowdSec Network
docker network create --driver overlay --attachable crowdsec

# Prüfen
docker network ls
# Sollte "overlay" als Driver zeigen
```

**Wichtig:** `--attachable` erlaubt auch normale Container (nicht nur Services) sich zu verbinden.

---

## Schritt 5: Shared Storage einrichten (optional, aber empfohlen)

### Option A: NFS (empfohlen)

**Auf einem Node (NFS Server):**
```bash
# NFS Server installieren
sudo apt install nfs-kernel-server

# Export erstellen
sudo mkdir -p /exports/traefik-acme
sudo chown nobody:nogroup /exports/traefik-acme
sudo chmod 755 /exports/traefik-acme

# Export konfigurieren
echo "/exports/traefik-acme *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

**Auf allen Nodes (NFS Client):**
```bash
sudo apt install nfs-common
```

**In docker-stack.yml:**
```yaml
volumes:
  traefik-acme:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.local,rw
      device: ":/exports/traefik-acme"
```

### Option B: Node Constraints (einfach, aber kein HA)

Services laufen immer auf einem festen Node. Wenn der Node ausfällt, ist der Service down.

**In docker-stack.yml:**
```yaml
deploy:
  placement:
    constraints:
      - node.hostname == node1
```

---

## Schritt 6: Traefik Stack deployen

**1. Vorbereitung:**

```bash
cd docker/gateway-management/traefik-crowdsec

# Prüfe docker-stack.yml
cat docker-stack.yml
```

**2. Deploy:**

```bash
# Stack deployen
docker stack deploy -c docker-stack.yml gateway

# Status prüfen
docker service ls
docker service ps gateway_traefik
docker service ps gateway_crowdsec

# Logs prüfen
docker service logs gateway_traefik -f
```

**3. Testen:**

```bash
# Traefik sollte auf allen Nodes erreichbar sein
curl http://localhost:8080/api/rawdata

# Von anderen Nodes testen
curl http://<node-ip>:8080/api/rawdata
```

**4. Router/NAT anpassen:**

- Forwarde Port 80/443 an **irgendeinen** Swarm Node (oder mehrere)
- Swarm Routing Mesh leitet automatisch weiter

---

## Schritt 7: Weitere Services migrieren

**Für jeden Service:**

1. **docker-compose.yml → docker-stack.yml konvertieren:**
   - ❌ `container_name` entfernen
   - ✅ `deploy:` Section hinzufügen
   - ✅ Ports auf `mode: ingress` umstellen (außer DNS → `mode: host`)
   - ❌ `ipv4_address` entfernen
   - ✅ Volumes auf Named Volumes umstellen

2. **Deploy:**
```bash
docker stack deploy -c docker-stack.yml <stack-name>
```

3. **Prüfen:**
```bash
docker service ls
docker service ps <stack-name>_<service-name>
docker service logs <stack-name>_<service-name> -f
```

---

## Schritt 8: Alte Container stoppen

**WICHTIG: Erst wenn alles funktioniert!**

```bash
# Alte Container stoppen
docker-compose -f docker-compose.yml down

# Oder manuell
docker stop <container-name>
docker rm <container-name>
```

**Aber:** Lass die alten Container laufen, bis die neuen Services funktionieren!

---

## Schritt 9: Monitoring & Wartung

### Service Management

```bash
# Services auflisten
docker service ls

# Service Details
docker service ps <service-name>

# Service skalieren
docker service scale <service-name>=3

# Service updaten (Rolling Update)
docker service update --image traefik:v3.2.0 gateway_traefik

# Service Logs
docker service logs <service-name> -f

# Service entfernen
docker service rm <service-name>
```

### Stack Management

```bash
# Stack deployen
docker stack deploy -c docker-stack.yml <stack-name>

# Stack Status
docker stack services <stack-name>
docker stack ps <stack-name>

# Stack entfernen
docker stack rm <stack-name>
```

### Node Management

```bash
# Nodes auflisten
docker node ls

# Node Details
docker node inspect <node-name>

# Node drainen (für Wartung)
docker node update --availability drain <node-name>

# Node wieder aktivieren
docker node update --availability active <node-name>
```

---

## Troubleshooting

### Problem: Service startet nicht

```bash
# Service Logs prüfen
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

---

## Rollback Plan

**Falls etwas schief geht:**

1. **Stack entfernen:**
```bash
docker stack rm <stack-name>
```

2. **Alte docker-compose.yml wieder starten:**
```bash
docker-compose -f docker-compose.yml up -d
```

3. **Netzwerke prüfen:**
```bash
docker network ls
# Falls nötig: docker network create proxy
```

---

## Checkliste

- [ ] Firewall Ports geöffnet (2377, 7946, 4789)
- [ ] Swarm initialisiert (`docker swarm init`)
- [ ] Weitere Nodes hinzugefügt (`docker node ls` zeigt alle)
- [ ] Overlay Networks erstellt (`proxy`, `crowdsec`)
- [ ] Shared Storage eingerichtet (NFS oder Node Constraints)
- [ ] Traefik Stack deployed (`docker stack deploy`)
- [ ] Traefik funktioniert (Routing Mesh getestet)
- [ ] Router/NAT Port-Forwarding angepasst
- [ ] Weitere Services migriert
- [ ] Alte Container gestoppt (nach erfolgreichem Test)
- [ ] Monitoring eingerichtet
- [ ] Backup erstellt

---

## Nächste Schritte

1. **Health Checks aktivieren** für alle Services
2. **Monitoring** mit Prometheus/Grafana
3. **Backup-Strategie** für Volumes
4. **Auto-Scaling** (optional, mit externen Tools)
5. **Multi-Site Setup** (VPN + GSLB, siehe Haupt-Guide)

---

**Viel Erfolg mit deinem Swarm Setup! 🚀**

