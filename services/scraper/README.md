# Image Scraper Service

Multi-source image scraper for Harvard buildings with GCS integration.

## Features

- **Multi-source scraping**: Wikimedia Commons, Google Places, Mapillary, Flickr
- **Rate limiting**: Built-in delays to avoid 429 errors
- **Image validation**: 512x512 min, format/quality checks
- **Deduplication**: Perceptual hashing
- **GCS versioning**: Shared `lib/gcs_utils` framework
- **Target**: 20+ images/building

## Directory Structure

```
src/image_scraper/
├── scrape_all_sources.py    # Unified multi-source scraper (use this)
├── scrape_images.py          # Wikimedia Commons + categories
├── scrape_places.py          # Google Places Photos API
├── scrape_mapillary.py       # Mapillary street imagery
└── scrape_flickr.py          # Flickr API with CC licenses
```

## Storage

- Uses shared `lib/gcs_utils/` for uploads (NOT local `gcs_manager.py`)
- Upload script: `upload_all_data.sh` (handles images, CSVs, manifests)

## Quick Start

### 1. Docker Setup

```bash
./docker-shell.sh  # Handles secrets, lib, volume mounts
```

### 2. Scrape Images

```bash
# Inside container - scrape all sources
uv run python src/image_scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --target 20

# Outputs: /data/images/{building_id}/{hash}.jpg + manifests
```

### 3. Upload to GCS

```bash
# Uses shared lib/gcs_utils framework
./upload_all_data.sh historicam-images

# Auto-versioning: v20251112_143022
# Uploads: images, CSVs, manifests + metadata tracking
```

## API Keys

Set in Docker environment or `.env`:

```bash
# Optional - scraper works without these
export GOOGLE_MAPS_API_KEY="AIza..."      # ~$8 for 150 buildings
export MAPILLARY_ACCESS_TOKEN="MLY|..."   # Free
export FLICKR_API_KEY="abc..."            # Free
```

See [QUICK_START.md](QUICK_START.md) or [MULTI_SOURCE_GUIDE.md](MULTI_SOURCE_GUIDE.md).

## Image Sources

| Source | Count | Cost | Notes |
|--------|-------|------|-------|
| Wikimedia Commons | 5-10 | Free | Rate limited (0.5-1.5s delays) |
| Google Places | 5-10 | ~$0.05/building | Requires billing |
| Mapillary | 3-5 | Free | Street imagery |
| Flickr | 3-5 | Free | CC licensed |

## GCS Bucket Structure

```
gs://bucket/
├── images/v20251112_143022/{building_id}/{hash}.jpg
├── manifests/v20251112_143022/*.csv
├── csv/buildings/v20251112_143022/buildings_names.csv
├── csv/metadata/v20251112_143022/*.csv
└── metadata/versions.json  # Tracks all versions
```

## Rate Limiting

Wikimedia Commons has aggressive rate limiting:
- 0.5s delay before each API call
- 1.0s delay between image info requests
- 1.5s delay after each download
- Still may hit 429 errors - wait 30-60 min before retrying

## Troubleshooting

- **429 errors**: Wait 30-60 minutes, Wikimedia rate limit is temporary
- **No manifest found**: Run scraper first to generate `*_manifest.csv`
- **GCS auth errors**: Check `GOOGLE_APPLICATION_CREDENTIALS` path
- **Import errors**: Ensure `lib/gcs_utils` is in Python path (Docker handles this)
