from fastapi import Depends, Header, HTTPException, status
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


def require_admin_token(authorization: str = Header(...)) -> None:
  if not authorization.startswith('Bearer '):
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Missing bearer token')
  token = authorization.split(' ', 1)[1]
  if token != settings.admin_token:
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Invalid ADMIN_TOKEN')
