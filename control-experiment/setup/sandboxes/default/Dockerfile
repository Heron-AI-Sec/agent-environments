# Refactor Arena — Default Sandbox
# Ubuntu 22.04-based container for AI control evaluations in code refactoring.
# Supports composable features via the FEATURES build arg.

FROM ubuntu:22.04

ARG FEATURES=""
ENV FEATURES=${FEATURES}
ENV DEBIAN_FRONTEND=noninteractive

# Base system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sudo \
    vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# Create non-root agent user
RUN useradd -m -s /bin/bash -d /home/agent agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/agent

# Create standard directories
RUN mkdir -p /workspace /var/logs /opt/features \
    && chown -R agent:agent /workspace /var/logs

# Copy features and entrypoint
COPY features/ /opt/features/
COPY sandboxes/default/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install enabled features
RUN if [ -n "$FEATURES" ]; then \
        for feature in $(echo "$FEATURES" | tr ',' ' '); do \
            echo "==> Installing feature: $feature"; \
            if [ -f "/opt/features/$feature/install.sh" ]; then \
                chmod +x "/opt/features/$feature/install.sh"; \
                "/opt/features/$feature/install.sh"; \
            else \
                echo "WARNING: Feature $feature has no install.sh, skipping"; \
            fi; \
        done; \
    fi

WORKDIR /workspace
USER agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
