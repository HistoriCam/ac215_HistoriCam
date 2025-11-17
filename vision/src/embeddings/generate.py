"""
Generate embeddings from GCS images and save as JSONL for Vector Search.
"""
import json
import argparse
import io
from pathlib import Path
from typing import Optional
import pandas as pd
from google.cloud import storage
import vertexai
from PIL import Image

from .multimodal import MultimodalEmbeddings
from ..config import Config


def resize_image_if_needed(image_bytes: bytes, max_size_mb: float = 20.0, max_dimension: int = 2048) -> bytes:
    """
    Resize image if it exceeds size limit or dimension limit.

    Args:
        image_bytes: Original image bytes
        max_size_mb: Maximum size in MB (default 20MB, well below 27MB API limit)
        max_dimension: Maximum width or height in pixels

    Returns:
        Resized image bytes (JPEG format) or original if already small enough
    """
    size_mb = len(image_bytes) / (1024 * 1024)

    # Open image to check dimensions
    try:
        img = Image.open(io.BytesIO(image_bytes))
        width, height = img.size
        needs_resize = size_mb > max_size_mb or max(width, height) > max_dimension

        if not needs_resize:
            return image_bytes

        # Calculate new dimensions maintaining aspect ratio
        if width > height:
            new_width = min(width, max_dimension)
            new_height = int(height * (new_width / width))
        else:
            new_height = min(height, max_dimension)
            new_width = int(width * (new_height / height))

        # Resize image
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Convert to RGB if necessary (handles RGBA, grayscale, etc.)
        if img_resized.mode != 'RGB':
            img_resized = img_resized.convert('RGB')

        # Save to bytes with quality optimization
        output = io.BytesIO()
        img_resized.save(output, format='JPEG', quality=85, optimize=True)
        resized_bytes = output.getvalue()

        new_size_mb = len(resized_bytes) / (1024 * 1024)
        print(f"    Resized: {size_mb:.2f}MB ({width}x{height}) → {new_size_mb:.2f}MB ({new_width}x{new_height})")

        return resized_bytes

    except Exception as e:
        print(f"    Warning: Could not resize image: {e}, using original")
        return image_bytes


def generate_embeddings_from_gcs(
    bucket_name: str,
    version: str,
    model_name: str = "multimodal",
    dimension: int = 512,
    project_id: Optional[str] = None,
    location: str = "us-central1",
    output_local: Optional[Path] = None,
    exclude_images_file: Optional[Path] = None
):
    """
    Generate embeddings from images in GCS and save as JSONL.

    Args:
        bucket_name: GCS bucket name
        version: Data version (e.g., 'v20251015_143022' or 'latest')
        model_name: Embedding model to use ('multimodal')
        dimension: Embedding dimension
        project_id: GCP project ID
        location: GCP location
        output_local: Optional local path to save JSONL (for testing)
        exclude_images_file: Path to file with image IDs to exclude (test set)
    """
    # Initialize GCS client
    storage_client = storage.Client(project=project_id)
    bucket = storage_client.bucket(bucket_name)

    # Resolve "latest" version if specified
    if version == "latest":
        print("Resolving 'latest' version from GCS...")
        from gcs_utils import GCSDataManager
        manager = GCSDataManager(bucket_name, project_id=project_id)
        versions = manager.list_versions()
        if not versions:
            raise ValueError("No versions found in bucket")
        version = versions[-1]['version']  # Get most recent
        print(f"Using latest version: {version}")

    # Load exclude list if specified
    exclude_images = set()
    if exclude_images_file:
        exclude_path = Path(exclude_images_file)
        if exclude_path.exists():
            with open(exclude_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        exclude_images.add(str(line))
            print(f"Excluding {len(exclude_images)} test images from embeddings")
        else:
            print(f"Warning: Exclude file not found: {exclude_path}")

    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)

    # Initialize model
    print(f"Initializing {model_name} model with dimension {dimension}...")
    if model_name == "multimodal":
        model = MultimodalEmbeddings(dimension=dimension)
    else:
        raise ValueError(f"Unknown model: {model_name}")

    # Download manifest
    manifest_path = f"manifests/{version}/image_manifest.csv"
    print(f"Downloading manifest: gs://{bucket_name}/{manifest_path}")

    manifest_blob = bucket.blob(manifest_path)
    manifest_content = manifest_blob.download_as_text()
    df = pd.read_csv(pd.io.common.StringIO(manifest_content))

    print(f"Found {len(df)} images in manifest")

    # Generate embeddings
    embeddings_data = []

    for idx, row in df.iterrows():
        building_id = str(row['building_id'])
        image_hash = row['image_hash']

        # Skip if in exclude list (test set) - check by image ID
        image_id = f"{building_id}_{image_hash}"
        if image_id in exclude_images:
            continue

        image_filename = row.get('filename', f"{image_hash}.jpg")

        # Construct GCS path
        gcs_image_path = f"images/{version}/{building_id}/{image_filename}"

        try:
            # Download image
            image_blob = bucket.blob(gcs_image_path)
            image_bytes = image_blob.download_as_bytes()

            # Resize if needed to stay under API limits (27MB)
            image_bytes = resize_image_if_needed(image_bytes)

            # Generate embedding
            embedding = model.generate_embedding(image_bytes)

            # Format for Vector Search JSONL
            record = {
                "id": f"{building_id}_{image_hash}",
                "embedding": embedding,
                "restricts": [
                    {"namespace": "building_id", "allow": [building_id]},
                    {"namespace": "building_name", "allow": [row.get('building_name', '')]},
                ]
            }

            # Add GPS coordinates if available
            if pd.notna(row.get('latitude')) and pd.notna(row.get('longitude')):
                record["numeric_restricts"] = [
                    {"namespace": "latitude", "value_double": float(row['latitude'])},
                    {"namespace": "longitude", "value_double": float(row['longitude'])},
                ]

            embeddings_data.append(record)

            if (idx + 1) % 10 == 0:
                print(f"  Processed {idx + 1}/{len(df)} images...")

        except Exception as e:
            print(f"  Failed to process {gcs_image_path}: {e}")
            continue

    print(f"\nSuccessfully generated {len(embeddings_data)} embeddings")

    # Save as JSONL
    output_gcs_path = f"embeddings/{version}/{model.model_name}/embeddings.jsonl"

    # Save locally first (if specified)
    if output_local:
        output_local = Path(output_local)
        output_local.parent.mkdir(parents=True, exist_ok=True)
        with open(output_local, 'w') as f:
            for record in embeddings_data:
                f.write(json.dumps(record) + '\n')
        print(f"Saved locally: {output_local}")

    # Save to GCS
    print(f"Uploading to gs://{bucket_name}/{output_gcs_path}")
    output_blob = bucket.blob(output_gcs_path)

    # Convert to JSONL string
    jsonl_content = '\n'.join(json.dumps(record) for record in embeddings_data)
    output_blob.upload_from_string(jsonl_content, content_type='application/jsonl')

    print(f"✓ Embeddings saved to gs://{bucket_name}/{output_gcs_path}")
    return output_gcs_path


def main():
    parser = argparse.ArgumentParser(description="Generate embeddings from GCS images")
    parser.add_argument("--bucket", required=True, help="GCS bucket name")
    parser.add_argument("--version", required=True, help="Data version (e.g., v20251015_143022 or 'latest')")
    parser.add_argument("--model", default="multimodal", help="Model name (default: multimodal)")
    parser.add_argument("--dimension", type=int, default=512, help="Embedding dimension (default: 512)")
    parser.add_argument("--project", help="GCP project ID (uses default if not specified)")
    parser.add_argument("--location", default="us-central1", help="GCP location (default: us-central1)")
    parser.add_argument("--output-local", help="Optional local path to save JSONL")
    parser.add_argument("--exclude-images", help="Path to file with image IDs to exclude (test set)")

    args = parser.parse_args()

    generate_embeddings_from_gcs(
        bucket_name=args.bucket,
        version=args.version,
        model_name=args.model,
        dimension=args.dimension,
        project_id=args.project,
        location=args.location,
        output_local=args.output_local,
        exclude_images_file=args.exclude_images
    )


if __name__ == "__main__":
    main()
