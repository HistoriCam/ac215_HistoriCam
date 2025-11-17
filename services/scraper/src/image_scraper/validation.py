"""
Image validation utilities for quality control.
"""
from PIL import Image
from pathlib import Path
from typing import Dict, Optional, Tuple
from io import BytesIO


class ImageValidator:
    """Validates images for quality and suitability"""

    def __init__(
        self,
        min_width: int = 512,
        min_height: int = 512,
        preferred_width: int = 1024,
        preferred_height: int = 1024,
        max_size_mb: int = 10,
        allowed_formats: Tuple[str, ...] = ("JPEG", "PNG", "WebP")
    ):
        """
        Initialize validator.

        Args:
            min_width: Minimum image width in pixels (default 512 for better quality)
            min_height: Minimum image height in pixels (default 512)
            preferred_width: Preferred minimum width (default 1024)
            preferred_height: Preferred minimum height (default 1024)
            max_size_mb: Maximum file size in MB
            allowed_formats: Tuple of allowed image formats
        """
        self.min_width = min_width
        self.min_height = min_height
        self.preferred_width = preferred_width
        self.preferred_height = preferred_height
        self.max_size_bytes = max_size_mb * 1024 * 1024
        self.allowed_formats = allowed_formats

    def validate_image_file(self, file_path: Path) -> Dict:
        """
        Validate an image file.

        Args:
            file_path: Path to image file

        Returns:
            Dict with validation results: {valid: bool, errors: List[str], metadata: Dict}
        """
        errors = []
        metadata = {}

        try:
            # Check file size
            file_size = file_path.stat().st_size
            metadata["file_size_bytes"] = file_size

            if file_size > self.max_size_bytes:
                errors.append(
                    f"File too large: {file_size / (1024*1024):.2f}MB "
                    f"(max: {self.max_size_bytes / (1024*1024):.2f}MB)"
                )

            # Open and validate image
            with Image.open(file_path) as img:
                # Get basic metadata
                metadata["format"] = img.format
                metadata["mode"] = img.mode
                metadata["width"] = img.width
                metadata["height"] = img.height

                # Check format
                if img.format not in self.allowed_formats:
                    errors.append(
                        f"Invalid format: {img.format} "
                        f"(allowed: {', '.join(self.allowed_formats)})"
                    )

                # Check dimensions
                if img.width < self.min_width:
                    errors.append(
                        f"Width too small: {img.width}px (min: {self.min_width}px)"
                    )

                if img.height < self.min_height:
                    errors.append(
                        f"Height too small: {img.height}px (min: {self.min_height}px)"
                    )

                # Add quality score based on resolution
                metadata["quality_score"] = self._compute_quality_score(img.width, img.height)

                # Check aspect ratio (too narrow or too wide)
                aspect_ratio = img.width / img.height
                if aspect_ratio > 5 or aspect_ratio < 0.2:
                    errors.append(
                        f"Unusual aspect ratio: {aspect_ratio:.2f} "
                        "(might be a banner or icon)"
                    )

                # Verify image integrity
                img.verify()

        except Exception as e:
            errors.append(f"Failed to open/validate image: {str(e)}")

        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "metadata": metadata
        }

    def _compute_quality_score(self, width: int, height: int) -> float:
        """
        Compute quality score based on resolution (0.0 to 1.0).

        Args:
            width: Image width in pixels
            height: Image height in pixels

        Returns:
            Quality score (1.0 = preferred resolution or higher, 0.0 = minimum)
        """
        # Calculate based on smaller dimension to handle both portrait and landscape
        min_dim = min(width, height)

        if min_dim >= self.preferred_width:
            return 1.0
        elif min_dim <= self.min_width:
            return 0.0
        else:
            # Linear scale between min and preferred
            return (min_dim - self.min_width) / (self.preferred_width - self.min_width)

    def validate_image_bytes(self, image_bytes: bytes) -> Dict:
        """
        Validate image from bytes.

        Args:
            image_bytes: Image data as bytes

        Returns:
            Dict with validation results
        """
        errors = []
        metadata = {}

        try:
            # Check size
            file_size = len(image_bytes)
            metadata["file_size_bytes"] = file_size

            if file_size > self.max_size_bytes:
                errors.append(
                    f"Image too large: {file_size / (1024*1024):.2f}MB "
                    f"(max: {self.max_size_bytes / (1024*1024):.2f}MB)"
                )

            # Open and validate
            with Image.open(BytesIO(image_bytes)) as img:
                metadata["format"] = img.format
                metadata["mode"] = img.mode
                metadata["width"] = img.width
                metadata["height"] = img.height

                # Check format
                if img.format not in self.allowed_formats:
                    errors.append(
                        f"Invalid format: {img.format} "
                        f"(allowed: {', '.join(self.allowed_formats)})"
                    )

                # Check dimensions
                if img.width < self.min_width or img.height < self.min_height:
                    errors.append(
                        f"Image too small: {img.width}x{img.height}px "
                        f"(min: {self.min_width}x{self.min_height}px)"
                    )

                # Check aspect ratio
                aspect_ratio = img.width / img.height
                if aspect_ratio > 5 or aspect_ratio < 0.2:
                    errors.append(f"Unusual aspect ratio: {aspect_ratio:.2f}")

                # Verify integrity
                img.verify()

        except Exception as e:
            errors.append(f"Failed to validate image: {str(e)}")

        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "metadata": metadata
        }


def validate_image_directory(directory: Path, validator: Optional[ImageValidator] = None) -> Dict:
    """
    Validate all images in a directory.

    Args:
        directory: Directory containing images
        validator: ImageValidator instance (creates default if None)

    Returns:
        Dict with validation summary
    """
    if validator is None:
        validator = ImageValidator()

    results = {
        "total_images": 0,
        "valid_images": 0,
        "invalid_images": 0,
        "errors": []
    }

    for img_path in directory.rglob("*.jpg"):
        results["total_images"] += 1
        validation = validator.validate_image_file(img_path)

        if validation["valid"]:
            results["valid_images"] += 1
        else:
            results["invalid_images"] += 1
            results["errors"].append({
                "file": str(img_path),
                "errors": validation["errors"]
            })

    for img_path in directory.rglob("*.png"):
        results["total_images"] += 1
        validation = validator.validate_image_file(img_path)

        if validation["valid"]:
            results["valid_images"] += 1
        else:
            results["invalid_images"] += 1
            results["errors"].append({
                "file": str(img_path),
                "errors": validation["errors"]
            })

    return results


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python validation.py <image_directory>")
        sys.exit(1)

    img_dir = Path(sys.argv[1])
    print(f"Validating images in: {img_dir}\n")

    results = validate_image_directory(img_dir)

    print("="*50)
    print("VALIDATION SUMMARY")
    print("="*50)
    print(f"Total images: {results['total_images']}")
    print(f"Valid images: {results['valid_images']}")
    print(f"Invalid images: {results['invalid_images']}")

    if results['errors']:
        print("\nERRORS:")
        for error in results['errors'][:10]:  # Show first 10
            print(f"\n{error['file']}:")
            for err in error['errors']:
                print(f"  - {err}")
