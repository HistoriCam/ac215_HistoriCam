import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import rag_core


app = FastAPI(title="llm-rag API")

# Configure CORS: allow all origins in development
# For production, set ALLOWED_ORIGINS environment variable with specific origins
allowed = os.environ.get("ALLOWED_ORIGINS")
if allowed:
    # Parse comma-separated list and strip whitespace
    origins = [o.strip() for o in allowed.split(",") if o.strip()]
else:
    # Allow all origins for development
    origins = ["*"]

# Apply CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,  # Must be False when allow_origins is ["*"]
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
