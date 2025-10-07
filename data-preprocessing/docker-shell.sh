#!/bin/bash

set -e

export IMAGE_NAME="historicam-preprocessing"
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(pwd)/../secrets/
export GCP_PROJECT="your-gcp-project-id"
export GCS_BUCKET_NAME="your-bucket-name"

# Build the image
docker build -t $IMAGE_NAME -f Dockerfile .

# Run container
docker run --rm --name $IMAGE_NAME -ti \
  -v "$BASE_DIR":/app \
  -v "$SECRETS_DIR":/secrets \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/data-service-account.json \
  -e GCP_PROJECT=$GCP_PROJECT \
  -e GCS_BUCKET_NAME=$GCS_BUCKET_NAME \
  $IMAGE_NAME
