"""
Wikimedia Commons image scraper for Harvard buildings.
Uses Wikidata QIDs to fetch images from Wikimedia Commons.
"""
import requests
import time
import hashlib
from pathlib import Path
from typing import Optional, List, Dict
from io import BytesIO
from PIL import Image


class WikimediaImageScraper:
    """Scraper for Wikimedia Commons images via Wikidata"""

    def __init__(self, user_agent: str = "HistoriCam/1.0 (Educational project)"):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': user_agent})
        self.wikidata_api = "https://www.wikidata.org/w/api.php"
        self.commons_api = "https://commons.wikimedia.org/w/api.php"

    def get_images_for_qid(self, qid: str, limit: int = 10) -> List[Dict]:
        """
        Get image URLs from Wikimedia Commons for a given Wikidata QID.

        Args:
            qid: Wikidata QID (e.g., 'Q4684454')
            limit: Maximum number of images to fetch

        Returns:
            List of dicts with image metadata: {url, filename, width, height, size}
        """
        if not qid or qid.strip() == "":
            return []

        images = []

        # Step 1: Get image filenames from Wikidata
        params = {
            "action": "wbgetclaims",
            "entity": qid,
            "property": "P18",  # P18 = image property
            "format": "json"
        }

        try:
            resp = self.session.get(self.wikidata_api, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()

            # Extract image filenames
            claims = data.get("claims", {}).get("P18", [])
            if not claims:
                print(f"  No images found in Wikidata for {qid}")
                return []

            filenames = []
            for claim in claims[:limit]:
                try:
                    filename = claim["mainsnak"]["datavalue"]["value"]
                    filenames.append(filename)
                except (KeyError, TypeError):
                    continue

            # Step 2: Get image URLs and metadata from Commons
            for filename in filenames:
                image_info = self._get_image_info(filename)
                if image_info:
                    images.append(image_info)
                    time.sleep(0.5)  # Rate limiting

        except requests.exceptions.RequestException as e:
            print(f"  Error fetching images for {qid}: {e}")

        return images

    def _get_image_info(self, filename: str) -> Optional[Dict]:
        """Get image URL and metadata from Commons"""
        params = {
            "action": "query",
            "titles": f"File:{filename}",
            "prop": "imageinfo",
            "iiprop": "url|size|mime",
            "format": "json"
        }

        try:
            resp = self.session.get(self.commons_api, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()

            pages = data.get("query", {}).get("pages", {})
            for page in pages.values():
                imageinfo = page.get("imageinfo", [])
                if imageinfo:
                    info = imageinfo[0]
                    return {
                        "url": info.get("url"),
                        "filename": filename,
                        "width": info.get("width"),
                        "height": info.get("height"),
                        "size": info.get("size"),
                        "mime": info.get("mime")
                    }
        except requests.exceptions.RequestException as e:
            print(f"  Error getting info for {filename}: {e}")

        return None

    def download_image(self, url: str, validate: bool = True) -> Optional[bytes]:
        """
        Download image from URL.

        Args:
            url: Image URL
            validate: Whether to validate the image

        Returns:
            Image bytes if successful, None otherwise
        """
        try:
            resp = self.session.get(url, timeout=30)
            resp.raise_for_status()
            image_bytes = resp.content

            if validate:
                # Validate it's a valid image
                try:
                    img = Image.open(BytesIO(image_bytes))
                    img.verify()  # Verify it's not corrupted
                except Exception as e:
                    print(f"  Invalid image from {url}: {e}")
                    return None

            return image_bytes

        except requests.exceptions.RequestException as e:
            print(f"  Error downloading {url}: {e}")
            return None

    @staticmethod
    def compute_hash(data: bytes) -> str:
        """Compute SHA256 hash of image data"""
        return hashlib.sha256(data).hexdigest()


def scrape_images_for_buildings(
    csv_path: str,
    output_dir: str,
    max_images_per_building: int = 10
) -> Dict:
    """
    Scrape images for all buildings in CSV.

    Args:
        csv_path: Path to buildings CSV with wikibase_item column
        output_dir: Directory to save images
        max_images_per_building: Max images per building

    Returns:
        Summary statistics
    """
    import pandas as pd

    df = pd.read_csv(csv_path)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    scraper = WikimediaImageScraper()
    stats = {
        "total_buildings": len(df),
        "buildings_with_images": 0,
        "total_images_downloaded": 0,
        "failed_downloads": 0
    }

    # Track image metadata for manifest
    manifest = []

    for idx, row in df.iterrows():
        building_id = row['id']
        building_name = row['name']
        qid = row.get('wikibase_item', '')

        print(f"\n[{idx+1}/{len(df)}] Processing: {building_name} ({qid})")

        if not qid or pd.isna(qid):
            print(f"  Skipping - no Wikidata QID")
            continue

        # Get images from Wikimedia
        images = scraper.get_images_for_qid(qid, limit=max_images_per_building)

        if not images:
            print(f"  No images found")
            continue

        stats["buildings_with_images"] += 1
        building_dir = output_path / str(building_id)
        building_dir.mkdir(exist_ok=True)

        # Download each image
        for img_idx, img_info in enumerate(images):
            print(f"  Downloading image {img_idx+1}/{len(images)}: {img_info['filename']}")

            image_bytes = scraper.download_image(img_info['url'])
            if not image_bytes:
                stats["failed_downloads"] += 1
                continue

            # Compute hash for deduplication
            img_hash = scraper.compute_hash(image_bytes)

            # Save with hash as filename
            ext = Path(img_info['filename']).suffix or '.jpg'
            img_path = building_dir / f"{img_hash}{ext}"

            with open(img_path, 'wb') as f:
                f.write(image_bytes)

            stats["total_images_downloaded"] += 1

            # Add to manifest
            manifest.append({
                "building_id": building_id,
                "building_name": building_name,
                "qid": qid,
                "image_hash": img_hash,
                "original_filename": img_info['filename'],
                "local_path": str(img_path),
                "url": img_info['url'],
                "width": img_info['width'],
                "height": img_info['height'],
                "size_bytes": img_info['size'],
                "mime_type": img_info['mime']
            })

            time.sleep(1)  # Rate limiting

    # Save manifest
    manifest_df = pd.DataFrame(manifest)
    manifest_path = output_path / "image_manifest.csv"
    manifest_df.to_csv(manifest_path, index=False)
    print(f"\n✓ Saved manifest to {manifest_path}")

    return stats


if __name__ == "__main__":
    import sys

    csv_path = sys.argv[1] if len(sys.argv) > 1 else "../../data/buildings_names_metadata.csv"
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "../../data/images"

    print(f"Scraping images from: {csv_path}")
    print(f"Saving to: {output_dir}\n")

    stats = scrape_images_for_buildings(csv_path, output_dir)

    print("\n" + "="*50)
    print("SUMMARY")
    print("="*50)
    print(f"Total buildings: {stats['total_buildings']}")
    print(f"Buildings with images: {stats['buildings_with_images']}")
    print(f"Total images downloaded: {stats['total_images_downloaded']}")
    print(f"Failed downloads: {stats['failed_downloads']}")

# In docker:
# 1. Scrape images from Wikimedia Commons
# uv run python src/scraper/scrape_images.py \
#     /data/buildings_names_metadata.csv \
#     /data/images