#!/bin/bash

# Exit on error
set -e

# Load .env if it exists
if [ -f .env ]; then
    echo "Loading environment from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
export IMAGE_NAME="historicam-api"
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(cd ../../secrets && pwd)

# GCP Configuration (with defaults)
export GCP_PROJECT="${GCP_PROJECT:-ac215-historicam}"
export GCP_LOCATION="${GCP_LOCATION:-us-central1}"

# API Configuration
export TOP_K="${TOP_K:-5}"
export CONFIDENCE_THRESHOLD="${CONFIDENCE_THRESHOLD:-0.8}"
export BACKUP_THRESHOLD="${BACKUP_THRESHOLD:-0.6}"

echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo ""
echo "Starting API container..."
echo "  GCP Project: $GCP_PROJECT"
echo "  API will be available at: http://localhost:8080"
echo ""

# Run container
docker run --rm -it \
  --name $IMAGE_NAME \
  -p 8080:8080 \
  -v "$BASE_DIR":/app \
  -v "$SECRETS_DIR":/secrets \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcs-service-account.json \
  -e GCP_PROJECT=$GCP_PROJECT \
  -e GCP_LOCATION=$GCP_LOCATION \
  -e EMBEDDINGS_PATH=$EMBEDDINGS_PATH \
  -e EMBEDDING_DIMENSION=$EMBEDDING_DIMENSION \
  -e TOP_K=$TOP_K \
  -e CONFIDENCE_THRESHOLD=$CONFIDENCE_THRESHOLD \
  -e BACKUP_THRESHOLD=$BACKUP_THRESHOLD \
  $IMAGE_NAME
