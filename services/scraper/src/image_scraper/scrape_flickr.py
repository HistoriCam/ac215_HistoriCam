"""
Flickr API scraper for building images.
Searches for Creative Commons licensed photos by building name and location.
"""
import requests
import time
import os
from pathlib import Path
from typing import Optional, List, Dict
import pandas as pd
from image_scraper.scrape_images import WikimediaImageScraper


class FlickrScraper:
    """Scraper for Flickr API with Creative Commons license filtering"""

    # Creative Commons licenses that allow use
    # See: https://www.flickr.com/services/api/flickr.photos.licenses.getInfo.html
    ALLOWED_LICENSES = {
        "1": "Attribution-NonCommercial-ShareAlike",
        "2": "Attribution-NonCommercial",
        "3": "Attribution-NonCommercial-NoDerivs",
        "4": "Attribution",
        "5": "Attribution-ShareAlike",
        "6": "Attribution-NoDerivs",
        "7": "No known copyright restrictions",
        "8": "United States Government Work",
        "9": "Public Domain Dedication (CC0)",
        "10": "Public Domain Mark"
    }

    def __init__(self, api_key: str, user_agent: str = "HistoriCam/1.0"):
        """
        Initialize Flickr scraper.

        Args:
            api_key: Flickr API key (get from https://www.flickr.com/services/api/)
            user_agent: User agent string
        """
        self.api_key = api_key
        self.base_url = "https://api.flickr.com/services/rest/"
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': user_agent})

    def search_photos(
        self,
        text: str,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        radius: float = 0.1,  # km
        min_upload_date: Optional[str] = None,
        per_page: int = 50,
        sort: str = "relevance"
    ) -> List[Dict]:
        """
        Search for photos on Flickr.

        Args:
            text: Search text (building name)
            lat: Latitude for geo search
            lon: Longitude for geo search
            radius: Search radius in km (default 0.1km = 100m)
            min_upload_date: Minimum upload date (YYYY-MM-DD)
            per_page: Results per page (max 500)
            sort: Sort order (relevance, date-posted-desc, interestingness-desc)

        Returns:
            List of photo metadata dicts
        """
        params = {
            "method": "flickr.photos.search",
            "api_key": self.api_key,
            "text": text,
            "license": ",".join(self.ALLOWED_LICENSES.keys()),  # Only CC licenses
            "content_type": 1,  # Photos only (no screenshots)
            "media": "photos",
            "per_page": per_page,
            "page": 1,
            "sort": sort,
            "extras": "description,license,date_upload,date_taken,owner_name,tags,geo,url_c,url_l,url_o",
            "format": "json",
            "nojsoncallback": 1
        }

        # Add geo filtering if coordinates provided
        if lat is not None and lon is not None:
            params["lat"] = lat
            params["lon"] = lon
            params["radius"] = radius
            params["radius_units"] = "km"

        if min_upload_date:
            # Convert to Unix timestamp
            from datetime import datetime
            dt = datetime.strptime(min_upload_date, "%Y-%m-%d")
            params["min_upload_date"] = int(dt.timestamp())

        try:
            resp = self.session.get(self.base_url, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()

            if data.get("stat") != "ok":
                print(f"  Flickr API error: {data.get('message')}")
                return []

            photos = data.get("photos", {}).get("photo", [])
            return photos

        except Exception as e:
            print(f"  Error searching Flickr: {e}")
            return []

    def get_best_photo_url(self, photo: Dict) -> Optional[str]:
        """
        Get the best available photo URL (prefer large, fall back to medium).

        Args:
            photo: Photo metadata from Flickr API

        Returns:
            Photo URL or None
        """
        # Priority: original > large > medium
        if photo.get("url_o"):
            return photo["url_o"]
        elif photo.get("url_l"):
            return photo["url_l"]
        elif photo.get("url_c"):
            return photo["url_c"]
        else:
            # Construct URL manually
            return f"https://live.staticflickr.com/{photo['server']}/{photo['id']}_{photo['secret']}_b.jpg"

    def download_photo(self, url: str) -> Optional[bytes]:
        """
        Download photo from URL.

        Args:
            url: Photo URL

        Returns:
            Photo bytes or None
        """
        try:
            resp = self.session.get(url, timeout=30)
            resp.raise_for_status()
            return resp.content
        except Exception as e:
            print(f"  Error downloading from {url}: {e}")
            return None

    def get_photo_info(self, photo_id: str) -> Optional[Dict]:
        """
        Get detailed photo information including license.

        Args:
            photo_id: Flickr photo ID

        Returns:
            Photo info dict or None
        """
        params = {
            "method": "flickr.photos.getInfo",
            "api_key": self.api_key,
            "photo_id": photo_id,
            "format": "json",
            "nojsoncallback": 1
        }

        try:
            resp = self.session.get(self.base_url, params=params, timeout=10)
            resp.raise_for_status()
            data = resp.json()

            if data.get("stat") == "ok":
                return data.get("photo")
            return None

        except Exception as e:
            print(f"  Error getting photo info: {e}")
            return None


def scrape_flickr_for_buildings(
    csv_path: str,
    output_dir: str,
    api_key: str,
    max_images_per_building: int = 10,
    use_geo_search: bool = True,
    search_radius_km: float = 0.1
) -> Dict:
    """
    Scrape Flickr images for all buildings.

    Args:
        csv_path: Path to buildings CSV with name, latitude, longitude
        output_dir: Directory to save images
        api_key: Flickr API key
        max_images_per_building: Max images per building
        use_geo_search: Whether to use geo filtering (requires lat/lon)
        search_radius_km: Geo search radius in kilometers

    Returns:
        Summary statistics
    """
    df = pd.read_csv(csv_path)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    scraper = FlickrScraper(api_key)
    hash_util = WikimediaImageScraper()

    stats = {
        "total_buildings": len(df),
        "buildings_with_images": 0,
        "total_images_downloaded": 0,
        "api_calls": 0,
        "failed_downloads": 0,
        "skipped_no_results": 0
    }

    manifest = []

    for idx, row in df.iterrows():
        building_id = row['id']
        building_name = row['name']
        lat = row.get('latitude') if use_geo_search else None
        lon = row.get('longitude') if use_geo_search else None

        print(f"\n[{idx+1}/{len(df)}] Processing: {building_name}")

        # Search for photos
        search_query = f"{building_name} Harvard"

        # Use geo search if coordinates available
        if use_geo_search and not (pd.isna(lat) or pd.isna(lon)):
            photos = scraper.search_photos(
                text=search_query,
                lat=lat,
                lon=lon,
                radius=search_radius_km,
                per_page=max_images_per_building * 2  # Get extras in case some fail
            )
        else:
            photos = scraper.search_photos(
                text=search_query,
                per_page=max_images_per_building * 2
            )

        stats["api_calls"] += 1

        if not photos:
            print(f"  No Flickr photos found")
            stats["skipped_no_results"] += 1
            continue

        print(f"  Found {len(photos)} photos on Flickr")

        # Download images
        building_dir = output_path / str(building_id)
        building_dir.mkdir(exist_ok=True)

        downloaded_count = 0
        for photo in photos:
            if downloaded_count >= max_images_per_building:
                break

            # Get photo URL
            photo_url = scraper.get_best_photo_url(photo)
            if not photo_url:
                continue

            # Download photo
            photo_data = scraper.download_photo(photo_url)
            if not photo_data:
                stats["failed_downloads"] += 1
                continue

            # Generate hash for deduplication
            img_hash = hash_util.compute_hash(photo_data)

            # Save with hash as filename
            filename = f"{img_hash}_flickr.jpg"
            img_path = building_dir / filename

            with open(img_path, 'wb') as f:
                f.write(photo_data)

            downloaded_count += 1
            stats["total_images_downloaded"] += 1

            # Add to manifest
            license_name = FlickrScraper.ALLOWED_LICENSES.get(
                str(photo.get("license", "unknown")),
                "Unknown"
            )

            manifest.append({
                "building_id": building_id,
                "building_name": building_name,
                "image_hash": img_hash,
                "filename": img_path.name,  # Actual filename on disk
                "local_path": str(img_path),
                "source": "flickr",
                "flickr_id": photo.get("id"),
                "flickr_url": f"https://www.flickr.com/photos/{photo.get('owner')}/{photo.get('id')}",
                "license": license_name,
                "license_id": photo.get("license"),
                "owner": photo.get("ownername"),
                "title": photo.get("title"),
                "date_taken": photo.get("datetaken"),
                "tags": photo.get("tags")
            })

            time.sleep(0.5)  # Rate limiting

        if downloaded_count > 0:
            stats["buildings_with_images"] += 1
            print(f"  Downloaded {downloaded_count} Flickr images")

    # Save manifest
    manifest_df = pd.DataFrame(manifest)
    manifest_path = output_path / "flickr_manifest.csv"
    manifest_df.to_csv(manifest_path, index=False)
    print(f"\n✓ Saved manifest to {manifest_path}")

    return stats


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python scrape_flickr.py <csv_path> <output_dir> [api_key]")
        print("\nAPI key can be provided as:")
        print("  1. Command line argument")
        print("  2. FLICKR_API_KEY environment variable")
        print("\nGet API key from: https://www.flickr.com/services/api/")
        sys.exit(1)

    csv_path = sys.argv[1]
    output_dir = sys.argv[2]
    api_key = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("FLICKR_API_KEY")

    if not api_key:
        print("Error: Flickr API key required!")
        print("Set FLICKR_API_KEY environment variable or pass as argument")
        sys.exit(1)

    print(f"Scraping Flickr images from: {csv_path}")
    print(f"Saving to: {output_dir}\n")

    stats = scrape_flickr_for_buildings(csv_path, output_dir, api_key)

    print("\n" + "="*50)
    print("FLICKR SCRAPING SUMMARY")
    print("="*50)
    print(f"Total buildings: {stats['total_buildings']}")
    print(f"Buildings with images: {stats['buildings_with_images']}")
    print(f"Total images downloaded: {stats['total_images_downloaded']}")
    print(f"API calls made: {stats['api_calls']}")
    print(f"Failed downloads: {stats['failed_downloads']}")
    print(f"Skipped (no results): {stats['skipped_no_results']}")
    print(f"\nAll images are Creative Commons licensed!")
