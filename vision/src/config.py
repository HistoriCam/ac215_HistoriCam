"""
Configuration for HistoriCam vision pipeline.
"""
import os
from dataclasses import dataclass


@dataclass
class Config:
    """Vision pipeline configuration."""

    # GCP Settings
    project_id: str = os.getenv("GCP_PROJECT", "")
    location: str = os.getenv("GCP_LOCATION", "us-central1")

    # GCS Settings
    bucket_name: str = os.getenv("GCS_BUCKET", "")

    # GCS Paths
    images_prefix: str = "images"
    manifests_prefix: str = "manifests"
    embeddings_prefix: str = "embeddings"

    # Vector Search Settings
    index_display_name: str = "historicam-buildings"
    endpoint_display_name: str = "historicam-endpoint"

    # Embedding Settings
    embedding_dimension: int = 512
    distance_measure: str = "DOT_PRODUCT_DISTANCE"  # Cosine similarity

    @classmethod
    def from_env(cls):
        """Create config from environment variables."""
        return cls()
