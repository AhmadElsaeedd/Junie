import logging
from typing import Final

from openai import OpenAI
from openai.types.audio.transcription import Transcription
from settings.variables import OPENAI_API_KEY

logger: Final[logging.Logger] = logging.getLogger(__name__)

class OpenAIService:
    def __init__(self):
        self.client: Final[OpenAI] = OpenAI(api_key=OPENAI_API_KEY)

    def transcribe(self, *, file_content: bytes, filename: str) -> str:
        """
        Calls the OpenAI API to transcribe an audio file and returns the transcription.
        """
        logger.info(f"Processing file '{filename}' through OpenAI API.")
        
        transcription: Final[Transcription] = self.client.audio.transcriptions.create(
            file=(filename, file_content),
            model="whisper-1",
            language="en",
        )
        
        return transcription.text