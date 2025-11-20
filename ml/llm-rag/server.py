import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import rag_core


app = FastAPI(title="llm-rag API")

# Configure CORS: allow a set of sensible dev origins by default, but allow
# overriding via the ALLOWED_ORIGINS environment variable (comma-separated).
allowed = os.environ.get("ALLOWED_ORIGINS")
if allowed:
    # Parse comma-separated list and strip whitespace
    origins = [o.strip() for o in allowed.split(",") if o.strip()]
else:
    # sensible development defaults (common front-end dev ports)
    origins = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:8001",
        "http://127.0.0.1:8001",
    ]

# Apply CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    question: str
    chunk_type: str = "char-split"
    top_k: int = 5
    return_docs: bool = False


@app.post("/chat")
def chat(req: ChatRequest):
    if not req.question or req.question.strip() == "":
        raise HTTPException(status_code=400, detail="question is required")

    try:
        result = rag_core.answer_question(req.question, chunk_type=req.chunk_type, top_k=req.top_k)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except RuntimeError as re:
        raise HTTPException(status_code=503, detail=str(re))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"internal error: {e}")

    response = {"answer": result.get("answer")}
    if req.return_docs:
        response["documents"] = result.get("documents")
        response["metadatas"] = result.get("metadatas")

    return response


if __name__ == "__main__":
    # Run with: python server.py
    uvicorn.run(app, host="0.0.0.0", port=8000)
