#!/usr/bin/env python3
"""
Evaluate vision pipeline accuracy using test images.

This script queries the Vector Search endpoint directly with test images
and measures accuracy of building identification.
"""
import argparse
import os
from pathlib import Path
from typing import Dict, List
from collections import Counter, defaultdict
import vertexai
from google.cloud import aiplatform, storage
from vertexai.vision_models import MultiModalEmbeddingModel


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
        # Parse building_id from image_id
        building_id = image_id.split('_')[0]
        image_hash = image_id.split('_', 1)[1]
        
        # Try common extensions
        for ext in ['.jpg', '.JPG', '.jpeg', '.JPEG', '.png', '.PNG']:
            gcs_path = f"images/{version}/{building_id}/{image_hash}{ext}"
            blob = bucket.blob(gcs_path)
            
            if blob.exists():
                image_bytes = blob.download_as_bytes()
                test_images.append({
                    'image_id': image_id,
                    'building_id': building_id,
                    'image_bytes': image_bytes
                })
                break
    
    print(f"Successfully loaded {len(test_images)} test images")
    return test_images


def evaluate_endpoint(
    test_images: List[Dict],
    endpoint_id: str,
    deployed_index_id: str,
    project_id: str,
    location: str = "us-central1",
    dimension: int = 512,
    top_k: int = 5,
    confidence_threshold: float = 0.7
):
    """
    Evaluate Vector Search endpoint with test images.
    
    Args:
        test_images: List of test images with ground truth building_ids
        endpoint_id: Vertex AI endpoint ID
        deployed_index_id: Deployed index ID
        project_id: GCP project ID
        location: GCP location
        dimension: Embedding dimension
        top_k: Number of neighbors to retrieve
        confidence_threshold: Similarity threshold for classification
    """
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    aiplatform.init(project=project_id, location=location)
    
    # Initialize model and endpoint
    print("Initializing model and endpoint...")
    model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")
    endpoint = aiplatform.MatchingEngineIndexEndpoint(
        index_endpoint_name=f"projects/{project_id}/locations/{location}/indexEndpoints/{endpoint_id}"
    )
    
    # Evaluate each test image
    results = []
    correct_confident = 0
    correct_any = 0
    total = len(test_images)
    
    for i, test_img in enumerate(test_images):
        # Generate embedding
        response = model.get_embeddings(
            image=test_img['image_bytes'],
            dimension=dimension
        )
        embedding = response.image_embedding
        
        # Query endpoint
        search_response = endpoint.find_neighbors(
            deployed_index_id=deployed_index_id,
            queries=[embedding],
            num_neighbors=top_k
        )
        
        # Parse results
        matches = []
        if search_response and len(search_response) > 0:
            for neighbor in search_response[0]:
                building_id = neighbor.id.split('_')[0]
                similarity = 1.0 - neighbor.distance
                matches.append({
                    'building_id': building_id,
                    'similarity': similarity
                })
        
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
    parser.add_argument("--endpoint-id", required=True, help="Vertex AI endpoint ID")
    parser.add_argument("--deployed-index-id", required=True, help="Deployed index ID")
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument("--location", default="us-central1", help="GCP location")
    parser.add_argument("--dimension", type=int, default=512, help="Embedding dimension")
    parser.add_argument("--top-k", type=int, default=5, help="Number of neighbors")
    parser.add_argument("--threshold", type=float, default=0.7, help="Confidence threshold")
    
    args = parser.parse_args()
    
    # Resolve version if needed
    version = args.version
    if version == "latest":
        from gcs_utils import GCSDataManager
        manager = GCSDataManager(args.bucket, project_id=args.project)
        versions = manager.list_versions()
        version = versions[-1]['version']
        print(f"Using latest version: {version}")
    
    # Load test images
    test_images = load_test_images(
        Path(args.test_file),
        args.bucket,
        version
    )
    
    # Evaluate
    results = evaluate_endpoint(
        test_images=test_images,
        endpoint_id=args.endpoint_id,
        deployed_index_id=args.deployed_index_id,
        project_id=args.project,
        location=args.location,
        dimension=args.dimension,
        top_k=args.top_k,
        confidence_threshold=args.threshold
    )


if __name__ == "__main__":
    main()
