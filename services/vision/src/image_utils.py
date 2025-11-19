"""
Image preprocessing utilities for consistent embedding generation.
"""
import io
from PIL import Image


def resize_image_if_needed(image_bytes: bytes, max_size_mb: float = 20.0, max_dimension: int = 2048) -> bytes:
    """
    Resize image if it exceeds size limit or dimension limit.

    This ensures consistent preprocessing for embedding generation across:
    - Embeddings generation (training)
    - Evaluation (testing)
    - API service (inference)

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

        # Suppress logging in production API
        # new_size_mb = len(resized_bytes) / (1024 * 1024)
        # print(f"    Resized: {size_mb:.2f}MB ({width}x{height}) → {new_size_mb:.2f}MB ({new_width}x{new_height})")

        return resized_bytes

    except Exception as e:
        # Log warning but continue with original
        print(f"Warning: Could not resize image: {e}, using original")
        return image_bytes
