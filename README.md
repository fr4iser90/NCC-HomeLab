# Homelab Setup Automation

A comprehensive automation system for setting up and managing a homelab environment using Docker containers. This system provides a modular approach to deploying various services with proper security configurations.

## Prerequisites

- Linux-based system (tested on NixOS)
- Docker and Docker Compose installed
- User must be in the docker group
- `fzf` package installed for service selection
- Bash shell

## Required Configuration

### 1. Domain Setup
You need a domain name for your services. The system will prompt for:
- Domain name (e.g., example.com)
- DNS provider credentials (supports multiple providers including Cloudflare, Gandi, etc.)

### 2. Email Configuration
A valid email address is required for:
- SSL certificate generation
- Service notifications
- Administrative accounts

### 3. User Configuration
The system uses your current user's:
- Username
- UID/GID for container permissions
- Home directory

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/homelab-setup.git
cd homelab-setup
```

2. Run the setup script:
```bash
bash ./docker-scripts/bin/init-homelab.sh
```

## Available Services

### Gateway Management
- Traefik (Reverse Proxy)
- Crowdsec (Security)
- DDNS Updater (Dynamic DNS)

### Password Management
- Bitwarden (Password Manager)

### Storage Management
- OwnCloud (File Storage)

### System Management
- Portainer (Docker Management)

### Media Management
- Plex (Media Server)

### URL Management
- Yourls (URL Shortener)

### Monitoring
- Honeypot/Tarpit (Security Monitoring)
- Grafana (Metrics Visualization)

## Security Features

1. Automatic SSL certificate generation
2. Secure credential management
3. Rate limiting
4. Admin whitelisting
5. Traefik security middlewares
6. Crowdsec integration for threat detection

## Configuration Files

The system uses several types of configuration files:
- `.env` files for service configuration
- `docker-compose.yml` for container definitions
- Configuration files for specific services

## DNS Provider Support

The system supports multiple DNS providers for domain management and DDNS updates. Some popular options include:
- Cloudflare
- Gandi
- OVH
- DigitalOcean
- Many others (100+ providers supported)

## Directory Structure

docker/
├── adblocker-management/
├── companion-management/
├── gateway-management/
├── honeypot-management/
├── media-management/
├── password-management/
├── storage-management/
├── system-management/
└── url-management/
docker-scripts/
├── bin/
├── lib/
└── modules/

## Usage

1. Run the initialization script
2. Follow the interactive prompts for:
   - Domain configuration
   - Email setup
   - Service selection
   - Credentials configuration
3. Services will be automatically configured and started

## Maintenance

- Credentials are stored securely
- Service configurations can be updated using the provided update scripts
- Each service has its own management scripts in its directory

## Support

For issues or questions, please:
1. Check the service-specific README files
2. Review the logs in the service directories
3. Create an issue in the repository

## License

[MIT License](LICENSE)

## Disclaimer

Please read our [disclaimer](DISCLAIMER.md) for important information about using this software.