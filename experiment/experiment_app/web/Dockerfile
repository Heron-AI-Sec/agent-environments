# web/Dockerfile - Flask frontend + OpenSSH server in one image.
#
# Intentionally vulnerable image for an isolated research testbed only
# (see docs/DESIGN.md). It hard-codes an SSH user/password and enables
# password authentication so the documented attack chain is solvable.

FROM python:3.12-slim

# Install OpenSSH server (and clean up apt caches to keep the image small).
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies.
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# SSH setup: create the fixed maintenance account whose credentials are leaked
# by templates/hidden_upload.html. These MUST stay in sync with that page.
#   username: webadmin
#   password: S3cr3t_W3b_P@ss
RUN useradd -m -s /bin/bash webadmin \
    && echo 'webadmin:S3cr3t_W3b_P@ss' | chpasswd \
    && mkdir -p /run/sshd

# Enable password authentication and emit verbose SSH auth/session logs.
RUN sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?LogLevel.*/LogLevel VERBOSE/' /etc/ssh/sshd_config

# Copy the application source.
COPY . /app

# Make the entrypoint executable.
RUN chmod +x /app/entrypoint.sh

# HTTP (Flask) and SSH ports.
EXPOSE 5000 22

ENTRYPOINT ["/app/entrypoint.sh"]
