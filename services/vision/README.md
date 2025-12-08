# HistoriCam Vision Service

Microservice for identifying Harvard buildings from images using in-memory embedding similarity.

## Architecture

This service provides fast, exact similarity search for building identification:
- Loads 252 embeddings (~500KB) into memory at startup
- Computes exact cosine similarity with all indexed buildings
- Returns top-k matches with confidence scores
- Perfect for datasets with <1000 images

## Setup

### Prerequisites

- Generated embeddings JSONL file in GCS (see `../../vision/README.md`)
- GCP service account key in `../../secrets/gcs-service-account.json`

### Environment Variables

Create a `.env` file from the template:

```bash
cp .env.example .env
```

Edit `.env` and set your values:

```bash
# Required
EMBEDDINGS_PATH=gs://historicam-images/embeddings/v20251116_035157/multimodal-512d/embeddings.jsonl

# Optional (defaults shown)
GCP_PROJECT=ac215-historicam
GCP_LOCATION=us-central1
EMBEDDING_DIMENSION=512
TOP_K=5
CONFIDENCE_THRESHOLD=0.7
BACKUP_THRESHOLD=0.4
```

The `docker-shell.sh` script will automatically load these variables from `.env`.

## Usage

### Run Locally

```bash
# 1. Set up environment (first time only)
cp .env.example .env
# Edit .env with your VERTEX_ENDPOINT_ID

# 2. Start API server
./docker-shell.sh
```

API will be available at `http://localhost:8080`


### Test the API

```bash
# Download a test image from GCS (first time only)
./download_test_images.sh

# Run automated tests (validates API works)
uv run python test_api.py

# Or test with a specific image
uv run python test_api.py --image path/to/building.jpg --expected-building 5

# Test deployed API
uv run python test_api.py --url https://historicam-vision-<hash>-uc.a.run.app
```

### API Endpoints

**Health Check**
```bash
curl http://localhost:8080/
```

**Identify Building**
```bash
curl -X POST http://localhost:8080/identify \
  -F "image=@path/to/building-photo.jpg"
```

**Response Format**:
```json
{
  "status": "confident" | "uncertain" | "no_match",
  "building_id": "23",
  "confidence": 0.85,
  "matches": [
    {"building_id": "23", "similarity": 0.85},
    {"building_id": "23", "similarity": 0.82}
  ]
}
```

## Classification Logic

The service uses a majority voting system:

1. **Confident Match** (`status: "confident"`)
   - Multiple top-k results above `CONFIDENCE_THRESHOLD` (default 0.7)
   - Returns most common building ID
   
2. **Uncertain Match** (`status: "uncertain"`)
   - Results above `BACKUP_THRESHOLD` (default 0.4)
   - Lower confidence - building might be nearby
   
3. **No Match** (`status: "no_match"`)
   - All results below backup threshold
   - Image doesn't match any known buildings

## Finding Optimal Parameters

Before deploying to production, run evaluation to find optimal `TOP_K`, `CONFIDENCE_THRESHOLD`, and `BACKUP_THRESHOLD`:

```bash
# 1. Run evaluation with default parameters
cd ../../vision
./docker-shell.sh
uv run python -m src.evaluation.evaluate \
  --embeddings-path gs://historicam-images/embeddings/v20251116_035157/multimodal-512d/embeddings.jsonl \
  --project ac215-historicam \
  --bucket historicam-images \
  --top-k 5 \
  --threshold 0.7

# 2. Try different parameter combinations
# Adjust based on accuracy results

# 3. Update .env with optimal values
```

The evaluation script shows:
- Overall accuracy on test set (68 held-out images)
- Breakdown by status (confident/uncertain/no_match)
- Per-building accuracy for buildings with errors

See [../../vision/README.md](../../vision/README.md) for details.

## Complete Workflow

**From data collection to production deployment:**

1. **Generate embeddings** (from `../../vision/`)
   ```bash
   cd ../../vision
   ./docker-shell.sh
   uv run python -m src.embeddings.generate \
     --bucket historicam-images \
     --version latest \
     --exclude-images test_data/test_images.txt \
     --project ac215-historicam
   ```

2. **Evaluate parameters** (from `../../vision/`)
   ```bash
   uv run python -m src.evaluation.evaluate \
     --embeddings-path gs://historicam-images/embeddings/.../embeddings.jsonl \
     --project ac215-historicam \
     --bucket historicam-images \
     --top-k 5 \
     --threshold 0.7
   ```

3. **Update vision service config**
   ```bash
   cd ../services/vision
   # Edit .env with embeddings path and optimal parameters
   EMBEDDINGS_PATH=gs://historicam-images/embeddings/.../embeddings.jsonl
   TOP_K=5
   CONFIDENCE_THRESHOLD=0.7
   BACKUP_THRESHOLD=0.4
   ```

4. **Test locally**
   ```bash
   ./docker-shell.sh
   # In another terminal:
   uv run python test_api.py
   ```

5. **Deploy to Cloud Run**
   ```bash
   ./deploy-cloud-run.sh
   # Test deployed service:
   uv run python test_api.py --url <DEPLOYED_URL>
   ```

## Testing in GitHub Actions

The test script is designed to work in CI/CD:

```yaml
# .github/workflows/test-vision-service.yml
- name: Test Vision Service
  run: |
    cd services/vision
    python test_api.py --url ${{ env.API_URL }}
```
