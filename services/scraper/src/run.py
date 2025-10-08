import argparse
import sys
from pathlib import Path

# Add the src directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from scraper.scrape_building_name import scrape_building_names as scrape_wikipedia


def main():
    parser = argparse.ArgumentParser(
        description="HistoriCam Data Scraper CLI"
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=None,
        help="Output CSV file path (default: data/wikipedia_buildings_baseline.csv in repo root)"
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

    print(f"Scraping Wikipedia buildings...")
    print(f"Output file: {output_path}")

    # Call the scraper
    scrape_wikipedia(str(output_path))

    print(f"Successfully scraped data to {output_path}")


if __name__ == "__main__":
    main()
