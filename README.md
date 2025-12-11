# HistoriCam

HistoriCam is a mobile-first web application that combines computer vision, geolocation, and historical data to provide instant information about landmarks. Users can point their camera at a building or landmark, and the app will identify it and provide historical context and interesting facts.

Find the live app here: [App](https://ac215-histori-cam.vercel.app/)

For final presentation, find the link here: [https://www.youtube.com/watch?v=uLzQu0OiA5k](https://www.youtube.com/watch?v=uLzQu0OiA5k)

## Architecture

This project follows AC215 MLOps best practices with containerized microservices and GCP deployment:

![Architecture Diagram](docs/design/technical_architecture.png)

We also run the data extraction sperately at the begining but it is not an active component:

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
│   ├── llm-rag/               # RAG pipeline with ChromaDB
│   └── vision/                # Vision model API
│
├── apps/mobile/               # Flutter mobile app
│
├── ml/
│   ├── llm-finetuning/        # LLM fine-tuning experiments
│   └── vision-setup/          # Vision model setup & training
│
├── deployment/                # Kubernetes & GCP deployment configs
├── vision-setup/              # Additional vision model utilities
├── data/                      # Scraped building data & images
├── docs/                      # Project documentation
└── secrets/                   # GCP credentials (gitignored)
```

## Prerequisites

- [uv](https://docs.astral.sh/uv/) - Fast Python package manager
- Docker & Docker Compose
- Python 3.11+
- Flutter SDK 3.0+ (for mobile app)
- GCP account with enabled APIs:
  - Cloud Storage
  - Vertex AI
  - Cloud Run / GKE

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/HistoriCam/ac215_HistoriCam.git
   cd ac215_HistoriCam
   ```

2. **Set up GCP credentials**
   ```bash
   # Create secrets directory
   mkdir -p secrets

   # Add GCP service account
   # Place your service account JSON in secrets/gcs-service-account.json
   ```

3. **Set up Supabase credentials** (for mobile app)
   ```bash
   # Create secrets/supabase_key.env with:
   echo '{"SUPABASE_KEY": "your_api_key"}' > secrets/supabase_key.env
   ```

## Deployment

### Local Development

**Backend Services:**
```bash
# Vision API
cd services/vision
./docker-shell.sh

# LLM-RAG Service
cd ml/llm-rag
./docker-shell.sh
```

**Mobile App:**
```bash
cd apps/mobile
flutter run --dart-define-from-file=../../secrets/supabase_key.env
```

### Production Deployment

**Kubernetes (GKE):**
```bash
cd deployment
kubectl apply -f kubernetes/
```

**Flutter Web (Vercel):**
- Automatically deploys from main branch
- Live at: [ac215-histori-cam.vercel.app](https://ac215-histori-cam.vercel.app/)

## Usage

### Data Collection Pipeline

**Scrape building data:**
```bash
cd services/scraper
./docker-shell.sh
uv run python src/run.py
```

**Upload to GCS:**
```bash
uv run python src/scraper/gcs_manager.py upload $GCS_BUCKET_NAME /data/images
```

### RAG Pipeline

**Process building data:**
```bash
cd ml/llm-rag
./docker-shell.sh
# Place building text files in input-datasets/buildings/
```

### Vision API

**Test prediction:**
```bash
curl -X POST http://localhost:8080/predict \
  -F "file=@/path/to/image.jpg"
```

### Mobile App

1. Open app in browser or device
2. Point camera at landmark
3. Take photo
4. View building information and chat with AI

## CI/CD

### Continuous Integration
- **Linting:** Flutter code analysis on every commit
- **Testing:** Automated unit tests for Flutter app
- **Coverage:** Test coverage reports in [docs/](docs/)

**Untested Features:**
- ChatbotWidget integration
- State transitions
- Error scenarios
- Typing animation

### Continuous Deployment
- **Platform:** Vercel
- **Trigger:** Push to main branch
- **URL:** [https://ac215-histori-cam.vercel.app/](https://ac215-histori-cam.vercel.app/)

## Known Issues and Limitations

### Current Limitations
- Vision model limited to pre-trained landmarks
- RAG database requires manual updates for new buildings
- Mobile app requires camera permissions
- Offline mode not supported

### Known Issues
- Image loading may be slow on low bandwidth
- Camera permissions must be granted on first use
- Some landmarks may not be recognized in poor lighting
- Chat responses depend on GCP API availability

## Development Guides

### Phase 1: Data Collection
Scraper service collects building data from Wikipedia and Wikimedia Commons.

```bash
cd services/scraper
./docker-shell.sh
uv run python src/run.py
```

**Outputs:** `data/buildings_names_metadata.csv`, `data/images/`

### Phase 2: LLM-RAG Pipeline
Process building information for retrieval-augmented generation.

```bash
cd ml/llm-rag
./docker-shell.sh
```

**Components:** ChromaDB vector DB, Vertex AI embeddings, Gemini 2.0 Flash

### Phase 3: Vision Pipeline
Vision model using Vertex AI for landmark recognition.

```bash
cd services/vision
cp .env.example .env  # Add VERTEX_ENDPOINT_ID
./docker-shell.sh
```

### Phase 4: Mobile Application
Flutter web app for user interface.

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define-from-file=../../secrets/supabase_key.env
```

## Team

AC215 Fall 2025

## License

MIT
