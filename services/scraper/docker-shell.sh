#!/bin/bash

# Exit on error
set -e

# Configuration
export IMAGE_NAME="historicam-scraper"
export BASE_DIR=$(pwd)
export DATA_DIR=$(cd ../../data && pwd)
export SECRETS_DIR=$(cd ../../secrets && pwd)
export LIB_DIR=$(cd ../../lib && pwd)

# GCP Configuration (optional - set if using GCS)
export GCP_PROJECT="${GCP_PROJECT:-your-project-id}"
export GCS_BUCKET_NAME="${GCS_BUCKET_NAME:-historicam-images}"

echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo ""
echo "Starting container with mounted volumes:"
echo "  - Source code: $BASE_DIR"
echo "  - Data output: $DATA_DIR"
echo "  - Secrets: $SECRETS_DIR"
echo "  - Shared lib: $LIB_DIR"
echo ""

# Run container with volume mounts
docker run --rm -it \
  --name $IMAGE_NAME \
  -v "$BASE_DIR":/app \
  -v "$DATA_DIR":/data \
  -v "$SECRETS_DIR":/secrets \
  -v "$LIB_DIR":/app/lib \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcs-service-account.json \
  -e GCP_PROJECT=$GCP_PROJECT \
  -e GCS_BUCKET_NAME=$GCS_BUCKET_NAME \
  $IMAGE_NAME
