#!/usr/bin/env python3
"""
Generate test/train split for vision pipeline evaluation.
Excludes 20% of images per building (only for buildings with 2+ images).
"""
import random
from pathlib import Path
from collections import defaultdict
from google.cloud import storage
import pandas as pd
import io


def generate_test_split(
    bucket_name: str = "historicam-images",
    version: str = "latest",
    seed: int = 42,
    test_ratio: float = 0.2,
    output_path: Path = None
):
    """
    Generate test image split.

    Args:
        bucket_name: GCS bucket name
        version: Data version or 'latest'
        seed: Random seed for reproducibility
        test_ratio: Fraction of images to hold out per building
        output_path: Where to save test_images.txt (default: test_data/test_images.txt)
    """
    # Set random seed
    random.seed(seed)

    # Get latest version if needed
    if version == "latest":
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        metadata_blob = bucket.blob("metadata/versions.json")

        import json
        metadata = json.loads(metadata_blob.download_as_text())
        versions = metadata.get("versions", [])
        if not versions:
            raise ValueError("No versions found")
        version = versions[-1]["version"]
        print(f"Using latest version: {version}")

    # Download manifest
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    manifest_path = f"manifests/{version}/image_manifest.csv"

    print(f"Downloading manifest: gs://{bucket_name}/{manifest_path}")
    blob = bucket.blob(manifest_path)
    manifest_content = blob.download_as_text()
    df = pd.read_csv(io.StringIO(manifest_content))

    print(f"Total images in manifest: {len(df)}")

    # Group images by building
    building_images = defaultdict(list)
    for _, row in df.iterrows():
        building_id = str(row['building_id'])
        image_hash = row['image_hash']
        image_id = f"{building_id}_{image_hash}"
        building_images[building_id].append(image_id)

    # Sample test images (skip buildings with only 1 image)
    test_images = []
    skipped_buildings = []

    for building_id, images in sorted(building_images.items()):
        if len(images) == 1:
            skipped_buildings.append(building_id)
            continue

        test_size = max(1, int(len(images) * test_ratio))
        test_sample = random.sample(images, test_size)
        test_images.extend(test_sample)

    test_images.sort()

    # Print summary
    print(f"\nBuildings with 1 image (excluded from test set): {len(skipped_buildings)}")
    if skipped_buildings:
        print(f"  IDs: {', '.join(skipped_buildings)}")
    print(f"\nTest images: {len(test_images)}")
    print(f"Train images: {len(df) - len(test_images)}")
    print(f"Test ratio: {len(test_images) / len(df) * 100:.1f}%")

    # Save to file
    if output_path is None:
        output_path = Path(__file__).parent / "test_images.txt"

    output_path = Path(output_path)
    with open(output_path, 'w') as f:
        f.write(f"# Test image IDs - ~{test_ratio*100:.0f}% of images per building\n")
        f.write(f"# Format: building_id_image_hash\n")
        f.write(f"# Total: {len(test_images)} test images ({len(test_images)/len(df)*100:.1f}% of {len(df)} total)\n")
        f.write(f"# Buildings with only 1 image are excluded from test set\n")
        f.write(f"#\n")
        for img_id in test_images:
            f.write(f"{img_id}\n")

    print(f"\n✓ Saved test split to: {output_path}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate test/train split")
    parser.add_argument("--bucket", default="historicam-images", help="GCS bucket name")
    parser.add_argument("--version", default="latest", help="Data version")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--test-ratio", type=float, default=0.2, help="Test ratio (default: 0.2)")
    parser.add_argument("--output", help="Output path (default: test_data/test_images.txt)")

    args = parser.parse_args()

    generate_test_split(
        bucket_name=args.bucket,
        version=args.version,
        seed=args.seed,
        test_ratio=args.test_ratio,
        output_path=args.output
    )
