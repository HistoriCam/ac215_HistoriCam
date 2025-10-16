# Scraper Service

Scraper service for collecting Harvard building data and images from various sources.

## Features

- **Building name scraping** from Wikipedia
- **Metadata scraping** (coordinates, aliases) from Wikidata
- **Image scraping** from Wikimedia Commons
- **Image validation** with quality checks
- **GCS upload** with versioning support
- **Extensible** - ready to add more sources (Google Street View, Flickr, etc.)

## Scripts

- `scrape_building_name.py` - Scrapes building names from Wikipedia categories
- `scrape_metadata.py` - Enriches data with coordinates and aliases from Wikidata
- `scrape_images.py` - Downloads images from Wikimedia Commons
- `validation.py` - Validates image quality and format
- `gcs_manager.py` - Manages GCS uploads with versioning

## Quick Start

You can run the scraper either **locally** or **in Docker**. Docker is recommended for consistency and reproducibility.

### Option A: Docker (Recommended)

```bash
cd services/scraper

# Build and run with one command
./docker-shell.sh

# Inside the container, run any scraper commands
# (see examples below)
```

See [DOCKER_USAGE.md](DOCKER_USAGE.md) for detailed Docker instructions.

### Option B: Local Development

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv sync
```

### 2. Scrape Building Data

```bash
# Full pipeline: names + metadata
uv run python src/run.py

# Skip metadata (faster)
uv run python src/run.py --skip-metadata

# Only scrape metadata from existing CSV
uv run python src/run.py --metadata-only -i ../../data/buildings_names.csv
```

Output:
- `../../data/buildings_names.csv` - Base building data
- `../../data/buildings_names_metadata.csv` - Enriched with coordinates and aliases

### 3. Scrape Images

```bash
# Scrape images from Wikimedia Commons
uv run python src/scraper/scrape_images.py \
    ../../data/buildings_names_metadata.csv \
    ../../data/images

# This will:
# - Fetch images for each building using their Wikidata QID
# - Download and validate images
# - Save images organized by building ID
# - Generate image_manifest.csv with metadata
```

Output structure:
```
data/images/
├── 1/                      # Building ID
│   ├── abc123def.jpg       # Image hash
│   └── xyz789abc.jpg
├── 2/
│   └── def456ghi.jpg
└── image_manifest.csv      # Metadata for all images
```

### 4. Validate Images

```bash
# Validate all images in directory
uv run python src/scraper/validation.py ../../data/images

# This checks:
# - Minimum dimensions (224x224)
# - File size limits (max 10MB)
# - Valid image formats (JPEG, PNG, WebP)
# - Aspect ratio (not too narrow/wide)
# - Image integrity (not corrupted)
```

### 5. Upload to GCS (with versioning)

See [GCS_SETUP.md](../../GCS_SETUP.md) for detailed setup instructions.

```bash
# First time: Set up GCS bucket
export GCP_PROJECT="your-project-id"
export BUCKET_NAME="historicam-images"

uv run python src/scraper/gcs_manager.py setup $GCP_PROJECT $BUCKET_NAME

# Upload images with automatic versioning
export GOOGLE_APPLICATION_CREDENTIALS="../../secrets/gcs-service-account.json"

uv run python src/scraper/gcs_manager.py upload \
    $BUCKET_NAME \
    ../../data/images \
    ../../data/images/image_manifest.csv

# List all versions
uv run python src/scraper/gcs_manager.py list $BUCKET_NAME
```

## Data Validation

The scraper includes built-in validation:

### Image Validation Rules

- **Minimum size**: 224x224 pixels (required for ML models)
- **Maximum file size**: 10MB
- **Allowed formats**: JPEG, PNG, WebP
- **Aspect ratio**: Between 0.2 and 5.0 (filters out banners/icons)
- **Integrity check**: Verifies image is not corrupted

### Quality Filters

Images are automatically filtered:
- ✅ Building exteriors
- ✅ Clear, well-lit photos
- ✅ Multiple angles when available
- ❌ Indoor shots (when possible to detect)
- ❌ Very small thumbnails
- ❌ Heavily watermarked images
- ❌ Corrupted files

## Data Versioning

All data uploads to GCS are versioned with timestamps:

```
gs://bucket/images/v20251015_143022/    # Version 1
gs://bucket/images/v20251016_091500/    # Version 2
```

**Version metadata** stored in `gs://bucket/metadata/versions.json`:
```json
{
  "versions": [
    {
      "version": "v20251015_143022",
      "created_at": "2025-10-15T14:30:22Z",
      "images_count": 245,
      "bytes_uploaded": 164234567
    }
  ]
}
```

### Why Versioning?

1. **ML Reproducibility**: Track which data version trained each model
2. **Rollback**: Revert to previous data if issues found
3. **Comparison**: A/B test models with different data versions
4. **Audit Trail**: Know exactly when data changed

## Future Data Sources

The scraper is designed to support multiple image sources:

### Planned Sources

1. ✅ **Wikimedia Commons** (implemented)
2. 🚧 **Google Street View API** (planned)
   - Consistent street-level views
   - Multiple angles
   - Requires API key + billing

3. 🚧 **Flickr API** (planned)
   - Creative Commons images
   - User-contributed photos
   - Free tier available

4. 🚧 **Custom uploads** (planned)
   - User-submitted photos
   - Manual curation

To add a new source, create `scrape_{source}.py` following the pattern in `scrape_images.py`.

## Configuration

Create `.env` file in project root:

```bash
# GCP Configuration
GCP_PROJECT=your-project-id
GCS_BUCKET_NAME=historicam-images
GOOGLE_APPLICATION_CREDENTIALS=../../secrets/gcs-service-account.json

# Scraping Configuration
MAX_IMAGES_PER_BUILDING=10
MIN_IMAGE_WIDTH=224
MIN_IMAGE_HEIGHT=224
MAX_IMAGE_SIZE_MB=10

# Rate Limiting
REQUESTS_PER_SECOND=1
```

## Troubleshooting

### No images found for buildings

- Check that `wikibase_item` (Wikidata QID) exists in your CSV
- Some buildings may not have images in Wikimedia Commons
- Verify internet connection and API access

### Image validation failures

- Images too small: Wikimedia thumbnails, need higher resolution
- Images too large: Reduce `MAX_IMAGE_SIZE_MB` or resize before upload
- Corrupted images: Re-download or skip

### GCS upload errors

- Check `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
- Verify service account has Storage Admin permissions
- Ensure bucket exists and is in same project

## Development

### Run tests (when available)

```bash
uv run pytest tests/
```

### Format code

```bash
uv run black src/
uv run ruff check src/
```

## Next Steps

1. **Scrape images**: Run the image scraper for all buildings
2. **Upload to GCS**: Version and upload to cloud storage
3. **Add more sources**: Integrate Google Street View API
4. **Automate**: Set up Cloud Scheduler for regular scraping
5. **Monitor**: Track data quality metrics over time
