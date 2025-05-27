import logging
from typing import Final

import requests
from browser_use.dataclasses.create_run_response import CreateRunResponse
from browser_use.dataclasses.task_details import TaskDetails
from settings.variables import BROWSER_USE_API_KEY

logger: Final[logging.Logger] = logging.getLogger(__name__)

class BrowserUseService:
    """
    Service class that interacts with the browser-use API at https://docs.browser-use.com/cloud.
    """
    
    __BASE_URL: Final[str] = "https://api.browser-use.com/api/v1"
    __HEADERS: Final[dict[str, str]] = {'Authorization': f'Bearer {BROWSER_USE_API_KEY}'}
    
    @staticmethod
    def create_task(*, instructions: str) -> str:
        """
        Creates a new browser-use run. Returns the id of the run used to get the status of the run and the live url to watch it.
        """
        logger.info(f"Creating run with instructions: {instructions}")
        
        create_run_url: Final[str] = f'{BrowserUseService.__BASE_URL}/run-task'
        
        logger.info(f"Sending request to: {create_run_url}")
        
        response: Final[requests.Response] = requests.post(
            url=create_run_url, 
            headers=BrowserUseService.__HEADERS, 
            json={
                # TODO: Don't use string literals.
                "task": instructions,
                "llm_model": "gemini-2.0-flash",
                "highlight_elements": False,
            }
        )
        
        if response.status_code != 200:
            # TODO: Will need to log something about the user, etc. in the future.
            raise Exception("Failed to create run.")
        
        create_run_response: Final[CreateRunResponse] = CreateRunResponse(**response.json())
        
        return create_run_response.id
    
    @staticmethod
    def get_task_details(*, task_id: str) -> TaskDetails:
        """
        Gets the entire details of a run and serializes them into a pydantic model.
        """
        response: Final[requests.Response] = requests.get(f'{BrowserUseService.__BASE_URL}/task/{task_id}', headers=BrowserUseService.__HEADERS)
        
        if response.status_code != 200:
            raise Exception("Failed to get task details.")
        
        return TaskDetails(**response.json())
        