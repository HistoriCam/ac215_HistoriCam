# Quick Reference: Image Scraping with Docker

## One-Line Setup

```bash
cd services/scraper && ./docker-shell.sh
```

## Inside Container: Complete Workflow

```bash
# 1. Scrape images (uses existing buildings_names_metadata.csv)
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# 2. Validate images
uv run python src/scraper/validation.py /data/images

# 3. Upload to GCS with versioning
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/image_manifest.csv
```

## Output Locations

When running in Docker, files are saved to:

```
Container Path              → Host Path
------------------------------------------------------
/data/images/              → data/images/
/data/images/1/*.jpg       → data/images/1/*.jpg
/data/image_manifest.csv   → data/images/image_manifest.csv
```

## Common Commands

### Scrape Images
```bash
# Default (max 10 images per building)
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Limit to 5 images per building
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    5
```

### Validate Images
```bash
uv run python src/scraper/validation.py /data/images
```

### GCS Operations
```bash
# Setup bucket (first time only)
uv run python src/scraper/gcs_manager.py setup \
    your-project-id \
    historicam-images

# Upload with versioning
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/image_manifest.csv

# List versions
uv run python src/scraper/gcs_manager.py list historicam-images

# Download specific version
uv run python src/scraper/gcs_manager.py download \
    historicam-images \
    v20251015_143022 \
    /data/downloaded
```

## Environment Variables (Set Before Running)

```bash
# On host, before ./docker-shell.sh
export GCP_PROJECT="your-project-id"
export GCS_BUCKET_NAME="historicam-images"

./docker-shell.sh
```

## Troubleshooting

### Images not downloading
- Check internet connection in container: `ping wikipedia.org`
- Verify QIDs exist: `cat /data/buildings_names_metadata.csv | grep -v "^$" | wc -l`

### GCS authentication failed
```bash
# Inside container, check:
ls -la /secrets/gcs-service-account.json
echo $GOOGLE_APPLICATION_CREDENTIALS
```

### Permission denied on /data
```bash
# On host:
sudo chown -R $(id -u):$(id -g) ../../data/
```

## Exit Container

```bash
exit
# or Ctrl+D
```

Data persists on host in `data/` directory after exiting!
