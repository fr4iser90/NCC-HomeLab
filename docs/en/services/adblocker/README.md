# Adblocker Services

Adblocker services block ads and tracking at network level.

## Services

- [Pi-hole](./pihole.md) - DNS-based Ad Blocker

## Overview

Pi-hole blocks ads and tracking for the entire network via DNS filtering.

## Setup

1. Deploy Pi-hole
2. Set router DNS to Pi-hole IP
3. Configure web UI

## Important

- DNS ports must use `mode: host` (Routing Mesh doesn't work for DNS)
- Pi-hole should run on a fixed node (consistent DNS)

