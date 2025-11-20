import argparse
import sys
from pathlib import Path

# Add the src directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from services.scraper.src.info_scraper.scrape_building_name import scrape_building_names as scrape_wikipedia
from services.scraper.src.info_scraper.scrape_metadata import scrape_metadata


def main():
    parser = argparse.ArgumentParser(
        description="HistoriCam Data Scraper CLI"
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=None,
        help="Output CSV file path (default: data/buildings_names.csv in repo root)"
    )
    parser.add_argument(
        "--skip-metadata",
        action="store_true",
        help="Skip metadata scraping (latitude, longitude, aliases)"
    )
    parser.add_argument(
        "--metadata-only",
        action="store_true",
        help="Only scrape metadata from existing buildings CSV"
    )
    parser.add_argument(
        "--input",
        "-i",
        type=str,
        default=None,
        help="Input CSV file for metadata scraping (used with --metadata-only)"
    )

    args = parser.parse_args()

    # Determine the repository root (3 levels up from this file)
    repo_root = Path(__file__).parent.parent.parent.parent

    # Set default output path to data folder in repo root
    if args.output is None:
        output_path = repo_root / "data" / "buildings_names.csv"
    else:
        output_path = Path(args.output)

    # Ensure the data directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Metadata-only mode
    if args.metadata_only:
        input_path = Path(args.input) if args.input else output_path
        print(f"Scraping metadata for buildings in {input_path}...")
        metadata_output = scrape_metadata(str(input_path))
        print(f"Successfully scraped metadata to {metadata_output}")
        return

    # Step 1: Scrape building names
    print(f"Step 1: Scraping Wikipedia buildings...")
    print(f"Output file: {output_path}")
    scrape_wikipedia(str(output_path))
    print(f"Successfully scraped {output_path}")

    # Step 2: Scrape metadata (unless skipped)
    if not args.skip_metadata:
        print(f"\nStep 2: Scraping metadata (latitude, longitude, aliases)...")
        metadata_output = scrape_metadata(str(output_path))
        print(f"Successfully scraped metadata to {metadata_output}")
    else:
        print("\nSkipping metadata scraping (--skip-metadata flag set)")

    print("\n✓ Scraping complete!")


if __name__ == "__main__":
    main()
