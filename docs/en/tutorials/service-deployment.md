# Service Deployment - Deploying Services

Guide for deploying services in NCC-HomeLab.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Docker Compose (Standard)

### Start Service

```bash
cd docker/<category>/<service>
docker-compose up -d
```

### Stop Service

```bash
docker-compose down
```

### Service Logs

```bash
docker-compose logs -f
```

## Docker Swarm (for HA)

### Deploy Stack

```bash
cd docker/<category>/<service>
docker stack deploy -c docker-stack.yml <stack-name>
```

### Stack Status

```bash
docker stack services <stack-name>
docker stack ps <stack-name>
```

### Remove Stack

```bash
docker stack rm <stack-name>
```

## Service Configuration

### Environment Variables

Most services use `.env` files:

```bash
# Example: Traefik
cd docker/gateway-management/traefik-crowdsec
cat traefik.env
```

### Update Scripts

Many services have update scripts:

```bash
./update-traefik-env.sh
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker logs <container-name>

# Compose logs
docker-compose logs
```

### Network Issues

```bash
# Check network
docker network inspect proxy

# Check container network
docker inspect <container-name> | grep -A 10 Networks
```

### Ports Not Reachable

```bash
# Check ports
docker ps | grep <service>

# Check firewall
sudo ufw status
```

## Best Practices

1. **Traefik first** - All other services depend on it
2. **Backup before updates** - Backup important data
3. **Check logs** - Always check logs when problems occur
4. **Check network** - Services must be in `proxy` network

## Further Information

- [Docker Swarm Guide](../guides/docker-swarm.md)
- [Service Documentation](../services/)

