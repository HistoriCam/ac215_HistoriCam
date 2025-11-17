"""
Google Cloud Storage manager for uploading and versioning image data.
"""
import json
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List
from google.cloud import storage
import pandas as pd


class GCSDataManager:
    """Manages data uploads to GCS with versioning"""

    def __init__(self, bucket_name: str, project_id: Optional[str] = None):
        """
        Initialize GCS manager.

        Args:
            bucket_name: GCS bucket name
            project_id: GCP project ID (optional, uses default credentials if None)
        """
        self.bucket_name = bucket_name
        self.client = storage.Client(project=project_id)
        self.bucket = self.client.bucket(bucket_name)

    def upload_images_with_versioning(
        self,
        local_image_dir: Path,
        manifest_path: Path,
        version: Optional[str] = None
    ) -> Dict:
        """
        Upload images to GCS with versioning.

        Directory structure in GCS:
        gs://bucket/
          ├── images/
          │   └── v1/                    # Version directory
          │       ├── 1/                 # Building ID
          │       │   ├── abc123.jpg
          │       │   └── def456.jpg
          │       └── 2/
          │           └── xyz789.jpg
          ├── manifests/
          │   └── v1/
          │       └── image_manifest.csv
          └── metadata/
              └── versions.json          # Version metadata

        Args:
            local_image_dir: Local directory containing images
            manifest_path: Path to image manifest CSV
            version: Version string (auto-generated if None)

        Returns:
            Dict with upload summary
        """
        if version is None:
            version = f"v{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

        print(f"Uploading images with version: {version}")

        stats = {
            "version": version,
            "images_uploaded": 0,
            "bytes_uploaded": 0,
            "failed_uploads": 0
        }

        # Upload images (support both lowercase and uppercase extensions)
        image_dir = Path(local_image_dir)
        extensions = ["*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.png", "*.PNG", "*.tif", "*.TIF", "*.tiff", "*.TIFF"]

        for ext in extensions:
            for img_path in image_dir.rglob(ext):
                # Get building ID from parent directory
                building_id = img_path.parent.name
                if building_id == image_dir.name:
                    continue  # Skip if not in building subdirectory

                # Construct GCS path: images/{version}/{building_id}/{filename}
                gcs_path = f"images/{version}/{building_id}/{img_path.name}"

                try:
                    blob = self.bucket.blob(gcs_path)
                    blob.upload_from_filename(str(img_path))

                    stats["images_uploaded"] += 1
                    stats["bytes_uploaded"] += img_path.stat().st_size

                    if stats["images_uploaded"] % 10 == 0:
                        print(f"  Uploaded {stats['images_uploaded']} images...")

                except Exception as e:
                    print(f"  Failed to upload {img_path}: {e}")
                    stats["failed_uploads"] += 1

        # Upload manifest
        manifest_gcs_path = f"manifests/{version}/image_manifest.csv"
        try:
            blob = self.bucket.blob(manifest_gcs_path)
            blob.upload_from_filename(str(manifest_path))
            print(f"✓ Uploaded manifest to {manifest_gcs_path}")
        except Exception as e:
            print(f"  Failed to upload manifest: {e}")

        # Update version metadata
        self._update_version_metadata(version, stats)

        return stats

    def _update_version_metadata(self, version: str, stats: Dict):
        """Update versions.json with new version info"""
        metadata_path = "metadata/versions.json"

        # Download existing metadata
        blob = self.bucket.blob(metadata_path)
        try:
            existing_data = json.loads(blob.download_as_text())
        except Exception:
            existing_data = {"versions": []}

        # Add new version
        version_info = {
            "version": version,
            "created_at": datetime.utcnow().isoformat(),
            "images_count": stats["images_uploaded"],
            "bytes_uploaded": stats["bytes_uploaded"],
            "failed_uploads": stats["failed_uploads"]
        }
        existing_data["versions"].append(version_info)

        # Upload updated metadata
        blob.upload_from_string(
            json.dumps(existing_data, indent=2),
            content_type="application/json"
        )
        print(f"✓ Updated version metadata: {metadata_path}")

    def list_versions(self) -> List[Dict]:
        """List all available data versions"""
        metadata_path = "metadata/versions.json"
        blob = self.bucket.blob(metadata_path)

        try:
            data = json.loads(blob.download_as_text())
            return data.get("versions", [])
        except Exception as e:
            print(f"Failed to fetch versions: {e}")
            return []

    def download_version(
        self,
        version: str,
        local_dir: Path,
        download_images: bool = True,
        download_manifest: bool = True
    ):
        """
        Download a specific version from GCS.

        Args:
            version: Version to download
            local_dir: Local directory to save files
            download_images: Whether to download images
            download_manifest: Whether to download manifest
        """
        local_dir = Path(local_dir)
        local_dir.mkdir(parents=True, exist_ok=True)

        # Download manifest
        if download_manifest:
            manifest_blob = self.bucket.blob(f"manifests/{version}/image_manifest.csv")
            manifest_path = local_dir / "image_manifest.csv"
            try:
                manifest_blob.download_to_filename(str(manifest_path))
                print(f"✓ Downloaded manifest to {manifest_path}")
            except Exception as e:
                print(f"Failed to download manifest: {e}")

        # Download images
        if download_images:
            prefix = f"images/{version}/"
            blobs = self.client.list_blobs(self.bucket_name, prefix=prefix)

            count = 0
            for blob in blobs:
                # Extract relative path after version
                rel_path = blob.name[len(prefix):]
                local_path = local_dir / "images" / rel_path
                local_path.parent.mkdir(parents=True, exist_ok=True)

                try:
                    blob.download_to_filename(str(local_path))
                    count += 1

                    if count % 10 == 0:
                        print(f"  Downloaded {count} images...")

                except Exception as e:
                    print(f"Failed to download {blob.name}: {e}")

            print(f"✓ Downloaded {count} images")

    def upload_csv_with_versioning(
        self,
        csv_path: Path,
        data_type: str,
        version: Optional[str] = None
    ):
        """
        Upload CSV data to GCS with versioning.

        Args:
            csv_path: Path to CSV file
            data_type: Type of data (e.g., 'buildings', 'metadata')
            version: Version string (auto-generated if None)
        """
        if version is None:
            version = f"v{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

        gcs_path = f"csv/{data_type}/{version}/{csv_path.name}"

        try:
            blob = self.bucket.blob(gcs_path)
            blob.upload_from_filename(str(csv_path))
            print(f"✓ Uploaded {csv_path.name} to {gcs_path}")
        except Exception as e:
            print(f"Failed to upload CSV: {e}")


def setup_gcs_bucket(project_id: str, bucket_name: str, location: str = "us-central1"):
    """
    Create and configure GCS bucket for HistoriCam data.

    Args:
        project_id: GCP project ID
        bucket_name: Desired bucket name
        location: GCS bucket location
    """
    client = storage.Client(project=project_id)

    # Create bucket
    try:
        bucket = client.bucket(bucket_name)
        if not bucket.exists():
            bucket = client.create_bucket(bucket_name, location=location)
            print(f"✓ Created bucket: {bucket_name}")
        else:
            print(f"Bucket {bucket_name} already exists")

        # Set lifecycle rules for old versions (optional)
        # This deletes versions older than 90 days
        bucket.lifecycle_rules = [{
            "action": {"type": "Delete"},
            "condition": {
                "age": 90,
                "matchesPrefix": ["images/v"]
            }
        }]
        bucket.patch()
        print("✓ Set lifecycle rules")

        # Create initial directory structure with placeholder files
        placeholders = [
            "images/.gitkeep",
            "manifests/.gitkeep",
            "metadata/.gitkeep",
            "csv/.gitkeep"
        ]

        for placeholder in placeholders:
            blob = bucket.blob(placeholder)
            if not blob.exists():
                blob.upload_from_string("")

        print("✓ Created directory structure")

        # Initialize versions metadata
        versions_blob = bucket.blob("metadata/versions.json")
        if not versions_blob.exists():
            initial_data = {
                "versions": [],
                "created_at": datetime.utcnow().isoformat(),
                "bucket_name": bucket_name,
                "project_id": project_id
            }
            versions_blob.upload_from_string(
                json.dumps(initial_data, indent=2),
                content_type="application/json"
            )
            print("✓ Initialized version metadata")

        print(f"\n✓ Bucket setup complete!")
        print(f"  Bucket: gs://{bucket_name}")

    except Exception as e:
        print(f"Failed to setup bucket: {e}")
        raise


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage:")
        print("  Setup bucket: python gcs_manager.py setup <project_id> <bucket_name>")
        print("  Upload: python gcs_manager.py upload <bucket_name> <local_dir> <manifest>")
        print("  List versions: python gcs_manager.py list <bucket_name>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "setup":
        project_id = sys.argv[2]
        bucket_name = sys.argv[3]
        setup_gcs_bucket(project_id, bucket_name)

    elif command == "upload":
        bucket_name = sys.argv[2]
        local_dir = Path(sys.argv[3])
        manifest = Path(sys.argv[4])

        manager = GCSDataManager(bucket_name)
        stats = manager.upload_images_with_versioning(local_dir, manifest)

        print("\n" + "="*50)
        print("UPLOAD SUMMARY")
        print("="*50)
        print(f"Version: {stats['version']}")
        print(f"Images uploaded: {stats['images_uploaded']}")
        print(f"Bytes uploaded: {stats['bytes_uploaded'] / (1024*1024):.2f} MB")
        print(f"Failed uploads: {stats['failed_uploads']}")

    elif command == "list":
        bucket_name = sys.argv[2]
        manager = GCSDataManager(bucket_name)
        versions = manager.list_versions()

        print("\nAvailable versions:")
        for v in versions:
            print(f"\n  {v['version']}:")
            print(f"    Created: {v['created_at']}")
            print(f"    Images: {v['images_count']}")
            print(f"    Size: {v['bytes_uploaded'] / (1024*1024):.2f} MB")
