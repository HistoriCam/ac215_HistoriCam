"""
Data preprocessing pipeline
"""
import os
from google.cloud import storage

def main():
    project = os.environ.get('GCP_PROJECT')
    bucket_name = os.environ.get('GCS_BUCKET_NAME')

    print(f"Starting preprocessing for project: {project}")
    # TODO: Add preprocessing logic

if __name__ == "__main__":
    main()
