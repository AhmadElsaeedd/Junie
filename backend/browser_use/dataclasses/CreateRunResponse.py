from pydantic import BaseModel


class CreateRunResponse(BaseModel):
    id: str
