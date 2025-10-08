# Data Collection

Local scripts for gathering data from various sources. **Not containerized** - run these locally to collect initial datasets.

## Scripts

- `scrape_wikipedia_buildings.py` - Scrapes Harvard buildings from Wikipedia

## Usage

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync

# Run scraper
uv run python scrape_wikipedia_buildings.py output.csv
```

## Output

Raw data is saved to `scraped_data/` (gitignored). Upload to GCS for use in containerized pipelines.
