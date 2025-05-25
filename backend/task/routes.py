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
__RUN_ID_KEY: Final[str] = "run_id"

@tasks_router.post("/create/", tags=["Task Operations"])
async def create_task(audio_file: UploadFile):
    """
    Transcribes the audio file and creates a browser-use run using the transcription.
    """
    FileUtils.assert_valid_file(file=audio_file)
    
    target_file_name: Final[str] = audio_file.filename

    try:        
        logger.info(f"Creating task for file '{target_file_name}'.")
        
        transcription: Final[str] = FileService.transcribe_audio_file(file=audio_file)
        
        run_id: Final[str] = BrowserUseService.create_run(instructions=transcription)
        
        # TODO: Get the live URL from the run id and return it to the caller.
        
        return JSONResponse(
            content={
                __MESSAGE_KEY: __SUCCESS_MESSAGE,
                __RUN_ID_KEY: run_id,
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