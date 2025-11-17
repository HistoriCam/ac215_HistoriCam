"""
Vertex AI Multimodal Embedding model implementation using new Generative AI SDK.
"""
from typing import List
import base64
from vertexai.preview.vision_models import MultiModalEmbeddingModel, Image as VisionImage
from .base import EmbeddingModel


class MultimodalEmbeddings(EmbeddingModel):
    """Vertex AI Multimodal Embedding model using the new Generative AI SDK."""

    def __init__(self, dimension: int = 512):
        """
        Initialize Vertex AI Multimodal model.

        Args:
            dimension: Embedding dimension (128, 256, 512, or 1408)
        """
        if dimension not in [128, 256, 512, 1408]:
            raise ValueError(f"Invalid dimension: {dimension}. Must be 128, 256, 512, or 1408")

        # Use the preview API which has the updated interface
        self.model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")
        self._dimension = dimension

    def generate_embedding(self, image_bytes: bytes) -> List[float]:
        """
        Generate embedding from image bytes using Vertex AI.

        Args:
            image_bytes: Raw image bytes

        Returns:
            Embedding vector as list of floats
        """
        # Create Image object from bytes
        image = VisionImage(image_bytes=image_bytes)

        # Get embeddings using the new API
        embeddings = self.model.get_embeddings(
            image=image,
            dimension=self._dimension
        )

        # Return image embedding vector
        return embeddings.image_embedding

    @property
    def dimension(self) -> int:
        """Return embedding dimension."""
        return self._dimension

    @property
    def model_name(self) -> str:
        """Return model identifier."""
        return f"multimodal-{self._dimension}d"
