import logging
from typing import Final

from browser_use.service import BrowserUseService
from fastapi import APIRouter, HTTPException, UploadFile
from fastapi.responses import JSONResponse
from file.service import FileService
from file.utils import FileUtils

logger: Final[logging.Logger] = logging.getLogger(__name__)

tasks_router: Final[APIRouter] = APIRouter()

__SUCCESS_MESSAGE: Final[str] = "Successfully started task."
__MESSAGE_KEY: Final[str] = "message"
__TASK_ID_KEY: Final[str] = "task_id"

@tasks_router.post("/create/", tags=["Task Operations"])
async def create_task(audio_file: UploadFile):
    """
    Transcribes the audio file and creates a browser-use run using the transcription.
    """
    FileUtils.assert_valid_file(file=audio_file)
    
    try:        
        logger.info(f"Creating task for file '{audio_file.filename}'.")
        
        transcription: Final[str] = FileService.transcribe_audio_file(file=audio_file)
        
        task_id: Final[str] = BrowserUseService.create_task(instructions=transcription)
        
        return JSONResponse(
            content={
                __MESSAGE_KEY: __SUCCESS_MESSAGE,
                __TASK_ID_KEY: task_id,
            }, 
            status_code=200,
        )
    except Exception as e:
        logger.error(f"Error starting task: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Could not start task. Error: {str(e)}",
        )
    finally:
        await audio_file.close() 