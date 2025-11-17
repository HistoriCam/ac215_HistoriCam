"""
Google Places API Photos scraper for building images.
Uses user-contributed photos from Google Maps - better angles than Street View.
"""
import requests
import time
import os
from pathlib import Path
from typing import Optional, List, Dict
import pandas as pd
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from image_scraper.scrape_images import WikimediaImageScraper


class GooglePlacesScraper:
    """Scraper for Google Places API Photos"""

    def __init__(self, api_key: str, user_agent: str = "HistoriCam/1.0"):
        """
        Initialize Google Places scraper.

        Args:
            api_key: Google Maps API key with Places API enabled
            user_agent: User agent string
        """
        self.api_key = api_key
        self.base_url = "https://maps.googleapis.com/maps/api/place"
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': user_agent})

    def find_place(
        self,
        building_name: str,
        lat: Optional[float] = None,
        lon: Optional[float] = None
    ) -> Optional[str]:
        """
        Find a place ID for a building.

        Args:
            building_name: Name of the building
            lat: Latitude (optional, helps narrow search)
            lon: Longitude (optional, helps narrow search)

        Returns:
            Place ID or None
        """
        params = {
            "input": building_name,
            "inputtype": "textquery",
            "fields": "place_id,name,geometry",
            "key": self.api_key
        }

        # Add location bias if coordinates provided
        if lat and lon:
            params["locationbias"] = f"point:{lat},{lon}"

        try:
            resp = self.session.get(
                f"{self.base_url}/findplacefromtext/json",
                params=params,
                timeout=30
            )
            resp.raise_for_status()
            data = resp.json()

            candidates = data.get("candidates", [])
            if not candidates:
                return None

            # Return first candidate's place_id
            return candidates[0].get("place_id")

        except Exception as e:
            print(f"  Error finding place: {e}")
            return None

    def get_place_photos(
        self,
        place_id: str,
        max_photos: int = 10
    ) -> List[Dict]:
        """
        Get photos for a place.

        Args:
            place_id: Google Places ID
            max_photos: Maximum number of photos to fetch

        Returns:
            List of photo metadata dicts
        """
        params = {
            "place_id": place_id,
            "fields": "photos",
            "key": self.api_key
        }

        try:
            resp = self.session.get(
                f"{self.base_url}/details/json",
                params=params,
                timeout=30
            )
            resp.raise_for_status()
            data = resp.json()

            result = data.get("result", {})
            photos = result.get("photos", [])

            if not photos:
                return []

            # Limit to max_photos
            photos = photos[:max_photos]

            # Extract photo references
            photo_list = []
            for photo in photos:
                photo_list.append({
                    "photo_reference": photo.get("photo_reference"),
                    "width": photo.get("width"),
                    "height": photo.get("height"),
                    "attributions": photo.get("html_attributions", [])
                })

            return photo_list

        except Exception as e:
            print(f"  Error getting photos: {e}")
            return []

    def download_photo(
        self,
        photo_reference: str,
        max_width: int = 1600
    ) -> Optional[bytes]:
        """
        Download a photo using its reference.

        Args:
            photo_reference: Photo reference from Places API
            max_width: Maximum width in pixels (max 1600)

        Returns:
            Image bytes or None
        """
        params = {
            "photoreference": photo_reference,
            "maxwidth": max_width,
            "key": self.api_key
        }

        try:
            resp = self.session.get(
                f"{self.base_url}/photo",
                params=params,
                timeout=30
            )
            resp.raise_for_status()
            return resp.content

        except Exception as e:
            print(f"  Error downloading photo: {e}")
            return None


def scrape_places_for_buildings(
    csv_path: str,
    output_dir: str,
    api_key: str,
    max_images_per_building: int = 10
) -> Dict:
    """
    Scrape Google Places photos for all buildings.

    Args:
        csv_path: Path to buildings CSV
        output_dir: Directory to save images
        api_key: Google Maps API key
        max_images_per_building: Max images per building

    Returns:
        Summary statistics
    """
    df = pd.read_csv(csv_path)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    scraper = GooglePlacesScraper(api_key)
    hash_util = WikimediaImageScraper()

    stats = {
        "total_buildings": len(df),
        "buildings_with_place_id": 0,
        "buildings_with_photos": 0,
        "total_images_downloaded": 0,
        "api_calls": 0,
        "skipped_no_place": 0,
        "skipped_no_photos": 0
    }

    manifest = []

    for idx, row in df.iterrows():
        building_id = row['id']
        building_name = row['name']
        lat = row.get('latitude')
        lon = row.get('longitude')

        print(f"\n[{idx+1}/{len(df)}] Processing: {building_name}")

        # Find place ID
        place_id = scraper.find_place(
            building_name=f"{building_name} Harvard",
            lat=lat if not pd.isna(lat) else None,
            lon=lon if not pd.isna(lon) else None
        )
        stats["api_calls"] += 1

        if not place_id:
            print(f"  Place not found in Google Maps")
            stats["skipped_no_place"] += 1
            continue

        stats["buildings_with_place_id"] += 1
        print(f"  Found place: {place_id}")

        # Get photos
        photos = scraper.get_place_photos(place_id, max_photos=max_images_per_building)
        stats["api_calls"] += 1

        if not photos:
            print(f"  No photos available")
            stats["skipped_no_photos"] += 1
            continue

        print(f"  Found {len(photos)} photos")

        # Download photos
        building_dir = output_path / str(building_id)
        building_dir.mkdir(exist_ok=True)

        for photo in photos:
            image_data = scraper.download_photo(
                photo["photo_reference"],
                max_width=1600
            )
            stats["api_calls"] += 1

            if not image_data:
                continue

            # Generate hash
            img_hash = hash_util.compute_hash(image_data)

            # Save with filename
            filename = f"{img_hash}_places.jpg"
            img_path = building_dir / filename

            with open(img_path, 'wb') as f:
                f.write(image_data)

            stats["total_images_downloaded"] += 1

            # Add to manifest
            manifest.append({
                "building_id": building_id,
                "building_name": building_name,
                "image_hash": img_hash,
                "filename": img_path.name,  # Actual filename on disk
                "local_path": str(img_path),
                "source": "google_places",
                "place_id": place_id,
                "width": photo["width"],
                "height": photo["height"],
                "attributions": "; ".join(photo["attributions"])
            })

            time.sleep(0.1)  # Rate limiting

        if stats["total_images_downloaded"] > 0:
            stats["buildings_with_photos"] += 1
            print(f"  Downloaded {len(photos)} Google Places photos")

    # Save manifest
    manifest_df = pd.DataFrame(manifest)
    manifest_path = output_path / "places_manifest.csv"
    manifest_df.to_csv(manifest_path, index=False)
    print(f"\n✓ Saved manifest to {manifest_path}")

    return stats


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python scrape_places.py <csv_path> <output_dir> [api_key]")
        print("\nAPI key can be provided as:")
        print("  1. Command line argument")
        print("  2. GOOGLE_API_KEY environment variable")
        print("  3. GOOGLE_MAPS_API_KEY environment variable (legacy)")
        print("\nRequires Places API enabled: https://console.cloud.google.com/apis/library/places-backend.googleapis.com")
        sys.exit(1)

    csv_path = sys.argv[1]
    output_dir = sys.argv[2]
    api_key = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("GOOGLE_API_KEY") or os.environ.get("GOOGLE_MAPS_API_KEY")

    if not api_key:
        print("Error: Google API key required!")
        print("Set GOOGLE_API_KEY environment variable or pass as argument")
        sys.exit(1)

    print(f"Scraping Google Places photos from: {csv_path}")
    print(f"Saving to: {output_dir}\n")

    stats = scrape_places_for_buildings(csv_path, output_dir, api_key)

    print("\n" + "="*50)
    print("GOOGLE PLACES SCRAPING SUMMARY")
    print("="*50)
    print(f"Total buildings: {stats['total_buildings']}")
    print(f"Buildings with Place ID: {stats['buildings_with_place_id']}")
    print(f"Buildings with photos: {stats['buildings_with_photos']}")
    print(f"Total images downloaded: {stats['total_images_downloaded']}")
    print(f"API calls made: {stats['api_calls']}")
    print(f"Skipped (no place): {stats['skipped_no_place']}")
    print(f"Skipped (no photos): {stats['skipped_no_photos']}")
    print(f"\nEstimated cost: ${stats['api_calls'] * 0.017:.2f}")
    print("(Find Place: $0.017, Place Details: $0.017, Photo: free)")
