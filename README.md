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
│   ├── buildings_names_metadata.csv     # Enriched with lat/lon/aliases
│   ├── buildings_info.csv               # Comprehensive building information
│   └── image_data.csv                   # Image data from Wikipedia baseline scrape
│
└── secrets/               # Service accounts and credentials (gitignored)
```

## Getting Started

### Prerequisites

- [uv](https://docs.astral.sh/uv/) - Fast Python package manager
- Docker & Docker Compose
- Python 3.11+
- Flutter SDK 3.0+ (for mobile app)
- GCP account with enabled APIs:
  - Cloud Storage
  - Vertex AI
  - Cloud Run / GKE

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/HistoriCam/ac215_HistoriCam.git
   cd ac215_HistoriCam
   ```

2. **Set up GCP credentials** (if using cloud storage)
   - Follow the complete setup guide in [GCS_SETUP.md](GCS_SETUP.md)
   - Place service account JSON in `secrets/gcs-service-account.json`
   - The secrets directory is gitignored for security

## Complete Pipeline Guide

### Phase 1: Data Collection (Scraper Service)

The scraper service collects building data and images from Wikipedia and Wikimedia Commons.

#### Using Docker (Recommended)

```bash
cd services/scraper

# Build and enter container with mounted volumes
./docker-shell.sh

# Inside container - Full pipeline (names + metadata + images)
uv run python src/run.py
uv run python src/scraper/scrape_images.py /data/buildings_names_metadata.csv /data/images

# Upload to GCS with versioning (optional)
uv run python src/scraper/gcs_manager.py upload \
    $GCS_BUCKET_NAME \
    /data/images \
    /data/images/image_manifest.csv
```

#### Using Local Python (Alternative)

```bash
cd services/scraper

# Install dependencies with uv
uv sync

# Run scraping pipeline
# Step 1: Scrape building names from Wikipedia
uv run python src/run.py

# Step 2: Scrape images from Wikimedia Commons
uv run python src/scraper/scrape_images.py \
    ../../data/buildings_names_metadata.csv \
    ../../data/images

# Step 3: Validate images (optional)
uv run python src/scraper/validation.py ../../data/images

# Step 4: Upload to GCS (optional, requires GCP setup)
export GOOGLE_APPLICATION_CREDENTIALS="../../secrets/gcs-service-account.json"
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    ../../data/images \
    ../../data/images/image_manifest.csv
```

**Output Files:**
- `data/buildings_names.csv` - Base building data (id, name, source_url)
- `data/buildings_names_metadata.csv` - Enriched with lat/lon/aliases from Wikidata
- `data/buildings_info.csv` - Comprehensive building information
- `data/image_data.csv` - Image data from Wikipedia baseline scrape
- `data/images/` - Downloaded images organized by building ID
- `data/images/image_manifest.csv` - Image metadata (URLs, dimensions, hashes)

**Available CLI Options:**
```bash
# Skip metadata scraping (faster)
uv run python src/run.py --skip-metadata

# Only scrape metadata from existing CSV
uv run python src/run.py --metadata-only -i ../../data/buildings_names.csv

# Scrape specific number of images per building
uv run python src/scraper/scrape_images.py <csv> <output_dir> --max-images 5
```

**Docker Details:**
- **Dockerfile**: Uses Python 3.11 slim with uv package manager
- **Volumes**: Mounts source code, data directory, and secrets
- **pyproject.toml**: Dependencies include requests, google-cloud-storage, pillow, pandas

### Phase 2: ML Training Pipeline

The ML pipeline trains image classification models using Vertex AI.

```bash
cd ml

# Build Docker image
docker build -t historicam-ml .

# Run training (customize as needed)
docker run --rm \
  -v "$(pwd)/data":/app/data \
  -v "$(pwd)/models":/app/models \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/gcs-service-account.json \
  historicam-ml

# Or run locally with uv (when pyproject.toml is added)
# uv run python src/train.py
```

**Docker Details:**
- **Dockerfile**: Uses official uv base image (ghcr.io/astral-sh/uv:python3.11-bookworm-slim)
- **Entry point**: `uv run python src/train.py`
- **Data**: Fetches versioned data from GCS

### Phase 3: API Service (Backend)

The FastAPI service provides REST endpoints for the mobile app.

```bash
cd services/api

# Option 1: Docker (when docker-compose.yml is ready)
# docker-compose up
# API available at http://localhost:8000

# Option 2: Local development
uv sync
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

**Docker Details:**
- **Dockerfile**: TBD (to be implemented)
- **pyproject.toml**: Dependencies include requests (FastAPI to be added)
- **Endpoints**: Will serve predictions and building information

### Phase 4: Mobile Application

The Flutter mobile app provides the user interface.

```bash
cd apps/mobile

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for production
flutter build apk --release              # Android
flutter build ios --release              # iOS (macOS only)
```

**Platform-specific setup:**
- **Android**: Requires Android Studio and Android SDK
- **iOS**: Requires Xcode (macOS only) and CocoaPods
- See [apps/mobile/README.md](apps/mobile/README.md) for detailed instructions

**Key Features:**
- Camera integration for capturing building photos
- Real-time image recognition (API integration ready)
- Interactive chatbot for building information
- Tour suggestions for nearby historic sites

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
