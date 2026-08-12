# OpenCode AI Dev Environment
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# =========================
# System Dependencies
# =========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    openssh-client \
    sudo \
    nano \
    unzip \
    jq \
    ripgrep \
    fzf \
    htop \
    build-essential \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*


# =========================
# Python Setup
# =========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
 && rm -rf /var/lib/apt/lists/*

# Python tooling (lint/format/typecheck)
RUN pip3 install --no-cache-dir \
    black \
    ruff \
    pylint \
    mypy


# =========================
# Node.js (LTS) + npm
# =========================
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get install -y nodejs

# Global JS dev tools
RUN npm install -g \
    eslint \
    prettier \
    typescript \
    ts-node \
    yarn


# =========================
# Docker CLI (optional tooling inside container)
# =========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker-cli \
 && rm -rf /var/lib/apt/lists/*


# =========================
# User Setup
# =========================
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu \
 && echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu


# =========================
# SSH Setup for GitHub
# =========================
RUN mkdir -p /home/ubuntu/.ssh \
 && touch /home/ubuntu/.ssh/known_hosts \
 && ssh-keyscan -T 5 github.com >> /home/ubuntu/.ssh/known_hosts 2>/dev/null || true


# =========================
# OpenCode AI Install
# =========================
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH="/home/ubuntu/.opencode/bin:${PATH}"


# =========================
# Default Shell
# =========================
CMD ["/bin/bash"]
