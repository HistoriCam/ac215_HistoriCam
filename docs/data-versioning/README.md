# Data Versioning Strategy

## Method: GCS-Based Versioning with Timestamped Snapshots

**Justification:** We use Google Cloud Storage (GCS) with timestamp-based versioning instead of DVC because:
- **Native cloud integration**: Data already lives in GCS for our ML pipeline (Vertex AI embeddings, Cloud Run deployment)
- **Simplicity**: No additional tooling or git-lfs overhead
- **Immutability**: Each version is a complete snapshot in its own GCS prefix
- **Cost-effective**: GCS lifecycle policies can archive old versions automatically

## Version Schema

Versions follow the format: `v{YYYYMMDD}_{HHMMSS}` (e.g., `v20251116_035157`)

Each version is a complete snapshot containing:
- Images (scraped building photos)
- Manifests (image metadata, hashes, building IDs)
- CSV metadata (building names, coordinates, descriptions)
- Generated embeddings (512D multimodal vectors)

## GCS Directory Structure

```
gs://historicam-images/
├── images/
│   └── v20251116_035157/           # Images organized by building ID
│       ├── 1_hash1.jpg
│       ├── 1_hash2.jpg
│       ├── 5_hash3.jpg
│       └── ...
├── manifests/
│   └── v20251116_035157/
│       └── image_manifest.csv       # Image filenames, hashes, building IDs
├── csv/
│   ├── buildings/
│   │   └── v20251116_035157/
│   │       └── buildings_names.csv  # Building IDs and names
│   └── metadata/
│       └── v20251116_035157/
│           ├── buildings_names_metadata.csv
│           └── buildings_info.csv
├── embeddings/
│   └── v20251116_035157/
│       └── multimodal-512d/
│           └── embeddings.jsonl     # Generated 512D embeddings
└── metadata/
    └── versions.json                # Version history and metadata
```

## Version History

All versions are tracked in `gs://historicam-images/metadata/versions.json`:

```json
{
  "versions": [
    {
      "version": "v20251116_035157",
      "created_at": "2025-11-16T03:56:48.528941",
      "images_count": 312,
      "bytes_uploaded": 1614106324,
      "failed_uploads": 0
    }
  ]
}
```

Each entry contains:
- `version`: Timestamp-based version identifier
- `created_at`: ISO 8601 timestamp of creation
- `images_count`: Number of images in this version
- `bytes_uploaded`: Total size of uploaded data
- `failed_uploads`: Count of failed image uploads (for data quality tracking)

## Data Upload Workflow

### 1. Create New Version

```bash
cd services/scraper
./docker-shell.sh

# Inside container:
./upload_all_data.sh historicam-images
# Auto-generates version: v{current_timestamp}

# Or specify custom version:
./upload_all_data.sh historicam-images v20251116_120000
```

The upload script:
1. Uploads all scraped images to `images/{version}/`
2. Uploads image manifest to `manifests/{version}/`
3. Uploads CSV metadata to `csv/{buildings,metadata}/{version}/`
4. Updates `metadata/versions.json` with new version entry

### 2. Generate Embeddings for Version

```bash
cd vision
./docker-shell.sh

# Generate embeddings for specific version
uv run python -m src.embeddings.generate \
  --bucket historicam-images \
  --version v20251116_035157 \
  --exclude-images test_data/test_images.txt \
  --project ac215-historicam

# Or use "latest" tag (resolves to most recent version)
uv run python -m src.embeddings.generate \
  --bucket historicam-images \
  --version latest \
  --exclude-images test_data/test_images.txt \
  --project ac215-historicam
```

Embeddings are saved to: `gs://historicam-images/embeddings/{version}/multimodal-512d/embeddings.jsonl`

## Data Retrieval

### Pull Specific Version

```bash
# Download images from specific version
gsutil -m cp -r gs://historicam-images/images/v20251116_035157/ ./data/images/

# Download manifests
gsutil -m cp -r gs://historicam-images/manifests/v20251116_035157/ ./data/manifests/

# Download CSV metadata
gsutil -m cp -r gs://historicam-images/csv/*/v20251116_035157/ ./data/csv/

# Download embeddings
gsutil cp gs://historicam-images/embeddings/v20251116_035157/multimodal-512d/embeddings.jsonl \
  ./data/embeddings.jsonl
```

### Resolve "latest" Version

The `"latest"` tag is a logical reference that resolves to the most recent version in `versions.json`:

```bash
# Download versions.json
gsutil cp gs://historicam-images/metadata/versions.json ./versions.json

# Extract latest version using Python
VERSION=$(python3 -c "import json; \
  data = json.load(open('versions.json')); \
  print(data['versions'][-1]['version'])")

echo "Latest version: $VERSION"

# Use in downstream commands
gsutil -m cp -r gs://historicam-images/images/$VERSION/ ./data/images/
```

All pipeline scripts (embeddings generation, evaluation) automatically resolve `--version latest` to the actual version.

## Reproducibility Guarantees

1. **Immutable snapshots**: Each version is never modified after creation
2. **Complete lineage**: `versions.json` tracks creation time and metrics for all versions
3. **Deterministic resolution**: "latest" tag always resolves to `versions[-1]` in metadata
4. **Content-addressable images**: Image filenames include SHA256 hash of building ID + image bytes
5. **Manifest tracking**: CSV manifests link images to metadata for full provenance

## Version Lifecycle

### Active Development
- Use `--version latest` for training/evaluation during development
- Automatically picks up most recent data

### Production Deployment
- Pin to specific version in `.env`:
  ```bash
  EMBEDDINGS_PATH=gs://historicam-images/embeddings/v20251116_035157/multimodal-512d/embeddings.jsonl
  ```
- Ensures reproducible production behavior

### Version Rollback
```bash
# Revert to previous version by updating .env
EMBEDDINGS_PATH=gs://historicam-images/embeddings/v20251015_143022/multimodal-512d/embeddings.jsonl

# Regenerate embeddings for old version if needed
uv run python -m src.embeddings.generate \
  --version v20251015_143022 \
  --bucket historicam-images
```