import argparse
from pathlib import Path
from scraper.scrape_wikipedia_buildings import main as scrape_wikipedia


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

    # Determine the repository root (4 levels up from this file)
    repo_root = Path(__file__).parent.parent.parent.parent

    # Set default output path to data folder in repo root
    if args.output is None:
        output_path = repo_root / "data" / "wikipedia_buildings_baseline.csv"
    else:
        output_path = Path(args.output)

    # Ensure the data directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Scraping Wikipedia buildings...")
    print(f"Output file: {output_path}")

    # Call the scraper
    scrape_wikipedia(str(output_path))

    print(f" Successfully scraped data to {output_path}")


if __name__ == "__main__":
    main()
