from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..deps import get_db
from ..models.routine import Routine
from ..models.routine_log import RoutineLog
from ..schemas.pet import PetState as PetStateSchema
from ..schemas.routine import (
  RoutineCompleteRequest,
  RoutineCompleteResponse,
  RoutineCreate,
  RoutineRead,
  RoutineUpdate,
)
from ..services.pet_state_service import get_or_create_pet_state
from ..services.progress_service import calculate_streak

router = APIRouter(prefix='/api/routine', tags=['routine'])

XP_REWARD = {
  'done': 10,
  'partial': 5,
  'late': 6,
  'miss': 0,
}


@router.get('', response_model=list[RoutineRead])
async def list_routines(
  user_id: int = Query(default=1, ge=1),
  session: AsyncSession = Depends(get_db),
) -> list[RoutineRead]:
  result = await session.execute(
    select(Routine).where(Routine.user_id == user_id).order_by(Routine.id)
  )
  return [_to_schema(record) for record in result.scalars().all()]


@router.post('', response_model=RoutineRead, status_code=status.HTTP_201_CREATED)
async def create_routine(
  payload: RoutineCreate,
  session: AsyncSession = Depends(get_db),
) -> RoutineRead:
  record = Routine(
    user_id=payload.user_id,
    title=payload.title,
    time=payload.time,
    days=_dump_days(payload.days),
    difficulty=payload.difficulty,
    active=payload.active,
    icon_key=payload.icon_key,
  )
  session.add(record)
  await session.commit()
  await session.refresh(record)
  return _to_schema(record)


@router.put('/{routine_id}', response_model=RoutineRead)
async def update_routine(
  payload: RoutineUpdate,
  routine_id: int = Path(..., ge=1),
  session: AsyncSession = Depends(get_db),
) -> RoutineRead:
  record = await session.get(Routine, routine_id)
  if record is None:
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Routine not found')
  if payload.title is not None:
    record.title = payload.title
  if payload.time is not None:
    record.time = payload.time
  if payload.days is not None:
    record.days = _dump_days(payload.days)
  if payload.difficulty is not None:
    record.difficulty = payload.difficulty
  if payload.active is not None:
    record.active = payload.active
  if payload.icon_key is not None:
    record.icon_key = payload.icon_key
  await session.commit()
  await session.refresh(record)
  return _to_schema(record)


@router.delete('/{routine_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_routine(
  routine_id: int = Path(..., ge=1),
  session: AsyncSession = Depends(get_db),
) -> Response:
  record = await session.get(Routine, routine_id)
  if record is None:
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Routine not found')
  await session.delete(record)
  await session.commit()
  return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post('/complete', response_model=RoutineCompleteResponse)
async def complete_routine(
  payload: RoutineCompleteRequest,
  session: AsyncSession = Depends(get_db),
) -> RoutineCompleteResponse:
  pet = await get_or_create_pet_state(session, payload.user_id)
  xp_gain = XP_REWARD.get(payload.status, 0)
  pet.xp += xp_gain
  leveled_up = False
  while pet.xp >= pet.next_level_threshold:
    pet.xp -= pet.next_level_threshold
    pet.level += 1
    pet.next_level_threshold += 50
    leveled_up = True

  log = RoutineLog(
    user_id=payload.user_id,
    routine_id=payload.routine_id,
    status=payload.status,
    started_at=payload.started_at,
    ended_at=payload.ended_at,
    note=payload.note,
  )
  session.add(log)
  await session.flush()

  streak = await calculate_streak(session, payload.user_id)
  await session.commit()

  hint = _coach_hint(payload.status, xp_gain, leveled_up)
  return RoutineCompleteResponse(
    pet_state=PetStateSchema.model_validate(pet),
    streak=streak,
    coach_hint=hint,
  )


def _coach_hint(status_value: str, xp_gain: int, leveled_up: bool) -> str:
  if leveled_up:
    return '레벨이 상승했어요! 새로운 보상을 준비 중입니다.'
  if status_value == 'miss':
    return '이번에는 놓쳤지만 다시 시작하면 됩니다.'
  if xp_gain >= 10:
    return '완벽해요! 지금 리듬을 그대로 이어가요.'
  return '조금 더 힘내면 금방 목표에 도달할 수 있어요.'


def _to_schema(record: Routine) -> RoutineRead:
  return RoutineRead(
    id=record.id,
    user_id=record.user_id,
    title=record.title,
    time=record.time,
    days=_load_days(record.days),
    difficulty=record.difficulty,
    active=record.active,
    icon_key=record.icon_key,
  )


def _dump_days(days: list[str]) -> str:
  return json.dumps(days, ensure_ascii=False)


def _load_days(raw: str) -> list[str]:
  try:
    data = json.loads(raw)
    if isinstance(data, list):
      return [str(item) for item in data]
  except json.JSONDecodeError:
    pass
  return [part.strip() for part in raw.split(',') if part.strip()]
