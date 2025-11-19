"""
Vision service for building identification using in-memory embedding similarity
"""
import os
import json
from typing import Dict, List
from collections import Counter
import numpy as np
import vertexai
from google.cloud import storage
from vertexai.vision_models import MultiModalEmbeddingModel, Image
from .image_utils import resize_image_if_needed


class VisionService:
    """Service for identifying buildings from images"""

    def __init__(self):
        """Initialize embedding model and load index from GCS"""
        # Load configuration from environment
        self.project_id = os.getenv("GCP_PROJECT")
        self.location = os.getenv("GCP_LOCATION", "us-central1")
        self.embeddings_path = os.getenv("EMBEDDINGS_PATH")
        self.embedding_dimension = int(os.getenv("EMBEDDING_DIMENSION", "512"))

        # Validate required config
        if not all([self.project_id, self.embeddings_path]):
            raise ValueError(
                "Missing required environment variables: "
                "GCP_PROJECT, EMBEDDINGS_PATH"
            )

        # Initialize Vertex AI for embedding model only
        vertexai.init(project=self.project_id, location=self.location)

        # Initialize embedding model
        print("Loading embedding model...")
        self.model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")

        # Load embeddings index from GCS
        print(f"Loading embeddings from {self.embeddings_path}...")
        self.index = self._load_embeddings_from_gcs(self.embeddings_path)
        print(f"Loaded {len(self.index)} embeddings into memory")

        # Configuration for classification
        self.top_k = int(os.getenv("TOP_K", "5"))
        self.confidence_threshold = float(os.getenv("CONFIDENCE_THRESHOLD", "0.7"))
        self.backup_threshold = float(os.getenv("BACKUP_THRESHOLD", "0.4"))

    def _load_embeddings_from_gcs(self, gcs_path: str) -> Dict[str, np.ndarray]:
        """
        Load embeddings from GCS JSONL file into memory.

        Args:
            gcs_path: GCS path to embeddings JSONL (gs://bucket/path/embeddings.jsonl)

        Returns:
            Dict mapping image_id to embedding vector (numpy array)
        """
        # Parse GCS path
        if not gcs_path.startswith("gs://"):
            raise ValueError(f"Invalid GCS path: {gcs_path}")

        path_parts = gcs_path[5:].split("/", 1)
        bucket_name = path_parts[0]
        blob_path = path_parts[1] if len(path_parts) > 1 else ""

        # Download embeddings JSONL
        client = storage.Client(project=self.project_id)
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(blob_path)

        embeddings_json = blob.download_as_text()

        # Parse JSONL and convert to numpy arrays
        index = {}
        for line in embeddings_json.strip().split("\n"):
            if line:
                record = json.loads(line)
                index[record["id"]] = np.array(record["embedding"], dtype=np.float32)

        return index

    def _generate_embedding(self, image_bytes: bytes) -> np.ndarray:
        """Generate embedding from image bytes"""
        # Preprocess image (must match training preprocessing!)
        preprocessed_bytes = resize_image_if_needed(image_bytes)

        # Generate embedding with Image wrapper
        response = self.model.get_embeddings(
            image=Image(preprocessed_bytes),
            dimension=self.embedding_dimension
        )
        return np.array(response.image_embedding, dtype=np.float32)

    def _compute_similarities(self, query_embedding: np.ndarray) -> List[Dict]:
        """
        Compute exact cosine similarities between query and all indexed embeddings.

        Args:
            query_embedding: Query embedding vector

        Returns:
            List of dicts with id, building_id, and similarity (sorted by similarity desc)
        """
        # Normalize query embedding for cosine similarity
        query_norm = query_embedding / np.linalg.norm(query_embedding)

        # Compute dot products with all indexed embeddings (cosine similarity)
        similarities = {}
        for image_id, stored_embedding in self.index.items():
            stored_norm = stored_embedding / np.linalg.norm(stored_embedding)
            similarity = float(np.dot(query_norm, stored_norm))
            similarities[image_id] = similarity

        # Sort by similarity (descending) and return top-k
        sorted_results = sorted(similarities.items(), key=lambda x: x[1], reverse=True)

        results = []
        for image_id, similarity in sorted_results[:self.top_k]:
            # Parse ID format: "building_id_image_hash"
            parts = image_id.split('_', 1)
            building_id = parts[0] if len(parts) > 0 else image_id

            results.append({
                'id': image_id,
                'building_id': building_id,
                'similarity': similarity
            })

        return results

    def _classify_results(self, results: List[Dict]) -> Dict:
        """
        Apply classification logic to determine building identity.

        Uses majority voting from top-k results with confidence thresholds.
        """
        if not results:
            return {
                "status": "no_match",
                "message": "No similar buildings found",
                "building_id": None,
                "confidence": 0.0
            }

        # Results already have similarity scores from _compute_similarities
        # Filter by confidence threshold
        confident_results = [r for r in results if r['similarity'] >= self.confidence_threshold]

        if confident_results:
            # Confident match: use majority vote
            building_ids = [r['building_id'] for r in confident_results]
            most_common_building = Counter(building_ids).most_common(1)[0][0]

            # Calculate average similarity for the most common building
            building_similarities = [
                r['similarity'] for r in confident_results
                if r['building_id'] == most_common_building
            ]
            avg_similarity = sum(building_similarities) / len(building_similarities)

            return {
                "status": "confident",
                "building_id": most_common_building,
                "confidence": round(avg_similarity, 3),
                "matches": [
                    {"building_id": r['building_id'], "similarity": round(r['similarity'], 3)}
                    for r in confident_results
                ]
            }

        # Check backup threshold
        backup_results = [r for r in results if r['similarity'] >= self.backup_threshold]

        if backup_results:
            # Uncertain match
            building_ids = [r['building_id'] for r in backup_results]
            most_common_building = Counter(building_ids).most_common(1)[0][0]

            building_similarities = [
                r['similarity'] for r in backup_results
                if r['building_id'] == most_common_building
            ]
            avg_similarity = sum(building_similarities) / len(building_similarities)

            return {
                "status": "uncertain",
                "message": "Low confidence match - building might be nearby",
                "building_id": most_common_building,
                "confidence": round(avg_similarity, 3),
                "matches": [
                    {"building_id": r['building_id'], "similarity": round(r['similarity'], 3)}
                    for r in backup_results
                ]
            }

        # No match
        return {
            "status": "no_match",
            "message": "No similar buildings found in database",
            "building_id": None,
            "confidence": round(results[0]['similarity'], 3) if results else 0.0
        }

    async def identify_building(self, image_bytes: bytes) -> Dict:
        """
        Main method to identify a building from image bytes.

        Args:
            image_bytes: Raw image file bytes

        Returns:
            Classification result with status, building_id, and confidence
        """
        # Generate embedding
        embedding = self._generate_embedding(image_bytes)

        # Compute similarities with all indexed embeddings
        results = self._compute_similarities(embedding)

        # Classify results
        classification = self._classify_results(results)

        return classification
