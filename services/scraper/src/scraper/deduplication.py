"""
Image deduplication utilities using perceptual hashing.
Detects and removes duplicate or near-duplicate images.
"""
import imagehash
from PIL import Image
from pathlib import Path
from typing import Dict, List, Set, Tuple
import pandas as pd
from io import BytesIO


class ImageDeduplicator:
    """Deduplicates images using perceptual hashing"""

    def __init__(self, hash_size: int = 8, similarity_threshold: int = 5):
        """
        Initialize deduplicator.

        Args:
            hash_size: Size of perceptual hash (default 8 = 64-bit hash)
            similarity_threshold: Max hamming distance for duplicates (0-64)
                                 0 = exact match only
                                 5 = very similar
                                 10 = similar
                                 15+ = different
        """
        self.hash_size = hash_size
        self.similarity_threshold = similarity_threshold

    def compute_phash(self, image_path: Path) -> imagehash.ImageHash:
        """
        Compute perceptual hash for an image file.

        Args:
            image_path: Path to image file

        Returns:
            Perceptual hash
        """
        with Image.open(image_path) as img:
            return imagehash.phash(img, hash_size=self.hash_size)

    def compute_phash_from_bytes(self, image_bytes: bytes) -> imagehash.ImageHash:
        """
        Compute perceptual hash from image bytes.

        Args:
            image_bytes: Image data as bytes

        Returns:
            Perceptual hash
        """
        with Image.open(BytesIO(image_bytes)) as img:
            return imagehash.phash(img, hash_size=self.hash_size)

    def find_duplicates_in_directory(
        self,
        directory: Path,
        recursive: bool = True
    ) -> Dict[str, List[Path]]:
        """
        Find all duplicate images in a directory.

        Args:
            directory: Directory to search
            recursive: Whether to search subdirectories

        Returns:
            Dict mapping representative image to list of duplicates
        """
        # Build hash index
        hash_to_images = {}

        pattern = "**/*" if recursive else "*"
        for ext in [".jpg", ".jpeg", ".png", ".webp"]:
            for img_path in directory.glob(f"{pattern}{ext}"):
                try:
                    img_hash = self.compute_phash(img_path)
                    hash_str = str(img_hash)

                    if hash_str not in hash_to_images:
                        hash_to_images[hash_str] = []
                    hash_to_images[hash_str].append(img_path)

                except Exception as e:
                    print(f"  Error hashing {img_path}: {e}")

        # Find near-duplicates using similarity threshold
        duplicates = {}
        processed_hashes = set()

        for hash1, paths1 in hash_to_images.items():
            if hash1 in processed_hashes:
                continue

            # Find all hashes within similarity threshold
            similar_paths = list(paths1)

            for hash2, paths2 in hash_to_images.items():
                if hash2 == hash1 or hash2 in processed_hashes:
                    continue

                # Compute hamming distance
                h1 = imagehash.hex_to_hash(hash1)
                h2 = imagehash.hex_to_hash(hash2)
                distance = h1 - h2

                if distance <= self.similarity_threshold:
                    similar_paths.extend(paths2)
                    processed_hashes.add(hash2)

            if len(similar_paths) > 1:
                # Use first path as representative
                duplicates[str(similar_paths[0])] = similar_paths[1:]
                processed_hashes.add(hash1)

        return duplicates

    def remove_duplicates(
        self,
        directory: Path,
        dry_run: bool = True,
        keep_highest_resolution: bool = True
    ) -> Dict:
        """
        Remove duplicate images from directory.

        Args:
            directory: Directory containing images
            dry_run: If True, don't actually delete files
            keep_highest_resolution: Keep highest resolution version

        Returns:
            Summary statistics
        """
        duplicates = self.find_duplicates_in_directory(directory)

        stats = {
            "total_duplicate_groups": len(duplicates),
            "total_duplicates_found": sum(len(dups) for dups in duplicates.values()),
            "files_deleted": 0,
            "space_saved_bytes": 0
        }

        for representative, duplicate_list in duplicates.items():
            all_images = [Path(representative)] + duplicate_list

            # Determine which to keep
            if keep_highest_resolution:
                # Keep highest resolution image
                best_image = max(
                    all_images,
                    key=lambda p: Image.open(p).size[0] * Image.open(p).size[1]
                )
            else:
                # Keep first (representative)
                best_image = Path(representative)

            # Delete others
            for img_path in all_images:
                if img_path != best_image:
                    file_size = img_path.stat().st_size
                    stats["space_saved_bytes"] += file_size

                    if not dry_run:
                        img_path.unlink()
                        print(f"  Deleted: {img_path}")
                    else:
                        print(f"  Would delete: {img_path}")

                    stats["files_deleted"] += 1

        return stats


def deduplicate_manifest(
    manifest_csv: Path,
    image_dir: Path,
    output_csv: Path,
    similarity_threshold: int = 5
) -> pd.DataFrame:
    """
    Deduplicate images listed in a manifest CSV.

    Args:
        manifest_csv: Path to manifest CSV with image metadata
        image_dir: Directory containing images
        output_csv: Path to save deduplicated manifest
        similarity_threshold: Hamming distance threshold for duplicates

    Returns:
        Deduplicated DataFrame
    """
    df = pd.read_csv(manifest_csv)
    deduplicator = ImageDeduplicator(similarity_threshold=similarity_threshold)

    # Compute perceptual hashes for all images
    print("Computing perceptual hashes...")
    df["phash"] = None

    for idx, row in df.iterrows():
        img_path = Path(row["local_path"])
        if img_path.exists():
            try:
                phash = str(deduplicator.compute_phash(img_path))
                df.at[idx, "phash"] = phash
            except Exception as e:
                print(f"  Error hashing {img_path}: {e}")

    # Find duplicates
    print("Finding duplicates...")
    hash_groups = df.groupby("phash")

    # For each duplicate group, keep only the first entry
    deduplicated_indices = []
    duplicate_count = 0

    for phash, group in hash_groups:
        if pd.isna(phash):
            # Keep all rows with no hash
            deduplicated_indices.extend(group.index.tolist())
        else:
            # Keep only first image in each hash group
            deduplicated_indices.append(group.index[0])
            duplicate_count += len(group) - 1

    deduplicated_df = df.loc[deduplicated_indices].drop(columns=["phash"])

    print(f"\nFound {duplicate_count} duplicates")
    print(f"Kept {len(deduplicated_df)} unique images")

    # Save deduplicated manifest
    deduplicated_df.to_csv(output_csv, index=False)
    print(f"Saved to: {output_csv}")

    return deduplicated_df


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage:")
        print("  Find duplicates:  python deduplication.py find <image_dir>")
        print("  Remove duplicates: python deduplication.py remove <image_dir> [--no-dry-run]")
        print("  Dedupe manifest:  python deduplication.py manifest <manifest.csv> <image_dir> <output.csv>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "find":
        if len(sys.argv) < 3:
            print("Usage: python deduplication.py find <image_dir>")
            sys.exit(1)

        image_dir = Path(sys.argv[2])
        deduplicator = ImageDeduplicator(similarity_threshold=5)

        print(f"Searching for duplicates in: {image_dir}\n")
        duplicates = deduplicator.find_duplicates_in_directory(image_dir)

        print("\n" + "="*50)
        print("DUPLICATE DETECTION RESULTS")
        print("="*50)
        print(f"Total duplicate groups: {len(duplicates)}")
        print(f"Total duplicate images: {sum(len(dups) for dups in duplicates.values())}")

        if duplicates:
            print("\nDuplicate groups:")
            for representative, dups in list(duplicates.items())[:10]:
                print(f"\n  {representative}")
                for dup in dups:
                    print(f"    → {dup}")

            if len(duplicates) > 10:
                print(f"\n  ... and {len(duplicates) - 10} more groups")

    elif command == "remove":
        if len(sys.argv) < 3:
            print("Usage: python deduplication.py remove <image_dir> [--no-dry-run]")
            sys.exit(1)

        image_dir = Path(sys.argv[2])
        dry_run = "--no-dry-run" not in sys.argv

        deduplicator = ImageDeduplicator(similarity_threshold=5)

        print(f"Removing duplicates from: {image_dir}")
        print(f"Dry run: {dry_run}\n")

        stats = deduplicator.remove_duplicates(image_dir, dry_run=dry_run)

        print("\n" + "="*50)
        print("DEDUPLICATION SUMMARY")
        print("="*50)
        print(f"Duplicate groups: {stats['total_duplicate_groups']}")
        print(f"Duplicates found: {stats['total_duplicates_found']}")
        print(f"Files deleted: {stats['files_deleted']}")
        print(f"Space saved: {stats['space_saved_bytes'] / (1024*1024):.2f} MB")

        if dry_run:
            print("\nThis was a DRY RUN - no files were actually deleted")
            print("Run with --no-dry-run to actually remove duplicates")

    elif command == "manifest":
        if len(sys.argv) < 5:
            print("Usage: python deduplication.py manifest <manifest.csv> <image_dir> <output.csv>")
            sys.exit(1)

        manifest_csv = Path(sys.argv[2])
        image_dir = Path(sys.argv[3])
        output_csv = Path(sys.argv[4])

        deduplicate_manifest(manifest_csv, image_dir, output_csv)

    else:
        print(f"Unknown command: {command}")
        print("Valid commands: find, remove, manifest")
        sys.exit(1)
