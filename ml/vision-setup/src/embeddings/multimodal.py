"""
Multimodal embedding generation using Vertex AI.
"""
from vertexai.vision_models import MultiModalEmbeddingModel, Image


class MultimodalEmbeddings:
    """Wrapper for Vertex AI multimodal embeddings."""

    def __init__(self, dimension: int = 512):
        """
        Initialize multimodal embedding model.

        Args:
            dimension: Embedding dimension (128, 256, 512, or 1408)
        """
        self.dimension = dimension
        self.model_name = f"multimodal-{dimension}d"
        self.model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")

    def generate_embedding(self, image_bytes: bytes) -> list:
        """
        Generate embedding for an image.

        Args:
            image_bytes: Raw image bytes

        Returns:
            List of floats representing the embedding
        """
        response = self.model.get_embeddings(
            image=Image(image_bytes),
            dimension=self.dimension
        )
        return response.image_embedding
