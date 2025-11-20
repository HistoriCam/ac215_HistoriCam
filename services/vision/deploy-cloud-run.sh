#!/bin/bash

# Deploy HistoriCam API to Cloud Run
set -e

# Load .env if it exists
if [ -f .env ]; then
    echo "Loading environment from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
export IMAGE_NAME="historicam-api"
export GCP_PROJECT="${GCP_PROJECT:-ac215-historicam}"
export GCP_LOCATION="${GCP_LOCATION:-us-central1}"
export SERVICE_NAME="historicam-api"
export GCR_IMAGE="gcr.io/${GCP_PROJECT}/${IMAGE_NAME}"

# Validate required environment variables
if [ -z "$VERTEX_ENDPOINT_ID" ]; then
    echo "ERROR: VERTEX_ENDPOINT_ID not set"
    echo "Please set it in .env file or export it"
    exit 1
fi

echo "==========================================="
echo "DEPLOYING HISTORICAM API TO CLOUD RUN"
echo "==========================================="
echo "Project: $GCP_PROJECT"
echo "Location: $GCP_LOCATION"
echo "Service: $SERVICE_NAME"
echo "Image: $GCR_IMAGE"
echo ""

# Step 1: Build Docker image
echo "Step 1/3: Building Docker image..."
echo "-------------------------------------------"
docker build -t $IMAGE_NAME .

# Step 2: Tag and push to Google Container Registry
echo ""
echo "Step 2/3: Pushing to Container Registry..."
echo "-------------------------------------------"
docker tag $IMAGE_NAME $GCR_IMAGE
docker push $GCR_IMAGE

# Step 3: Deploy to Cloud Run
echo ""
echo "Step 3/3: Deploying to Cloud Run..."
echo "-------------------------------------------"

gcloud run deploy $SERVICE_NAME \
    --image $GCR_IMAGE \
    --platform managed \
    --region $GCP_LOCATION \
    --project $GCP_PROJECT \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 1 \
    --timeout 60 \
    --set-env-vars "GCP_PROJECT=$GCP_PROJECT" \
    --set-env-vars "GCP_LOCATION=$GCP_LOCATION" \
    --set-env-vars "VERTEX_ENDPOINT_ID=$VERTEX_ENDPOINT_ID" \
    --set-env-vars "DEPLOYED_INDEX_ID=${DEPLOYED_INDEX_ID:-historicam-buildings-v1}" \
    --set-env-vars "EMBEDDING_DIMENSION=${EMBEDDING_DIMENSION:-512}" \
    --set-env-vars "TOP_K=${TOP_K:-5}" \
    --set-env-vars "CONFIDENCE_THRESHOLD=${CONFIDENCE_THRESHOLD:-0.7}" \
    --set-env-vars "BACKUP_THRESHOLD=${BACKUP_THRESHOLD:-0.4}"

echo ""
echo "==========================================="
echo "✓ DEPLOYMENT COMPLETE!"
echo "==========================================="
echo ""
echo "Your API is now live at:"
gcloud run services describe $SERVICE_NAME \
    --platform managed \
    --region $GCP_LOCATION \
    --project $GCP_PROJECT \
    --format 'value(status.url)'
echo ""
echo "Test with:"
echo "  curl \$(gcloud run services describe $SERVICE_NAME --region $GCP_LOCATION --format 'value(status.url)')"
echo ""
