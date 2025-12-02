# Honeypot Services

Honeypot services detect attacks and slow down attackers.

## Services

- [Tarpit](./tarpit.md) - Security Honeypot

## Overview

Tarpit is a security honeypot that detects attacks and slows down attackers.

## Features

- SSH honeypot
- HTTP honeypot
- Attacker slowdown
- Logging & monitoring

## Setup

1. Deploy Tarpit
2. Configure ports (not on real ports!)
3. Set up monitoring (optional)

## Important

- ⚠️ Should run on separate ports (not port 22/80!)
- Keep isolated from real services
- Monitoring with Prometheus/Grafana possible

