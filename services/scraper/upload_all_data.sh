#!/bin/bash
# Upload all scraped data (images, CSVs, manifests) to GCS with versioning
# Uses shared lib/gcs_utils framework

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

# Use Python script with shared GCS utilities
uv run python << PYEOF
import sys
import os
from pathlib import Path

# Add lib to path
sys.path.insert(0, '/app/lib')

from gcs_utils import GCSDataManager

bucket_name = "${BUCKET}"
version = "${VERSION}"

print("Initializing GCS Data Manager...")
manager = GCSDataManager(bucket_name)

# Step 1: Upload images with versioning
print("\nStep 1/3: Uploading images...")
print("----------------------------------------")

# Find combined manifest or use first available manifest
manifest_path = Path('/data/images/combined_manifest.csv')
if not manifest_path.exists():
    # Try to find any manifest
    manifests = list(Path('/data/images').glob('*_manifest.csv'))
    if manifests:
        manifest_path = manifests[0]
        print(f"Using manifest: {manifest_path.name}")
    else:
        print("Error: No manifest file found")
        sys.exit(1)

stats = manager.upload_images_with_versioning(
    Path('/data/images'),
    manifest_path,
    version=version
)

print(f"\n✓ Uploaded {stats['images_uploaded']} images")
print(f"  Version: {stats['version']}")
print(f"  Size: {stats['bytes_uploaded'] / (1024*1024):.2f} MB")

# Step 2: Upload CSV files
print("\nStep 2/3: Uploading CSV data...")
print("----------------------------------------")

csv_files = [
    ('/data/buildings_names.csv', 'buildings'),
    ('/data/buildings_names_metadata.csv', 'metadata'),
    ('/data/buildings_info.csv', 'metadata')
]

for csv_path_str, data_type in csv_files:
    csv_path = Path(csv_path_str)
    if csv_path.exists():
        manager.upload_csv_with_versioning(csv_path, data_type, version=version)
    else:
        print(f"⊗ Skipping {csv_path.name} (not found)")

# Step 3: Upload additional manifests
print("\nStep 3/3: Uploading additional manifests...")
print("----------------------------------------")

manifest_count = 0
for manifest in Path('/data/images').glob('*_manifest.csv'):
    if manifest != manifest_path:  # Skip already uploaded manifest
        gcs_path = f"manifests/{version}/{manifest.name}"
        try:
            blob = manager.bucket.blob(gcs_path)
            blob.upload_from_filename(str(manifest))
            print(f"✓ Uploaded {manifest.name}")
            manifest_count += 1
        except Exception as e:
            print(f"Failed to upload {manifest.name}: {e}")

if manifest_count == 0:
    print("No additional manifest files found")

print("\n" + "="*50)
print("✓ UPLOAD COMPLETE!")
print("="*50)

PYEOF

echo ""
echo "Version: $VERSION"
echo ""
echo "View your data:"
echo "  gsutil ls gs://$BUCKET/images/$VERSION/"
echo "  gsutil ls gs://$BUCKET/csv/buildings/$VERSION/"
echo "  gsutil ls gs://$BUCKET/csv/metadata/$VERSION/"
echo "  gsutil ls gs://$BUCKET/manifests/$VERSION/"
echo ""
echo "Bucket structure:"
echo "  gs://$BUCKET/"
echo "  ├── images/$VERSION/              # Building images"
echo "  ├── manifests/$VERSION/           # Image metadata CSVs"
echo "  ├── csv/buildings/$VERSION/       # Buildings names CSV"
echo "  ├── csv/metadata/$VERSION/        # Metadata & info CSVs"
echo "  └── metadata/versions.json        # Version tracking"
echo ""
