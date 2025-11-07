from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..schemas.pet import PetState as PetStateSchema
from ..services.pet_state_service import get_or_create_pet_state

router = APIRouter(prefix='/api/pet', tags=['pet'])


@router.get('/state', response_model=PetStateSchema)
async def get_pet_state(
  user_id: int = Query(default=1, ge=1),
  session: AsyncSession = Depends(get_session),
) -> PetStateSchema:
  pet = await get_or_create_pet_state(session, user_id)
  await session.commit()
  return PetStateSchema.model_validate(pet)
