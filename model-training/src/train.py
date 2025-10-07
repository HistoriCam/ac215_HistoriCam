"""
Model training pipeline
"""
import os

def main():
    project = os.environ.get('GCP_PROJECT')
    bucket_name = os.environ.get('GCS_BUCKET_NAME')

    print(f"Starting training for project: {project}")
    # TODO: Add training logic

if __name__ == "__main__":
    main()
