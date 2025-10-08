# HistoriCam

Use your current location and phone's camera to identify nearby landmarks, and instantly discover historical or interesting facts about them.

## Project Overview

HistoriCam is a mobile-first web application that combines computer vision, geolocation, and historical data to provide instant information about landmarks. Users can point their camera at a building or landmark, and the app will identify it and provide historical context and interesting facts.

## Architecture

This project follows AC215 MLOps best practices with containerized microservices and GCP deployment:

```
┌──────────────────┐
│  Scraper Service │──┐
└──────────────────┘  │
                      ▼
              ┌──────────────────┐
              │  Google Cloud    │
              │  Storage (Data)  │
              └──────────────────┘
                      │
                      ▼
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Mobile App     │─────▶│   API Service    │─────▶│  ML Pipeline    │
│  (Flutter)      │      │   (FastAPI)      │      │  (Vertex AI)    │
└─────────────────┘      └──────────────────┘      └─────────────────┘
```

## Project Structure

```
ac215_HistoriCam/
├── services/                 # Containerized microservices
│   ├── scraper/             # data scraper service
│   │   ├── Dockerfile
│   │   ├── pyproject.toml   # uv package configuration
│   │   ├── README.md
│   │   └── src/
│   │       ├── run.py       # Main CLI entry point
│   │       └── scraper/
│   │           ├── scrape_building_name.py      # Initial building name scraper
│   │           └── scrape_metadata.py           # Metadata scraper (lat/lon/aliases)
│   │
│   └── api/                 # FastAPI backend service
│       ├── Dockerfile
│       └── src/
│
├── apps/                    # Frontend applications
│   └── mobile/             # Mobile-first web application
│
├── ml/                     # Machine learning pipelines
│   └── src/               # Training and inference code
│
├── data/                   # Data directory
│   ├── buildings_names.csv              # Base building data
│   └── buildings_names_metadata.csv     # Enriched with lat/lon/aliases
│
└── secrets/               # Service accounts and credentials (gitignored)
```

## Getting Started

### Prerequisites

- [uv](https://docs.astral.sh/uv/) - Fast Python package manager
- Docker & Docker Compose
- Python 3.11+
- Node.js 20+ (for frontend)
- GCP account with enabled APIs:
  - Cloud Storage
  - Vertex AI
  - Cloud Run / GKE

### Setup

1. **Data Collection (Scraper Service)**
   ```bash
   cd services/scraper
   uv sync

   # Full scrape (building names + metadata)
   uv run python src/run.py

   # Skip metadata scraping
   uv run python src/run.py --skip-metadata

   # Scrape metadata only from existing CSV
   uv run python src/run.py --metadata-only -i ../../data/buildings_names.csv
   ```

   Output files:
   - `data/buildings_names.csv` - Base building data (id, name, source_url, etc.)
   - `data/buildings_names_metadata.csv` - Enriched data with latitude, longitude, and aliases

2. **API Service (Containerized)**
   ```bash
   cd services/api
   docker-compose up
   # API available at http://localhost:8000
   ```

3. **Frontend (Containerized)**
   ```bash
   cd apps/mobile
   # TBD: Docker setup
   # App available at http://localhost:3000
   ```

4. **ML Pipeline (Containerized)**
   ```bash
   cd ml
   # TBD: Training pipeline
   ```

## Development Workflow

1. **Package Management**: This project uses [uv](https://docs.astral.sh/uv/) for fast, reliable Python dependency management
   - Each Python component has a `pyproject.toml` for dependencies
   - Docker images use the official uv base image for optimal caching
   - Run `uv sync` to install dependencies locally
   - Run `uv lock` to update the lockfile after changing dependencies
2. **Local Development**: Use `docker-shell.sh` in each component for development
3. **Data Flow**: GCS buckets for data transfer between components (don't bundle data in containers)
4. **Secrets**: Place service account JSON files in `secrets/` directory
5. **CI/CD**: GitHub Actions → Docker Hub → GCP deployment

## Deployment

Deploy to GCP using Kubernetes:

```bash
cd deployment/kubernetes
kubectl apply -f .
```

Or use Terraform for infrastructure:

```bash
cd deployment/terraform
terraform init
terraform apply
```

## Tech Stack

- **Package Management**: uv
- **Frontend**: React/Next.js, TailwindCSS
- **Backend**: FastAPI, Python
- **ML**: TensorFlow/PyTorch, Vertex AI
- **Storage**: Google Cloud Storage
- **Deployment**: GKE, Cloud Run
- **CI/CD**: GitHub Actions, Docker

## Team

AC215 Fall 2024

## License

MIT
