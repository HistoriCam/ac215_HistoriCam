"""
Vision service for building identification using Vertex AI Vector Search
"""
import os
from typing import Dict, List
from collections import Counter
import vertexai
from google.cloud import aiplatform
from vertexai.vision_models import MultiModalEmbeddingModel


class VisionService:
    """Service for identifying buildings from images"""

    def __init__(self):
        """Initialize Vector Search connection and embedding model"""
        # Load configuration from environment
        self.project_id = os.getenv("GCP_PROJECT")
        self.location = os.getenv("GCP_LOCATION", "us-central1")
        self.endpoint_id = os.getenv("VERTEX_ENDPOINT_ID")
        self.deployed_index_id = os.getenv("DEPLOYED_INDEX_ID")
        self.embedding_dimension = int(os.getenv("EMBEDDING_DIMENSION", "512"))

        # Validate required config
        if not all([self.project_id, self.endpoint_id, self.deployed_index_id]):
            raise ValueError(
                "Missing required environment variables: "
                "GCP_PROJECT, VERTEX_ENDPOINT_ID, DEPLOYED_INDEX_ID"
            )

        # Initialize Vertex AI
        vertexai.init(project=self.project_id, location=self.location)
        aiplatform.init(project=self.project_id, location=self.location)

        # Initialize embedding model
        self.model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")

        # Initialize Vector Search endpoint
        self.endpoint = aiplatform.MatchingEngineIndexEndpoint(
            index_endpoint_name=f"projects/{self.project_id}/locations/{self.location}/indexEndpoints/{self.endpoint_id}"
        )

        # Configuration for classification
        self.top_k = int(os.getenv("TOP_K", "5"))
        self.confidence_threshold = float(os.getenv("CONFIDENCE_THRESHOLD", "0.7"))
        self.backup_threshold = float(os.getenv("BACKUP_THRESHOLD", "0.4"))

    def _generate_embedding(self, image_bytes: bytes) -> List[float]:
        """Generate embedding from image bytes"""
        response = self.model.get_embeddings(
            image=image_bytes,
            dimension=self.embedding_dimension
        )
        return response.image_embedding

    def _query_vector_search(self, embedding: List[float]) -> List[Dict]:
        """Query Vector Search index with embedding"""
        response = self.endpoint.find_neighbors(
            deployed_index_id=self.deployed_index_id,
            queries=[embedding],
            num_neighbors=self.top_k
        )

        # Parse results
        results = []
        if response and len(response) > 0:
            for neighbor in response[0]:
                # Parse ID format: "building_id_image_hash"
                parts = neighbor.id.split('_', 1)
                building_id = parts[0] if len(parts) > 0 else neighbor.id

                results.append({
                    'id': neighbor.id,
                    'building_id': building_id,
                    'distance': neighbor.distance
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

        # Convert distance to similarity (assuming DOT_PRODUCT_DISTANCE)
        # For normalized embeddings: similarity = 1 - distance
        for result in results:
            result['similarity'] = 1.0 - result['distance']

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

        # Query Vector Search
        results = self._query_vector_search(embedding)

        # Classify results
        classification = self._classify_results(results)

        return classification
