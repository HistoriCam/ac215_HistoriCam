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

# Step 1: Upload images
echo ""
echo "Step 1/4: Uploading images..."
echo "----------------------------------------"

# Find manifest file
MANIFEST_PATH="/data/images/combined_manifest.csv"
if [ ! -f "$MANIFEST_PATH" ]; then
    MANIFEST_PATH=$(find /data/images -name "*_manifest.csv" -type f | head -n 1)
    if [ -z "$MANIFEST_PATH" ]; then
        echo "Error: No manifest file found"
        exit 1
    fi
    echo "Using manifest: $(basename $MANIFEST_PATH)"
fi

# Upload all image files
IMAGE_COUNT=0
TOTAL_SIZE=0

for ext in jpg JPG jpeg JPEG png PNG tif TIF tiff TIFF; do
    for img in /data/images/*.$ext; do
        if [ -f "$img" ]; then
            filename=$(basename "$img")
            gsutil -q cp "$img" "gs://$BUCKET/images/$VERSION/$filename"
            IMAGE_COUNT=$((IMAGE_COUNT + 1))
            SIZE=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null)
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        fi
    done
done

echo "✓ Uploaded $IMAGE_COUNT images"
echo "  Size: $((TOTAL_SIZE / 1024 / 1024)) MB"

# Step 2: Upload image manifest
echo ""
echo "Step 2/4: Uploading image manifest..."
echo "----------------------------------------"

gsutil -q cp "$MANIFEST_PATH" "gs://$BUCKET/manifests/$VERSION/image_manifest.csv"
echo "✓ Uploaded image_manifest.csv"

# Upload any additional manifests
MANIFEST_COUNT=0
for manifest in /data/images/*_manifest.csv; do
    if [ -f "$manifest" ] && [ "$manifest" != "$MANIFEST_PATH" ]; then
        filename=$(basename "$manifest")
        gsutil -q cp "$manifest" "gs://$BUCKET/manifests/$VERSION/$filename"
        MANIFEST_COUNT=$((MANIFEST_COUNT + 1))
        echo "✓ Uploaded $filename"
    fi
done

if [ $MANIFEST_COUNT -eq 0 ]; then
    echo "No additional manifest files found"
fi

# Step 3: Upload CSV files
echo ""
echo "Step 3/4: Uploading CSV data..."
echo "----------------------------------------"

if [ -f "/data/buildings_names.csv" ]; then
    gsutil -q cp "/data/buildings_names.csv" "gs://$BUCKET/csv/buildings/$VERSION/buildings_names.csv"
    echo "✓ Uploaded buildings_names.csv"
else
    echo "⊗ Skipping buildings_names.csv (not found)"
fi

if [ -f "/data/buildings_names_metadata.csv" ]; then
    gsutil -q cp "/data/buildings_names_metadata.csv" "gs://$BUCKET/csv/metadata/$VERSION/buildings_names_metadata.csv"
    echo "✓ Uploaded buildings_names_metadata.csv"
else
    echo "⊗ Skipping buildings_names_metadata.csv (not found)"
fi

if [ -f "/data/buildings_info.csv" ]; then
    gsutil -q cp "/data/buildings_info.csv" "gs://$BUCKET/csv/metadata/$VERSION/buildings_info.csv"
    echo "✓ Uploaded buildings_info.csv"
else
    echo "⊗ Skipping buildings_info.csv (not found)"
fi

# Step 4: Update version metadata
echo ""
echo "Step 4/4: Updating version metadata..."
echo "----------------------------------------"

# Download existing metadata or create new
METADATA_FILE="/tmp/versions.json"
if gsutil -q stat "gs://$BUCKET/metadata/versions.json" 2>/dev/null; then
    gsutil -q cp "gs://$BUCKET/metadata/versions.json" "$METADATA_FILE"
else
    echo '{"versions": []}' > "$METADATA_FILE"
fi

# Add new version using Python
python3 << PYEOF
import json
from datetime import datetime

with open("$METADATA_FILE", "r") as f:
    metadata = json.load(f)

# Add new version entry
metadata["versions"].append({
    "version": "$VERSION",
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "images_count": $IMAGE_COUNT,
    "size_bytes": $TOTAL_SIZE
})

with open("$METADATA_FILE", "w") as f:
    json.dump(metadata, f, indent=2)
PYEOF

# Upload updated metadata
gsutil -q cp "$METADATA_FILE" "gs://$BUCKET/metadata/versions.json"
echo "✓ Updated versions.json"

echo ""
echo "="*50
echo "✓ UPLOAD COMPLETE!"
echo "="*50

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
