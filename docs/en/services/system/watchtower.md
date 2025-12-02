# Watchtower - Auto-Updates

Watchtower automatically updates Docker containers to the latest images.

> **Note:** Installation is done via `init-homelab.sh`. This documentation describes Docker configuration and features.

## Overview

- **Image:** `containrrr/watchtower:latest`
- **Network:** No special network needed
- **Configuration:** `docker/system-management/watchtower/`

## Docker Configuration

### Docker Compose

```bash
cd docker/system-management/watchtower
docker-compose up -d
```

**Files:**
- `docker-compose.yml` - Container definition

## Features

- ✅ Automatic image updates
- ✅ Container restart after update
- ✅ Notifications (optional)
- ✅ Configurable update strategies

## Configuration

### Update Interval

Default: Every 24 hours

Adjust in `docker-compose.yml`:
```yaml
command: --interval 3600  # Every 60 minutes
```

### Update Strategies

- **Default:** Update all containers
- **Labels:** Only containers with specific labels
- **Exclude:** Exclude specific containers

### Exclude Containers

```yaml
# In docker-compose.yml of the service
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

## Security

- ✅ Checks images before update
- ✅ Can be configured for cleanup
- ⚠️ Test updates in test environment first!

## Troubleshooting

### Watchtower Not Updating

```bash
# Check logs
docker logs watchtower

# Container status
docker ps | grep watchtower
```

### Container Not Updated

```bash
# Check labels
docker inspect <container> | grep watchtower

# Update manually
docker-compose pull
docker-compose up -d
```

## Further Information

- [Watchtower GitHub](https://github.com/containrrr/watchtower)
- [Watchtower Documentation](https://containrrr.dev/watchtower/)

