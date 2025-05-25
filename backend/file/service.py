import logging
from typing import Final

from fastapi import UploadFile
from open_ai.service import OpenAIService

logger: Final[logging.Logger] = logging.getLogger(__name__)

class FileService:
    
    @staticmethod
    def transcribe_audio_file(*, file: UploadFile) -> str:
        """
        Transcribes an audio file using the openai service and returns the transcription.
        """
        logger.info(f"Transcribing file '{file.filename}' with type '{file.content_type}'.")
        
        file_content: Final[bytes] = file.file.read()
        
        transcription: Final[str] = OpenAIService().transcribe(
            file_content=file_content, 
            filename=file.filename,
        )
        
        logger.info(f"Transcription result: {transcription}")
        
        return transcription