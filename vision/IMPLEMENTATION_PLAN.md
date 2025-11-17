# HistoriCam ML Implementation Plan

> **UPDATE:** This plan has been updated to use **Vertex AI Multimodal Embeddings API** instead of Vision API web detection workaround. See [vision/README.md](README.md) for the implemented architecture.

**Key Changes:**
- ✅ Using `multimodalembedding@001` for proper 512-dimensional embeddings
- ✅ Modular architecture with swappable embedding models
- ✅ Direct GCS-to-JSONL pipeline (no local storage needed)
- ✅ Simplified index deployment via `src/indexing/deploy.py`

**Implementation Status:**
- [x] Embedding generation with Vertex AI Multimodal
- [x] Vector Search index deployment
- [ ] Query API (to be added to services/api)
- [ ] Custom model training (Phase 2)

---

## Phase 1: MVP Demo (Week 1)

### Day 1-2: Generate Embeddings with Vision API

```python
# ml/src/generate_embeddings_vision_api.py
from google.cloud import vision
import numpy as np
import pandas as pd
from pathlib import Path
import pickle

def generate_vision_embeddings(image_dir: str, manifest_csv: str, output_file: str):
    """
    Generate embeddings for all images using Google Cloud Vision API.

    Args:
        image_dir: Directory containing building images
        manifest_csv: CSV with image metadata
        output_file: Where to save embeddings
    """
    client = vision.ImageAnnotatorClient()

    df = pd.read_csv(manifest_csv)
    embeddings = []

    for idx, row in df.iterrows():
        img_path = row['local_path']

        # Read image
        with open(img_path, 'rb') as f:
            content = f.read()

        image = vision.Image(content=content)

        # Get image properties (contains embedding-like features)
        response = client.image_properties(image=image)

        # Alternative: Use landmark detection which gives better features
        response = client.landmark_detection(image=image)

        # For actual embeddings, we'll use Web Detection
        response = client.web_detection(image=image)

        # Store features
        embeddings.append({
            'image_hash': row['image_hash'],
            'building_id': row['building_id'],
            'building_name': row['building_name'],
            'embedding': extract_features(response),  # Custom feature extraction
            'latitude': row.get('latitude'),
            'longitude': row.get('longitude')
        })

        if idx % 10 == 0:
            print(f"Processed {idx}/{len(df)} images")

    # Save embeddings
    with open(output_file, 'wb') as f:
        pickle.dump(embeddings, f)

    print(f"✓ Saved {len(embeddings)} embeddings to {output_file}")

# Run for your dataset
generate_vision_embeddings(
    image_dir='/data/images',
    manifest_csv='/data/images/combined_manifest.csv',
    output_file='/data/embeddings/vision_api_embeddings.pkl'
)
```

**Cost:** ~2,000 images × $0.0015 = **$3**

---

### Day 3-4: Set Up Vertex AI Vector Search

```python
# ml/src/setup_vector_db.py
from google.cloud import aiplatform
import numpy as np

def create_vector_index(embeddings_file: str, project_id: str, location: str):
    """
    Create Vertex AI Vector Search index.

    Args:
        embeddings_file: Pickle file with embeddings
        project_id: GCP project ID
        location: GCP region (us-central1)
    """
    aiplatform.init(project=project_id, location=location)

    # Load embeddings
    with open(embeddings_file, 'rb') as f:
        embeddings = pickle.load(f)

    # Format for Vertex AI
    # Each record: {id, embedding, metadata}
    records = []
    for emb in embeddings:
        records.append({
            "id": emb['image_hash'],
            "embedding": emb['embedding'],
            "restricts": [
                {"namespace": "building_id", "allow": [str(emb['building_id'])]},
                {"namespace": "building_name", "allow": [emb['building_name']]}
            ],
            "numeric_restricts": [
                {"namespace": "latitude", "value_double": emb['latitude']},
                {"namespace": "longitude", "value_double": emb['longitude']}
            ]
        })

    # Create index
    index = aiplatform.MatchingEngineIndex.create_tree_ah_index(
        display_name="historicam-buildings-v1",
        dimensions=2048,  # Vision API embedding size
        approximate_neighbors_count=10,
        distance_measure_type="DOT_PRODUCT_DISTANCE",
        description="Harvard building image embeddings"
    )

    # Deploy index
    endpoint = aiplatform.MatchingEngineIndexEndpoint.create(
        display_name="historicam-endpoint-v1"
    )

    endpoint.deploy_index(
        index=index,
        deployed_index_id="historicam_v1"
    )

    print(f"✓ Vector index deployed at: {endpoint.resource_name}")
    return endpoint

# Setup
endpoint = create_vector_index(
    embeddings_file='/data/embeddings/vision_api_embeddings.pkl',
    project_id='your-project-id',
    location='us-central1'
)
```

**Cost:** Vertex AI Vector Search = **~$50/month** for 2k vectors

---

### Day 5-6: Build Query API

```python
# api-service/src/routers/identify.py
from fastapi import APIRouter, UploadFile, File, HTTPException
from google.cloud import vision, aiplatform
from typing import List, Optional
import numpy as np
from pydantic import BaseModel

router = APIRouter()

class IdentificationResult(BaseModel):
    building_id: int
    building_name: str
    confidence: float
    image_url: str
    facts: List[str]

class IdentificationRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None

def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculate distance in meters between two GPS coordinates."""
    from math import radians, cos, sin, asin, sqrt

    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371000  # Radius of earth in meters
    return c * r

@router.post("/identify", response_model=List[IdentificationResult])
async def identify_landmark(
    image: UploadFile = File(...),
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    top_k: int = 3
):
    """
    Identify a landmark from an uploaded image.

    Args:
        image: User photo
        latitude: GPS latitude (optional but preferred)
        longitude: GPS longitude (optional but preferred)
        top_k: Number of results to return

    Returns:
        List of potential matches with confidence scores
    """

    # Step 1: Generate embedding for user photo
    vision_client = vision.ImageAnnotatorClient()
    content = await image.read()
    image_obj = vision.Image(content=content)

    # Get embedding (using web detection as proxy)
    response = vision_client.web_detection(image=image_obj)
    user_embedding = extract_features(response)

    # Step 2: GPS filtering (if available)
    filters = []
    if latitude and longitude:
        # Filter to buildings within 500m radius
        # This is done client-side by filtering results
        nearby_filter = lambda building: (
            haversine_distance(
                latitude, longitude,
                building['latitude'], building['longitude']
            ) < 500  # 500 meter radius
        )
    else:
        nearby_filter = None

    # Step 3: Query vector database
    endpoint = aiplatform.MatchingEngineIndexEndpoint(
        index_endpoint_name="projects/YOUR_PROJECT/locations/us-central1/indexEndpoints/YOUR_ENDPOINT_ID"
    )

    response = endpoint.find_neighbors(
        deployed_index_id="historicam_v1",
        queries=[user_embedding],
        num_neighbors=top_k * 3  # Get extras for GPS filtering
    )

    # Step 4: Filter by GPS and aggregate by building
    matches = response[0]
    building_scores = {}  # building_id -> {max_score, name, images}

    for match in matches:
        metadata = get_metadata(match.id)  # Fetch from database
        building_id = metadata['building_id']

        # Apply GPS filter
        if nearby_filter and not nearby_filter(metadata):
            continue

        # Aggregate scores per building (keep max score)
        if building_id not in building_scores:
            building_scores[building_id] = {
                'building_id': building_id,
                'building_name': metadata['building_name'],
                'confidence': match.distance,
                'images': []
            }

        building_scores[building_id]['confidence'] = max(
            building_scores[building_id]['confidence'],
            match.distance
        )
        building_scores[building_id]['images'].append(metadata['image_url'])

    # Step 5: Sort by confidence and return top_k
    results = sorted(
        building_scores.values(),
        key=lambda x: x['confidence'],
        reverse=True
    )[:top_k]

    # Step 6: Enrich with facts from database
    for result in results:
        result['facts'] = get_building_facts(result['building_id'])

    # Step 7: Confidence thresholding
    if results and results[0]['confidence'] < 0.60:
        raise HTTPException(
            status_code=404,
            detail="No confident match found. Please try a clearer photo or enable GPS."
        )

    return results


@router.get("/nearby")
async def get_nearby_landmarks(
    latitude: float,
    longitude: float,
    radius: int = 500
):
    """Get all landmarks within radius of GPS coordinates."""
    # Query database for nearby buildings
    buildings = query_nearby_buildings(latitude, longitude, radius)
    return buildings
```

---

### Day 7: Frontend Integration

```typescript
// apps/mobile/src/services/identification.ts
export async function identifyLandmark(
  photoBlob: Blob,
  gpsLocation?: { latitude: number; longitude: number }
): Promise<IdentificationResult[]> {

  const formData = new FormData();
  formData.append('image', photoBlob);

  const params = new URLSearchParams();
  if (gpsLocation) {
    params.set('latitude', gpsLocation.latitude.toString());
    params.set('longitude', gpsLocation.longitude.toString());
  }

  const response = await fetch(
    `${API_URL}/identify?${params}`,
    {
      method: 'POST',
      body: formData
    }
  );

  if (!response.ok) {
    throw new Error('Failed to identify landmark');
  }

  return response.json();
}

// Usage in component
const handlePhotoCapture = async (photo: Blob) => {
  setLoading(true);

  try {
    // Get GPS if available
    const gps = await getCurrentPosition();

    // Identify landmark
    const results = await identifyLandmark(photo, gps);

    if (results[0].confidence > 0.80) {
      // Show single result
      showResult(results[0]);
    } else {
      // Show top 3 for user to choose
      showMultipleResults(results);
    }
  } catch (error) {
    showError("Couldn't identify landmark. Try again?");
  } finally {
    setLoading(false);
  }
};
```

**Week 1 Result:** Working demo with 75-85% accuracy ✅

---

## Phase 2: Production (Weeks 2-6)

### Week 2-3: Fine-tune Custom Model

**Why MobileNetV3 + ArcFace Loss:**
- MobileNetV3: Fast inference, mobile-friendly
- ArcFace loss: Better feature learning for retrieval tasks
- 512-dim embeddings: Smaller than Vision API, faster search

```python
# ml/src/train_model.py
import torch
import torch.nn as nn
from torchvision import models
import pytorch_lightning as pl

class BuildingEmbeddingModel(pl.LightningModule):
    """
    MobileNetV3 with ArcFace loss for building identification.
    """

    def __init__(
        self,
        num_buildings: int,
        embedding_dim: int = 512,
        arcface_scale: float = 30.0,
        arcface_margin: float = 0.5
    ):
        super().__init__()

        # Backbone: MobileNetV3
        self.backbone = models.mobilenet_v3_large(pretrained=True)

        # Remove classifier, keep features
        self.backbone.classifier = nn.Identity()

        # Embedding projection
        self.embedding = nn.Sequential(
            nn.Linear(960, embedding_dim),
            nn.BatchNorm1d(embedding_dim)
        )

        # ArcFace head (for training only)
        self.arcface = ArcFaceHead(
            embedding_dim=embedding_dim,
            num_classes=num_buildings,
            scale=arcface_scale,
            margin=arcface_margin
        )

    def forward(self, x):
        features = self.backbone(x)
        embeddings = self.embedding(features)
        # L2 normalize embeddings
        embeddings = nn.functional.normalize(embeddings, p=2, dim=1)
        return embeddings

    def training_step(self, batch, batch_idx):
        images, building_ids = batch
        embeddings = self(images)

        # ArcFace loss
        logits = self.arcface(embeddings, building_ids)
        loss = nn.functional.cross_entropy(logits, building_ids)

        self.log('train_loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        images, building_ids = batch
        embeddings = self(images)

        # For validation: compute retrieval metrics
        # (Compare embeddings to database, check if correct building in top-5)
        top5_accuracy = compute_retrieval_accuracy(embeddings, building_ids)
        self.log('val_top5_acc', top5_accuracy)


# Training script
def train_model(
    image_dir: str,
    manifest_csv: str,
    output_model: str,
    epochs: int = 20,
    batch_size: int = 32
):
    """
    Train custom embedding model.

    Expected training time: 2-4 hours on Vertex AI GPU
    """

    # Create dataset
    dataset = BuildingImageDataset(image_dir, manifest_csv)
    train_loader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    # Create model
    num_buildings = dataset.num_buildings
    model = BuildingEmbeddingModel(num_buildings=num_buildings)

    # Train on Vertex AI
    trainer = pl.Trainer(
        max_epochs=epochs,
        accelerator='gpu',
        devices=1,
        precision=16,  # Mixed precision for speed
    )

    trainer.fit(model, train_loader)

    # Save model
    torch.save(model.state_dict(), output_model)
    print(f"✓ Model saved to {output_model}")

# Run training
train_model(
    image_dir='/data/images',
    manifest_csv='/data/images/combined_manifest.csv',
    output_model='/data/models/mobilenet_arcface_v1.pth',
    epochs=20
)
```

**Training cost:** Vertex AI GPU (T4) = ~$1.50/hour × 3 hours = **$5**

---

### Week 4: Generate Custom Embeddings & Rebuild Vector DB

```python
# ml/src/generate_custom_embeddings.py
def generate_custom_embeddings(
    model_path: str,
    image_dir: str,
    manifest_csv: str,
    output_file: str
):
    """Generate embeddings using fine-tuned model."""

    # Load model
    model = BuildingEmbeddingModel.load_from_checkpoint(model_path)
    model.eval()
    model = model.cuda()

    df = pd.read_csv(manifest_csv)
    embeddings = []

    with torch.no_grad():
        for idx, row in df.iterrows():
            img = load_and_preprocess_image(row['local_path'])
            img = img.cuda()

            embedding = model(img.unsqueeze(0)).cpu().numpy()[0]

            embeddings.append({
                'image_hash': row['image_hash'],
                'building_id': row['building_id'],
                'building_name': row['building_name'],
                'embedding': embedding,  # 512-dim
                'latitude': row.get('latitude'),
                'longitude': row.get('longitude')
            })

    # Save
    with open(output_file, 'wb') as f:
        pickle.dump(embeddings, f)

    print(f"✓ Generated {len(embeddings)} custom embeddings")

# Run
generate_custom_embeddings(
    model_path='/data/models/mobilenet_arcface_v1.pth',
    image_dir='/data/images',
    manifest_csv='/data/images/combined_manifest.csv',
    output_file='/data/embeddings/custom_embeddings_v1.pkl'
)
```

---

### Week 5-6: Deploy Custom Model + Switch to Self-hosted Inference

**Option A: Deploy on Cloud Run (Recommended)**

```python
# api-service/src/inference.py
import torch
from PIL import Image
import numpy as np

# Load model once at startup
model = BuildingEmbeddingModel.load_from_checkpoint('model.pth')
model.eval()
model = model.cpu()  # CPU inference on Cloud Run

def generate_embedding(image_bytes: bytes) -> np.ndarray:
    """Generate embedding for user photo."""
    img = Image.open(BytesIO(image_bytes))
    img = preprocess(img)  # Resize, normalize

    with torch.no_grad():
        embedding = model(img.unsqueeze(0)).numpy()[0]

    return embedding
```

**Deployment:**
```dockerfile
# api-service/Dockerfile
FROM python:3.11-slim

# Install dependencies
RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Copy model
COPY model.pth /app/model.pth

# Run FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Cost:** Cloud Run (CPU) = ~$5-10/month for 1000s of requests

---

## Social/Crowdsourcing Features

### User-uploaded Content Flow

```python
@router.post("/contribute")
async def contribute_landmark(
    image: UploadFile,
    landmark_name: str,
    latitude: float,
    longitude: float,
    facts: List[str],
    user_id: str
):
    """
    Allow users to contribute new landmarks/facts.

    Workflow:
    1. User uploads photo + info
    2. Generate embedding (using current model)
    3. Store in "pending" table
    4. Admin reviews/approves
    5. Add to vector DB
    6. Track user contributions for "tour guide" ranking
    """

    # Generate embedding
    content = await image.read()
    embedding = generate_embedding(content)

    # Store in database
    contribution_id = db.insert_pending_contribution({
        'user_id': user_id,
        'landmark_name': landmark_name,
        'latitude': latitude,
        'longitude': longitude,
        'facts': facts,
        'embedding': embedding,
        'status': 'pending',
        'upvotes': 0
    })

    return {"contribution_id": contribution_id, "status": "pending_review"}


@router.post("/approve_contribution/{contribution_id}")
async def approve_contribution(contribution_id: int):
    """Admin approves contribution -> add to main DB."""

    contribution = db.get_contribution(contribution_id)

    # Add to main landmarks table
    landmark_id = db.insert_landmark(contribution)

    # Add embedding to vector DB
    vector_db.add_embedding(
        id=f"user_{landmark_id}",
        embedding=contribution['embedding'],
        metadata={
            'building_id': landmark_id,
            'building_name': contribution['landmark_name'],
            'latitude': contribution['latitude'],
            'longitude': contribution['longitude']
        }
    )

    # Update user stats (for tour guide leaderboard)
    db.increment_user_contributions(contribution['user_id'])

    return {"status": "approved", "landmark_id": landmark_id}
```

**This approach supports:**
- ✅ Dynamic content (users add landmarks)
- ✅ Vector DB easily grows
- ✅ Social features (upvotes, rankings)
- ✅ No retraining needed (just add embeddings)

---

## Cost Summary

### Phase 1 (Week 1 - MVP)
- Vision API embeddings: **$3** one-time
- Vertex AI Vector Search: **$50/month**
- Cloud Run API: **$5/month**
- **Total: ~$60/month**

### Phase 2 (Production)
- Model training: **$5** one-time (Vertex AI GPU)
- Vector DB: **$30/month** (smaller embeddings)
- Cloud Run API + Model: **$10/month**
- **Total: ~$40/month**

**Well within your $50-100 budget!** ✅

---

## Next Steps

1. **This week:** Run enhanced Wikimedia scraper to get more images
2. **Tomorrow:** Start implementing Phase 1 (Vision API + Vector DB)
3. **Week 2:** Begin fine-tuning custom model in parallel

Want me to create the actual code files for Phase 1 to get you started?
