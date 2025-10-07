# API Service

Containerized FastAPI backend for HistoriCam.

## Usage

```bash
# Development
sh docker-shell.sh

# Production with docker-compose
docker-compose up
```

## Endpoints

- `POST /identify` - Identify landmark from image + location
- `GET /landmarks/{id}` - Get landmark details
- `GET /health` - Health check
