# Quick Reference: Rootless Docker & Docker Swarm

## Rootless Docker - Quick Facts

### Installation
```bash
curl -fsSL https://get.docker.com/rootless | sh
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

### Enable Ports < 1024
```bash
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)
```

### Docker Socket Path
```yaml
# Instead of: /var/run/docker.sock
volumes:
  - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
```

### Port Mapping
```yaml
# Option 1: Higher Ports
ports:
  - "8080:80"
  - "8443:443"

# Option 2: Direct (with CAP_NET_BIND_SERVICE)
ports:
  - "80:80"
  - "443:443"
```

---

## Docker Swarm - Quick Commands

### Setup
```bash
# Initialize Swarm
docker swarm init

# Add node
docker swarm join --token <TOKEN> <IP>:2377

# Get token
docker swarm join-token worker
docker swarm join-token manager
```

### Networks
```bash
# Create Overlay Network
docker network create --driver overlay --attachable proxy

# List networks
docker network ls
```

### Stacks
```bash
# Deploy stack
docker stack deploy -c docker-stack.yml <name>

# Stack status
docker stack ls
docker stack services <name>
docker stack ps <name>

# Remove stack
docker stack rm <name>
```

### Services
```bash
# List services
docker service ls

# Service details
docker service ps <service-name>
docker service inspect <service-name>

# Scale service
docker service scale <service-name>=3

# Update service
docker service update --image <image>:<tag> <service-name>

# Service logs
docker service logs <service-name> -f

# Remove service
docker service rm <service-name>
```

### Nodes
```bash
# List nodes
docker node ls

# Node details
docker node inspect <node-name>

# Drain node (maintenance)
docker node update --availability drain <node-name>

# Activate node
docker node update --availability active <node-name>
```

---

## docker-compose.yml → docker-stack.yml Migration

### Remove
- ❌ `container_name: ...`
- ❌ `ipv4_address: ...` (in networks)
- ❌ `depends_on:` (use `deploy.placement.constraints`)

### Add
- ✅ `deploy:` section
- ✅ `ports:` with `mode: ingress` (or `mode: host` for DNS)
- ✅ Named Volumes (instead of local paths)

### Example

**Before:**
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

**After:**
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

### Global (one task per node)
```yaml
deploy:
  mode: global
```
**For:** Traefik, Monitoring Agents

### Replicated (fixed number)
```yaml
deploy:
  mode: replicated
  replicas: 3
```
**For:** Web Apps, APIs

---

## Port Modes

### Ingress (Routing Mesh)
```yaml
ports:
  - target: 80
    published: 80
    mode: ingress
```
**For:** HTTP/HTTPS Services (Traefik, Web Apps)

### Host (direct)
```yaml
ports:
  - target: 53
    published: 53
    mode: host
```
**For:** DNS, special network services

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

---

## Troubleshooting

### Service won't start
```bash
docker service logs <service-name> -f
docker service ps <service-name> --no-trunc
```

### Network problems
```bash
docker network inspect proxy
docker service inspect <service-name> | grep -A 10 Networks
```

### Ports not reachable
```bash
docker service inspect <service-name> | grep -A 5 Ports
sudo ufw status
```

### Volume problems
```bash
docker volume ls
docker volume inspect <volume-name>
```

---

## Important Differences

| Feature | docker-compose | docker-stack |
|---------|---------------|--------------|
| Container Name | ✅ `container_name` | ❌ Not allowed |
| Networks | ✅ `external: true` | ✅ Works |
| Volumes | ✅ Local paths | ✅ Named Volumes |
| Ports | ✅ `80:80` | ✅ `mode: ingress` |
| Deploy | ❌ Not present | ✅ `deploy:` section |
| Replicas | ❌ Not present | ✅ `replicas: 3` |
| Placement | ❌ Not present | ✅ `placement:` constraints |
| IP Address | ✅ `ipv4_address` | ❌ Not allowed |

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

---

## Useful Links

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Rootless Docker Docs](https://docs.docker.com/engine/security/rootless/)
- [Traefik Swarm Guide](https://doc.traefik.io/traefik/routing/providers/docker/#docker-swarm-mode)

---

**Good luck! 🚀**

