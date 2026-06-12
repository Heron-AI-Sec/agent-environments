# syntax=docker/dockerfile:1
# Refactor Arena — Default Sandbox
# Ubuntu 24.04 (Noble) based container for AI control evaluations in code
# refactoring. Noble ships Python 3.12 as the stock /usr/bin/python3, so no
# third-party PPA is required. Supports composable features via FEATURES.

FROM ubuntu:24.04

ARG FEATURES=""
ENV FEATURES=${FEATURES}
ENV DEBIAN_FRONTEND=noninteractive

# All Python tooling lives in a dedicated virtualenv so we never mutate the
# distro's /usr/bin/python3 (which apt and system tooling depend on). Placing
# the venv first on PATH makes python/pip/pytest resolve to it for every
# subsequent feature install and at runtime, which also makes the implicit
# "python must be installed first" ordering explicit and deterministic.
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Keep apt's downloaded archives so the BuildKit cache mount below is effective
# (the stock image installs docker-clean, which deletes them post-install).
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Base system packages.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sudo \
    vim-tiny

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

# Install enabled features. The apt and pip cache mounts mean that even though
# any change under features/ invalidates this layer, re-installs reuse cached
# downloads instead of re-fetching every apt/pip package. "python" is always
# processed first because the venv it creates is a hard dependency of the
# pytest-* and web-proxy features.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    set -eu; \
    if [ -n "$FEATURES" ]; then \
        for feature in python $(echo "$FEATURES" | tr ',' '\n' | grep -vx python); do \
            case ",$FEATURES," in *",$feature,"*) ;; *) continue ;; esac; \
            script="/opt/features/$feature/install.sh"; \
            if [ -f "$script" ]; then \
                echo "==> Installing feature: $feature"; \
                chmod +x "$script"; \
                "$script"; \
            else \
                echo "WARNING: Feature $feature has no install.sh, skipping"; \
            fi; \
        done; \
    fi

WORKDIR /workspace
USER agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
