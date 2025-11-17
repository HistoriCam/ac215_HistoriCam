# HistoriCam Vision Pipeline

Generate embeddings from building images and deploy to Vertex AI Vector Search.

## Overview

This pipeline has two independent parts:

1. **Embedding Generation** - Reads images from GCS, generates embeddings, saves JSONL to GCS
2. **Index Deployment** - Reads JSONL from GCS, deploys to Vertex AI Vector Search

## Setup

### Prerequisites

- GCP project with Vertex AI API enabled
- GCS bucket with images (from scraper service)
- Service account key in `../secrets/gcs-service-account.json`

### Environment Variables

```bash
export GCP_PROJECT="your-project-id"
export GCS_BUCKET="your-bucket-name"
```

## Usage

### 1. Generate Embeddings

```bash
# Enter Docker shell
./docker-shell.sh

# Generate embeddings from latest data version (excludes 20% test images per building)
uv run python -m src.embeddings.generate \
    --bucket $GCS_BUCKET \
    --version latest \
    --model multimodal \
    --dimension 512 \
    --project $GCP_PROJECT \
    --exclude-images test_data/test_images.txt

# Or specify exact version
uv run python -m src.embeddings.generate \
    --bucket $GCS_BUCKET \
    --version v20251112_185257 \
    --model multimodal \
    --dimension 512 \
    --project $GCP_PROJECT \
    --exclude-images test_data/test_images.txt

# Output: gs://bucket/embeddings/{VERSION}/multimodal-512d/embeddings.jsonl
```

**Options:**
- `--version`: Version string or "latest" to auto-detect newest
- `--dimension`: 128, 256, 512, or 1408 (default: 512)
- `--exclude-images`: Path to test images file (20% per building for train/test split)
- `--output-local`: Save JSONL locally for inspection

### 2. Deploy Vector Search Index

```bash
# Deploy index (takes 15-30 minutes)
uv run python -m src.indexing.deploy \
    --embeddings-path gs://$GCS_BUCKET/embeddings/v20251112_185257/multimodal-512d/embeddings.jsonl \
    --index-name historicam-buildings-v1 \
    --dimensions 512 \
    --project $GCP_PROJECT

# Save the endpoint ID and deployed index ID from output
```

### 3. Test Deployed Index (Optional)

```bash
# Query index with a test image
uv run python -m src.query \
    --image test_data/test_image.jpg \
    --endpoint-id YOUR_ENDPOINT_ID \
    --deployed-index-id historicam-buildings-v1 \
    --project $GCP_PROJECT \
    --top-k 10

# Shows top-k nearest neighbors and unique buildings
```

## Architecture

```
GCS Bucket Structure:
  images/v{VERSION}/{building_id}/{image}.jpg    ← Scraped images
  manifests/v{VERSION}/image_manifest.csv        ← Image metadata
  embeddings/v{VERSION}/{model}/embeddings.jsonl ← Generated embeddings
  metadata/versions.json                         ← Version tracking

Vertex AI Vector Search:
  Index → Endpoint → Query

Test/Train Split:
  test_data/test_images.txt                      ← 20% held-out images per building
  All buildings in index, but with 80% of images for training
```

## Switching Models

To use a different embedding model in the future:

1. Create new model class in `src/embeddings/` (inherit from `EmbeddingModel`)
2. Generate embeddings: `--model custom`
3. Deploy index with new embeddings path

No changes needed to indexing or query logic!

## Cost Estimate

**Phase 1 (Vertex AI Multimodal):**
- Multimodal embeddings: ~$0.0025 per image (2000 images = $5)
- Vector Search: ~$50/month for 2k vectors
- **Total: ~$55/month**

## Troubleshooting

**"Quota exceeded" error:**
- Request quota increase in GCP Console for Vertex AI

**"Bucket not found":**
- Verify `GCS_BUCKET` environment variable
- Check service account has Storage Object Viewer role

**"Index deployment timeout":**
- This is normal, deployment takes 15-30 minutes
- Check status: `gcloud ai index-endpoints list --project=$GCP_PROJECT`
