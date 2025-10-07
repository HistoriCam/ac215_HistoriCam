"""
HistoriCam API Service
"""
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="HistoriCam API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "HistoriCam API"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/identify")
async def identify_landmark(
    image: UploadFile = File(...),
    latitude: float = 0.0,
    longitude: float = 0.0
):
    """Identify landmark from image and location"""
    # TODO: Implement landmark identification
    return {
        "landmark": "Sample Building",
        "confidence": 0.95,
        "facts": ["Built in 1890", "Famous for..."]
    }
