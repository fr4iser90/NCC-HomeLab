# Rootless Docker - Complete Guide

## What is Rootless Docker?

**Rootless Docker** means Docker runs without root privileges. Instead, it uses:
- **User Namespaces** (UID/GID mapping)
- **RootlessKit** (port forwarding without root)
- **slirp4netns** or **VPNKit** (networking without root)

---

## Why Rootless Docker?

### Advantages
- ✅ **Security**: Containers don't run as root → less attack surface
- ✅ **Isolation**: Even if a container is compromised, it has no root privileges on the host
- ✅ **Compliance**: Meets many security best practices
- ✅ **Multi-User**: Multiple users can use Docker in parallel

### Disadvantages
- ⚠️ **Ports < 1024**: Need special configuration (CAP_NET_BIND_SERVICE or RootlessKit)
- ⚠️ **Performance**: Slightly slower (User Namespace overhead)
- ⚠️ **Compatibility**: Not all features work (e.g., some storage drivers)

---

## How Does Rootless Docker Work?

### 1. User Namespace Mapping

**The Problem:** Containers need root (UID 0) internally, but shouldn't be root on the host.

**The Solution:** User Namespace Mapping

```
Host System:                    Container sees:
UID 1000 (your user)    →       UID 0 (root in container)
UID 100000              →       UID 1
UID 100001              →       UID 2
...
```

**Example:**
- Your user on host: `fr4iser` (UID 1000)
- Container runs as "root" (UID 0) **inside** the container
- On the host, the process runs as UID 1000 (your user)
- Docker maps: Container-UID 0 → Host-UID 1000

### 2. Networking without Root

**Normal Docker (with root):**
- Docker creates bridge networks directly
- Binding to port 80/443 works directly

**Rootless Docker:**
- Uses **slirp4netns** or **VPNKit**
- Port forwarding via **RootlessKit**
- Ports < 1024 are mapped via RootlessKit

**Example Port Mapping:**
```
Container Port 80  →  RootlessKit  →  Host Port 8080 (or higher)
```

Or with **CAP_NET_BIND_SERVICE**:
```bash
# Set capability for ports < 1024
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)
```

---

## How Does a Reverse Proxy (Traefik) Get Rights in Rootless Docker?

### Problem 1: Binding Port 80/443

#### Option A: RootlessKit Port Forwarding (Standard)

Traefik binds internally to port 80/443, RootlessKit maps it:

```yaml
# docker-compose.yml
services:
  traefik:
    ports:
      - "8080:80"   # Host:Container
      - "8443:443"
```

**Router/NAT:** Forward 80/443 → Host:8080/8443

#### Option B: CAP_NET_BIND_SERVICE (Ports < 1024 directly)

```bash
# Install rootlesskit with capability
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Now Traefik can bind directly to 80/443
services:
  traefik:
    ports:
      - "80:80"
      - "443:443"
```

#### Option C: iptables/Forwarding (requires root for setup)

```bash
# One-time as root:
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
```

### Problem 2: Docker Socket Access

**Normal Docker:**
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Rootless Docker:**
```yaml
volumes:
  - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
  # Or:
  - ~/.local/share/docker/run/docker.sock:/var/run/docker.sock:ro
```

**Important:** The socket belongs to your user, not root!

**Find socket path:**
```bash
# Current socket path
echo $XDG_RUNTIME_DIR/docker.sock

# Or
ls -la ~/.local/share/docker/run/docker.sock
```

### Problem 3: Log Access

**Normal Docker:**
```yaml
volumes:
  - /var/log/traefik:/var/log/traefik
```

**Rootless Docker:**
```yaml
volumes:
  - ~/docker-logs/traefik:/var/log/traefik
  # Or with permissions:
  - ./logs/traefik:/var/log/traefik
```

**Set permissions:**
```bash
mkdir -p ~/docker-logs/traefik
chmod 755 ~/docker-logs/traefik
```

---

## Rootless Docker Setup - Step by Step

### Step 1: Install Rootless Docker

```bash
# Method 1: Official Rootless Install Script
curl -fsSL https://get.docker.com/rootless | sh

# After installation:
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# Check if it works
docker --version
docker ps
```

**Alternative: Podman (rootless by default)**
```bash
# Podman is a Docker alternative that runs rootless by default
# No additional configuration needed
podman --version
```

### Step 2: Set Environment Variables Permanently

**For your shell (.bashrc / .zshrc):**
```bash
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

**Or for Systemd User Service:**
```bash
# Automatically set when Docker runs as Systemd service
```

### Step 3: Systemd Service (optional, for auto-start)

```bash
# Rootless Docker as Systemd User Service
systemctl --user enable docker
systemctl --user start docker

# Check status
systemctl --user status docker
```

### Step 4: Enable Ports < 1024 (optional)

```bash
# Check if rootlesskit is installed
which rootlesskit

# Set capability for ports < 1024
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Check
getcap $(which rootlesskit)
# Should show: cap_net_bind_service=ep

# Or: Use higher ports (8080/8443) and forward in router
```

### Step 5: Adjust Docker Compose

**Before (Root Docker):**
```yaml
services:
  traefik:
    container_name: traefik
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log/traefik:/var/log/traefik
```

**After (Rootless Docker):**
```yaml
services:
  traefik:
    # container_name can stay (docker-compose allows it)
    ports:
      - "8080:80"    # Or 80:80 if CAP_NET_BIND_SERVICE set
      - "8443:443"   # Or 443:443 if CAP_NET_BIND_SERVICE set
    volumes:
      - $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock:ro
      - ./logs/traefik:/var/log/traefik
    # Important: User Namespace stays automatically active
```

**Important:** `$XDG_RUNTIME_DIR` is not automatically expanded by Docker Compose!

**Solution:**
```bash
# In docker-compose.yml use the full path:
# Or set it as environment variable
export XDG_RUNTIME_DIR=/run/user/$(id -u)
docker-compose up -d
```

**Or in docker-compose.yml:**
```yaml
services:
  traefik:
    volumes:
      # Use the full path
      - /run/user/1000/docker.sock:/var/run/docker.sock:ro
      # Or use .env file
      - ${DOCKER_SOCKET_PATH}:/var/run/docker.sock:ro
```

**In .env file:**
```bash
DOCKER_SOCKET_PATH=/run/user/1000/docker.sock
```

### Step 6: Adjust Networks

**Rootless Docker uses different network ranges:**

```yaml
networks:
  proxy:
    driver: bridge
    ipam:
      config:
        - subnet: 172.40.0.0/16  # Can stay, will be mapped
```

**Important:** External networks must be created beforehand:
```bash
docker network create proxy
```

**Check networks:**
```bash
docker network ls
docker network inspect proxy
```

---

## Practical Examples

### Example 1: Traefik with Rootless Docker

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.1.0
    ports:
      - "8080:80"    # Higher ports
      - "8443:443"
    volumes:
      - /run/user/1000/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/traefik.yml:ro
      - ./traefik/acme:/traefik
      - ./logs/traefik:/var/log/traefik
    networks:
      - proxy
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

networks:
  proxy:
    external: true
```

**Router/NAT Configuration:**
- Forward Port 80 → Host:8080
- Forward Port 443 → Host:8443

### Example 2: Pi-hole with Rootless Docker

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  pihole:
    image: pihole/pihole:latest
    ports:
      - "5353:53/tcp"    # Higher ports for DNS
      - "5353:53/udp"
    volumes:
      - ./pihole-data:/etc/pihole
      - ./pihole-dnsmasq:/etc/dnsmasq.d
    networks:
      - proxy
    restart: unless-stopped
```

**Router DNS Configuration:**
- Set DNS server to Host-IP:5353

---

## Troubleshooting

### Problem: Docker Socket Not Found

```bash
# Check socket path
echo $XDG_RUNTIME_DIR
ls -la $XDG_RUNTIME_DIR/docker.sock

# If not present:
ls -la ~/.local/share/docker/run/docker.sock

# Restart Docker
systemctl --user restart docker
```

### Problem: Ports < 1024 Don't Work

```bash
# Check rootlesskit capability
getcap $(which rootlesskit)

# If not set:
sudo setcap cap_net_bind_service=+ep $(which rootlesskit)

# Or: Use higher ports
```

### Problem: Network Not Working

```bash
# Check networks
docker network ls
docker network inspect proxy

# Recreate network
docker network rm proxy
docker network create proxy
```

### Problem: Permission Denied

```bash
# Check permissions
ls -la ~/docker-logs/
chmod 755 ~/docker-logs/

# Check user
whoami
id
```

### Problem: Container Won't Start

```bash
# Docker logs
journalctl --user -u docker -f

# Container logs
docker logs <container-name>

# Check environment
echo $DOCKER_HOST
echo $PATH
```

---

## Rootless Docker - Practical Checklist

- [ ] Rootless Docker installed (`docker --version` check)
- [ ] `DOCKER_HOST` environment variable set
- [ ] `PATH` contains `$HOME/bin`
- [ ] Ports configured (8080/8443 or CAP_NET_BIND_SERVICE)
- [ ] Docker socket path adjusted (`$XDG_RUNTIME_DIR/docker.sock`)
- [ ] Log directories moved to user-space
- [ ] Networks created (`docker network create`)
- [ ] Router/NAT port forwarding adjusted (if needed)
- [ ] Systemd service enabled (optional)
- [ ] Environment variables set in .bashrc/.zshrc
- [ ] All docker-compose.yml files adjusted

---

## Comparison: Root vs Rootless Docker

| Feature | Root Docker | Rootless Docker |
|---------|-------------|-----------------|
| Installation | `sudo apt install docker.io` | `curl ... \| sh` (User-space) |
| Socket | `/var/run/docker.sock` | `$XDG_RUNTIME_DIR/docker.sock` |
| Ports < 1024 | ✅ Direct | ⚠️ CAP_NET_BIND_SERVICE or higher ports |
| Logs | `/var/log/` | `~/docker-logs/` or `./logs/` |
| Network | Bridge directly | slirp4netns/VPNKit |
| Performance | ✅ Fast | ⚠️ Slightly slower |
| Security | ⚠️ Root privileges | ✅ User privileges |
| Multi-User | ❌ Difficult | ✅ Easy |

---

## Best Practices

1. **Use higher ports** (8080/8443) instead of CAP_NET_BIND_SERVICE if possible
2. **Store logs in user-space** (`~/docker-logs/` or `./logs/`)
3. **Set environment variables permanently** (.bashrc/.zshrc)
4. **Enable Systemd service** for auto-start
5. **Backup** your configurations
6. **Test** in VM/test environment first

---

## Useful Links

- [Docker Rootless Docs](https://docs.docker.com/engine/security/rootless/)
- [RootlessKit GitHub](https://github.com/rootless-containers/rootlesskit)
- [Podman Docs](https://podman.io/) (Alternative to Docker, rootless by default)

---

## Summary

**Rootless Docker** is a secure alternative to normal Docker:
- ✅ Runs without root privileges
- ✅ Better isolation
- ⚠️ Slightly more configuration needed
- ⚠️ Ports < 1024 need setup
- ✅ Perfect for Homelab and multi-user environments

**Recommendation:** Test it first in a VM, then migrate step by step.

---

**Good luck with Rootless Docker! 🔒**

