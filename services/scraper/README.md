# Scraper Service

Scraper service for collecting Harvard building data and images from various sources. **Extracts at least 4 images per building from different angles** using multiple complementary sources.

## Features

- **Building name scraping** from Wikipedia
- **Metadata scraping** (coordinates, aliases) from Wikidata
- **Multi-source image scraping**: Wikimedia Commons, Google Places Photos, Mapillary, Flickr
- **Image validation** with quality checks (512x512 minimum)
- **Image deduplication** with perceptual hashing
- **GCS upload** with versioning support
- **Target: 4+ images per building (minimum), 20+ images recommended**
- **Diverse angles**: Automatically collects images from different perspectives

## Scripts

### Building Data
- `scrape_building_name.py` - Scrapes building names from Wikipedia categories
- `scrape_metadata.py` - Enriches data with coordinates and aliases from Wikidata

### Image Collection
- `scrape_all_sources.py` - **Unified scraper** for all image sources (recommended)
- `scrape_images.py` - Wikimedia Commons (enhanced with category search)
- `scrape_places.py` - Google Places Photos API
- `scrape_mapillary.py` - Mapillary crowdsourced imagery
- `scrape_flickr.py` - Flickr API with CC license filtering

### Quality Control
- `deduplication.py` - Removes duplicate images using perceptual hashing
- `validation.py` - Validates image quality and format

### Storage
- `gcs_manager.py` - Manages GCS uploads with versioning

## Quick Start

### 1. Prerequisites

**API Keys** (optional but recommended for 4+ images per building):
- **Google Places API**: ~$8 for 150 buildings ([Get key](https://console.cloud.google.com/apis/credentials))
- **Mapillary**: Free ([Get token](https://www.mapillary.com/dashboard/developers))
- **Flickr**: Free ([Get key](https://www.flickr.com/services/api/misc.api_keys.html))

### 2. Setup

You can run the scraper either **locally** or **in Docker**. Docker is recommended for consistency and reproducibility.

#### Option A: Docker (Recommended)

```bash
cd services/scraper

# Set API keys (optional - will use Wikimedia only if not set)
export GOOGLE_MAPS_API_KEY="your-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-key"

# Build and run container
./docker-shell.sh

# Inside the container, run scraper commands
# (see examples below)
```

#### Option B: Local Development

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv sync

# Set API keys
export GOOGLE_MAPS_API_KEY="your-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-key"
```

### 3. Scrape Building Data

```bash
# Full pipeline: names + metadata
uv run python src/run.py

# Output:
# - ../../data/buildings_names.csv (base building data)
# - ../../data/buildings_names_metadata.csv (enriched with coordinates)
```

### 4. Scrape Images from All Harvard Buildings

**This extracts at least 4 images per building from different angles:**

```bash
# Scrape from all sources (minimum 4 images per building)
uv run python src/scraper/scrape_all_sources.py \
    ../../data/buildings_names_metadata.csv \
    ../../data/images \
    --min-images 4 \
    --target 20

# This will automatically:
# 1. Scrape Wikimedia Commons (2-10 images from different angles)
# 2. Scrape Google Places Photos (2-10 user-contributed images)
# 3. Scrape Mapillary (1-5 street-level images)
# 4. Scrape Flickr (1-5 community photos)
# 5. Deduplicate using perceptual hashing
# 6. Validate image quality (512x512 minimum)
# 7. Generate combined_manifest.csv
```

**Without API keys** (Wikimedia only - may not reach 4 images for all buildings):
```bash
# Uses only Wikimedia Commons (free, no API key needed)
uv run python src/scraper/scrape_all_sources.py \
    ../../data/buildings_names_metadata.csv \
    ../../data/images
```

Output structure:
```
data/images/
├── 1/                          # Building ID
│   ├── abc123_wm.jpg          # Wikimedia
│   ├── def456_places.jpg      # Google Places
│   ├── ghi789_mapillary.jpg   # Mapillary
│   └── jkl012_flickr.jpg      # Flickr
├── 2/
│   └── ...
├── image_manifest.csv          # Wikimedia manifest
├── places_manifest.csv         # Google Places manifest
├── mapillary_manifest.csv      # Mapillary manifest
├── flickr_manifest.csv         # Flickr manifest
└── combined_manifest.csv       # All sources (after dedup)
```

### 4. Validate Images (Optional - automatic in unified scraper)

```bash
# Validate all images in directory
uv run python src/scraper/validation.py ../../data/images

# This checks:
# - Minimum dimensions (512x512, preferred 1024x1024)
# - File size limits (max 10MB)
# - Valid image formats (JPEG, PNG, WebP)
# - Aspect ratio (not too narrow/wide)
# - Image integrity (not corrupted)
# - Quality score (0.0-1.0)
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

- **Minimum size**: 512x512 pixels (required for vision models)
- **Preferred size**: 1024x1024 pixels or larger
- **Maximum file size**: 10MB
- **Allowed formats**: JPEG, PNG, WebP
- **Aspect ratio**: Between 0.2 and 5.0 (filters out banners/icons)
- **Integrity check**: Verifies image is not corrupted
- **Quality score**: 0.0-1.0 based on resolution

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

## Multi-Source Image Collection

The scraper supports **four complementary sources** to achieve 20+ images per building:

### Available Sources

1. ✅ **Wikimedia Commons** (enhanced)
   - High-quality, curated images
   - Creative Commons licensed
   - Enhanced with category search
   - ~5-10 images per building
   - **Cost**: Free

2. ✅ **Google Places Photos API** (implemented)
   - User-contributed building photos
   - Good angles and perspectives
   - Better than Street View for buildings
   - ~5-10 images per building
   - **Cost**: ~$0.05 per building (~$8 for 150 buildings)
   - Requires: API key + billing setup

3. ✅ **Mapillary** (implemented)
   - Crowdsourced street imagery
   - Building-oriented filtering
   - Free and open
   - ~3-5 images per building
   - **Cost**: Free!
   - Requires: Free access token

4. ✅ **Flickr API** (implemented)
   - User-contributed photos
   - Seasonal/temporal variety
   - CC license filtering
   - ~3-5 images per building
   - **Cost**: Free (3600 requests/hour)
   - Requires: Free API key

### Scrape from All Sources

```bash
# Set API keys (optional - will skip sources without keys)
export GOOGLE_MAPS_API_KEY="your-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-key"

# Scrape from all sources at once
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --target 20
```

This will:
- ✅ Scrape all available sources (Wikimedia, Places, Mapillary, Flickr)
- ✅ Deduplicate images automatically
- ✅ Validate image quality
- ✅ Generate combined manifest

See [MULTI_SOURCE_GUIDE.md](MULTI_SOURCE_GUIDE.md) for detailed instructions on multi-source scraping.

## Configuration

Create `.env` file in project root:

```bash
# GCP Configuration
GCP_PROJECT=your-project-id
GCS_BUCKET_NAME=historicam-images
GOOGLE_APPLICATION_CREDENTIALS=../../secrets/gcs-service-account.json

# Scraping Configuration
MAX_IMAGES_PER_BUILDING=20
MIN_IMAGE_WIDTH=512
MIN_IMAGE_HEIGHT=512
MAX_IMAGE_SIZE_MB=10

# API Keys (optional)
GOOGLE_MAPS_API_KEY=your-google-places-key
MAPILLARY_ACCESS_TOKEN=MLY|your-mapillary-token
FLICKR_API_KEY=your-flickr-key

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

## Running on Google Cloud Platform (GCP)

This section shows how to run the scraper on GCP for production use.

### Prerequisites

1. **GCP Project** with billing enabled
2. **Service Account** with these permissions:
   - Storage Admin (for GCS)
   - Compute Admin (for VM)
3. **API Keys** set in VM environment variables

### Step 1: Set Up GCS Bucket

```bash
# Create bucket for images
gsutil mb -p your-project-id -c STANDARD -l us-central1 gs://historicam-images

# Enable versioning
gsutil versioning set on gs://historicam-images

# Set up lifecycle management (optional - auto-delete old versions after 90 days)
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 3,
          "daysSinceNoncurrentTime": 90
        }
      }
    ]
  }
}
EOF
gsutil lifecycle set lifecycle.json gs://historicam-images
```

### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create historicam-scraper \
    --display-name="HistoriCam Image Scraper" \
    --project=your-project-id

# Grant Storage Admin permission
gcloud projects add-iam-policy-binding your-project-id \
    --member="serviceAccount:historicam-scraper@your-project-id.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create ./secrets/gcs-service-account.json \
    --iam-account=historicam-scraper@your-project-id.iam.gserviceaccount.com
```

### Step 3: Run Scraper on GCP Compute Engine

```bash
# Create VM instance
gcloud compute instances create historicam-scraper \
    --project=your-project-id \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=50GB \
    --scopes=storage-full \
    --service-account=historicam-scraper@your-project-id.iam.gserviceaccount.com

# SSH into VM
gcloud compute ssh historicam-scraper --zone=us-central1-a

# On the VM: Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Clone repository
git clone https://github.com/your-org/ac215_HistoriCam.git
cd ac215_HistoriCam/services/scraper

# Set API keys
export GOOGLE_MAPS_API_KEY="your-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-key"
export GOOGLE_APPLICATION_CREDENTIALS="/app/secrets/gcs-service-account.json"

# Run scraper in Docker
./docker-shell.sh

# Inside container: Run scraper
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --min-images 4 \
    --target 20
```

### Step 4: Upload to GCS

```bash
# Inside the Docker container or VM
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/combined_manifest.csv

# Verify upload
gsutil ls gs://historicam-images/images/
```

### Step 5: Automate with Cloud Scheduler (Optional)

```bash
# Create Cloud Run job for periodic scraping
gcloud run jobs create historicam-scraper \
    --image=gcr.io/your-project-id/historicam-scraper \
    --region=us-central1 \
    --memory=2Gi \
    --cpu=1 \
    --max-retries=3 \
    --task-timeout=3600s \
    --service-account=historicam-scraper@your-project-id.iam.gserviceaccount.com \
    --set-env-vars GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY,MAPILLARY_ACCESS_TOKEN=$MAPILLARY_ACCESS_TOKEN

# Schedule monthly scraping
gcloud scheduler jobs create http historicam-monthly-scrape \
    --location=us-central1 \
    --schedule="0 0 1 * *" \
    --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/your-project-id/jobs/historicam-scraper:run" \
    --http-method=POST \
    --oauth-service-account-email=historicam-scraper@your-project-id.iam.gserviceaccount.com
```

### Cost Estimation for GCP

**One-time scraping (150 buildings):**
- Compute Engine (e2-medium): ~$0.50/hour × 2 hours = **$1.00**
- API costs (Google Places): **~$8.00**
- GCS Storage: 6 GB × $0.020/GB = **$0.12/month**
- **Total**: ~$9-10 one-time + $0.12/month storage

**Monthly automated scraping:**
- Cloud Run: ~$0.10/execution
- GCS Storage: $0.12/month (grows with versions)
- **Total**: ~$0.22/month

### Quick Reference: Common GCS Commands

```bash
# List all images
gsutil ls gs://historicam-images/images/

# Download all images
gsutil -m cp -r gs://historicam-images/images/ ./local_images/

# Check bucket size
gsutil du -sh gs://historicam-images/

# List versions
uv run python src/scraper/gcs_manager.py list historicam-images

# Delete old version
gsutil rm -r gs://historicam-images/images/v20251015_143022/
```

## Next Steps

1. ✅ **Scrape images**: Run the multi-source scraper for all buildings
2. ✅ **Upload to GCS**: Version and upload to cloud storage
3. **Train vision model**: Use collected images for building recognition
4. **Automate**: Set up Cloud Scheduler for regular scraping
5. **Monitor**: Track data quality metrics over time

## References

- [MULTI_SOURCE_GUIDE.md](MULTI_SOURCE_GUIDE.md) - Detailed multi-source scraping guide
- [QUICK_START.md](QUICK_START.md) - Quick start guide with API setup
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick reference for common commands
