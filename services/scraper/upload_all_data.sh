#!/bin/bash
# Upload all scraped data (images, CSVs, manifests) to GCS with versioning

set -e

BUCKET=$1
VERSION=${2:-$(date -u +v%Y%m%d_%H%M%S)}

if [ -z "$BUCKET" ]; then
    echo "Usage: ./upload_all_data.sh <bucket-name> [version]"
    echo ""
    echo "Example:"
    echo "  ./upload_all_data.sh historicam-images"
    echo "  ./upload_all_data.sh historicam-images v20251026_150000"
    echo ""
    echo "Environment variables required:"
    echo "  GOOGLE_APPLICATION_CREDENTIALS - Path to service account JSON"
    exit 1
fi

echo "=========================================="
echo "UPLOADING ALL DATA TO GCS"
echo "=========================================="
echo "Bucket: $BUCKET"
echo "Version: $VERSION"
echo ""

# Check if data exists
if [ ! -d "/data/images" ]; then
    echo "Error: /data/images directory not found"
    exit 1
fi

if [ ! -f "/data/buildings_names_metadata.csv" ]; then
    echo "Error: /data/buildings_names_metadata.csv not found"
    exit 1
fi

# Pass bucket and version to Python script
export UPLOAD_BUCKET=$BUCKET
export UPLOAD_VERSION=$VERSION

# 1. Upload images using Python manager (includes versioning metadata)
echo "Step 1/3: Uploading images..."
echo "----------------------------------------"
uv run python src/scraper/gcs_manager.py upload \
    $BUCKET \
    /data/images \
    /data/images/combined_manifest.csv

echo ""
echo "Step 2/3: Uploading CSV data..."
echo "----------------------------------------"

# Use Python script to upload CSVs and manifests (uses same auth as images)
python3 << 'PYEOF'
import os
from pathlib import Path
from google.cloud import storage

bucket_name = os.environ.get('UPLOAD_BUCKET')
version = os.environ.get('UPLOAD_VERSION')

client = storage.Client()
bucket = client.bucket(bucket_name)

# Upload buildings CSV
buildings_csv = Path('/data/buildings_names.csv')
if buildings_csv.exists():
    blob = bucket.blob(f'csv/buildings/{version}/buildings_names.csv')
    blob.upload_from_filename(str(buildings_csv))
    print(f'✓ Uploaded buildings_names.csv')
else:
    print('⊗ Skipping buildings_names.csv (not found)')

# Upload metadata CSV
metadata_csv = Path('/data/buildings_names_metadata.csv')
if metadata_csv.exists():
    blob = bucket.blob(f'csv/metadata/{version}/buildings_names_metadata.csv')
    blob.upload_from_filename(str(metadata_csv))
    print(f'✓ Uploaded buildings_names_metadata.csv')
else:
    print('⊗ Skipping buildings_names_metadata.csv (not found)')

# Upload info CSV
info_csv = Path('/data/buildings_info.csv')
if info_csv.exists():
    blob = bucket.blob(f'csv/metadata/{version}/buildings_info.csv')
    blob.upload_from_filename(str(info_csv))
    print(f'✓ Uploaded buildings_info.csv')
else:
    print('⊗ Skipping buildings_info.csv (not found)')

print('')
print('Step 3/3: Uploading all manifests...')
print('----------------------------------------')

# Upload all manifest files
manifest_count = 0
for manifest in Path('/data/images').glob('*_manifest.csv'):
    blob = bucket.blob(f'manifests/{version}/{manifest.name}')
    blob.upload_from_filename(str(manifest))
    print(f'✓ Uploaded {manifest.name}')
    manifest_count += 1

if manifest_count == 0:
    print('⊗ No manifest files found')
PYEOF

echo ""
echo "=========================================="
echo "✓ UPLOAD COMPLETE!"
echo "=========================================="
echo "Version: $VERSION"
echo ""
echo "View your data:"
echo "  gsutil ls gs://$BUCKET/images/$VERSION/"
echo "  gsutil ls gs://$BUCKET/csv/$VERSION/"
echo "  gsutil ls gs://$BUCKET/manifests/$VERSION/"
echo ""
echo "Bucket structure:"
echo "  gs://$BUCKET/"
echo "  ├── images/$VERSION/        # Building images"
echo "  ├── manifests/$VERSION/     # Image metadata CSVs"
echo "  ├── csv/$VERSION/           # Building data CSVs"
echo "  └── metadata/versions.json  # Version tracking"
echo ""
