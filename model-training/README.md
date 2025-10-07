# Model Training

Containerized ML model training pipeline.

## Usage

```bash
# Build and run container
sh docker-shell.sh

# Inside container
python src/train.py
```

## Input
- Preprocessed data from GCS

## Output
- Trained model artifacts to GCS
- Model registry in Vertex AI
