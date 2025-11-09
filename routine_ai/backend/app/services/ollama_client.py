from __future__ import annotations

import json
import re
from typing import Any

import httpx


class OllamaException(RuntimeError):
  """Raised when Ollama interaction fails."""


class OllamaClient:
  """간단한 Ollama HTTP 클라이언트."""

  def __init__(self, base_url: str, model: str, timeout_seconds: float = 15.0) -> None:
    self._base_url = base_url.rstrip('/')
    self._model = model
    self._timeout = httpx.Timeout(timeout_seconds, read=timeout_seconds, connect=10.0)

  async def generate(self, prompt: str) -> str:
    payload = {'model': self._model, 'prompt': prompt, 'stream': False}
    try:
      async with httpx.AsyncClient(timeout=self._timeout) as client:
        response = await client.post(f'{self._base_url}/api/generate', json=payload)
      response.raise_for_status()
    except httpx.HTTPError as error:
      raise OllamaException(f'Ollama 요청 실패: {error}') from error

    data = response.json()
    text = data.get('response')
    if not isinstance(text, str) or not text.strip():
      raise OllamaException('Ollama 응답에 텍스트가 없습니다.')
    return text.strip()

  @staticmethod
  def extract_json_block(text: str) -> Any:
    """코드펜스로 둘러싸인 JSON 문자열을 파싱한다."""

    cleaned = text.strip()
    if cleaned.startswith('```'):
      cleaned = '\n'.join(
        line for line in cleaned.splitlines() if not line.strip().startswith('```')
      ).strip()

    match = re.search(r'\{.*\}', cleaned, re.DOTALL)
    if match:
      cleaned = match.group(0)

    try:
      return json.loads(cleaned)
    except json.JSONDecodeError as error:
      raise OllamaException(f'JSON 파싱 실패: {error}') from error
