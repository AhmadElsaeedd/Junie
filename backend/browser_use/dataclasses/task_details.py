from datetime import datetime
from enum import Enum

from pydantic import BaseModel


class TaskStatus(str, Enum):
    CREATED = "created"
    RUNNING = "running"
    FINISHED = "finished"
    STOPPED = "stopped"
    PAUSED = "paused"
    FAILED = "failed"


class Step(BaseModel):
    id: str
    step: int
    evaluation_previous_goal: str
    next_goal: str
    url: str


class Cookie(BaseModel):
    name: str
    value: str
    domain: str
    path: str
    expires: float  # Or int, depending on the exact format, using float for now as in example
    httpOnly: bool
    secure: bool
    sameSite: str | None = None


class BrowserData(BaseModel):
    cookies: list[Cookie]


class TaskDetails(BaseModel):
    id: str
    task: str
    output: str | None = None
    status: TaskStatus
    created_at: datetime
    finished_at: datetime | None = None
    live_url: str | None = None
    steps: list[Step]
    browser_data: BrowserData | None = None
