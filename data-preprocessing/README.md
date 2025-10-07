# Data Preprocessing

Containerized pipeline for cleaning and preprocessing raw data.

## Usage

```bash
# Build and run container
sh docker-shell.sh

# Inside container
python src/preprocess.py
```

## Input
- Raw data from GCS bucket

## Output
- Cleaned data to GCS bucket
