import logging
from typing import Final

from fastapi import APIRouter, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from services.files import FileService

logger: Final[logging.Logger] = logging.getLogger(__name__)

# Define the router
files_router: Final[APIRouter] = APIRouter()

@files_router.post("/upload_audio/", tags=["File Operations"])
async def upload_audio_file(audio_file: UploadFile):
    """
    TODO: Add docstring
    """
    target_file_name: Final[str | None] = audio_file.filename
    
    if not audio_file or target_file_name is None:
        raise HTTPException(status_code=400, detail="No file or filename was uploaded.")

    try:        
        logger.info(f"File '{target_file_name}' received.")
        FileService.create_audio_file(file=audio_file)
        
        return JSONResponse(
            content={"message": f"File '{target_file_name}' successfully uploaded."}, 
            status_code=200,
        )
    except Exception as e:
        logger.error(f"Error saving file '{target_file_name}': {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Could not save file '{target_file_name}'. Error: {str(e)}",
        )
    finally:
        await audio_file.close() 