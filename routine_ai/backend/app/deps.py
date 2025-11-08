from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings
from .db import get_session as _get_session
from .services.ollama_client import OllamaClient

_ollama_client = OllamaClient(settings.ollama_url, settings.ollama_model)


async def get_db() -> AsyncSession:
  async for session in _get_session():
    yield session


def get_ollama_client() -> OllamaClient:
  return _ollama_client
