# Docker Swarm - Complete Guide

## What is Docker Swarm?

**Docker Swarm** is Docker's native orchestration. It transforms multiple Docker hosts into a **cluster**.

### Concepts
- **Manager Nodes**: Control the cluster (consensus via Raft)
- **Worker Nodes**: Run containers
- **Services**: Containers running as services (instead of individual containers)
- **Stacks**: Multiple services together (like docker-compose, but for Swarm)
- **Overlay Networks**: Networks that span multiple nodes
- **Routing Mesh**: Automatic load balancing

---

## Why Docker Swarm?

### Advantages
- ✅ **Redundancy**: Services run on multiple nodes
- ✅ **High Availability**: Failure of one node = no problem
- ✅ **Load Balancing**: Automatic via Routing Mesh
- ✅ **Rolling Updates**: Zero-downtime updates
- ✅ **Native Docker**: No additional software needed
- ✅ **Simpler than Kubernetes**: Perfect for Homelab

### Disadvantages
- ⚠️ **Complexity**: More configuration than docker-compose
- ⚠️ **Network**: Overlay networks have overhead
- ⚠️ **Storage**: Shared storage needed for stateful services

---

## Docker Swarm - Architecture

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

## Docker Swarm Setup - Step by Step

### Step 1: Initialize Swarm

```bash
# On the first node (becomes Manager)
docker swarm init

# Output shows you a join token:
# Swarm initialized: current node (xxx) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#   docker swarm join --token SWMTKN-1-... <IP>:2377

# Check status
docker node ls
```

### Step 2: Add More Nodes

```bash
# On other nodes (as Worker)
docker swarm join --token <WORKER-TOKEN> <MANAGER-IP>:2377

# Or as Manager (for HA)
docker swarm join-token manager
docker swarm join --token <MANAGER-TOKEN> <MANAGER-IP>:2377
```

**Get token:**
```bash
# Worker Token
docker swarm join-token worker

# Manager Token
docker swarm join-token manager
```

### Step 3: Create Overlay Networks

```bash
# Create Overlay Network (works across all nodes)
docker network create --driver overlay --attachable proxy
docker network create --driver overlay --attachable crowdsec

# Check
docker network ls
# Should show "overlay" as Driver
```

**Important:** `--attachable` allows normal containers (not just services) to connect.

---

## Migration: docker-compose.yml → docker-stack.yml

### Differences between Compose and Stack

| Feature | docker-compose | docker-stack |
|---------|---------------|--------------|
| Container | `container_name` | ❌ Not allowed |
| Networks | `external: true` | ✅ Works |
| Volumes | Local paths | ✅ Works (but shared storage better) |
| Ports | `80:80` | ✅ Works (Routing Mesh) |
| Deploy | ❌ Not present | ✅ `deploy:` Section |
| Replicas | ❌ Not present | ✅ `replicas: 3` |
| Placement | ❌ Not present | ✅ `placement:` Constraints |
| IP Address | ✅ `ipv4_address` | ❌ Not allowed |

### Example: Traefik Migration

**Before (docker-compose.yml):**
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

**After (docker-stack.yml):**
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
      mode: global  # Or: replicas: 3
      placement:
        constraints:
          - node.role == manager  # Optional: only on Managers
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    # Labels stay the same!
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

**Important changes:**
1. ❌ `container_name` removed (Swarm assigns names automatically)
2. ✅ `ports:` format changed (with `mode: ingress` for Routing Mesh)
3. ✅ `deploy:` section added
4. ✅ `volumes:` as Named Volumes (for Shared Storage later)

---

## Deploy Modes: Global vs Replicated

### Global Mode
```yaml
deploy:
  mode: global
```
- **One task per node** (automatic)
- Perfect for: Traefik, Monitoring Agents
- Example: 3 nodes = 3 Traefik tasks

### Replicated Mode
```yaml
deploy:
  mode: replicated
  replicas: 3
```
- **Fixed number of tasks** (distributed across nodes)
- Perfect for: Web Apps, APIs
- Example: 3 replicas on 5 nodes = 3 tasks somewhere

---

## Routing Mesh - How Does It Work?

**Routing Mesh** means: Every node can accept requests for **any service**.

```
Internet Request → Node 1 (Port 80) → Swarm Routing Mesh → Traefik Task (somewhere)
Internet Request → Node 2 (Port 80) → Swarm Routing Mesh → Traefik Task (somewhere)
Internet Request → Node 3 (Port 80) → Swarm Routing Mesh → Traefik Task (somewhere)
```

**Advantage:** You don't need to know which node Traefik runs on!

**Router/NAT Configuration:**
- Forward Port 80/443 to **any** node (or multiple)
- Swarm automatically forwards

### Port Modes

#### Ingress Mode (Routing Mesh)
```yaml
ports:
  - target: 80
    published: 80
    mode: ingress
```
**For:** HTTP/HTTPS Services (Traefik, Web Apps)

#### Host Mode (direct)
```yaml
ports:
  - target: 53
    published: 53
    mode: host
```
**For:** DNS, special network services (Pi-hole DNS)

---

## Shared Storage for Stateful Services

**Problem:** Services with data (e.g., Traefik ACME, databases) need persistent storage.

### Option 1: NFS (recommended for Homelab)
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
# On one node
sudo apt install nfs-kernel-server
sudo mkdir -p /exports/traefik-acme
sudo chown nobody:nogroup /exports/traefik-acme
echo "/exports/traefik-acme *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

**On all nodes (NFS Client):**
```bash
sudo apt install nfs-common
```

### Option 2: GlusterFS / Ceph
- More complex, but very robust
- For larger setups

### Option 3: Node Constraints (simple, but no HA)
```yaml
deploy:
  placement:
    constraints:
      - node.hostname == node1
```
- Service always runs on Node1
- If Node1 fails → Service down

---

## Placement Constraints

```yaml
deploy:
  placement:
    constraints:
      - node.role == manager      # Only Manager nodes
      - node.hostname == node1     # Fixed node
      - node.labels.env == prod    # Custom labels
```

**Set node labels:**
```bash
docker node update --label-add env=prod <node-name>
docker node update --label-add storage=ssd <node-name>
```

**Use node labels:**
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
# List services
docker service ls

# Service details
docker service ps <service-name>
docker service inspect <service-name>

# Service logs
docker service logs <service-name> -f

# Scale service
docker service scale <service-name>=5

# Update service (Rolling Update)
docker service update --image traefik:v3.2.0 <stack-name>_traefik

# Remove service
docker service rm <service-name>
```

### Stacks
```bash
# Deploy stack
docker stack deploy -c docker-stack.yml <stack-name>

# Stack status
docker stack ls
docker stack services <stack-name>
docker stack ps <stack-name>

# Remove stack
docker stack rm <stack-name>
```

### Nodes
```bash
# List nodes
docker node ls

# Node details
docker node inspect <node-name>

# Drain node (for maintenance)
docker node update --availability drain <node-name>

# Activate node
docker node update --availability active <node-name>

# Node labels
docker node update --label-add <key>=<value> <node-name>
```

### Networks
```bash
# List networks
docker network ls

# Network details
docker network inspect proxy

# Create network
docker network create --driver overlay --attachable proxy
```

---

## Firewall Ports

**Swarm requires:**
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

## Practical Examples

### Example 1: Traefik as Global Service

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
      mode: global  # One Traefik per node
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

### Example 2: Pi-hole with Host Mode for DNS

```yaml
version: '3.8'

services:
  pihole:
    image: pihole/pihole:latest
    networks:
      - proxy
    ports:
      # DNS Ports - Host Mode for DNS!
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
          - node.hostname == node1  # DNS should run consistently
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

### Example 3: Web App with Replicas

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
      replicas: 3  # 3 instances
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

**Automatic on service updates:**
```bash
docker service update --image traefik:v3.2.0 <stack-name>_traefik
```

**Configure in docker-stack.yml:**
```yaml
deploy:
  update_config:
    parallelism: 1        # How many tasks update simultaneously
    delay: 10s            # Wait time between updates
    failure_action: rollback  # On error: Rollback
    monitor: 60s          # Health check time
```

**Rollback:**
```bash
docker service rollback <stack-name>_traefik
```

---

## Troubleshooting

### Problem: Service Won't Start
```bash
# Service logs
docker service logs <service-name> -f

# Service details
docker service ps <service-name> --no-trunc

# Node logs
journalctl -u docker -f
```

### Problem: Network Not Working
```bash
# Check network
docker network inspect proxy

# Check service network
docker service inspect <service-name> | grep -A 10 Networks
```

### Problem: Ports Not Reachable
```bash
# Check Routing Mesh
docker service inspect <service-name> | grep -A 5 Ports

# Check firewall
sudo ufw status
sudo iptables -L -n
```

### Problem: Volumes Not Found
```bash
# List volumes
docker volume ls

# Volume details
docker volume inspect <volume-name>
```

### Problem: Node Can't Join
```bash
# Check firewall
sudo ufw status

# Check network
ping <manager-ip>

# Check ports
telnet <manager-ip> 2377
```

---

## Best Practices

1. **Migrate Traefik first** (all others depend on it)
2. **Shared Storage** for stateful services (ACME, databases)
3. **Health Checks** for all services
4. **Node Constraints** for DNS (Pi-hole should run consistently)
5. **Global Mode** for Traefik (one per node for HA)
6. **Replicated Mode** for web apps (fixed number)
7. **Host Mode** for DNS ports (Routing Mesh doesn't work well)
8. **Backup** before migration!
9. **Multiple Managers** for HA (odd number: 3, 5, 7)
10. **Enable Monitoring**

---

## Checklist: Migration to Swarm

- [ ] Firewall ports opened (2377, 7946, 4789)
- [ ] Swarm initialized (`docker swarm init`)
- [ ] More nodes added (optional)
- [ ] Overlay networks created (`proxy`, `crowdsec`, etc.)
- [ ] Shared storage set up (NFS or Node Constraints)
- [ ] Traefik stack created and deployed
- [ ] Traefik works (Routing Mesh tested)
- [ ] Other services migrated (docker-compose → docker-stack)
- [ ] `container_name` removed from all services
- [ ] `deploy:` section added
- [ ] Ports changed to `mode: ingress` (except DNS → `mode: host`)
- [ ] `ipv4_address` removed (Swarm assigns IPs)
- [ ] Labels checked (stay the same)
- [ ] Volumes converted to Named Volumes (for Shared Storage)
- [ ] Router/NAT port forwarding adjusted (to one/multiple nodes)
- [ ] Health checks tested
- [ ] Rolling updates tested

---

## Summary

**Docker Swarm** is Docker's native orchestration:
- ✅ High Availability
- ✅ Automatic Load Balancing (Routing Mesh)
- ✅ Rolling Updates
- ⚠️ Shared Storage needed for stateful services
- ⚠️ Slightly more complex than docker-compose
- ✅ Perfect for Homelab

**Recommendation:** Start with a small cluster (2-3 nodes), test the migration, then expand.

---

## Useful Links

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Swarm Mode Tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)

---

**Good luck with Docker Swarm! 🚀**

