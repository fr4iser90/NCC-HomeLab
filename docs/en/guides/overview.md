# Rootless Docker & Docker Swarm - Overview

This file is an **overview** of both topics. For detailed information, see the separate guides:

## 📚 Separate Guides

### 1. [ROOTLESS-DOCKER-GUIDE.md](./rootless-docker.md)
**Complete guide to Rootless Docker:**
- What is Rootless Docker?
- Installation and setup
- How it works (User Namespaces, RootlessKit)
- Reverse proxy configuration (Traefik)
- Ports < 1024 setup
- Docker socket adjustments
- Practical examples
- Troubleshooting

### 2. [DOCKER-SWARM-GUIDE.md](./docker-swarm.md)
**Complete guide to Docker Swarm:**
- What is Docker Swarm?
- Architecture and concepts
- Setup and configuration
- Migration: docker-compose → docker-stack
- Routing Mesh
- Shared storage
- Management commands
- Practical examples

### 3. [SWARM-MIGRATION-STEPS.md](./migration.md)
**Practical step-by-step guide:**
- Firewall configuration
- Initialize Swarm
- Migrate services
- Troubleshooting
- Checklist

---

## 🎯 Quick Decision

### Only Rootless Docker?
→ See [ROOTLESS-DOCKER-GUIDE.md](./rootless-docker.md)

### Only Docker Swarm?
→ See [DOCKER-SWARM-GUIDE.md](./docker-swarm.md)  
→ See [SWARM-MIGRATION-STEPS.md](./migration.md) for practical steps

### Combine both?
⚠️ **Warning:** Rootless Docker + Swarm is possible, but complex and has limitations.

**Recommendation:**
- For **Homelab**: First Swarm, then Rootless (or vice versa)
- For **Production**: Normal Docker (with root) + Swarm is easier
- **Alternative**: Podman (rootless by default) + Podman Swarm

---

## 🔗 Combination: Rootless Docker + Swarm

### Problems when combining

1. **Ports < 1024**: Need CAP_NET_BIND_SERVICE or higher ports
2. **Overlay Networks**: Can have problems with User Namespaces
3. **Docker Socket**: Must be accessible for all nodes
4. **Complexity**: Significantly more setup effort

### If you still want to try it

1. **Install Rootless Docker on all nodes**
   - See [ROOTLESS-DOCKER-GUIDE.md](./rootless-docker.md)

2. **Initialize Swarm**
   - See [DOCKER-SWARM-GUIDE.md](./docker-swarm.md)

3. **Configure ports**
   - Use higher ports (8080/8443) or CAP_NET_BIND_SERVICE
   - Adjust router/NAT accordingly

4. **Adjust Docker socket**
   - In docker-stack.yml: use `$XDG_RUNTIME_DIR/docker.sock`
   - Configure the same on all nodes

5. **Test, test, test!**
   - First in VM/test environment
   - Migrate step by step

---

## 📋 Quick Reference

See [QUICK-REFERENCE.md](../reference/quick-reference.md) for:
- Important commands
- Migration cheatsheet
- Troubleshooting quick fixes

---

## 🚀 Recommended Path

### For Homelab (simple):
1. **Docker Swarm** first (see [DOCKER-SWARM-GUIDE.md](./docker-swarm.md))
2. **Rootless Docker** later (optional, see [ROOTLESS-DOCKER-GUIDE.md](./rootless-docker.md))

### For maximum security:
1. **Rootless Docker** first (see [ROOTLESS-DOCKER-GUIDE.md](./rootless-docker.md))
2. **Swarm** later (optional, see [DOCKER-SWARM-GUIDE.md](./docker-swarm.md))

### For production:
- **Normal Docker + Swarm** (easier, proven)
- Or: **Podman + Podman Swarm** (rootless by default)

---

**Good luck! 🎉**

