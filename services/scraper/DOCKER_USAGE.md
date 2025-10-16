# Docker Usage Guide for Scraper Service

This guide shows how to run the scraper service in Docker for a consistent, reproducible environment.

## Quick Start

### Option 1: Using docker-shell.sh (Recommended)

The easiest way to run the scraper in Docker:

```bash
cd services/scraper

# Build and run in one command
./docker-shell.sh
```

This will:
1. Build the Docker image
2. Mount your code, data, and secrets directories
3. Drop you into an interactive bash shell inside the container
4. Activate the uv virtual environment automatically

### Option 2: Manual Docker Commands

```bash
cd services/scraper

# Build the image
docker build -t historicam-scraper .

# Run interactively
docker run --rm -it \
  -v "$(pwd)":/app \
  -v "$(pwd)/../../data":/data \
  -v "$(pwd)/../../secrets":/secrets \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcs-service-account.json \
  historicam-scraper
```

## Inside the Container

Once inside the container, you'll have access to all scraper commands:

### 1. Scrape Building Names and Metadata

```bash
# Full pipeline
uv run python src/run.py

# Building names only
uv run python src/run.py --skip-metadata

# Metadata only
uv run python src/run.py --metadata-only -i /data/buildings_names.csv
```

Output saved to: `/data/buildings_names.csv` and `/data/buildings_names_metadata.csv`

### 2. Scrape Images from Wikimedia Commons

```bash
# Scrape images for all buildings
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# With custom max images per building
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --max-images 5
```

Output:
- Images saved to: `/data/images/{building_id}/`
- Manifest saved to: `/data/images/image_manifest.csv`

### 3. Validate Images

```bash
# Validate all downloaded images
uv run python src/scraper/validation.py /data/images
```

### 4. Upload to GCS with Versioning

```bash
# Setup bucket (first time only)
uv run python src/scraper/gcs_manager.py setup \
    your-project-id \
    historicam-images

# Upload images
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/image_manifest.csv

# List versions
uv run python src/scraper/gcs_manager.py list historicam-images
```

### 5. Complete Workflow Example

Run everything in sequence:

```bash
# 1. Scrape building data
uv run python src/run.py

# 2. Scrape images
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# 3. Validate images
uv run python src/scraper/validation.py /data/images

# 4. Upload to GCS
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/image_manifest.csv
```

## Volume Mounts Explained

The container mounts three directories:

```
Host                          → Container
------------------------------------------------------
services/scraper/             → /app/              (code)
data/                         → /data/             (output)
secrets/                      → /secrets/          (credentials)
```

**Benefits:**
- Code changes on host are immediately available in container
- Data persists after container stops
- Secrets stay secure, never baked into image

## Environment Variables

Configure via environment variables or `.env` file:

```bash
# GCP Configuration
export GCP_PROJECT="your-project-id"
export GCS_BUCKET_NAME="historicam-images"
export GOOGLE_APPLICATION_CREDENTIALS="/secrets/gcs-service-account.json"

# Scraping Configuration
export MAX_IMAGES_PER_BUILDING="10"
export MIN_IMAGE_WIDTH="224"
export MIN_IMAGE_HEIGHT="224"

# Then run docker
./docker-shell.sh
```

Or create `.env` file in `services/scraper/`:

```bash
GCP_PROJECT=your-project-id
GCS_BUCKET_NAME=historicam-images
MAX_IMAGES_PER_BUILDING=10
```

And use with Docker:

```bash
docker run --rm -it \
  -v "$(pwd)":/app \
  -v "$(pwd)/../../data":/data \
  -v "$(pwd)/../../secrets":/secrets \
  --env-file .env \
  historicam-scraper
```

## Running One-Off Commands

You can run single commands without entering the interactive shell:

```bash
# Scrape images
docker run --rm \
  -v "$(pwd)":/app \
  -v "$(pwd)/../../data":/data \
  -v "$(pwd)/../../secrets":/secrets \
  historicam-scraper \
  -c "uv run python src/scraper/scrape_images.py /data/buildings_names_metadata.csv /data/images"

# Validate images
docker run --rm \
  -v "$(pwd)":/app \
  -v "$(pwd)/../../data":/data \
  historicam-scraper \
  -c "uv run python src/scraper/validation.py /data/images"
```

## Troubleshooting

### Permission Issues

If you get permission errors writing to `/data/`:

```bash
# Check ownership on host
ls -la ../../data/

# Fix ownership (run on host)
sudo chown -R $(id -u):$(id -g) ../../data/
```

### GCS Authentication Errors

Make sure service account JSON exists:

```bash
# Check on host
ls -la ../../secrets/gcs-service-account.json

# Inside container
ls -la /secrets/gcs-service-account.json
echo $GOOGLE_APPLICATION_CREDENTIALS
```

### Image Not Found

Rebuild the image:

```bash
docker build -t historicam-scraper . --no-cache
```

### Code Changes Not Reflected

The `/app` directory is mounted as a volume, so changes should be immediate. If not:

1. Check the volume mount: `docker inspect <container-id>`
2. Restart the container
3. Rebuild if you changed dependencies in `pyproject.toml`

### Dependencies Not Installed

If you added new dependencies to `pyproject.toml`:

```bash
# Rebuild image
docker build -t historicam-scraper .

# Or install inside running container
uv sync
```

## Production Usage

For automated/production scraping:

### Option 1: Cloud Run Job

```bash
# Build for Cloud Run
gcloud builds submit --tag gcr.io/$GCP_PROJECT/historicam-scraper

# Create Cloud Run Job
gcloud run jobs create historicam-scraper \
  --image gcr.io/$GCP_PROJECT/historicam-scraper \
  --set-env-vars GCP_PROJECT=$GCP_PROJECT,GCS_BUCKET_NAME=$GCS_BUCKET_NAME \
  --service-account historicam-scraper@$GCP_PROJECT.iam.gserviceaccount.com
```

### Option 2: Cloud Scheduler

Schedule regular scraping:

```bash
# Create Cloud Scheduler job to trigger Cloud Run Job
gcloud scheduler jobs create http historicam-scraper-daily \
  --schedule="0 2 * * *" \
  --uri="https://run.googleapis.com/v1/projects/$GCP_PROJECT/locations/us-central1/jobs/historicam-scraper:run" \
  --http-method POST \
  --oauth-service-account-email historicam-scraper@$GCP_PROJECT.iam.gserviceaccount.com
```

## Best Practices

1. **Always use docker-shell.sh** for development
2. **Keep secrets out of image** - use volume mounts
3. **Version your images** when deploying to production
4. **Test locally** before deploying to Cloud Run
5. **Monitor GCS costs** as data grows

## Next Steps

- Set up automated scraping with Cloud Scheduler
- Add monitoring/alerting for scraper failures
- Implement incremental scraping (only new buildings)
- Add image quality metrics to monitoring
