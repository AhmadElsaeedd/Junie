import asyncio
import logging
from typing import Final

from browser_use.dataclasses.task_details import TaskDetails
from browser_use.service import BrowserUseService
from fastapi import WebSocket, WebSocketDisconnect

logger: Final[logging.Logger] = logging.getLogger(__name__)


class TaskService:
    __ACTIVE_CONNECTIONS: Final[dict[str, WebSocket]] = {}
    __LIVE_URL_KEY: Final[str] = "live_url"
    __MONITORING_TASK_PREFIX: Final[str] = "monitoring_task_"
    
    @staticmethod
    def create_background_monitoring_task(*, task_id: str) -> None:
        """
        Creates a background task to check for the live url of the task.
        """
        task: asyncio.Task = asyncio.create_task(
            coro=TaskService.check_task_status(task_id=task_id),
            name=f"{TaskService.__MONITORING_TASK_PREFIX}{task_id}",
        )
        task.add_done_callback(
            callback=lambda _: logger.info(f"Background task {task.get_name()} for task {task_id} completed."),
        )
        logger.info(f"Created background task {task.get_name()} for task {task_id}.")
    
    @staticmethod
    async def maintain_task_websocket(*, websocket: WebSocket, task_id: str) -> None:
        """
        Accepts the websocket connection and adds it to the active connections dictionary.
        """
        await websocket.accept()
        TaskService.__ACTIVE_CONNECTIONS[task_id] = websocket
        logger.info(f"Added websocket connection for task {task_id}.")
        
        try:
            while True:
                # Keep the connection alive
                await websocket.receive_text()
        except WebSocketDisconnect:
            TaskService.__ACTIVE_CONNECTIONS.pop(task_id, None)
            
    @staticmethod
    async def check_task_status(*, task_id: str) -> None:
        """
        Periodically check task status until `live_url` is available
        """
        while True:
            try:
                task_details: TaskDetails = BrowserUseService.get_task_details(task_id=task_id)
                
                if task_details.live_url is not None:
                    logger.info(f"Live url found for task {task_id}. Notifying subscriber.")
                    await TaskService._notify_task_update(
                        task_id=task_id,
                        live_url=task_details.live_url,
                    )
                    break
            except Exception as e:
                logger.error(f"Error checking task status: {e}")
                break
            await asyncio.sleep(1.5)
            
    @staticmethod
    async def _notify_task_update(*, task_id: str, live_url: str) -> None:
        """
        Notify the subscriber of the task status update when the live url is available.
        """
        target_websocket: WebSocket | None = TaskService.__ACTIVE_CONNECTIONS.get(task_id)
        if target_websocket is None:
            logger.warning(f"No active connection found for task {task_id}.")
            return
        
        logger.info(f"Notifying task {task_id} with live url {live_url}.")
        
        await target_websocket.send_json(
            {
                TaskService.__LIVE_URL_KEY: live_url,
            },
        )
        await target_websocket.close()
        TaskService.__ACTIVE_CONNECTIONS.pop(task_id, None)