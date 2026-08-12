#!/bin/bash

docker run --rm -it \
  # Beschreibbarer Laufzeit-/Konfigurationsordner
  -v "$HOME/opencode/container-data:/home/ubuntu/.local" \
  -v "$HOME/opencode/container-data/config:/home/ubuntu/.config/opencode" \
  # Beschreibbarer Projekt-Workspace
  -v "$HOME/opencode/projects:/workspace" \
  -w /workspace \
  # Sicherstellen, dass OpenCode AI-Binary im PATH ist
  -e PATH="/home/fr4iser/.opencode/bin:${PATH}" \
  opencode-ai:latest \
  opencode
