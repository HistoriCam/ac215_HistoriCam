"""
Mapillary API scraper for building images.
Crowdsourced street-level imagery with better building angles than Street View.
Free API with generous limits.
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


class MapillaryScraper:
    """Scraper for Mapillary API - crowdsourced street imagery"""

    def __init__(self, access_token: str, user_agent: str = "HistoriCam/1.0"):
        """
        Initialize Mapillary scraper.

        Args:
            access_token: Mapillary API access token (get from https://www.mapillary.com/dashboard/developers)
            user_agent: User agent string
        """
        self.access_token = access_token
        self.base_url = "https://graph.mapillary.com"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': user_agent,
            'Authorization': f'OAuth {access_token}'
        })

    def search_images_near_location(
        self,
        lat: float,
        lon: float,
        radius: int = 50,
        limit: int = 100
    ) -> List[Dict]:
        """
        Search for images near a location.

        Args:
            lat: Latitude
            lon: Longitude
            radius: Search radius in meters (default 50m)
            limit: Max number of images

        Returns:
            List of image metadata dicts
        """
        # Mapillary uses bbox format: min_lon,min_lat,max_lon,max_lat
        # Convert radius to approximate bbox
        lat_delta = radius / 111000  # 1 degree lat ≈ 111km
        lon_delta = radius / (111000 * abs(lat))  # Adjust for latitude

        bbox = f"{lon - lon_delta},{lat - lat_delta},{lon + lon_delta},{lat + lat_delta}"

        params = {
            "bbox": bbox,
            "limit": limit,
            "fields": "id,captured_at,compass_angle,geometry,thumb_2048_url,computed_geometry"
        }

        try:
            response = self.session.get(
                f"{self.base_url}/images",
                params=params,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            images = []
            for feature in data.get("data", []):
                # Get coordinates
                coords = feature.get("geometry", {}).get("coordinates", [])
                if not coords:
                    coords = feature.get("computed_geometry", {}).get("coordinates", [])

                # Get image URL (2048px version)
                image_url = feature.get("thumb_2048_url")
                if not image_url:
                    continue

                images.append({
                    "id": feature.get("id"),
                    "url": image_url,
                    "captured_at": feature.get("captured_at"),
                    "compass_angle": feature.get("compass_angle"),
                    "longitude": coords[0] if len(coords) > 0 else None,
                    "latitude": coords[1] if len(coords) > 1 else None
                })

            return images

        except requests.exceptions.RequestException as e:
            print(f"  Error searching Mapillary: {e}")
            return []

    def download_image(self, url: str) -> Optional[bytes]:
        """
        Download image from Mapillary.

        Args:
            url: Image URL

        Returns:
            Image bytes or None
        """
        try:
            # Note: Mapillary image URLs don't need auth token
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            return resp.content
        except Exception as e:
            print(f"  Error downloading from {url}: {e}")
            return None

    def filter_building_oriented_images(
        self,
        images: List[Dict],
        target_lat: float,
        target_lon: float
    ) -> List[Dict]:
        """
        Filter images that are likely pointing toward the building.

        Args:
            images: List of image metadata
            target_lat: Building latitude
            target_lon: Building longitude

        Returns:
            Filtered list of images
        """
        import math

        filtered = []

        for img in images:
            if img.get("compass_angle") is None:
                # Keep if no angle data
                filtered.append(img)
                continue

            # Calculate bearing from image to building
            img_lat = img.get("latitude")
            img_lon = img.get("longitude")

            if img_lat is None or img_lon is None:
                filtered.append(img)
                continue

            # Calculate bearing
            y = math.sin(math.radians(target_lon - img_lon)) * math.cos(math.radians(target_lat))
            x = (math.cos(math.radians(img_lat)) * math.sin(math.radians(target_lat)) -
                 math.sin(math.radians(img_lat)) * math.cos(math.radians(target_lat)) *
                 math.cos(math.radians(target_lon - img_lon)))
            bearing = math.degrees(math.atan2(y, x))
            bearing = (bearing + 360) % 360

            # Check if camera is pointing roughly toward building
            compass_angle = img["compass_angle"]
            angle_diff = abs(compass_angle - bearing)
            if angle_diff > 180:
                angle_diff = 360 - angle_diff

            # Keep images pointing within 45 degrees of building
            if angle_diff < 45:
                filtered.append(img)

        return filtered


def scrape_mapillary_for_buildings(
    csv_path: str,
    output_dir: str,
    access_token: str,
    max_images_per_building: int = 10,
    search_radius: int = 50
) -> Dict:
    """
    Scrape Mapillary images for all buildings.

    Args:
        csv_path: Path to buildings CSV with latitude/longitude
        output_dir: Directory to save images
        access_token: Mapillary API access token
        max_images_per_building: Max images per building
        search_radius: Search radius in meters

    Returns:
        Summary statistics
    """
    df = pd.read_csv(csv_path)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    scraper = MapillaryScraper(access_token)
    hash_util = WikimediaImageScraper()

    stats = {
        "total_buildings": len(df),
        "buildings_with_coords": 0,
        "buildings_with_images": 0,
        "total_images_downloaded": 0,
        "skipped_no_coords": 0,
        "skipped_no_images": 0
    }

    manifest = []

    for idx, row in df.iterrows():
        building_id = row['id']
        building_name = row['name']
        lat = row.get('latitude')
        lon = row.get('longitude')

        print(f"\n[{idx+1}/{len(df)}] Processing: {building_name}")

        # Check coordinates
        if pd.isna(lat) or pd.isna(lon) or lat == '' or lon == '':
            print(f"  Skipping - no coordinates")
            stats["skipped_no_coords"] += 1
            continue

        stats["buildings_with_coords"] += 1

        # Search for nearby images
        images = scraper.search_images_near_location(
            lat=lat,
            lon=lon,
            radius=search_radius,
            limit=max_images_per_building * 3  # Get extras for filtering
        )

        if not images:
            print(f"  No Mapillary images found")
            stats["skipped_no_images"] += 1
            continue

        print(f"  Found {len(images)} Mapillary images nearby")

        # Filter images pointing toward building
        filtered_images = scraper.filter_building_oriented_images(images, lat, lon)
        print(f"  {len(filtered_images)} images likely show the building")

        # Limit to max_images_per_building
        filtered_images = filtered_images[:max_images_per_building]

        if not filtered_images:
            stats["skipped_no_images"] += 1
            continue

        # Download images
        building_dir = output_path / str(building_id)
        building_dir.mkdir(exist_ok=True)

        for img in filtered_images:
            image_data = scraper.download_image(img['url'])
            if not image_data:
                continue

            # Generate hash
            img_hash = hash_util.compute_hash(image_data)

            # Save with descriptive filename
            filename = f"{img_hash}_mapillary_a{int(img.get('compass_angle', 0))}.jpg"
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
                "source": "mapillary",
                "mapillary_id": img["id"],
                "captured_at": img["captured_at"],
                "compass_angle": img.get("compass_angle"),
                "latitude": lat,
                "longitude": lon
            })

        if stats["total_images_downloaded"] > 0:
            stats["buildings_with_images"] += 1
            print(f"  Downloaded {len(filtered_images)} Mapillary images")

        time.sleep(0.5)  # Rate limiting

    # Save manifest
    manifest_df = pd.DataFrame(manifest)
    manifest_path = output_path / "mapillary_manifest.csv"
    manifest_df.to_csv(manifest_path, index=False)
    print(f"\n✓ Saved manifest to {manifest_path}")

    return stats


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python scrape_mapillary.py <csv_path> <output_dir> [access_token]")
        print("\nAccess token can be provided as:")
        print("  1. Command line argument")
        print("  2. MAPILLARY_ACCESS_TOKEN environment variable")
        print("\nGet token from: https://www.mapillary.com/dashboard/developers")
        sys.exit(1)

    csv_path = sys.argv[1]
    output_dir = sys.argv[2]
    access_token = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("MAPILLARY_ACCESS_TOKEN")

    if not access_token:
        print("Error: Mapillary access token required!")
        print("Set MAPILLARY_ACCESS_TOKEN environment variable or pass as argument")
        sys.exit(1)

    print(f"Scraping Mapillary images from: {csv_path}")
    print(f"Saving to: {output_dir}\n")

    stats = scrape_mapillary_for_buildings(csv_path, output_dir, access_token)

    print("\n" + "="*50)
    print("MAPILLARY SCRAPING SUMMARY")
    print("="*50)
    print(f"Total buildings: {stats['total_buildings']}")
    print(f"Buildings with coordinates: {stats['buildings_with_coords']}")
    print(f"Buildings with images: {stats['buildings_with_images']}")
    print(f"Total images downloaded: {stats['total_images_downloaded']}")
    print(f"Skipped (no coords): {stats['skipped_no_coords']}")
    print(f"Skipped (no images): {stats['skipped_no_images']}")
    print(f"\n✓ All images are freely available (Creative Commons)")
