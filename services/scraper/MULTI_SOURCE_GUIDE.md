# Multi-Source Image Scraping Guide

Complete guide for collecting 20+ images per building from multiple sources.

## Overview

The scraper collects images from four complementary sources:

| Source | Images/Building | Cost | Strengths | Weaknesses |
|--------|----------------|------|-----------|------------|
| **Wikimedia Commons** | 5-10 | Free | High quality, curated, properly licensed | Limited coverage |
| **Google Places Photos** | 5-10 | ~$0.05/building | User-contributed, good angles, varied perspectives | Requires API key & billing |
| **Mapillary** | 3-5 | Free | Crowdsourced street imagery, building-oriented filtering | Requires coordinates, variable coverage |
| **Flickr** | 3-5 | Free | User variety, different seasons/times | Quality varies, not all buildings |

**Total: 16-30 images per building (target: 20+)**

## Quick Start

### Prerequisites

1. **Google Maps API Key** (recommended)
   - Go to: https://console.cloud.google.com/apis/credentials
   - Enable "Places API" (for user-contributed building photos)
   - Create API key
   - Set billing (required, but $300 free credit available)

2. **Mapillary Access Token** (recommended - free!)
   - Sign up at: https://www.mapillary.com/
   - Go to: https://www.mapillary.com/dashboard/developers
   - Create an application and copy the "Client Token"
   - Free tier with generous limits

3. **Flickr API Key** (optional)
   - Go to: https://www.flickr.com/services/api/misc.api_keys.html
   - Apply for non-commercial key
   - Free: 3600 requests/hour

### Setup

```bash
cd services/scraper

# Set API keys
export GOOGLE_MAPS_API_KEY="your-google-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-flickr-key"

# Run all-in-one scraper
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --target 20
```

## Usage

### Option 1: All Sources at Once (Recommended)

```bash
# Scrape from all sources with default settings
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Custom target (e.g., 30 images per building)
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images \
    --target 30
```

This will:
1. ✅ Scrape Wikimedia Commons (enhanced with category search)
2. ✅ Scrape Google Places Photos (if key provided)
3. ✅ Scrape Mapillary (if token provided)
4. ✅ Scrape Flickr (if key provided)
5. ✅ Deduplicate images automatically
6. ✅ Validate all images
7. ✅ Generate combined manifest

### Option 2: Individual Sources

```bash
# Wikimedia Commons only (enhanced with category search)
uv run python src/scraper/scrape_images.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Google Places Photos only
uv run python src/scraper/scrape_places.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Mapillary only
uv run python src/scraper/scrape_mapillary.py \
    /data/buildings_names_metadata.csv \
    /data/images

# Flickr only
uv run python src/scraper/scrape_flickr.py \
    /data/buildings_names_metadata.csv \
    /data/images
```

## Docker Usage

```bash
cd services/scraper

# Set API keys before running
export GOOGLE_MAPS_API_KEY="your-key"
export MAPILLARY_ACCESS_TOKEN="MLY|your-token"
export FLICKR_API_KEY="your-key"

# Run docker
./docker-shell.sh

# Inside container - scrape all sources
uv run python src/scraper/scrape_all_sources.py \
    /data/buildings_names_metadata.csv \
    /data/images
```

## Output Structure

```
data/images/
├── 1/                          # Building ID
│   ├── abc123_wm.jpg          # Wikimedia (_wm suffix)
│   ├── def456_places.jpg      # Google Places (_places suffix)
│   ├── ghi789_mapillary.jpg   # Mapillary (_mapillary suffix)
│   ├── jkl012_flickr.jpg      # Flickr (_flickr suffix)
│   └── ...
├── 2/
│   └── ...
├── image_manifest.csv          # Wikimedia manifest
├── places_manifest.csv         # Google Places manifest
├── mapillary_manifest.csv      # Mapillary manifest
├── flickr_manifest.csv         # Flickr manifest
└── combined_manifest.csv       # All sources combined (after dedup)
```

## Deduplication

Images are automatically deduplicated using perceptual hashing:

```bash
# Manual deduplication
uv run python src/scraper/deduplication.py find /data/images

# Remove duplicates (dry run)
uv run python src/scraper/deduplication.py remove /data/images

# Actually remove (no dry run)
uv run python src/scraper/deduplication.py remove /data/images --no-dry-run
```

**How it works:**
- Computes perceptual hash (pHash) for each image
- Finds images with Hamming distance ≤ 5 (very similar)
- Keeps highest resolution version
- Removes duplicates

## Validation

Images are validated with these criteria:

| Criterion | Value |
|-----------|-------|
| Min resolution | 512x512 px |
| Preferred resolution | 1024x1024 px |
| Max file size | 10 MB |
| Formats | JPEG, PNG, WebP |
| Aspect ratio | 0.2 - 5.0 |

```bash
# Validate all images
uv run python src/scraper/validation.py /data/images
```

Images receive a **quality score** (0.0-1.0):
- 1.0 = 1024x1024 or larger
- 0.5 = ~768x768
- 0.0 = 512x512 (minimum)

## Cost Estimation

For 150 Harvard buildings:

### Wikimedia Commons (Enhanced)
- **Cost**: $0 (free)
- **Images**: ~750-1,050 (5-7 per building with category search)
- **Coverage**: ~70% of buildings

### Google Places Photos
- **API calls**: ~150 Find Place + ~150 Place Details = 300 calls
- **Cost**: 300 × $0.017 = **$5.10**
- **Images**: ~750-1,200 (5-8 per building)
- **Coverage**: ~80% of buildings

### Mapillary
- **Cost**: $0 (free)
- **Images**: ~450-600 (3-4 per building)
- **Coverage**: ~40% of buildings (requires coordinates)

### Flickr
- **Cost**: $0 (free tier)
- **Images**: ~450-600 (3-4 per building)
- **Coverage**: ~50% of buildings

### Storage (GCS)
- **Total images**: ~2,400-3,450 raw, ~2,200-3,000 after dedup
- **Storage**: ~6 GB average
- **Cost**: **$0.15/month**

**Total one-time cost: ~$5-8**
**Monthly cost: ~$0.15**

## API Key Setup

### Google Maps API (Places Photos)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select project
3. Enable APIs:
   - Places API (New)
4. Create API key:
   - APIs & Services → Credentials
   - Create Credentials → API Key
5. Restrict key (recommended):
   - API restrictions: Only "Places API (New)"
   - Optional: IP restrictions
6. Set up billing (required, but $300 free credit available)

```bash
export GOOGLE_MAPS_API_KEY="AIza..."
```

### Mapillary API (Free!)

1. Create account at [Mapillary](https://www.mapillary.com/)
2. Go to [Developer Dashboard](https://www.mapillary.com/dashboard/developers)
3. Create a new application:
   - Name: HistoriCam Image Scraper
   - Description: Educational project for Harvard building recognition
4. Copy the **Client Token** (this is your access token)
5. Token should start with "MLY|"

```bash
export MAPILLARY_ACCESS_TOKEN="MLY|..."
```

### Flickr API

1. Go to [Flickr App Garden](https://www.flickr.com/services/api/misc.api_keys.html)
2. Click "Apply for your Key"
3. Select "Non-Commercial Key"
4. Fill out application
5. Copy API Key

```bash
export FLICKR_API_KEY="abc..."
```

## Best Practices

### 1. Start Small

Test with a subset before full scraping:

```python
# Test with first 10 buildings
df = pd.read_csv("buildings.csv")
df_test = df.head(10)
df_test.to_csv("test_buildings.csv", index=False)

# Scrape test set
uv run python src/scraper/scrape_all_sources.py \
    test_buildings.csv \
    test_images/
```

### 2. Monitor API Costs

```bash
# Check Places API usage
# Google Cloud Console → APIs & Services → Places API → Metrics
```

### 3. Handle Rate Limits

Built-in rate limiting:
- Wikimedia: 1 request/second
- Google Places: API quota-based (default 30,000 requests/day)
- Mapillary: 50,000 requests/hour (very generous)
- Flickr: 3600 requests/hour

### 4. Version Your Data

```bash
# Upload to GCS with versioning
uv run python src/scraper/gcs_manager.py upload \
    historicam-images \
    /data/images \
    /data/images/combined_manifest.csv
```

### 5. Quality Control

After scraping:

```bash
# 1. Validate images
uv run python src/scraper/validation.py /data/images

# 2. Check manifests
head -20 /data/images/combined_manifest.csv

# 3. Visual spot check
# Open random images in each building folder

# 4. Check coverage
python -c "
import pandas as pd
df = pd.read_csv('/data/images/combined_manifest.csv')
print(f'Buildings with images: {df.building_id.nunique()}')
print(f'Avg images per building: {len(df) / df.building_id.nunique():.1f}')
print(df.groupby('source').size())
"
```

## Troubleshooting

### No Places Photos

```
✗ Places Photos scraping failed: 403 Forbidden
```

**Solutions:**
- Check API key is valid
- Ensure Places API (New) is enabled
- Verify billing is set up (required for Places API)
- Check API key restrictions aren't too strict

### Mapillary 401 Unauthorized

```
✗ Mapillary scraping failed: 401 Unauthorized
```

**Solutions:**
- Verify MAPILLARY_ACCESS_TOKEN is set correctly
- Check token starts with "MLY|"
- Ensure you copied the "Client Token" (not Organization Token)
- Verify your Mapillary account is active

### Flickr No Results

```
No Flickr photos found for building X
```

**Normal** - not all buildings have Flickr photos. Flickr provides supplemental images.

### Deduplication Removes Too Many

```
Removed 500 duplicates (expected ~50)
```

**Solution:**
- Increase similarity threshold:
  ```python
  deduplicator = ImageDeduplicator(similarity_threshold=10)  # More permissive
  ```

### Low Quality Images

**Solution:**
- Adjust validation thresholds:
  ```python
  validator = ImageValidator(
      min_width=1024,  # Stricter
      preferred_width=2048
  )
  ```

## Next Steps

1. **Run full scraping**:
   ```bash
   ./docker-shell.sh
   uv run python src/scraper/scrape_all_sources.py /data/buildings_names_metadata.csv /data/images
   ```

2. **Upload to GCS**:
   ```bash
   uv run python src/scraper/gcs_manager.py upload historicam-images /data/images /data/images/combined_manifest.csv
   ```

3. **Train ML model** with diverse dataset

4. **Monitor & improve**:
   - Track buildings with <20 images
   - Add custom images for gaps
   - Re-scrape periodically for new Flickr photos

## Advanced: Custom Source Integration

To add a new image source (e.g., Instagram, custom API):

1. Create `scrape_{source}.py` following pattern:
   ```python
   def scrape_{source}_for_buildings(csv_path, output_dir, **kwargs):
       # Scraping logic
       return stats
   ```

2. Add to `scrape_all_sources.py`:
   ```python
   # Phase N: Your Source
   if your_api_key:
       stats = scrape_your_source_for_buildings(...)
       all_stats["your_source"] = stats
   ```

3. Update deduplication to include new manifest

Done!
