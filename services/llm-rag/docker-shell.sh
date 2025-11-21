#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

# Set vairables
export BASE_DIR=$(pwd)
export PERSISTENT_DIR=$(pwd)/../persistent-folder/
export SECRETS_DIR=$(pwd)/../../secrets/
export GCP_PROJECT="ac215-historicam"
export GOOGLE_APPLICATION_CREDENTIALS="/secrets/gcs-service-account.json"
export IMAGE_NAME="llm-rag-cli"


# Create the network if we don't have it yet
docker network inspect llm-rag-network >/dev/null 2>&1 || docker network create llm-rag-network

# Build the image based on the Dockerfile
docker build -t $IMAGE_NAME -f Dockerfile .

# Start all containers in detached mode
echo "Starting ChromaDB and LLM-RAG services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Check if embeddings need to be loaded
echo "Checking if embeddings are already loaded..."
CONTAINER_NAME="llm-rag-cli"
COLLECTION_COUNT=$(docker exec $CONTAINER_NAME /bin/bash -c "source /.venv/bin/activate && python -c \"import chromadb; client = chromadb.HttpClient(host='llm-rag-chromadb', port=8000); print(len(client.list_collections()))\" 2>/dev/null" || echo "0")

if [ "$COLLECTION_COUNT" -eq "0" ]; then
    echo "No embeddings found. Loading embeddings into ChromaDB..."
    docker exec $CONTAINER_NAME /bin/bash -c "source /.venv/bin/activate && python cli.py --chunk --embed --load --chunk_type recursive-split"
    echo "Embeddings loaded successfully!"
else
    echo "Embeddings already loaded. Skipping..."
fi

echo ""
echo "========================================="
echo "LLM-RAG services are running!"
echo "========================================="
echo "LLM-RAG API: http://localhost:8001"
echo "ChromaDB: http://localhost:8002"
echo ""
echo "Test with:"
echo "curl -X POST http://localhost:8001/chat -H 'Content-Type: application/json' -d '{\"question\":\"When was Memorial Hall built?\"}'"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
echo "========================================="