# Train/Test Split Documentation

## Overview

Simple train/test split for evaluating the vision pipeline and API logic.

**Strategy**: Exclude 20% of images **per building** (not entire buildings). This ensures all buildings can be identified while maintaining held-out images for evaluation.

## Test Set

- **File**: `test_data/test_images.txt`
- **Size**: 68 images (21.8% of 312 total)
- **Coverage**: ~20% of images from each building
- **Seed**: 42 (for reproducibility)
- **Format**: `building_id_image_hash` (one per line)

## Usage

### 1. Generate Embeddings (Excluding Test Images)

```bash
uv run python -m src.embeddings.generate \
    --bucket historicam-images \
    --version latest \
    --project $GCP_PROJECT \
    --exclude-images test_data/test_images.txt
```

This will:
- Skip the 68 test images (20% per building)
- Generate embeddings for remaining 80% of images from **all buildings**
- Save to GCS: `gs://bucket/embeddings/{VERSION}/multimodal-512d/embeddings.jsonl`

### 2. Deploy Index (Training Images)

```bash
uv run python -m src.indexing.deploy \
    --embeddings-path gs://historicam-images/embeddings/{VERSION}/multimodal-512d/embeddings.jsonl \
    --index-name historicam-buildings-v1 \
    --dimensions 512 \
    --project $GCP_PROJECT
```

The deployed index will contain **all buildings**, but only with their training images (80% per building).

### 3. Evaluate (Test Images)

**Option A: Simple Query Testing**
```bash
# Download a test image locally
# Query with held-out test image
uv run python -m src.query \
    --image /path/to/test_image.jpg \
    --endpoint-id YOUR_ENDPOINT_ID \
    --deployed-index-id historicam-buildings-v1 \
    --project $GCP_PROJECT \
    --top-k 10
```

Expected: Should return the correct building in top-k results (since building is in index, just with different images)

**Option B: Full Evaluation (later, when API exists)**
- Download all 68 test images
- Test different API parameters (top-k, similarity threshold)
- Measure accuracy on held-out images
- Evaluate different embedding models

## Regenerating Test Set

To create a new random split with 20% of images per building:

```python
import pandas as pd
import random
from collections import defaultdict

# Load manifest
df = pd.read_csv('data/images/image_manifest.csv')

# Group images by building
building_images = defaultdict(list)
for _, row in df.iterrows():
    building_id = str(row['building_id'])
    image_hash = row['image_hash']
    image_id = f"{building_id}_{image_hash}"
    building_images[building_id].append(image_id)

# Sample 20% from each building
random.seed(42)  # Change seed for different split
test_images = []

for building_id, images in building_images.items():
    test_size = max(1, int(len(images) * 0.2))  # At least 1 image per building
    test_sample = random.sample(images, test_size)
    test_images.extend(test_sample)

# Save to test_data/test_images.txt
test_images.sort()
with open('test_data/test_images.txt', 'w') as f:
    f.write(f"# Test image IDs - 20% of images per building\n")
    f.write(f"# Format: building_id_image_hash\n")
    f.write(f"# Total: {len(test_images)} test images\n")
    f.write("#\n")
    for img_id in test_images:
        f.write(f"{img_id}\n")
```

## Why This Approach?

✅ **Simple**: Just a text file
✅ **Version controlled**: Easy to track changes
✅ **Consistent**: Same test set across experiments
✅ **Flexible**: Easy to modify or regenerate
✅ **Local-first**: No complex infrastructure needed
