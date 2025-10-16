FROM python:3.11-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

# Tell uv to copy packages from the wheel into the site-packages
# ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT=/home/app/.venv

# Minimal OS deps; add others only as needed
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl && \
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
# Get into the uv virtual environment shell
CMD ["-c", "source /home/app/.venv/bin/activate && exec bash"]