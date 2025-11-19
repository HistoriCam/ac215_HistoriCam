#!/bin/bash
#
# Download one sample image from GCS for quick testing
#
# Usage: ./download_test_images.sh [version]
#   version: Data version (default: latest)

set -e

VERSION="${1:-latest}"
BUCKET="gs://historicam-images"
OUTPUT_DIR="test_images"

# Resolve "latest" version if specified
if [ "$VERSION" = "latest" ]; then
    echo "Resolving 'latest' version from GCS..."
    METADATA=$(gsutil cat "$BUCKET/metadata/versions.json" 2>/dev/null || echo "")

    if [ -z "$METADATA" ]; then
        echo "Error: No versions found in bucket (metadata/versions.json not found)"
        exit 1
    fi

    # Extract most recent version using python
    VERSION=$(echo "$METADATA" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['versions'][-1]['version'])" 2>/dev/null || echo "")

    if [ -z "$VERSION" ]; then
        echo "Error: Could not parse version from metadata/versions.json"
        exit 1
    fi

    echo "Using latest version: $VERSION"
fi

echo "Downloading test image from: $BUCKET/images/$VERSION/1/"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Hardcode building 1 for simplicity
FIRST_BUILDING=1

# Get first image from this building (any format)
FIRST_IMAGE=$(gsutil ls "$BUCKET/images/$VERSION/1/" | head -1)

if [ -z "$FIRST_IMAGE" ]; then
    echo "Error: No images found for building 1"
    exit 1
fi

# Get file extension
EXT="${FIRST_IMAGE##*.}"

# Download with standardized naming
OUTPUT_FILE="$OUTPUT_DIR/building_${FIRST_BUILDING}_sample.${EXT}"
gsutil -q cp "$FIRST_IMAGE" "$OUTPUT_FILE"

# Get file size for display
SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')

echo ""
echo "✓ Downloaded test image:"
echo "  File: building_${FIRST_BUILDING}_sample.${EXT}"
echo "  Size: $SIZE"
echo "  Expected building: $FIRST_BUILDING"
echo ""
echo "Run test with: uv run python test_api.py"
