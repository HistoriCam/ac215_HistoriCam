FROM python:3.11-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

# Non-root user
RUN useradd -ms /bin/bash app -u 1000 && \
    mkdir -p /app && \
    chown -R app:app /app
USER app
WORKDIR /app

# Cache deps
COPY --chown=app:app pyproject.toml /app/

# Generate lockfile and sync dependencies
RUN uv lock && uv sync --frozen

# App code
COPY --chown=app:app . /app

# Expose port
EXPOSE 8080

# Run API
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
