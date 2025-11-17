"""
Abstract base class for embedding models.
"""
from abc import ABC, abstractmethod
from typing import List


class EmbeddingModel(ABC):
    """Base class for image embedding models."""

    @abstractmethod
    def generate_embedding(self, image_bytes: bytes) -> List[float]:
        """
        Generate embedding vector from image bytes.

        Args:
            image_bytes: Raw image bytes (JPEG, PNG, etc.)

        Returns:
            Embedding vector as list of floats
        """
        pass

    @property
    @abstractmethod
    def dimension(self) -> int:
        """Return embedding dimension."""
        pass

    @property
    @abstractmethod
    def model_name(self) -> str:
        """Return model identifier (e.g., 'multimodal-512d')."""
        pass
