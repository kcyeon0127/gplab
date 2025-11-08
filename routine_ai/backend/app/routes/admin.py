from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..deps import get_db
from ..models.routine import Routine
from ..models.routine_log import RoutineLog
from ..schemas.pet import PetState as PetStateSchema, PetStatePatch
from ..schemas.routine import (
  RoutineCreate,
  RoutineLogRead,
  RoutineRead,
  RoutineUpdate,
)
from ..services.pet_state_service import get_or_create_pet_state

router = APIRouter(prefix='/admin', tags=['admin'])


@router.get('/routines', response_model=list[RoutineRead])
async def list_routines(
  user_id: int = Query(default=1, ge=1),
  session: AsyncSession = Depends(get_db),
) -> list[RoutineRead]:
  result = await session.execute(select(Routine).where(Routine.user_id == user_id).order_by(Routine.id))
  records = result.scalars().all()
  return [_routine_to_schema(record) for record in records]


@router.post('/routines', response_model=RoutineRead, status_code=status.HTTP_201_CREATED)
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
  return _routine_to_schema(record)


@router.put('/routines/{routine_id}', response_model=RoutineRead)
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
  return _routine_to_schema(record)


@router.delete('/routines/{routine_id}', status_code=status.HTTP_204_NO_CONTENT)
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


@router.patch('/pet_state', response_model=PetStateSchema)
async def patch_pet_state(
  payload: PetStatePatch,
  session: AsyncSession = Depends(get_db),
) -> PetStateSchema:
  pet = await get_or_create_pet_state(session, payload.user_id)
  if payload.level is not None:
    pet.level = payload.level
  if payload.xp is not None:
    pet.xp = payload.xp
  if payload.next_level_threshold is not None:
    pet.next_level_threshold = payload.next_level_threshold
  await session.commit()
  await session.refresh(pet)
  return PetStateSchema.model_validate(pet)


@router.get('/logs', response_model=list[RoutineLogRead])
async def list_logs(
  limit: int = Query(default=100, ge=1, le=500),
  session: AsyncSession = Depends(get_db),
) -> list[RoutineLogRead]:
  result = await session.execute(
    select(RoutineLog)
    .order_by(RoutineLog.id.desc())
    .limit(limit)
  )
  return [RoutineLogRead.model_validate(log) for log in result.scalars().all()]


def _routine_to_schema(record: Routine) -> RoutineRead:
  days = _load_days(record.days)
  return RoutineRead(
    id=record.id,
    user_id=record.user_id,
    title=record.title,
    time=record.time,
    days=days,
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
