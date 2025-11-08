from fastapi import APIRouter, Depends

from ..deps import get_ollama_client
from ..schemas.coach import CoachChatRequest, CoachChatResponse
from ..services.ollama_client import OllamaClient, OllamaException

router = APIRouter(prefix='/api/coach', tags=['coach'])


@router.post('/chat', response_model=CoachChatResponse)
async def coach_chat(
  payload: CoachChatRequest,
  ollama: OllamaClient = Depends(get_ollama_client),
) -> CoachChatResponse:
  prompt = (
    '당신은 건강 루틴 코치입니다. 사용자 메시지를 3문장 이내로 공감하며 답하세요.'
    f"사용자 메시지: {payload.message}"
  )
  try:
    reply = await ollama.generate(prompt)
  except OllamaException:
    reply = '서버 연결에 문제가 있어요. 그래도 꾸준히 기록하면 좋은 루틴을 만들 수 있어요!'
  return CoachChatResponse(reply=reply)
