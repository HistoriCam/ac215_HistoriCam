"""
Simple query script for testing deployed Vertex AI Vector Search index.
Use this to validate the index works before building the full API.
"""
import argparse
from pathlib import Path
from typing import List, Dict
import vertexai
from google.cloud import aiplatform

from embeddings.multimodal import MultimodalEmbeddings


def query_index(
    image_path: str,
    index_endpoint_id: str,
    deployed_index_id: str,
    project_id: str,
    location: str = "us-central1",
    dimension: int = 512,
    num_neighbors: int = 10
) -> List[Dict]:
    """
    Query the deployed index with a test image.

    Args:
        image_path: Path to test image
        index_endpoint_id: Vertex AI index endpoint ID
        deployed_index_id: Deployed index ID
        project_id: GCP project ID
        location: GCP location
        dimension: Embedding dimension (must match index)
        num_neighbors: Number of neighbors to return

    Returns:
        List of matches with IDs and distances
    """
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    aiplatform.init(project=project_id, location=location)

    # Load image and generate embedding
    print(f"Generating embedding for: {image_path}")
    model = MultimodalEmbeddings(dimension=dimension)

    with open(image_path, 'rb') as f:
        image_bytes = f.read()

    embedding = model.generate_embedding(image_bytes)
    print(f"Embedding dimension: {len(embedding)}")

    # Query index
    print(f"Querying index endpoint: {index_endpoint_id}")
    endpoint = aiplatform.MatchingEngineIndexEndpoint(
        index_endpoint_name=f"projects/{project_id}/locations/{location}/indexEndpoints/{index_endpoint_id}"
    )

    # Find neighbors
    response = endpoint.find_neighbors(
        deployed_index_id=deployed_index_id,
        queries=[embedding],
        num_neighbors=num_neighbors
    )

    # Parse results
    results = []
    if response and len(response) > 0:
        for neighbor in response[0]:
            # Parse ID to get building_id and image_hash
            # ID format: "{building_id}_{image_hash}"
            parts = neighbor.id.split('_', 1)
            building_id = parts[0] if len(parts) > 0 else neighbor.id
            image_hash = parts[1] if len(parts) > 1 else ""

            results.append({
                'id': neighbor.id,
                'building_id': building_id,
                'image_hash': image_hash,
                'distance': neighbor.distance
            })

    return results


def main():
    parser = argparse.ArgumentParser(description="Query deployed vector search index")
    parser.add_argument("--image", required=True, help="Path to test image")
    parser.add_argument("--endpoint-id", required=True, help="Index endpoint ID")
    parser.add_argument("--deployed-index-id", required=True, help="Deployed index ID")
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument("--location", default="us-central1", help="GCP location")
    parser.add_argument("--dimension", type=int, default=512, help="Embedding dimension")
    parser.add_argument("--top-k", type=int, default=10, help="Number of results")

    args = parser.parse_args()

    # Query index
    results = query_index(
        image_path=args.image,
        index_endpoint_id=args.endpoint_id,
        deployed_index_id=args.deployed_index_id,
        project_id=args.project,
        location=args.location,
        dimension=args.dimension,
        num_neighbors=args.top_k
    )

    # Display results
    print(f"\n{'='*60}")
    print(f"TOP {len(results)} RESULTS")
    print(f"{'='*60}\n")

    # Group by building and show top match per building
    buildings_seen = set()
    unique_buildings = []

    for i, result in enumerate(results):
        building_id = result['building_id']

        # Mark if first time seeing this building
        is_new = building_id not in buildings_seen
        if is_new:
            buildings_seen.add(building_id)
            unique_buildings.append(result)

        marker = "★" if is_new else " "
        print(f"{marker} [{i+1}] Building: {building_id} | Distance: {result['distance']:.4f}")
        print(f"      ID: {result['id']}")
        print()

    print(f"{'='*60}")
    print(f"UNIQUE BUILDINGS: {len(unique_buildings)}")
    print(f"{'='*60}\n")

    for i, result in enumerate(unique_buildings):
        print(f"{i+1}. Building {result['building_id']} (distance: {result['distance']:.4f})")


if __name__ == "__main__":
    main()
