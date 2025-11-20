# HistoriCam API

FastAPI service for identifying Harvard buildings from images using Vertex AI Vector Search.

## Setup

### Prerequisites

- Deployed Vertex AI Vector Search index (see `vision/README.md`)
- GCP service account key in `../../secrets/gcs-service-account.json`
- Endpoint ID and Deployed Index ID from index deployment

### Environment Variables

Set these before running `./docker-shell.sh`:

```bash
export VERTEX_ENDPOINT_ID="your-endpoint-id"
export DEPLOYED_INDEX_ID="historicam-buildings-v1"
export GCP_PROJECT="ac215-historicam"
```

Optional configuration:
```bash
export TOP_K="5"                      # Number of neighbors to retrieve
export CONFIDENCE_THRESHOLD="0.7"     # Similarity threshold for confident match
export BACKUP_THRESHOLD="0.4"         # Similarity threshold for uncertain match
```

## Usage

### Run Locally

```bash
# Set endpoint ID (required)
export VERTEX_ENDPOINT_ID="1234567890123456789"

# Start API server
./docker-shell.sh
```

API will be available at `http://localhost:8080`

### API Endpoints

**Health Check**
```bash
curl http://localhost:8080/
```

**Identify Building**
```bash
curl -X POST http://localhost:8080/api/identify \
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

## Testing

See `vision/src/evaluation/` for evaluation scripts to test accuracy against held-out test set.
