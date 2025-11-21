# HistoriCam

HistoriCam is a mobile-first web application that combines computer vision, geolocation, and historical data to provide instant information about landmarks. Users can point their camera at a building or landmark, and the app will identify it and provide historical context and interesting facts.

## Milestone 4 Specifics

here is a demo of the full pipeline running locally: [video](https://drive.google.com/file/d/1xDccEPMYJSxnadXA0BW5U6aER20OuOAM/view?usp=sharing)

## Architecture

This project follows AC215 MLOps best practices with containerized microservices and GCP deployment:

![Architecture Diagram](design/HistoriCam_architecture.png)

```
┌──────────────────┐        ┌──────────────────┐
│  Scraper Service │ -----> │    GCP Bucket    │
└──────────────────┘        └──────────────────┘
```

## Project Structure

```
ac215_HistoriCam/
├── services/                   # Backend microservices (FastAPI)
│   ├── scraper/               # Data collection & image scraping
│   ├── api/                   # Main API service
│   └── vision/                # Vision model API (Cloud Run)
│
├── apps/mobile/               # Flutter mobile app
│
├── ml/
│   ├── llm-rag/              # RAG pipeline with ChromaDB
│   └── vision-model/         # Vision model training
│
├── data/                      # Scraped building data & images
├── design/                    # UI/UX mockups
└── secrets/                   # GCP credentials (gitignored)
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

### Phase 1.5: LLM-RAG Pipeline

The LLM-RAG service processes building information to create a retrieval-augmented generation system for answering questions about buildings.

#### Prerequisites

1. **Set up GCP credentials**
   - Place service account JSON in `secrets/llm-service-account.json`
   - Update `GCP_PROJECT` in `docker-shell.sh` with your project ID

2. **Prepare input data**
   - Place building text files in `ml/llm-rag/input-datasets/buildings/`
   - Each file should be named `[Building Name].txt` with building information

#### Running the LLM-RAG Container

```bash
cd ml/llm-rag

# Build and start containers (ChromaDB + LLM-RAG CLI)
./docker-shell.sh

# Inside container - Full RAG pipeline:

# Step 1: Chunk the text data
uv run python cli.py --chunk --chunk_type char-split

# Step 2: Generate embeddings
uv run python cli.py --embed --chunk_type char-split

# Step 3: Load embeddings into ChromaDB
uv run python cli.py --load --chunk_type char-split

# Step 4: Test with a query
uv run python cli.py --query --chunk_type char-split

# Step 5: Chat with the LLM (RAG-enabled)
uv run python cli.py --chat --chunk_type char-split

# Step 6: Use the LLM agent
uv run python cli.py --agent --chunk_type char-split
```

#### Alternative Chunking Methods

```bash
# Character-based splitting (default)
uv run python cli.py --chunk --chunk_type char-split

# Recursive character splitting
uv run python cli.py --chunk --chunk_type recursive-split

# Semantic splitting (groups by meaning)
uv run python cli.py --chunk --chunk_type semantic-split
```

#### Pipeline Architecture

The LLM-RAG system:
1. **Chunks** text into manageable pieces
2. **Embeds** chunks using Vertex AI text-embedding-004
3. **Stores** embeddings in ChromaDB vector database
4. **Retrieves** relevant chunks based on query similarity
5. **Generates** responses using Gemini 2.0 Flash with retrieved context

**Docker Components:**
- **llm-rag-cli**: Main CLI for processing and querying
- **chromadb**: Vector database for storing embeddings (persistent storage)
- **Network**: Custom `llm-rag-network` for inter-container communication

**Configuration:**
- Embedding model: `text-embedding-004` (256 dimensions)
- Generative model: `gemini-2.0-flash-001`
- Vector DB: ChromaDB with cosine similarity
- Port: ChromaDB exposed on `8000`

**Output Files:**
- `ml/llm-rag/outputs/chunks-[method]-[building].jsonl` - Chunked text
- `ml/llm-rag/outputs/embeddings-[method]-[building].jsonl` - Embedded chunks
- `ml/llm-rag/docker-volumes/chromadb/` - Persistent vector database

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
flutter build web --release  
```

**Platform-specific setup:**
- **Android**: Requires Android Studio and Android SDK
- **iOS**: Requires Xcode (macOS only) and CocoaPods
- See [apps/mobile/README.md](apps/mobile/README.md) for detailed instructions

## Team

AC215 Fall 2024

## License

MIT
