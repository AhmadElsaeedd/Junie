import logging
from typing import Final

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from services.files import FileService

logger: Final[logging.Logger] = logging.getLogger(__name__)

# Define the router
files_router: Final[APIRouter] = APIRouter()

@files_router.post("/upload_audio/", tags=["File Operations"])
async def upload_audio_file(audio_file: UploadFile = File(...)):
    """
    TODO: Add docstring
    """
    if not audio_file or not audio_file.filename:
        raise HTTPException(status_code=400, detail="No file or filename was uploaded.")

    try:        
        logger.info(f"File '{audio_file.filename}' received.")
        FileService.create_audio_file(file=audio_file)
        
        return JSONResponse(status_code=200)
    except Exception as e:
        logger.error(f"Error saving file '{audio_file.filename}': {e}")
        raise HTTPException(status_code=500, detail=f"Could not save file '{audio_file.filename}'. Error: {str(e)}")
    finally:
        await audio_file.close() 