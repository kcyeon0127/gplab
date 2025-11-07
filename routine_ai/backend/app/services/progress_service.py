from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.routine_log import RoutineLog


async def calculate_streak(session: AsyncSession, user_id: int, limit: int = 30) -> int:
  result = await session.execute(
    select(RoutineLog.status)
    .where(RoutineLog.user_id == user_id)
    .order_by(RoutineLog.ended_at.desc())
    .limit(limit)
  )
  streak = 0
  for status in result.scalars():
    if status == 'done':
      streak += 1
    else:
      break
  return streak
