"""
Unified scraper that collects images from all sources.
Target: 20+ images per building from multiple complementary sources.
"""
import os
import sys
from pathlib import Path
import pandas as pd
from typing import Dict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from scraper.scrape_images import scrape_images_for_buildings
from scraper.scrape_flickr import scrape_flickr_for_buildings
from scraper.scrape_mapillary import scrape_mapillary_for_buildings
from scraper.scrape_places import scrape_places_for_buildings
from scraper.validation import validate_image_directory


def scrape_all_sources(
    csv_path: str,
    output_dir: str,
    google_maps_api_key: str = None,
    flickr_api_key: str = None,
    mapillary_token: str = None,
    target_images_per_building: int = 20,
    min_images_per_building: int = 4
) -> Dict:
    """
    Scrape images from all available sources.

    Target distribution (minimum 4 images per building from different angles):
    - Wikimedia Commons (enhanced): 2-10 images (categories + direct)
    - Google Places Photos: 2-10 images (if API key provided)
    - Mapillary: 1-5 images (if token provided)
    - Flickr: 1-5 images (if API key provided)

    The scraper ensures at least 4 images per building from different angles
    by pulling from multiple sources (Wikimedia + Google Places prioritized).

    Args:
        csv_path: Path to buildings CSV
        output_dir: Output directory for images
        google_maps_api_key: Google Maps API key (for Places Photos)
        flickr_api_key: Flickr API key (optional)
        mapillary_token: Mapillary access token (optional)
        target_images_per_building: Target total images per building (default: 20)
        min_images_per_building: Minimum images per building (default: 4)

    Returns:
        Combined statistics
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    all_stats = {
        "wikimedia": {},
        "streetview": {},
        "places": {},
        "mapillary": {},
        "flickr": {},
        "total_images": 0,
        "deduplication": {},
        "validation": {}
    }

    print("="*60)
    print("HISTORICAM IMAGE SCRAPING - ALL SOURCES")
    print("="*60)
    print(f"Target: {target_images_per_building} images per building")
    print(f"Minimum: {min_images_per_building} images per building from different angles\n")

    # 1. Wikimedia Commons (enhanced with categories: prioritize diverse angles)
    print("\n" + "="*60)
    print("PHASE 1: Wikimedia Commons (Enhanced)")
    print("="*60)
    print("Collecting images with diverse angles and perspectives...")
    try:
        # Ensure at least 2 images from Wikimedia (for minimum coverage)
        wikimedia_max = max(10, min_images_per_building // 2)
        wikimedia_stats = scrape_images_for_buildings(
            csv_path=csv_path,
            output_dir=output_dir,
            max_images_per_building=wikimedia_max
        )
        all_stats["wikimedia"] = wikimedia_stats
        all_stats["total_images"] += wikimedia_stats.get("total_images_downloaded", 0)
        print(f"\n✓ Wikimedia: {wikimedia_stats.get('total_images_downloaded', 0)} images")
    except Exception as e:
        print(f"\n✗ Wikimedia scraping failed: {e}")

    # 2. Google Places Photos (user-contributed photos from different angles)
    if google_maps_api_key:
        print("\n" + "="*60)
        print("PHASE 2: Google Places Photos")
        print("="*60)
        print("Collecting user-contributed photos from various perspectives...")
        try:
            # Ensure at least 2 images from Places (for angle diversity)
            places_max = max(10, min_images_per_building // 2)
            places_stats = scrape_places_for_buildings(
                csv_path=csv_path,
                output_dir=output_dir,
                api_key=google_maps_api_key,
                max_images_per_building=places_max
            )
            all_stats["places"] = places_stats
            all_stats["total_images"] += places_stats.get("total_images_downloaded", 0)
            print(f"\n✓ Places Photos: {places_stats.get('total_images_downloaded', 0)} images")
            print(f"  API cost: ${places_stats.get('api_calls', 0) * 0.017:.2f}")
        except Exception as e:
            print(f"\n✗ Places Photos scraping failed: {e}")
    else:
        print("\n⊗ Skipping Google Places Photos (no API key)")
        print("  NOTE: Google Places provides diverse building angles from user photos")

    # 3. Mapillary (3-5 images per building)
    if mapillary_token:
        print("\n" + "="*60)
        print("PHASE 3: Mapillary")
        print("="*60)
        try:
            mapillary_stats = scrape_mapillary_for_buildings(
                csv_path=csv_path,
                output_dir=output_dir,
                access_token=mapillary_token,
                max_images_per_building=5,
                search_radius=50
            )
            all_stats["mapillary"] = mapillary_stats
            all_stats["total_images"] += mapillary_stats.get("total_images_downloaded", 0)
            print(f"\n✓ Mapillary: {mapillary_stats.get('total_images_downloaded', 0)} images")
        except Exception as e:
            print(f"\n✗ Mapillary scraping failed: {e}")
    else:
        print("\n⊗ Skipping Mapillary (no access token)")

    # 5. Flickr (optional - 3-5 images per building)
    if flickr_api_key:
        print("\n" + "="*60)
        print("PHASE 5: Flickr")
        print("="*60)
        try:
            flickr_stats = scrape_flickr_for_buildings(
                csv_path=csv_path,
                output_dir=output_dir,
                api_key=flickr_api_key,
                max_images_per_building=5,
                use_geo_search=True
            )
            all_stats["flickr"] = flickr_stats
            all_stats["total_images"] += flickr_stats.get("total_images_downloaded", 0)
            print(f"\n✓ Flickr: {flickr_stats.get('total_images_downloaded', 0)} images")
        except Exception as e:
            print(f"\n✗ Flickr scraping failed: {e}")
    else:
        print("\n⊗ Skipping Flickr (no API key)")

    # 6. Deduplication
    print("\n" + "="*60)
    print("PHASE 4: Deduplication")
    print("="*60)
    try:
        # Merge all manifests
        manifests = []
        manifest_files = [
            "image_manifest.csv",  # Wikimedia
            "places_manifest.csv",  # Google Places
            "mapillary_manifest.csv",  # Mapillary
            "flickr_manifest.csv"  # Flickr
        ]
        for manifest_file in manifest_files:
            manifest_path = output_path / manifest_file
            if manifest_path.exists():
                df = pd.read_csv(manifest_path)
                manifests.append(df)

        if manifests:
            combined_manifest = pd.concat(manifests, ignore_index=True)
            combined_path = output_path / "combined_manifest.csv"
            combined_manifest.to_csv(combined_path, index=False)
            print(f"✓ Combined {len(manifests)} manifests: {len(combined_manifest)} total images")

            # Deduplicate
            from scraper.deduplication import ImageDeduplicator
            deduplicator = ImageDeduplicator(similarity_threshold=5)

            print("Removing duplicate images...")
            dedup_stats = deduplicator.remove_duplicates(
                output_path,
                dry_run=False,
                keep_highest_resolution=True
            )
            all_stats["deduplication"] = dedup_stats

            print(f"✓ Removed {dedup_stats['files_deleted']} duplicates")
            print(f"  Space saved: {dedup_stats['space_saved_bytes'] / (1024*1024):.2f} MB")

            all_stats["total_images"] -= dedup_stats["files_deleted"]

    except Exception as e:
        print(f"✗ Deduplication failed: {e}")

    # 5. Validation
    print("\n" + "="*60)
    print("PHASE 5: Validation")
    print("="*60)
    try:
        validation_stats = validate_image_directory(output_path)
        all_stats["validation"] = validation_stats

        print(f"✓ Validated {validation_stats['total_images']} images")
        print(f"  Valid: {validation_stats['valid_images']}")
        print(f"  Invalid: {validation_stats['invalid_images']}")

    except Exception as e:
        print(f"✗ Validation failed: {e}")

    return all_stats


def print_final_summary(stats: Dict, csv_path: str):
    """Print final scraping summary"""
    df = pd.read_csv(csv_path)
    total_buildings = len(df)

    print("\n" + "="*60)
    print("FINAL SUMMARY")
    print("="*60)

    # Per-source breakdown
    print("\nImages by source:")
    if stats.get("wikimedia"):
        print(f"  Wikimedia Commons: {stats['wikimedia'].get('total_images_downloaded', 0)}")
    if stats.get("places"):
        print(f"  Google Places: {stats['places'].get('total_images_downloaded', 0)}")
    if stats.get("mapillary"):
        print(f"  Mapillary: {stats['mapillary'].get('total_images_downloaded', 0)}")
    if stats.get("streetview"):
        print(f"  Google Street View: {stats['streetview'].get('total_images_downloaded', 0)}")
    if stats.get("flickr"):
        print(f"  Flickr: {stats['flickr'].get('total_images_downloaded', 0)}")

    print(f"\nTotal buildings: {total_buildings}")
    print(f"Total images (after deduplication): {stats['total_images']}")
    print(f"Average images per building: {stats['total_images'] / total_buildings:.1f}")

    # Validation
    if stats.get("validation"):
        val = stats["validation"]
        print(f"\nValidation:")
        print(f"  Valid images: {val['valid_images']}")
        print(f"  Invalid images: {val['invalid_images']}")

    # Cost estimate
    total_cost = 0
    print(f"\nAPI costs:")
    if stats.get("places"):
        places_cost = stats["places"].get("api_calls", 0) * 0.017
        print(f"  Google Places: ${places_cost:.2f}")
        total_cost += places_cost
    if stats.get("streetview"):
        sv_cost = stats["streetview"].get("api_calls", 0) * 0.007
        print(f"  Google Street View: ${sv_cost:.2f}")
        total_cost += sv_cost
    print(f"  Mapillary: $0.00 (free)")
    print(f"  Flickr: $0.00 (free tier)")
    if total_cost > 0:
        print(f"  TOTAL: ${total_cost:.2f}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Scrape building images from all sources")
    parser.add_argument("csv_path", help="Path to buildings CSV")
    parser.add_argument("output_dir", help="Output directory for images")
    parser.add_argument("--google-api-key", help="Google API key (for Places API)")
    parser.add_argument("--flickr-key", help="Flickr API key")
    parser.add_argument("--mapillary-token", help="Mapillary access token")
    parser.add_argument("--target", type=int, default=20,
                       help="Target images per building (default: 20)")
    parser.add_argument("--min-images", type=int, default=4,
                       help="Minimum images per building (default: 4)")

    args = parser.parse_args()

    # Get API keys from args or environment
    # Support both GOOGLE_API_KEY (preferred) and GOOGLE_MAPS_API_KEY (legacy)
    google_key = args.google_api_key or os.environ.get("GOOGLE_API_KEY") or os.environ.get("GOOGLE_MAPS_API_KEY")
    flickr_key = args.flickr_key or os.environ.get("FLICKR_API_KEY")
    mapillary_token = args.mapillary_token or os.environ.get("MAPILLARY_ACCESS_TOKEN")

    if not google_key and not flickr_key and not mapillary_token:
        print("WARNING: No API keys provided. Only Wikimedia Commons will be scraped.")
        print("Set GOOGLE_API_KEY, FLICKR_API_KEY, and/or MAPILLARY_ACCESS_TOKEN environment variables")
        print("or use --google-api-key, --flickr-key, and --mapillary-token arguments\n")

    # Run scraping
    stats = scrape_all_sources(
        csv_path=args.csv_path,
        output_dir=args.output_dir,
        google_maps_api_key=google_key,
        flickr_api_key=flickr_key,
        mapillary_token=mapillary_token,
        target_images_per_building=args.target,
        min_images_per_building=args.min_images
    )

    # Print summary
    print_final_summary(stats, args.csv_path)

# Example usage:
# export GOOGLE_API_KEY="your-key"
# export MAPILLARY_ACCESS_TOKEN="your-token"
# export FLICKR_API_KEY="your-key"  # optional

# uv run python src/scraper/scrape_all_sources.py \
#     /data/buildings_names_metadata.csv \
#     /data/images \
#     --target 20