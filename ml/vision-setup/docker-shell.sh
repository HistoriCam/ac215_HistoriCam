#!/bin/bash

# Exit on error
set -e

# Configuration
export IMAGE_NAME="historicam-vision"
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(cd ../../secrets && pwd)

# GCP Configuration
export GCP_PROJECT="${GCP_PROJECT:-ac215-historicam}"
export GCS_BUCKET="${GCS_BUCKET_NAME:-historicam-images}"

echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo ""
echo "Starting container with mounted volumes:"
echo "  - Source code: $BASE_DIR"
echo "  - Secrets: $SECRETS_DIR"
echo ""

# Run container with volume mounts
docker run --rm -it \
  --name $IMAGE_NAME \
  -v "$BASE_DIR":/app \
  -v "$SECRETS_DIR":/secrets \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcs-service-account.json \
  -e GCP_PROJECT=$GCP_PROJECT \
  -e GCS_BUCKET=$GCS_BUCKET \
  $IMAGE_NAME