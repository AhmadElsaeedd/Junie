import logging
from typing import Final

import fastapi
import uvicorn
from file.routes import files_router

logging.basicConfig(level=logging.INFO)

app: Final[fastapi.FastAPI] = fastapi.FastAPI(
    title="Junie Backend API",
    description="API for Junie voice agent tasks.",
    version="0.1.0"
)

app.include_router(files_router, prefix="/files", tags=["File Operations"]) 

@app.get("/", tags=["General"])
async def read_root():
    return {"message": "Welcome to the Junie Backend! Visit /docs for API documentation."}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
