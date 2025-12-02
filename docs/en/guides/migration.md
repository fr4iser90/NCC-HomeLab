# Docker Swarm Migration - Step-by-Step Guide

## Prerequisites

- [ ] Docker installed on all nodes
- [ ] All nodes can reach each other (Port 2377, 7946, 4789)
- [ ] Firewall configured (see below)
- [ ] Backup of your current docker-compose.yml files

---

## Step 1: Open Firewall Ports

**On all nodes:**

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

**Or with iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 4789 -j ACCEPT
```

---

## Step 2: Initialize Swarm

**On the first node (becomes Manager):**

```bash
# Initialize Swarm
docker swarm init

# Output shows you:
# Swarm initialized: current node (xxx) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#   docker swarm join --token SWMTKN-1-xxx <IP>:2377
#
# To add a manager to this swarm, run:
#   docker swarm join-token manager
```

**Save token:**
```bash
# Worker Token
docker swarm join-token worker

# Manager Token (for HA)
docker swarm join-token manager
```

**Check status:**
```bash
docker node ls
# Should show: * Leader (if you're the first manager)
```

---

## Step 3: Add More Nodes

**On other nodes (as Worker):**

```bash
docker swarm join --token <WORKER-TOKEN> <MANAGER-IP>:2377
```

**As Manager (for High Availability):**

```bash
docker swarm join --token <MANAGER-TOKEN> <MANAGER-IP>:2377
```

**Check on Manager:**
```bash
docker node ls
# Should now show all nodes
```

---

## Step 4: Create Overlay Networks

**On a Manager Node:**

```bash
# Proxy Network (for Traefik)
docker network create --driver overlay --attachable proxy

# CrowdSec Network
docker network create --driver overlay --attachable crowdsec

# Check
docker network ls
# Should show "overlay" as Driver
```

**Important:** `--attachable` allows normal containers (not just services) to connect.

---

## Step 5: Setup Shared Storage (optional, but recommended)

### Option A: NFS (recommended)

**On one node (NFS Server):**
```bash
# Install NFS Server
sudo apt install nfs-kernel-server

# Create export
sudo mkdir -p /exports/traefik-acme
sudo chown nobody:nogroup /exports/traefik-acme
sudo chmod 755 /exports/traefik-acme

# Configure export
echo "/exports/traefik-acme *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

**On all nodes (NFS Client):**
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

### Option B: Node Constraints (simple, but no HA)

Services always run on a fixed node. If the node fails, the service is down.

**In docker-stack.yml:**
```yaml
deploy:
  placement:
    constraints:
      - node.hostname == node1
```

---

## Step 6: Deploy Traefik Stack

**1. Preparation:**

```bash
cd docker/gateway-management/traefik-crowdsec

# Check docker-stack.yml
cat docker-stack.yml
```

**2. Deploy:**

```bash
# Deploy stack
docker stack deploy -c docker-stack.yml gateway

# Check status
docker service ls
docker service ps gateway_traefik
docker service ps gateway_crowdsec

# Check logs
docker service logs gateway_traefik -f
```

**3. Test:**

```bash
# Traefik should be reachable on all nodes
curl http://localhost:8080/api/rawdata

# Test from other nodes
curl http://<node-ip>:8080/api/rawdata
```

**4. Adjust Router/NAT:**

- Forward Port 80/443 to **any** Swarm node (or multiple)
- Swarm Routing Mesh automatically forwards

---

## Step 7: Migrate More Services

**For each service:**

1. **Convert docker-compose.yml → docker-stack.yml:**
   - ❌ Remove `container_name`
   - ✅ Add `deploy:` section
   - ✅ Change ports to `mode: ingress` (except DNS → `mode: host`)
   - ❌ Remove `ipv4_address`
   - ✅ Convert volumes to Named Volumes

2. **Deploy:**
```bash
docker stack deploy -c docker-stack.yml <stack-name>
```

3. **Check:**
```bash
docker service ls
docker service ps <stack-name>_<service-name>
docker service logs <stack-name>_<service-name> -f
```

---

## Step 8: Stop Old Containers

**IMPORTANT: Only when everything works!**

```bash
# Stop old containers
docker-compose -f docker-compose.yml down

# Or manually
docker stop <container-name>
docker rm <container-name>
```

**But:** Keep old containers running until new services work!

---

## Step 9: Monitoring & Maintenance

### Service Management

```bash
# List services
docker service ls

# Service details
docker service ps <service-name>

# Scale service
docker service scale <service-name>=3

# Update service (Rolling Update)
docker service update --image traefik:v3.2.0 gateway_traefik

# Service logs
docker service logs <service-name> -f

# Remove service
docker service rm <service-name>
```

### Stack Management

```bash
# Deploy stack
docker stack deploy -c docker-stack.yml <stack-name>

# Stack status
docker stack services <stack-name>
docker stack ps <stack-name>

# Remove stack
docker stack rm <stack-name>
```

### Node Management

```bash
# List nodes
docker node ls

# Node details
docker node inspect <node-name>

# Drain node (for maintenance)
docker node update --availability drain <node-name>

# Reactivate node
docker node update --availability active <node-name>
```

---

## Troubleshooting

### Problem: Service Won't Start

```bash
# Check service logs
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

---

## Rollback Plan

**If something goes wrong:**

1. **Remove stack:**
```bash
docker stack rm <stack-name>
```

2. **Start old docker-compose.yml again:**
```bash
docker-compose -f docker-compose.yml up -d
```

3. **Check networks:**
```bash
docker network ls
# If needed: docker network create proxy
```

---

## Checklist

- [ ] Firewall ports opened (2377, 7946, 4789)
- [ ] Swarm initialized (`docker swarm init`)
- [ ] More nodes added (`docker node ls` shows all)
- [ ] Overlay networks created (`proxy`, `crowdsec`)
- [ ] Shared storage set up (NFS or Node Constraints)
- [ ] Traefik stack deployed (`docker stack deploy`)
- [ ] Traefik works (Routing Mesh tested)
- [ ] Router/NAT port forwarding adjusted
- [ ] More services migrated
- [ ] Old containers stopped (after successful test)
- [ ] Monitoring set up
- [ ] Backup created

---

## Next Steps

1. **Enable Health Checks** for all services
2. **Monitoring** with Prometheus/Grafana
3. **Backup strategy** for volumes
4. **Auto-Scaling** (optional, with external tools)
5. **Multi-Site Setup** (VPN + GSLB, see main guide)

---

**Good luck with your Swarm setup! 🚀**

