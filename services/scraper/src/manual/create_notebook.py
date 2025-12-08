#!/usr/bin/env python3
"""
Script to create the manual curation Jupyter notebook.
This ensures proper JSON formatting and encoding.
"""
import json
from pathlib import Path

# Read the cell source code from separate Python files for easier editing
# For now, embed directly in this script

cells_source = [
    # Cell 0: Markdown
    {
        "type": "markdown",
        "source": """# Manual Curation Workflow for HistoriCam

This notebook allows you to manually curate 10-20 high-quality buildings/statues for the HistoriCam dataset.

## Workflow:
1. **Cell 1-2**: Setup and define your curated list
2. **Cell 3-4**: Search Wikipedia and fetch metadata
3. **Cell 5**: Generate CSV files
4. **Cell 6**: Create image directories
5. **Manual step**: Download images for each building
6. **Cell 7**: Process images and generate manifest
7. **Cell 8**: Validate and view summary"""
    },

    # Cell 1: Imports
    {
        "type": "code",
        "source": """# Cell 1: Imports and Setup
import requests
import csv
import hashlib
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from PIL import Image
import pandas as pd

print("✓ All imports successful")"""
    },

    # Cell 2: User input
    {
        "type": "code",
        "source": """# Cell 2: User Input - Define Your Curated List
#
# Instructions:
# 1. List 10-20 buildings/statues you want to include
# 2. Provide the name and optionally the type (building/statue)
# 3. If Wikipedia search doesn't find the right page, you can manually add 'pageid'
#
# Example with manual pageid:
#   {"name": "Some Building", "type": "building", "pageid": 12345}

CURATED_ITEMS = [
    {"name": "Widener Library", "type": "building"},
    {"name": "Memorial Hall", "type": "building"},
    {"name": "John Harvard statue", "type": "statue"},
    {"name": "Harvard Science Center", "type": "building"},
    # Add more items here...
]

# Configuration
OUTPUT_DIR = Path("/Users/hughv/Documents/Harvard/AC215/ac215_HistoriCam/data_manual")
USER_AGENT = "HistoriCam/1.0 (Educational project; contact: hughvandeventer@g.harvard.edu)"
WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php"

print(f"✓ Configuration loaded")
print(f"  Items to curate: {len(CURATED_ITEMS)}")
print(f"  Output directory: {OUTPUT_DIR}")"""
    },

    # Cell 3: Wikipedia search functions
    {
        "type": "code",
        "source": """# Cell 3: Wikipedia Search Functions

def search_wikipedia(query: str, session: requests.Session, limit: int = 5) -> List[Tuple[str, str]]:
    \"\"\"
    Search Wikipedia for a query string.
    Returns list of (title, description) tuples.
    \"\"\"
    params = {
        "action": "opensearch",
        "search": query,
        "limit": limit,
        "format": "json",
        "namespace": 0  # Article pages only
    }

    try:
        r = session.get(WIKIPEDIA_API, params=params, timeout=30)
        r.raise_for_status()
        data = r.json()
        # opensearch returns: [query, [titles], [descriptions], [urls]]
        titles = data[1] if len(data) > 1 else []
        descriptions = data[2] if len(data) > 2 else [""] * len(titles)
        return list(zip(titles, descriptions))
    except Exception as e:
        print(f"  Error searching Wikipedia: {e}")
        return []


def get_pageid_from_title(title: str, session: requests.Session) -> Optional[int]:
    \"\"\"
    Get pageid for a specific Wikipedia page title.
    \"\"\"
    params = {
        "action": "query",
        "titles": title,
        "format": "json"
    }

    try:
        r = session.get(WIKIPEDIA_API, params=params, timeout=30)
        r.raise_for_status()
        pages = r.json()["query"]["pages"]
        # Get first (and only) page
        pageid = list(pages.keys())[0]
        if pageid == "-1":  # Page doesn't exist
            return None
        return int(pageid)
    except Exception as e:
        print(f"  Error getting pageid: {e}")
        return None


def fetch_page_details(pageid: int, session: requests.Session) -> Optional[Dict]:
    \"\"\"
    Fetch full metadata for a Wikipedia page by pageid.
    Reuses logic from scrape_building_name.py
    \"\"\"
    params = {
        "action": "query",
        "format": "json",
        "prop": "coordinates|pageprops|pageterms",
        "pageids": str(pageid),
        "coprop": "type|dim|name|country|region|globe",
        "ppprop": "wikibase_item",
        "wbptterms": "alias"
    }

    try:
        r = session.get(WIKIPEDIA_API, params=params, timeout=30)
        r.raise_for_status()
        data = r.json()
        page = data["query"]["pages"][str(pageid)]

        # Extract coordinates
        coords = page.get("coordinates", [{}])[0]
        lat = coords.get("lat")
        lon = coords.get("lon")

        # Extract Wikidata QID
        qid = page.get("pageprops", {}).get("wikibase_item")

        # Extract aliases
        aliases = page.get("terms", {}).get("alias", [])
        aliases_str = "|".join(aliases) if aliases else ""

        return {
            "title": page["title"],
            "pageid": pageid,
            "url": f"https://en.wikipedia.org/?curid={pageid}",
            "lat": lat,
            "lon": lon,
            "qid": qid,
            "aliases": aliases_str
        }
    except Exception as e:
        print(f"  Error fetching page details: {e}")
        return None


def interactive_search_and_select(item: Dict, session: requests.Session) -> Optional[Dict]:
    \"\"\"
    Search Wikipedia for item name and let user select correct match.
    Returns selected page details or None if no match.
    \"\"\"
    query = item["name"]

    # Search Wikipedia
    results = search_wikipedia(query, session, limit=5)

    if not results:
        print(f"  No results found for '{query}'")
        return None

    # Display results
    print(f"\\n  Found {len(results)} results:")
    for idx, (title, desc) in enumerate(results):
        desc_preview = desc[:80] + "..." if len(desc) > 80 else desc
        print(f"    [{idx}] {title}")
        if desc:
            print(f"        {desc_preview}")

    # User selection
    while True:
        choice = input(f"\\n  Select [0-{len(results)-1}] or 's' to skip: ").strip().lower()

        if choice == 's':
            return None

        try:
            idx = int(choice)
            if 0 <= idx < len(results):
                selected_title = results[idx][0]
                print(f"  Selected: {selected_title}")

                # Get pageid and fetch details
                pageid = get_pageid_from_title(selected_title, session)
                if pageid:
                    details = fetch_page_details(pageid, session)
                    if details:
                        details["manual_type"] = item.get("type", "unknown")
                        return details
                return None
        except ValueError:
            pass

        print("  Invalid choice, try again")


print("✓ Wikipedia search functions defined")"""
    },

    # Cell 4: Execute search
    {
        "type": "code",
        "source": """# Cell 4: Execute Wikipedia Search

# Initialize session
session = requests.Session()
session.headers.update({'User-Agent': USER_AGENT})

# Search and collect page details
found_pages = []
skipped_items = []

print(f"Starting Wikipedia search for {len(CURATED_ITEMS)} items...\\n")
print("="*60)

for idx, item in enumerate(CURATED_ITEMS, 1):
    print(f"\\n[{idx}/{len(CURATED_ITEMS)}] Searching for: {item['name']}")

    # Check if manual pageid provided
    if 'pageid' in item:
        print(f"  Using manually provided pageid: {item['pageid']}")
        details = fetch_page_details(item['pageid'], session)
        if details:
            details['manual_type'] = item.get('type', 'unknown')
            found_pages.append(details)
            print(f"  ✓ Found: {details['title']}")
        else:
            print(f"  ✗ Failed to fetch details for pageid {item['pageid']}")
            skipped_items.append(item)
    else:
        # Interactive search
        details = interactive_search_and_select(item, session)
        if details:
            found_pages.append(details)
            print(f"  ✓ Added to curated list")
        else:
            print(f"  ✗ Skipped")
            skipped_items.append(item)

    # Rate limiting
    time.sleep(0.5)

print("\\n" + "="*60)
print("SEARCH COMPLETE")
print("="*60)
print(f"✓ Found: {len(found_pages)} pages")
print(f"✗ Skipped: {len(skipped_items)} items")

if skipped_items:
    print("\\nSkipped items:")
    for item in skipped_items:
        print(f"  - {item['name']}")
    print("\\nTip: Add 'pageid' to skipped items and re-run this cell to include them")

if found_pages:
    print("\\nFound pages:")
    for p in found_pages:
        coord_str = f"({p['lat']:.4f}, {p['lon']:.4f})" if p.get('lat') and p.get('lon') else "(no coordinates)"
        qid_str = p.get('qid', 'no QID')
        print(f"  {p['title']} - {coord_str} - {qid_str}")"""
    },

    # Cell 5: Generate CSVs
    {
        "type": "code",
        "source": """# Cell 5: Generate CSV Files

def generate_buildings_csvs(pages: List[Dict], output_dir: Path) -> Tuple[Path, Path, Path]:
    \"\"\"
    Generate buildings_names.csv and buildings_names_metadata.csv.
    Maintains exact schema compatibility with existing pipeline.
    \"\"\"
    output_dir.mkdir(parents=True, exist_ok=True)
    now = datetime.utcnow().isoformat()

    # Schema 1: buildings_names.csv
    names_path = output_dir / "buildings_names.csv"
    with open(names_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["id", "name", "source_url", "last_seen", "source"])
        for idx, page in enumerate(pages, start=1):
            writer.writerow([
                idx,
                page['title'],
                page['url'],
                now,
                "wikipedia"
            ])
    print(f"✓ Created {names_path.name}")

    # Schema 2: buildings_names_metadata.csv
    metadata_path = output_dir / "buildings_names_metadata.csv"
    with open(metadata_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([
            "id", "name", "source_url", "last_seen", "source",
            "latitude", "longitude", "aliases", "wikibase_item"
        ])
        for idx, page in enumerate(pages, start=1):
            writer.writerow([
                idx,
                page['title'],
                page['url'],
                now,
                "wikipedia",
                page.get('lat', ''),
                page.get('lon', ''),
                page.get('aliases', ''),
                page.get('qid', '')
            ])
    print(f"✓ Created {metadata_path.name}")

    # Schema 3: buildings_info.csv (stub with empty fields for now)
    info_path = output_dir / "buildings_info.csv"
    with open(info_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([
            "id", "name", "source_url", "built_year", "architect",
            "architectural_style", "location", "materials", "building_type",
            "owner", "height", "construction_cost", "unstructured_info"
        ])
        for idx, page in enumerate(pages, start=1):
            writer.writerow([idx, page['title'], page['url']] + [''] * 10)
    print(f"✓ Created {info_path.name} (stub - populate later if needed)")

    return names_path, metadata_path, info_path


if not found_pages:
    print("⚠ No pages found. Cannot generate CSVs.")
    print("  Please re-run Cell 4 to search for pages.")
else:
    print("Generating CSV files...\\n")
    csv_paths = generate_buildings_csvs(found_pages, OUTPUT_DIR)
    print(f"\\n✓ All CSVs generated successfully in {OUTPUT_DIR}")
    print(f"  Total buildings: {len(found_pages)}")"""
    },

    # Cell 6: Setup image directories
    {
        "type": "code",
        "source": """# Cell 6: Setup Image Directories

def setup_image_directories(num_buildings: int, output_dir: Path) -> Path:
    \"\"\"
    Create empty image directories for each building.
    User will manually populate these.
    \"\"\"
    images_dir = output_dir / "images"
    images_dir.mkdir(exist_ok=True)

    for building_id in range(1, num_buildings + 1):
        building_dir = images_dir / str(building_id)
        building_dir.mkdir(exist_ok=True)

    return images_dir


if not found_pages:
    print("⚠ No pages found. Cannot create image directories.")
else:
    images_dir = setup_image_directories(len(found_pages), OUTPUT_DIR)

    print("✓ Created image directories\\n")
    print("="*60)
    print("MANUAL STEP: Download Images")
    print("="*60)
    print(f"\\nImage directories created at: {images_dir}")
    print("\\nNext steps:")
    print("1. Navigate to each numbered directory (1/, 2/, 3/, ...)")
    print("2. Manually download images for corresponding building")
    print("3. Use any filename - code will rename to hash-based names")
    print("4. Download as many images as you want per building")
    print("5. Supported formats: JPEG, PNG, WebP")
    print("6. Min size: 512x512 pixels")
    print("7. Max size: 10MB per image")
    print("\\nBuilding ID to Name mapping:")
    print("-" * 60)
    for idx, page in enumerate(found_pages, start=1):
        print(f"  {idx}/ -> {page['title']}")
    print("-" * 60)
    print("\\nOnce you've downloaded images, run Cell 7 to process them.")"""
    },
]

# Create notebook structure
notebook = {
    "cells": [],
    "metadata": {
        "kernelspec": {
            "display_name": "Python 3",
            "language": "python",
            "name": "python3"
        },
        "language_info": {
            "codemirror_mode": {"name": "ipython", "version": 3},
            "file_extension": ".py",
            "mimetype": "text/x-python",
            "name": "python",
            "nbconvert_exporter": "python",
            "pygments_lexer": "ipython3",
            "version": "3.9.0"
        }
    },
    "nbformat": 4,
    "nbformat_minor": 4
}

# Add all cells
for cell_data in cells_source:
    if cell_data["type"] == "markdown":
        notebook["cells"].append({
            "cell_type": "markdown",
            "metadata": {},
            "source": cell_data["source"]
        })
    else:  # code
        notebook["cells"].append({
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": cell_data["source"]
        })

# Save notebook
output_path = Path(__file__).parent / "data.ipynb"
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1, ensure_ascii=False)

print(f"✓ Created notebook at {output_path}")
print(f"  Total cells: {len(notebook['cells'])}")
print("\\nNote: Cells 7 and 8 still need to be added (image processing and validation)")
