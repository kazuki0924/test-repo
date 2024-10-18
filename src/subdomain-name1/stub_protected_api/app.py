"""Stub Intra API."""

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root() -> dict:
    """
    Root path endpoint.

    Returns:
        dict: Status OK.
    """
    return {"status": "OK"}


@app.get("/health")
async def health() -> dict:
    """
    Health check endpoint.

    Returns:
        dict: Status OK.
    """
    return {"status": "OK"}


@app.get("/dummy_endpoint")
async def dummy_endpoint() -> dict:
    """
    Return a dummy message.

    Returns:
        dict: Dummy message.
    """
    return {"message": "hoge"}
