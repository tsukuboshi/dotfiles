# Dev Container Dockerfile
# Reference: https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile
#
# Adjust to match the project's tech stack.

FROM debian:bookworm-slim@sha256:f9c6a2fd2ddbc23e336b6257a5245e31f996953ef06cd13a59fa0a1df2d5c252

ARG TZ=Asia/Tokyo

# Fail a piped RUN (e.g. `curl | sh`) when any stage fails, not just the last
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Timezone
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Base tools and CLIs required by hooks.
# Language runtimes (python/node/terraform/...) are managed by mise via runtime/config.toml,
# so they are intentionally not installed here.
# Versions stay unpinned: the bookworm archive drops superseded package versions
# on every security update, so pins would break the build within weeks.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Dev tools
    git \
    vim \
    nano \
    curl \
    wget \
    unzip \
    jq \
    zsh \
    less \
    xdg-utils \
    # Lint/format CLIs invoked by genai/hooks/post-edit-fmt.sh
    shellcheck \
    ripgrep \
    # mise build deps (required to build python / ruby and other mise-managed runtimes)
    build-essential \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    libyaml-dev \
    zlib1g-dev \
    # Networking (used by the firewall script)
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    # Security
    sudo \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# shfmt (not in the bookworm apt repository; fetch the release binary directly)
ARG SHFMT_VERSION=v3.8.0
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_linux_${ARCH}" \
    -o /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt

# git-secrets (required because common/.gitconfig [secrets] references its provider)
RUN git clone --depth 1 https://github.com/awslabs/git-secrets.git /tmp/git-secrets \
    && make -C /tmp/git-secrets install \
    && rm -rf /tmp/git-secrets

# mise (single source of truth for python/node/pnpm/terraform via runtime/config.toml)
RUN curl -fsSL https://mise.run | sh \
    && mv /root/.local/bin/mise /usr/local/bin/mise

# Create a non-root user
ARG DEV_USER=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $DEV_USER \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $DEV_USER \
    && echo "$DEV_USER ALL=(ALL) NOPASSWD: /usr/local/bin/init-firewall.sh" >> /etc/sudoers.d/$DEV_USER

# Create workspace, history, and language cache directories.
# Named volumes are root-owned on first mount, so chown to the dev user up-front.
RUN mkdir -p /workspace /commandhistory \
    /home/$DEV_USER/.npm \
    /home/$DEV_USER/.local/share/pnpm/store \
    /home/$DEV_USER/.local/share/mise \
    /home/$DEV_USER/.cache/uv \
    /home/$DEV_USER/.cache/pip \
    /home/$DEV_USER/.cache/mise \
    /home/$DEV_USER/.terraform.d/plugin-cache \
    /home/$DEV_USER/.config/mise \
    /home/$DEV_USER/.claude \
    && chown -R $DEV_USER:$DEV_USER /workspace /commandhistory /home/$DEV_USER

# devcontainer environment flag
ENV DEVCONTAINER=true

# Place firewall and post-create scripts
COPY scripts/init-firewall.sh /usr/local/bin/init-firewall.sh
COPY scripts/post-create.sh /usr/local/bin/post-create.sh
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/post-create.sh

USER $DEV_USER
# Add the user's local bin to PATH so the Claude Code installer (and other user-local
# binaries) is reachable in non-interactive shells.
ENV PATH="/home/dev/.local/bin:${PATH}"

# Activate mise for bash (zsh is activated inside the dotfiles .zshrc)
RUN echo "eval \"\$(mise activate bash)\"" >>/home/$DEV_USER/.bashrc

# Install Claude Code into the dev user's ~/.local/bin
RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /workspace
