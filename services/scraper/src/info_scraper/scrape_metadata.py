import requests
import csv
import time
from datetime import datetime
from pathlib import Path

S = requests.Session()
S.headers.update({
    'User-Agent': 'HistoriCam/1.0 (Educational project; contact: hughvandeventer@g.harvard.edu)'
})
API = "https://en.wikipedia.org/w/api.php"


def extract_page_id_from_url(url):
    """Extract page ID from Wikipedia URL."""
    if "curid=" in url:
        return url.split("curid=")[1].split("&")[0]
    return None


def fetch_page_metadata(page_id):
    """Fetch coordinates, aliases, and other metadata for a Wikipedia page."""
    params = {
        "action": "query",
        "format": "json",
        "prop": "coordinates|pageprops|pageterms",
        "pageids": page_id,
        "coprop": "type|dim|name|country|region|globe",
        "ppprop": "wikibase_item",
        "wbptterms": "alias"
    }

    try:
        r = S.get(API, params=params, timeout=30)
        r.raise_for_status()
        data = r.json()

        page_data = data["query"]["pages"].get(str(page_id), {})
        coords = page_data.get("coordinates", [{}])[0]

        # Extract aliases
        aliases = []
        if "terms" in page_data and "alias" in page_data["terms"]:
            aliases = page_data["terms"]["alias"]

        metadata = {
            "latitude": coords.get("lat"),
            "longitude": coords.get("lon"),
            "aliases": "|".join(aliases) if aliases else "",
            "wikibase_item": page_data.get("pageprops", {}).get("wikibase_item", "")
        }

        return metadata

    except Exception as e:
        print(f"Error fetching metadata for page {page_id}: {e}")
        return {
            "latitude": None,
            "longitude": None,
            "aliases": "",
            "wikibase_item": ""
        }


def scrape_metadata(input_csv, output_csv=None):
    """
    Read buildings CSV and scrape additional metadata.

    Args:
        input_csv: Path to input CSV with building names
        output_csv: Path to output CSV (defaults to input_csv with _metadata suffix)
    """
    input_path = Path(input_csv)

    if output_csv is None:
        output_csv = input_path.parent / f"{input_path.stem}_metadata.csv"
    else:
        output_csv = Path(output_csv)

    # Ensure output directory exists
    output_csv.parent.mkdir(parents=True, exist_ok=True)

    # Read input CSV
    buildings = []
    with open(input_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        buildings = list(reader)

    print(f"Processing {len(buildings)} buildings...")

    # Scrape metadata and write to output
    now = datetime.utcnow().isoformat()
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        fieldnames = [
            'id', 'name', 'source_url', 'last_seen', 'source',
            'latitude', 'longitude', 'aliases', 'wikibase_item'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for i, building in enumerate(buildings, 1):
            print(f"Processing {i}/{len(buildings)}: {building['name']}")

            # Extract page ID from URL
            page_id = extract_page_id_from_url(building['source_url'])

            if page_id:
                # Fetch metadata
                metadata = fetch_page_metadata(page_id)

                # Combine existing data with new metadata
                row = {
                    'id': building['id'],
                    'name': building['name'],
                    'source_url': building['source_url'],
                    'last_seen': now,
                    'source': building['source'],
                    'latitude': metadata['latitude'] if metadata['latitude'] is not None else '',
                    'longitude': metadata['longitude'] if metadata['longitude'] is not None else '',
                    'aliases': metadata['aliases'],
                    'wikibase_item': metadata['wikibase_item']
                }

                writer.writerow(row)

                # Rate limiting - be nice to Wikipedia
                time.sleep(0.1)
            else:
                print(f"  Warning: Could not extract page ID from {building['source_url']}")
                # Write row with empty metadata
                row = {
                    'id': building['id'],
                    'name': building['name'],
                    'source_url': building['source_url'],
                    'last_seen': now,
                    'source': building['source'],
                    'latitude': '',
                    'longitude': '',
                    'aliases': '',
                    'wikibase_item': ''
                }
                writer.writerow(row)

    print(f"\nMetadata scraping complete!")
    print(f"Output written to: {output_csv}")
    return str(output_csv)


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python scrape_metadata.py <input_csv> [output_csv]")
        sys.exit(1)

    input_csv = sys.argv[1]
    output_csv = sys.argv[2] if len(sys.argv) > 2 else None

    scrape_metadata(input_csv, output_csv)
