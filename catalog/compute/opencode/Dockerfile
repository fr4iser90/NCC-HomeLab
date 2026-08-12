FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/ubuntu
ENV PATH="/home/ubuntu/.local/bin:/home/ubuntu/.opencode/bin:/usr/local/bin:${PATH}"

# system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    openssh-client \
    sudo \
    python3 \
    python3-pip \
    build-essential \
    unzip \
    wget \
    htop \
    jq \
    ripgrep \
    fd-find \
    tree \
    gnupg \
 && rm -rf /var/lib/apt/lists/*

# docker cli + compose
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y docker-ce-cli docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

# ubuntu user
RUN id ubuntu 2>/dev/null || useradd -m -s /bin/bash ubuntu \
 && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu \
 && groupadd -f docker \
 && usermod -aG docker ubuntu

USER ubuntu
WORKDIR /home/ubuntu

# dirs
RUN mkdir -p /home/ubuntu/.local/bin \
 && mkdir -p /home/ubuntu/.ssh

# github known hosts
RUN ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts || true

# uv install
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# opencode install
RUN curl -fsSL https://opencode.ai/install | bash || true

# persist path
RUN echo 'export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"' >> /home/ubuntu/.bashrc
