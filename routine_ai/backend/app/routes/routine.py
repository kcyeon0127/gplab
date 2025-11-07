from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ..deps import get_db
from ..models.routine_log import RoutineLog
from ..schemas.pet import PetState as PetStateSchema
from ..schemas.routine import RoutineCompleteRequest, RoutineCompleteResponse
from ..services.pet_state_service import get_or_create_pet_state
from ..services.progress_service import calculate_streak

router = APIRouter(prefix='/api/routine', tags=['routine'])

XP_REWARD = {
  'done': 10,
  'partial': 5,
  'late': 6,
  'miss': 0,
}


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
