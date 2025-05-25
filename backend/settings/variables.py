import os
from typing import Final

from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY: Final[str] = os.getenv("OPENAI_API_KEY")