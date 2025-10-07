#!/bin/bash

set -e

export IMAGE_NAME="historicam-api"
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(pwd)/../secrets/
export GCP_PROJECT="your-gcp-project-id"

# Build the image
docker build -t $IMAGE_NAME -f Dockerfile .

# Run container
docker run --rm --name $IMAGE_NAME -ti \
  -v "$BASE_DIR":/app \
  -v "$SECRETS_DIR":/secrets \
  -p 8000:8000 \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/api-service-account.json \
  -e GCP_PROJECT=$GCP_PROJECT \
  $IMAGE_NAME
