#!/bin/bash

set -e

export IMAGE_NAME="historicam-frontend"
export BASE_DIR=$(pwd)

# Build the image
docker build -t $IMAGE_NAME -f Dockerfile .

# Run container
docker run --rm --name $IMAGE_NAME -ti \
  -v "$BASE_DIR":/app \
  -p 3000:3000 \
  $IMAGE_NAME
