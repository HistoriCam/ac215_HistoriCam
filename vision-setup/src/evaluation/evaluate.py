#!/usr/bin/env python3
"""
Evaluate vision pipeline accuracy using test images.

This script computes exact similarity with all indexed embeddings
and measures accuracy of building identification.
"""
import argparse
import json
import os
from pathlib import Path
from typing import Dict, List
from collections import Counter, defaultdict
import numpy as np
import vertexai
from google.cloud import storage
from vertexai.vision_models import MultiModalEmbeddingModel, Image
from ..utils import resize_image_if_needed


def load_test_images(test_file: Path, bucket_name: str, version: str) -> List[Dict]:
    """
    Load test image IDs and download from GCS.

    Returns list of dicts with image_id, building_id, and image_bytes
    """
    # Load test image IDs
    test_image_ids = []
    with open(test_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                test_image_ids.append(line)

    print(f"Loading {len(test_image_ids)} test images from GCS...")

    # Download images from GCS
    client = storage.Client()
    bucket = client.bucket(bucket_name)

    test_images = []
    for image_id in test_image_ids:
        # Parse building_id from image_id (format: "building_id_hash")
        building_id = image_id.split('_')[0]
        image_hash = image_id.split('_', 1)[1]

        # Images are stored flat in images/{version}/building_id/hash.ext"
        # Try common extensions
        found = False
        for ext in ['jpg', 'JPG', 'jpeg', 'JPEG', 'png', 'PNG', 'tif', 'TIF', 'tiff', 'TIFF']:
            gcs_path = f"images/{version}/{building_id}/{image_hash}.{ext}"
            blob = bucket.blob(gcs_path)

            if blob.exists():
                image_bytes = blob.download_as_bytes()
                test_images.append({
                    'image_id': image_id,
                    'building_id': building_id,
                    'image_bytes': image_bytes
                })
                found = True
                break

        if not found:
            print(f"  Warning: Could not find image for {image_id}")

    print(f"Successfully loaded {len(test_images)} test images")
    return test_images


def load_embeddings_index(embeddings_path: str, project_id: str) -> Dict[str, np.ndarray]:
    """Load embeddings from GCS JSONL into memory"""
    # Parse GCS path
    path_parts = embeddings_path[5:].split("/", 1)  # Remove 'gs://'
    bucket_name = path_parts[0]
    blob_path = path_parts[1]

    # Download embeddings
    print(f"Loading embeddings from {embeddings_path}...")
    client = storage.Client(project=project_id)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_path)
    embeddings_json = blob.download_as_text()

    # Parse JSONL
    index = {}
    for line in embeddings_json.strip().split("\n"):
        if line:
            record = json.loads(line)
            index[record["id"]] = np.array(record["embedding"], dtype=np.float32)

    print(f"Loaded {len(index)} embeddings into memory")
    return index


def evaluate_embeddings(
    test_images: List[Dict],
    embeddings_path: str,
    project_id: str,
    location: str = "us-central1",
    dimension: int = 512,
    top_k: int = 5,
    confidence_threshold: float = 0.7
):
    """
    Evaluate embedding similarity with test images.

    Args:
        test_images: List of test images with ground truth building_ids
        embeddings_path: GCS path to embeddings JSONL
        project_id: GCP project ID
        location: GCP location
        dimension: Embedding dimension
        top_k: Number of neighbors to retrieve
        confidence_threshold: Similarity threshold for classification
    """
    # Initialize Vertex AI (for embedding model only)
    vertexai.init(project=project_id, location=location)

    # Load embeddings index
    index = load_embeddings_index(embeddings_path, project_id)

    # Initialize embedding model
    print("Initializing embedding model...")
    model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")
    
    # Evaluate each test image
    results = []
    correct_confident = 0
    correct_any = 0
    total = len(test_images)

    print(f"\nEvaluating {total} test images...")

    for i, test_img in enumerate(test_images):
        # Preprocess image (must match training preprocessing!)
        preprocessed_bytes = resize_image_if_needed(test_img['image_bytes'])

        # Generate embedding
        response = model.get_embeddings(
            image=Image(preprocessed_bytes),
            dimension=dimension
        )
        query_embedding = np.array(response.image_embedding, dtype=np.float32)

        # Compute cosine similarities with all indexed embeddings
        query_norm = query_embedding / np.linalg.norm(query_embedding)

        similarities = {}
        for image_id, stored_embedding in index.items():
            stored_norm = stored_embedding / np.linalg.norm(stored_embedding)
            similarity = float(np.dot(query_norm, stored_norm))
            similarities[image_id] = similarity

        # Sort by similarity and get top-k
        sorted_results = sorted(similarities.items(), key=lambda x: x[1], reverse=True)

        matches = []
        for image_id, similarity in sorted_results[:top_k]:
            building_id = image_id.split('_')[0]
            matches.append({
                'building_id': building_id,
                'image_id': image_id,
                'similarity': similarity
            })

        # Debug: Print first 5 samples
        if i < 5:
            print(f"\n[Sample {i+1}] Test: {test_img['image_id']} (Building {test_img['building_id']})")
            print(f"  Top-{top_k} matches:")
            for j, m in enumerate(matches[:top_k]):
                print(f"    {j+1}. {m['image_id'][:50]:50s} | Building {m['building_id']:3s} | sim={m['similarity']:.4f}")
            if matches:
                print(f"  Max similarity: {max([m['similarity'] for m in matches]):.4f} (threshold: {confidence_threshold})")
            else:
                print(f"  No matches returned!")

        # Apply classification logic (majority vote above threshold)
        confident_matches = [m for m in matches if m['similarity'] >= confidence_threshold]
        
        if confident_matches:
            building_ids = [m['building_id'] for m in confident_matches]
            predicted_building = Counter(building_ids).most_common(1)[0][0]
            status = "confident"
        elif matches:
            building_ids = [m['building_id'] for m in matches]
            predicted_building = Counter(building_ids).most_common(1)[0][0]
            status = "uncertain"
        else:
            predicted_building = None
            status = "no_match"
        
        # Check if correct
        ground_truth = test_img['building_id']
        is_correct = (predicted_building == ground_truth)
        
        if is_correct and status == "confident":
            correct_confident += 1
        if is_correct:
            correct_any += 1
        
        results.append({
            'image_id': test_img['image_id'],
            'ground_truth': ground_truth,
            'predicted': predicted_building,
            'status': status,
            'correct': is_correct,
            'matches': matches
        })
        
        if (i + 1) % 10 == 0:
            print(f"  Evaluated {i + 1}/{total} images...")
    
    # Calculate metrics
    print(f"\n{'='*60}")
    print("EVALUATION RESULTS")
    print(f"{'='*60}\n")
    print(f"Total test images: {total}")
    print(f"Top-k: {top_k}")
    print(f"Confidence threshold: {confidence_threshold}")
    print(f"\nAccuracy (confident predictions only): {correct_confident/total*100:.1f}%")
    print(f"Accuracy (all predictions): {correct_any/total*100:.1f}%")
    
    # Status breakdown
    status_counts = Counter(r['status'] for r in results)
    print(f"\nPrediction Status:")
    for status, count in status_counts.items():
        print(f"  {status}: {count} ({count/total*100:.1f}%)")
    
    # Per-building accuracy
    building_results = defaultdict(lambda: {'total': 0, 'correct': 0})
    for r in results:
        building_id = r['ground_truth']
        building_results[building_id]['total'] += 1
        if r['correct']:
            building_results[building_id]['correct'] += 1
    
    print(f"\nPer-Building Accuracy (buildings with errors):")
    for building_id in sorted(building_results.keys()):
        stats = building_results[building_id]
        accuracy = stats['correct'] / stats['total'] * 100
        if accuracy < 100:
            print(f"  Building {building_id}: {accuracy:.1f}% ({stats['correct']}/{stats['total']})")
    
    return results


def main():
    parser = argparse.ArgumentParser(description="Evaluate vision pipeline accuracy")
    parser.add_argument("--test-file", default="test_data/test_images.txt", help="Path to test images file")
    parser.add_argument("--bucket", default="historicam-images", help="GCS bucket name")
    parser.add_argument("--version", default="latest", help="Data version")
    parser.add_argument("--embeddings-path", required=True, help="GCS path to embeddings JSONL")
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument("--location", default="us-central1", help="GCP location")
    parser.add_argument("--dimension", type=int, default=512, help="Embedding dimension")
    parser.add_argument("--top-k", type=int, default=5, help="Number of neighbors")
    parser.add_argument("--threshold", type=float, default=0.7, help="Confidence threshold")

    args = parser.parse_args()

    # Resolve version if needed
    version = args.version
    if version == "latest":
        client = storage.Client(project=args.project)
        bucket = client.bucket(args.bucket)
        metadata_blob = bucket.blob("metadata/versions.json")

        if not metadata_blob.exists():
            raise ValueError("No versions found in bucket (metadata/versions.json not found)")

        metadata = json.loads(metadata_blob.download_as_text())
        versions = metadata.get("versions", [])
        if not versions:
            raise ValueError("No versions found in metadata/versions.json")

        version = versions[-1]['version']
        print(f"Using latest version: {version}")

    # Load test images
    test_images = load_test_images(
        Path(args.test_file),
        args.bucket,
        version
    )

    # Evaluate
    results = evaluate_embeddings(
        test_images=test_images,
        embeddings_path=args.embeddings_path,
        project_id=args.project,
        location=args.location,
        dimension=args.dimension,
        top_k=args.top_k,
        confidence_threshold=args.threshold
    )


if __name__ == "__main__":
    main()
