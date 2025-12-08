FROM python:3.11-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

# Tell uv to copy packages from the wheel into the site-packages
# ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT=/home/app/.venv

# Minimal OS deps; add others only as needed
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      apt-transport-https \
      ca-certificates \
      gnupg && \
      rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
      apt-get update && apt-get install -y google-cloud-sdk && \
      rm -rf /var/lib/apt/lists/*

# Install uv (official)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
      mv /root/.local/bin/uv /usr/local/bin/uv

# Non-root user & workspace
RUN useradd -ms /bin/bash app -u 1000 && \
      mkdir -p /app /app/output && \
      chown -R app:app /app
USER app
WORKDIR /app

# Cache deps
COPY --chown=app:app pyproject.toml /app/

# Generate lockfile and sync dependencies
RUN uv lock && uv sync --frozen

# App code
COPY --chown=app:app . /app

# Entry point
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "exec bash"]