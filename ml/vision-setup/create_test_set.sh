#!/bin/bash
#
# Automatically create test set by sampling one image per building
#
# Usage: ./create_test_set.sh [version]
#   version: Data version (default: latest)

set -e

VERSION="${1:-latest}"
BUCKET="gs://historicam-images"
OUTPUT_FILE="test_data/test_images.txt"

# Authenticate gcloud/gsutil with service account
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "Activating service account..."
    gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet
fi

# Resolve "latest" version if specified
if [ "$VERSION" = "latest" ]; then
    echo "Resolving 'latest' version from GCS..."
    METADATA=$(gsutil cat "$BUCKET/metadata/versions.json" 2>&1)

    if [ -z "$METADATA" ]; then
        echo "Error: No versions found in bucket (metadata/versions.json not found)"
        exit 1
    fi

    # Check if gsutil command failed
    if echo "$METADATA" | grep -q "CommandException\|Error"; then
        echo "Error accessing metadata: $METADATA"
        exit 1
    fi

    VERSION=$(echo "$METADATA" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['versions'][-1]['version'])")

    if [ -z "$VERSION" ]; then
        echo "Error: Could not parse version from metadata/versions.json"
        echo "Metadata content: $METADATA"
        exit 1
    fi

    echo "Using latest version: $VERSION"
fi

echo "Creating test set from: $BUCKET/images/$VERSION/"
echo ""

# Create test_data directory if it doesn't exist
mkdir -p test_data

# Get list of all buildings (filter to numeric IDs only)
echo "Finding all buildings..."
BUILDINGS=$(gsutil ls "$BUCKET/images/$VERSION/" | sed "s|$BUCKET/images/$VERSION/||" | sed 's|/$||' | grep '^[0-9]\+$' | sort -n)

if [ -z "$BUILDINGS" ]; then
    echo "Error: No buildings found in $BUCKET/images/$VERSION/"
    exit 1
fi

BUILDING_COUNT=$(echo "$BUILDINGS" | wc -l | tr -d ' ')
echo "Found $BUILDING_COUNT buildings"
echo ""

# Sample one image from each building
echo "Sampling one image per building..."
> "$OUTPUT_FILE"  # Clear file

SAMPLED_COUNT=0
for BUILDING_ID in $BUILDINGS; do
    # Get first image from this building (skip .DS_Store files)
    FIRST_IMAGE=$(gsutil ls "$BUCKET/images/$VERSION/$BUILDING_ID/" 2>/dev/null | grep -v '\.DS_Store$' | head -1)

    if [ -z "$FIRST_IMAGE" ]; then
        echo "  ⚠️  Building $BUILDING_ID: No images found, skipping"
        continue
    fi

    # Extract filename and create image ID (format: {building_id}_{hash})
    FILENAME=$(basename "$FIRST_IMAGE")
    HASH="${FILENAME%.*}"  # Remove extension to get hash
    IMAGE_ID="${BUILDING_ID}_${HASH}"

    echo "$IMAGE_ID" >> "$OUTPUT_FILE"
    echo "  ✓ Building $BUILDING_ID: $IMAGE_ID"
    SAMPLED_COUNT=$((SAMPLED_COUNT + 1))
done

echo ""
echo "✓ Created test set with $SAMPLED_COUNT images"
echo "  Saved to: $OUTPUT_FILE"
echo ""
echo "Now run embeddings generation with:"
echo "  uv run python -m src.embeddings.generate \\"
echo "    --bucket historicam-images \\"
echo "    --version latest \\"
echo "    --exclude-images $OUTPUT_FILE \\"
echo "    --project ac215-historicam"
