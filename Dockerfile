FROM python:3.12-slim-bookworm
LABEL maintainer="ttek.com"

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies including Node.js and PostgreSQL dev libraries
ARG NODE_MAJOR=22
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        # PostgreSQL client and development libraries (for psycopg2)
        postgresql-client \
        libpq-dev \
        # Compiler and build tools (for psycopg2 and other Python packages)
        gcc \
        # Image processing libraries (for Pillow/PIL)
        libjpeg62-turbo-dev \
        zlib1g-dev && \
    # Add NodeSource repository for latest Node.js
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    # Cleanup to reduce image size
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt-get clean && \
    # Create non-root user
    useradd --create-home --shell /bin/bash app_user && \
    # Create necessary directories
    mkdir -p /vol/web/media /vol/web/static && \
    chown -R app_user:app_user /vol /app

# Copy requirements as root, then install
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

ARG DEV=false
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ]; then \
        pip install --no-cache-dir -r /tmp/requirements.dev.txt; \
    fi && \
    rm -rf /tmp

# Switch to non-root user
USER app_user

# Copy application code
COPY --chown=app_user:app_user . /app

# Verify Node.js and npm installation
RUN node --version && npm --version

EXPOSE 8000

# Set PATH to include user's local bin
ENV PATH="/home/app_user/.local/bin:$PATH"