"""
HistoriCam API - Building identification service
"""
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from .vision_service import VisionService

# Initialize FastAPI app
app = FastAPI(
    title="HistoriCam API",
    description="Identify Harvard buildings from images",
    version="1.0.0"
)

# CORS middleware for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize vision service
vision_service = VisionService()


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "HistoriCam API",
        "version": "1.0.0"
    }


@app.post("/identify")
async def identify_building(image: UploadFile = File(...)):
    """
    Identify a building from an uploaded image.

    Args:
        image: Uploaded image file (JPEG, PNG)

    Returns:
        Building identification result with confidence score
    """
    # Validate file type
    if not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type: {image.content_type}. Must be an image."
        )

    # Read image bytes
    image_bytes = await image.read()

    # Identify building
    result = await vision_service.identify_building(image_bytes)

    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
