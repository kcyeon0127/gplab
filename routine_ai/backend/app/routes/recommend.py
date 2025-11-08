from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends
from pydantic import ValidationError

from ..deps import get_ollama_client
from ..schemas.recommend import Plan, RecommendRequest, RecommendResponse
from ..services.ollama_client import OllamaClient, OllamaException

router = APIRouter(prefix='/api/recommend', tags=['recommend'])


@router.post('/generate', response_model=RecommendResponse)
async def generate_recommendations(
  payload: RecommendRequest,
  ollama: OllamaClient = Depends(get_ollama_client),
) -> RecommendResponse:
  prompt = _build_prompt(payload)
  plans: List[Plan] = []
  try:
    raw = await ollama.generate(prompt)
    parsed = OllamaClient.extract_json_block(raw)
    plans = _parse_plans(parsed)
  except (OllamaException, ValueError, ValidationError):
    plans = []

  if not plans:
    plans = _fallback_plans(payload)

  return RecommendResponse(plans=plans)


def _build_prompt(payload: RecommendRequest) -> str:
  goals = ', '.join(payload.goals) or '미설정'
  slots = ', '.join(payload.prefer_slots) or '미설정'
  return (
    '당신은 루틴 코치입니다. JSON만으로 답변하세요.'
    f'사용자 목표: {goals}'
    f'선호 시간대: {slots}'
    '각 루틴은 title, days(문자열 배열), time(HH:MM), duration_min(정수), difficulty(easy/mid/hard), reason(한글 설명)을 포함하세요.'
    '응답은 {"plans": [...]} 형식의 JSON만 포함해야 합니다.'
  )


def _parse_plans(payload: object) -> List[Plan]:
  if isinstance(payload, dict):
    payload = payload.get('plans')
  plans: List[Plan] = []
  if not isinstance(payload, list):
    return plans
  for entry in payload:
    if not isinstance(entry, dict):
      continue
    try:
      plans.append(Plan.model_validate(entry))
    except ValidationError:
      continue
  return plans


def _fallback_plans(payload: RecommendRequest) -> List[Plan]:
  slot_map = {
    'morning': '07:30',
    'noon': '12:30',
    'evening': '19:00',
    'night': '21:30',
  }
  sample_days = [
    ['월', '수', '금'],
    ['화', '목'],
    ['토', '일'],
  ]
  slot_time = slot_map.get(payload.prefer_slots[0] if payload.prefer_slots else 'morning', '07:30')
  base_goal = payload.goals[0] if payload.goals else '집중'
  suggestions = [
    Plan(title=f'{base_goal} 루틴 준비', days=sample_days[0], time=slot_time, duration_min=25, difficulty='easy', reason='부담 없이 몸과 마음을 깨우는 루틴입니다.'),
    Plan(title='집중 근력 루틴', days=sample_days[1], time='18:30', duration_min=30, difficulty='mid', reason='저녁 시간에 짧게 근력 운동을 마무리해 보세요.'),
    Plan(title='주말 리셋 스트레칭', days=sample_days[2], time='09:00', duration_min=20, difficulty='easy', reason='가볍게 몸을 풀고 주간 피로를 해소합니다.'),
  ]
  return suggestions[:3]
