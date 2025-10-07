# HistoriCam

Use your current location and phone's camera to identify nearby landmarks, and instantly discover historical or interesting facts about them.

## Project Overview

HistoriCam is a mobile-first web application that combines computer vision, geolocation, and historical data to provide instant information about landmarks. Users can point their camera at a building or landmark, and the app will identify it and provide historical context and interesting facts.

## Architecture

This project follows AC215 MLOps best practices with containerized components and GCP deployment:

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Frontend      │─────▶│   API Service    │─────▶│  ML Model       │
│  (React/Next)   │      │   (FastAPI)      │      │  (Vertex AI)    │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │  Google Cloud    │
                         │  Storage (Data)  │
                         └──────────────────┘
```

## Project Structure

```
ac215_HistoriCam/
├── data-collection/          # Local data gathering scripts (not containerized)
│   ├── scrape_wikipedia_buildings.py
│   └── scraped_data/        # Raw data output (gitignored)
│
├── data-preprocessing/       # Containerized data cleaning pipeline
│   ├── Dockerfile
│   ├── docker-shell.sh
│   └── src/preprocess.py
│
├── model-training/          # Containerized ML training pipeline
│   ├── Dockerfile
│   ├── docker-shell.sh
│   └── src/train.py
│
├── api-service/             # Containerized FastAPI backend
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-shell.sh
│   └── src/main.py
│
├── frontend/                # Containerized React/Next.js frontend
│   ├── Dockerfile
│   ├── docker-shell.sh
│   └── src/
│
├── deployment/              # K8s and Terraform configs
│   ├── kubernetes/
│   └── terraform/
│
├── notebooks/               # Jupyter notebooks for exploration
└── secrets/                 # Service accounts (gitignored)
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

1. **Data Collection (Local)**
   ```bash
   cd data-collection
   uv sync
   uv run python scrape_wikipedia_buildings.py
   ```

2. **Data Preprocessing (Containerized)**
   ```bash
   cd data-preprocessing
   # Update docker-shell.sh with your GCP project ID
   sh docker-shell.sh
   ```

3. **Model Training (Containerized)**
   ```bash
   cd model-training
   sh docker-shell.sh
   ```

4. **API Service (Containerized)**
   ```bash
   cd api-service
   docker-compose up
   # API available at http://localhost:8000
   ```

5. **Frontend (Containerized)**
   ```bash
   cd frontend
   sh docker-shell.sh
   # App available at http://localhost:3000
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
