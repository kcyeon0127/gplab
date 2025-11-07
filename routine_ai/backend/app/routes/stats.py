from __future__ import annotations

import json
from datetime import date, datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..deps import get_db
from ..models.routine_log import RoutineLog
from ..models.stats_cache import StatsCache
from ..schemas.stats import StatsWeeklyResponse
from ..services.progress_service import calculate_streak

router = APIRouter(prefix='/api/stats', tags=['stats'])


@router.get('/weekly', response_model=StatsWeeklyResponse)
async def get_weekly_stats(
  user_id: int = Query(default=1, ge=1),
  session: AsyncSession = Depends(get_db),
) -> StatsWeeklyResponse:
  week_start = _current_week_start()
  cached = await _load_cache(session, user_id, week_start)
  if cached:
    return cached

  stats = await _build_stats(session, user_id, week_start)
  return stats


async def _load_cache(session: AsyncSession, user_id: int, week_start: date) -> StatsWeeklyResponse | None:
  result = await session.execute(
    select(StatsCache).where(
      StatsCache.user_id == user_id,
      StatsCache.week_start == week_start.isoformat(),
    )
  )
  record = result.scalars().first()
  if record is None:
    return None

  insights_payload = _safe_json(record.insights_json)
  tips_payload = _safe_json(record.tips_json)
  insights = insights_payload.get('insights') if isinstance(insights_payload, dict) else insights_payload
  best_slots = insights_payload.get('best_slots') if isinstance(insights_payload, dict) else []
  return StatsWeeklyResponse(
    completion_rate=record.completion_rate,
    streak=record.streak,
    best_slots=_ensure_str_list(best_slots),
    insights=_ensure_str_list(insights),
    tips=_ensure_str_list(tips_payload),
  )


async def _build_stats(session: AsyncSession, user_id: int, week_start: date) -> StatsWeeklyResponse:
  logs = await _weekly_logs(session, user_id, week_start)
  total = len(logs)
  done = sum(1 for log in logs if log.status == 'done')
  half = sum(1 for log in logs if log.status in {'partial', 'late'}) * 0.5
  completion = (done + half) / total if total else 0.0
  streak = await calculate_streak(session, user_id)
  best_slots = _best_slots(logs)
  insights = _build_insights(completion, done)
  tips = _build_tips(best_slots)

  record = StatsCache(
    user_id=user_id,
    week_start=week_start.isoformat(),
    completion_rate=completion,
    streak=streak,
    insights_json=json.dumps({'insights': insights, 'best_slots': best_slots}, ensure_ascii=False),
    tips_json=json.dumps(tips, ensure_ascii=False),
  )
  session.add(record)
  await session.commit()

  return StatsWeeklyResponse(
    completion_rate=completion,
    streak=streak,
    best_slots=best_slots,
    insights=insights,
    tips=tips,
  )


async def _weekly_logs(session: AsyncSession, user_id: int, week_start: date) -> List[RoutineLog]:
  week_end = week_start + timedelta(days=7)
  result = await session.execute(select(RoutineLog).where(RoutineLog.user_id == user_id))
  logs: List[RoutineLog] = []
  for log in result.scalars():
    try:
      started = datetime.fromisoformat(log.started_at)
    except ValueError:
      continue
    if week_start <= started.date() < week_end:
      logs.append(log)
  return logs


def _best_slots(logs: List[RoutineLog]) -> List[str]:
  buckets: dict[str, int] = {}
  for log in logs:
    if log.status != 'done':
      continue
    try:
      started = datetime.fromisoformat(log.started_at)
    except ValueError:
      continue
    label = _slot_label(started)
    buckets[label] = buckets.get(label, 0) + 1
  sorted_labels = sorted(buckets.items(), key=lambda item: item[1], reverse=True)
  return [label for label, _ in sorted_labels][:3]


def _slot_label(value: datetime) -> str:
  hour = value.hour
  if 5 <= hour < 11:
    return '아침'
  if 11 <= hour < 14:
    return '점심'
  if 14 <= hour < 18:
    return '오후'
  if 18 <= hour < 22:
    return '저녁'
  return '밤'


def _build_insights(completion: float, done_count: int) -> List[str]:
  insights = []
  percentage = completion * 100
  if percentage >= 70:
    insights.append('이번 주에도 70% 이상을 실행했어요. 좋은 페이스를 유지해 보세요!')
  else:
    insights.append('완료율이 70% 미만입니다. 루틴 난이도나 시간을 조정해 보세요.')
  insights.append(f'완료한 루틴 수: {done_count}회')
  return insights


def _build_tips(best_slots: List[str]) -> List[str]:
  tips = ['루틴 실행 직후 2분 복기로 배운 점을 적어보세요.']
  if best_slots:
    tips.append(f'{best_slots[0]} 시간대에 성공률이 높아요. 해당 시간에 핵심 루틴을 배치해 보세요.')
  tips.append('일정에 과감히 휴식일을 넣으면 꾸준함이 더 쉬워집니다.')
  return tips


def _safe_json(raw: str | None):
  if not raw:
    return []
  try:
    return json.loads(raw)
  except json.JSONDecodeError:
    return []


def _ensure_str_list(value: object) -> List[str]:
  if isinstance(value, list):
    return [str(item) for item in value]
  return []


def _current_week_start() -> date:
  today = date.today()
  return today - timedelta(days=today.weekday())
