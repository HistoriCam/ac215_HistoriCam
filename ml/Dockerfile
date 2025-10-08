FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-install-project

# Copy source code
COPY src/ ./src/

# Run with uv
CMD ["uv", "run", "python", "src/train.py"]
