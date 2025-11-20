#!/bin/bash

# Exit on error
set -e

# Configuration
export IMAGE_NAME="historicam-api"
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(cd ../../secrets && pwd)

# GCP Configuration
export GCP_PROJECT="${GCP_PROJECT:-ac215-historicam}"
export GCP_LOCATION="${GCP_LOCATION:-us-central1}"

# Vector Search Configuration  
export VERTEX_ENDPOINT_ID="${VERTEX_ENDPOINT_ID}"
export DEPLOYED_INDEX_ID="${DEPLOYED_INDEX_ID:-historicam-buildings-v1}"
export EMBEDDING_DIMENSION="${EMBEDDING_DIMENSION:-512}"

# API Configuration
export TOP_K="${TOP_K:-5}"
export CONFIDENCE_THRESHOLD="${CONFIDENCE_THRESHOLD:-0.7}"
export BACKUP_THRESHOLD="${BACKUP_THRESHOLD:-0.4}"

echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo ""
echo "Starting API container..."
echo "  GCP Project: $GCP_PROJECT"
echo "  Endpoint ID: $VERTEX_ENDPOINT_ID"
echo "  Deployed Index: $DEPLOYED_INDEX_ID"
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
  -e VERTEX_ENDPOINT_ID=$VERTEX_ENDPOINT_ID \
  -e DEPLOYED_INDEX_ID=$DEPLOYED_INDEX_ID \
  -e EMBEDDING_DIMENSION=$EMBEDDING_DIMENSION \
  -e TOP_K=$TOP_K \
  -e CONFIDENCE_THRESHOLD=$CONFIDENCE_THRESHOLD \
  -e BACKUP_THRESHOLD=$BACKUP_THRESHOLD \
  $IMAGE_NAME
