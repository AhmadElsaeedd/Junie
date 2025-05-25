import logging
from typing import Final

from fastapi import APIRouter, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from file.service import FileService
from file.utils import FileUtils

logger: Final[logging.Logger] = logging.getLogger(__name__)

files_router: Final[APIRouter] = APIRouter()

__SUCCESS_MESSAGE: Final[str] = "Successfully transcribed file."
__MESSAGE_KEY: Final[str] = "message"
__TRANSCRIPTION_KEY: Final[str] = "transcription"

@files_router.post("/transcribe_audio/", tags=["File Operations"])
async def transcribe_audio_file(audio_file: UploadFile):
    """
    Transcribes the audio file and returns the transcription.
    """
    FileUtils.assert_valid_file(file=audio_file)
    
    target_file_name: Final[str] = audio_file.filename

    try:        
        logger.info(f"File '{target_file_name}' received.")
        transcription: Final[str] = FileService.transcribe_audio_file(file=audio_file)
        
        return JSONResponse(
            content={
                __MESSAGE_KEY: __SUCCESS_MESSAGE,
                __TRANSCRIPTION_KEY: transcription,
            }, 
            status_code=200,
        )
    except Exception as e:
        logger.error(f"Error transcribing file '{target_file_name}': {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Could not transcribe file '{target_file_name}'. Error: {str(e)}",
        )
    finally:
        await audio_file.close() 