# Quick Start: Collecting 20+ Images Per Building

Get started collecting images from multiple sources in 5 minutes.

## Step 1: Get API Keys (5 minutes)

### Google Maps (Recommended)
1. Go to https://console.cloud.google.com/apis/credentials
2. Enable "Places API" (for building photos)
3. Create API key
4. Set up billing (required, but $300 free credit)
5. Copy key

### Mapillary (Recommended - Free!)
1. Create account at https://www.mapillary.com/
2. Go to https://www.mapillary.com/dashboard/developers
3. Create an application
4. Copy the "Client Token" (this is your access token)
5. Free tier with generous limits

### Flickr (Optional)
1. Go to https://www.flickr.com/services/api/misc.api_keys.html
2. Apply for non-commercial key
3. Copy key

## Step 2: Set Environment Variables

```bash
# Recommended for Places Photos
export GOOGLE_MAPS_API_KEY="AIza..."

# Recommended for Mapillary (free!)
export MAPILLARY_ACCESS_TOKEN="MLY|abc..."

# Optional for Flickr
export FLICKR_API_KEY="abc..."

# Optional for GCS upload
export GOOGLE_APPLICATION_CREDENTIALS="../../secrets/gcs-service-account.json"
```

## Step 3: Run Docker

```bash
cd services/scraper
./docker-shell.sh
```

## Step 4: Scrape Images

### Option A: All Sources (Recommended - 20+ images per building)

```bash
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images
```

This automatically:
- Scrapes Wikimedia Commons (enhanced with categories)
- Scrapes Google Places Photos (if key set)
- Scrapes Mapillary (if token set)
- Scrapes Flickr (if key set)
- Deduplicates images
- Validates quality

### Option B: Individual Sources

```bash
# Wikimedia only (free, 5-10 images/building with category search)
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Google Places only (~$8 for 150 buildings, 5-10 images/building)
uv run python src/scraper/scrape_places.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Mapillary only (free, 3-5 images/building)
uv run python src/scraper/scrape_mapillary.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Flickr only (free, 3-5 images/building)
uv run python src/scraper/scrape_flickr.py \
    /data/buildings_names_metadata.csv \
    /data/images
```

## Step 5: Upload to GCS (Optional)

```bash
# Setup bucket (first time only)
uv run python src/scraper/gcs_manager.py setup \
    your-project-id \
    historicam-images

# Upload with versioning
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/combined_manifest.csv
```

## Expected Results

For **150 Harvard buildings**:

| Source | Images | Cost | Time |
|--------|--------|------|------|
| Wikimedia (enhanced) | ~750-1,050 | $0 | 10-15 min |
| Google Places | ~750-1,200 | ~$8 | 10-15 min |
| Mapillary | ~450-600 | $0 | 15-20 min |
| Flickr | ~450-600 | $0 | 15-20 min |
| **Total** | **~2,400-3,450** | **~$8** | **50-70 min** |

After deduplication: **~2,200-3,000 unique images**

Average: **15-20 images per building** (target: 20+)

## Verify Results

```bash
# Check total images
ls /data/images/*/  | wc -l

# Check manifest
head -20 /data/images/combined_manifest.csv

# Validate images
uv run python src/scraper/validation.py /data/images
```

## Troubleshooting

### "403 Forbidden" from Google Places
- Check API key is set: `echo $GOOGLE_MAPS_API_KEY`
- Verify Places API is enabled (not Street View Static API)
- Ensure billing is set up

### "401 Unauthorized" from Mapillary
- Check token is set: `echo $MAPILLARY_ACCESS_TOKEN`
- Verify you copied the "Client Token" from your app
- Token should start with "MLY|"

### "No images found"
- Normal for some buildings
- Wikimedia: ~70% coverage (improved with category search)
- Google Places: ~80% coverage
- Mapillary: ~40% coverage (requires coordinates)
- Flickr: ~50% coverage

### Images look low quality
- Check validation: `uv run python src/scraper/validation.py /data/images`
- Adjust thresholds in `validation.py` if needed

## Next Steps

1. **Review images** - Spot check a few buildings
2. **Upload to GCS** - Version and backup your data
3. **Train model** - Use diverse image dataset
4. **Monitor** - Track buildings with <20 images

## Full Documentation

- [README.md](README.md) - Complete scraper documentation
- [MULTI_SOURCE_GUIDE.md](MULTI_SOURCE_GUIDE.md) - Detailed multi-source guide
- [DOCKER_USAGE.md](DOCKER_USAGE.md) - Docker-specific instructions
- [GCS_SETUP.md](../../GCS_SETUP.md) - GCS setup guide

## Cost Summary

One-time costs:
- Google Places API: **~$8** (for 150 buildings)
- Mapillary: **$0** (free tier)
- Flickr: **$0** (free tier)
- Wikimedia Commons: **$0** (free)
- **Total: ~$8**

Monthly costs:
- GCS storage: **~$0.15/month** (~6 GB)

Very affordable! 🎉
