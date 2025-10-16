# Google Cloud Storage Setup Guide

This guide walks you through setting up GCS for HistoriCam image data with versioning.

## Prerequisites

1. **GCP Project**: Create or use an existing GCP project
2. **Enable APIs**:
   ```bash
   gcloud services enable storage.googleapis.com
   ```
3. **Service Account**: Create a service account with Storage Admin permissions

## Create Service Account

```bash
# Set your project ID
export GCP_PROJECT="your-project-id"

# Create service account
gcloud iam service-accounts create historicam-storage \
    --display-name="HistoriCam Storage Service Account" \
    --project=$GCP_PROJECT

# Grant Storage Admin role
gcloud projects add-iam-policy-binding $GCP_PROJECT \
    --member="serviceAccount:historicam-storage@$GCP_PROJECT.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create secrets/gcs-service-account.json \
    --iam-account=historicam-storage@$GCP_PROJECT.iam.gserviceaccount.com
```

## Set Up GCS Bucket

### Option 1: Using the Python Script

```bash
cd services/scraper
uv sync

# Create and configure bucket
uv run python src/scraper/gcs_manager.py setup \
    your-project-id \
    historicam-images-bucket
```

### Option 2: Using gcloud CLI

```bash
# Set variables
export BUCKET_NAME="historicam-images-$(date +%s)"
export LOCATION="us-central1"

# Create bucket
gcloud storage buckets create gs://$BUCKET_NAME \
    --project=$GCP_PROJECT \
    --location=$LOCATION \
    --uniform-bucket-level-access

# Set lifecycle policy (optional - deletes old versions after 90 days)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 90,
          "matchesPrefix": ["images/v"]
        }
      }
    ]
  }
}
EOF

gcloud storage buckets update gs://$BUCKET_NAME --lifecycle-file=lifecycle.json

echo "✓ Bucket created: gs://$BUCKET_NAME"
```

## Bucket Structure

Your GCS bucket will have this structure:

```
gs://historicam-images-bucket/
├── images/                          # Image files
│   ├── v20251015_143022/           # Version timestamp
│   │   ├── 1/                       # Building ID
│   │   │   ├── abc123def.jpg        # Image hash as filename
│   │   │   └── xyz789abc.jpg
│   │   └── 2/
│   │       └── def456ghi.jpg
│   └── v20251016_091500/           # Another version
│       └── ...
├── manifests/                       # Image metadata
│   ├── v20251015_143022/
│   │   └── image_manifest.csv       # CSV with image metadata
│   └── v20251016_091500/
│       └── image_manifest.csv
├── csv/                             # CSV datasets
│   ├── buildings/
│   │   └── v20251015_143022/
│   │       └── buildings_names.csv
│   └── metadata/
│       └── v20251015_143022/
│           └── buildings_names_metadata.csv
└── metadata/                        # Version tracking
    └── versions.json                # All versions metadata
```

## Configure Authentication

### Local Development

```bash
# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/secrets/gcs-service-account.json"

# Or use gcloud auth
gcloud auth application-default login
```

### In Docker Containers

The service account is already configured in `docker-shell.sh`:

```bash
-v "$SECRETS_DIR":/secrets \
-e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcs-service-account.json
```

## Usage Examples

### 1. Scrape Images and Upload to GCS

```bash
cd services/scraper
uv sync

# Scrape images locally
uv run python src/scraper/scrape_images.py \
    ../../data/buildings_names_metadata.csv \
    ../../data/images

# Upload to GCS with versioning
uv run python src/scraper/gcs_manager.py upload \
    historicam-images-bucket \
    ../../data/images \
    ../../data/images/image_manifest.csv
```

### 2. List Available Versions

```bash
uv run python src/scraper/gcs_manager.py list historicam-images-bucket
```

Output:
```
Available versions:

  v20251015_143022:
    Created: 2025-10-15T14:30:22.123456
    Images: 245
    Size: 156.78 MB

  v20251016_091500:
    Created: 2025-10-16T09:15:00.654321
    Images: 312
    Size: 198.45 MB
```

### 3. Download a Specific Version

```python
from pathlib import Path
from scraper.gcs_manager import GCSDataManager

manager = GCSDataManager("historicam-images-bucket")
manager.download_version(
    version="v20251015_143022",
    local_dir=Path("./downloaded_data"),
    download_images=True,
    download_manifest=True
)
```

## Data Versioning Strategy

### Why Version Data?

1. **Reproducibility**: Track exactly which data was used for training each model
2. **Rollback**: Revert to previous versions if needed
3. **Comparison**: Compare model performance across different data versions
4. **Audit Trail**: Know when and how data changed

### Version Naming

Versions use timestamp format: `vYYYYMMDD_HHMMSS`
- Example: `v20251015_143022` = October 15, 2025 at 14:30:22 UTC

### Best Practices

1. **Create a new version when:**
   - Adding new buildings/images
   - Re-scraping existing data
   - Cleaning/filtering data
   - Changing validation rules

2. **Tag versions in metadata:**
   ```json
   {
     "version": "v20251015_143022",
     "description": "Initial scrape from Wikimedia Commons",
     "buildings_count": 150,
     "images_count": 245
   }
   ```

3. **Track in version control:**
   - Commit the version string to git
   - Link model training runs to data versions

## Cost Estimation

GCS pricing (us-central1):
- **Storage**: $0.020 per GB/month
- **Download**: $0.12 per GB (to internet)
- **Operations**: Minimal cost

Example for 100 buildings with 5 images each (500 images @ 2MB avg):
- Storage: ~1 GB = **$0.02/month**
- With 3 versions: ~3 GB = **$0.06/month**

Very affordable for this use case!

## Monitoring

### View bucket usage:

```bash
gcloud storage du -s gs://historicam-images-bucket
```

### View recent uploads:

```bash
gcloud storage ls -l gs://historicam-images-bucket/images/
```

## Troubleshooting

### Permission Denied Error

```bash
# Verify service account has permissions
gcloud projects get-iam-policy $GCP_PROJECT \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:historicam-storage@*"

# Re-authenticate
export GOOGLE_APPLICATION_CREDENTIALS="secrets/gcs-service-account.json"
```

### Slow Uploads

- Use `gsutil -m` for parallel uploads (multi-threading)
- Consider uploading from a GCP VM in the same region
- Check your internet connection speed

### Version Metadata Missing

```bash
# Manually initialize versions.json
cat > versions.json <<EOF
{
  "versions": [],
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%S)Z"
}
EOF

gcloud storage cp versions.json gs://historicam-images-bucket/metadata/
```

## Next Steps

1. Set up automated scraping (Cloud Scheduler + Cloud Run)
2. Configure bucket notifications for new data
3. Set up monitoring/alerting for storage costs
4. Implement data lineage tracking with Vertex AI Metadata
