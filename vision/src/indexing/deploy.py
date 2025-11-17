"""
Deploy Vertex AI Vector Search index from embeddings JSONL.
"""
import argparse
from typing import Optional
from google.cloud import aiplatform


def deploy_vector_search_index(
    embeddings_gcs_path: str,
    index_name: str,
    dimensions: int,
    project_id: str,
    location: str = "us-central1",
    endpoint_name: Optional[str] = None,
    distance_measure: str = "DOT_PRODUCT_DISTANCE",
):
    """
    Create and deploy a Vertex AI Vector Search index.

    Args:
        embeddings_gcs_path: Full GCS path to embeddings JSONL (gs://bucket/path/to/embeddings.jsonl)
        index_name: Display name for the index
        dimensions: Embedding dimension
        project_id: GCP project ID
        location: GCP location
        endpoint_name: Optional endpoint name (creates new if not specified)
        distance_measure: Distance measure (DOT_PRODUCT_DISTANCE, COSINE_DISTANCE, etc.)
    """
    # Initialize Vertex AI
    aiplatform.init(project=project_id, location=location)

    print(f"Creating Vector Search index: {index_name}")
    print(f"  Embeddings: {embeddings_gcs_path}")
    print(f"  Dimensions: {dimensions}")
    print(f"  Distance: {distance_measure}")

    # Create index with algorithm config (optimized for ~300 images)
    index = aiplatform.MatchingEngineIndex.create_tree_ah_index(
        display_name=index_name,
        contents_delta_uri=embeddings_gcs_path,
        dimensions=dimensions,
        approximate_neighbors_count=10,
        distance_measure_type=distance_measure,
        leaf_node_embedding_count=100,  # ~100 embeddings per leaf (creates ~3 nodes for 300 images)
        leaf_nodes_to_search_percent=20,  # Search 20% of nodes (good accuracy for small dataset)
        description=f"HistoriCam building embeddings ({dimensions}D)",
    )

    print(f"✓ Index created: {index.resource_name}")
    print(f"  Index ID: {index.name}")

    # Create or use existing endpoint
    if endpoint_name is None:
        endpoint_name = f"{index_name}-endpoint"

    print(f"\nCreating endpoint: {endpoint_name}")
    endpoint = aiplatform.MatchingEngineIndexEndpoint.create(
        display_name=endpoint_name,
        description=f"Endpoint for {index_name}",
        public_endpoint_enabled=True,
    )

    print(f"✓ Endpoint created: {endpoint.resource_name}")
    print(f"  Endpoint ID: {endpoint.name}")

    # Deploy index to endpoint
    print(f"\nDeploying index to endpoint (this may take 15-30 minutes)...")
    deployed_index_id = f"{index_name.replace('-', '_')}_deployed"

    endpoint.deploy_index(
        index=index,
        deployed_index_id=deployed_index_id,
        min_replica_count=1,
        max_replica_count=1,
    )

    print(f"\n✓ Index deployed successfully!")
    print(f"  Deployed Index ID: {deployed_index_id}")
    print(f"  Endpoint Resource Name: {endpoint.resource_name}")
    print(f"\nSave these for querying:")
    print(f"  ENDPOINT_ID={endpoint.name}")
    print(f"  DEPLOYED_INDEX_ID={deployed_index_id}")

    return {
        "index": index,
        "endpoint": endpoint,
        "deployed_index_id": deployed_index_id,
    }


def main():
    parser = argparse.ArgumentParser(description="Deploy Vertex AI Vector Search index")
    parser.add_argument(
        "--embeddings-path",
        required=True,
        help="GCS path to embeddings JSONL (gs://bucket/path/embeddings.jsonl)"
    )
    parser.add_argument("--index-name", required=True, help="Display name for the index")
    parser.add_argument("--dimensions", type=int, required=True, help="Embedding dimensions")
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument("--location", default="us-central1", help="GCP location (default: us-central1)")
    parser.add_argument("--endpoint-name", help="Optional endpoint name (creates new if not specified)")
    parser.add_argument(
        "--distance",
        default="DOT_PRODUCT_DISTANCE",
        choices=["DOT_PRODUCT_DISTANCE", "COSINE_DISTANCE", "EUCLIDEAN_DISTANCE"],
        help="Distance measure (default: DOT_PRODUCT_DISTANCE for cosine similarity)"
    )

    args = parser.parse_args()

    deploy_vector_search_index(
        embeddings_gcs_path=args.embeddings_path,
        index_name=args.index_name,
        dimensions=args.dimensions,
        project_id=args.project,
        location=args.location,
        endpoint_name=args.endpoint_name,
        distance_measure=args.distance,
    )


if __name__ == "__main__":
    main()
