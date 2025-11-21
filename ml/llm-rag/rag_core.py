import os
import time
import chromadb
from google import genai
from google.genai import types
from google.genai import errors
from google.auth.exceptions import DefaultCredentialsError
import threading

# Configuration (kept in sync with cli.py)
GCP_PROJECT = os.environ.get("GCP_PROJECT")
GCP_LOCATION = os.environ.get("GCP_LOCATION", "us-central1")
EMBEDDING_MODEL = os.environ.get("EMBEDDING_MODEL", "text-embedding-004")
EMBEDDING_DIMENSION = int(os.environ.get("EMBEDDING_DIMENSION", 256))
GENERATIVE_MODEL = os.environ.get("GENERATIVE_MODEL", "gemini-2.0-flash-001")
INPUT_FOLDER = os.environ.get("INPUT_FOLDER", "input-datasets")
OUTPUT_FOLDER = os.environ.get("OUTPUT_FOLDER", "outputs")
CHROMADB_HOST = os.environ.get("CHROMADB_HOST", "llm-rag-chromadb")
CHROMADB_PORT = int(os.environ.get("CHROMADB_PORT", 8000))


# Lazily initialize the LLM client to avoid failing at import time when credentials are missing
_llm_client = None
_llm_lock = threading.Lock()


def get_llm_client():
    global _llm_client
    if _llm_client is not None:
        return _llm_client

    with _llm_lock:
        if _llm_client is not None:
            return _llm_client

        try:
            client = genai.Client(vertexai=True, project=GCP_PROJECT, location=GCP_LOCATION)
        except DefaultCredentialsError as e:
            raise RuntimeError(
                "Google application default credentials not found. Set GOOGLE_APPLICATION_CREDENTIALS to a valid service account JSON file and ensure it is mounted into the container (e.g. /secrets/llm-service-account.json)."
            ) from e
        _llm_client = client
        return _llm_client


def generate_query_embedding(query: str):
    """Generate an embedding for the provided query using Vertex AI.

    Returns a list[float].
    """
    kwargs = {"output_dimensionality": EMBEDDING_DIMENSION}
    client = get_llm_client()
    response = client.models.embed_content(
        model=EMBEDDING_MODEL,
        contents=query,
        config=types.EmbedContentConfig(**kwargs),
    )
    return response.embeddings[0].values


def _connect_chromadb(host: str = CHROMADB_HOST, port: int = CHROMADB_PORT):
    # Clear shared system cache to avoid stale state
    try:
        chromadb.api.client.SharedSystemClient.clear_system_cache()
    except Exception:
        pass

    client = chromadb.HttpClient(host=host, port=port)
    return client


def retrieve_documents(query_embedding, chunk_type="char-split", top_k: int = 5):
    """Return the top_k documents and their metadatas from Chroma for a query embedding.

    Returns: dict with keys 'documents', 'metadatas', 'ids'
    """
    client = _connect_chromadb()
    collection_name = f"{chunk_type}-collection"
    try:
        collection = client.get_collection(name=collection_name)
    except Exception as e:
        raise RuntimeError(f"Could not open collection '{collection_name}': {e}")

    results = collection.query(query_embeddings=[query_embedding], n_results=top_k)
    # results format: dict with keys 'ids', 'documents', 'metadatas' each mapping to a list per query
    return results


def answer_question(question: str, chunk_type: str = "char-split", top_k: int = 5):
    """Run a minimal RAG cycle: embed question, retrieve top_k docs, call LLM with context.

    Returns a dict: {answer: str, retrieved_documents: list[str], metadatas: list}
    """
    if not question or question.strip() == "":
        raise ValueError("question must be a non-empty string")

    # 1) Embed
    query_embedding = generate_query_embedding(question)

    # 2) Retrieve
    try:
        results = retrieve_documents(query_embedding, chunk_type=chunk_type, top_k=top_k)
    except Exception as e:
        raise RuntimeError(f"Failed to retrieve from ChromaDB: {e}")

    docs = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]

    # 3) Construct prompt: question + joined docs
    joined_docs = "\n".join(docs)
    INPUT_PROMPT = f"""
{question}
{joined_docs}
"""

    # 4) Call LLM
    try:
        client = get_llm_client()
        response = client.models.generate_content(model=GENERATIVE_MODEL, contents=INPUT_PROMPT)
        generated_text = response.text
    except errors.APIError as e:
        raise RuntimeError(f"LLM generation failed: {e}")

    return {
        "answer": generated_text,
        "documents": docs,
        "metadatas": metadatas,
    }
