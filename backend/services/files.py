import logging
from typing import Final

from fastapi import UploadFile

logger: Final[logging.Logger] = logging.getLogger(__name__)

class FileService:
    
    @staticmethod
    def create_audio_file(*, file: UploadFile) -> bool:
        """
        TODO: Add docstring
        """
        logger.info(f"Processing file '{file.filename}'.")
        
        return True