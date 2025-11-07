from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.pet_state import PetState
from ..models.user import User


async def get_or_create_pet_state(session: AsyncSession, user_id: int) -> PetState:
  pet = await session.get(PetState, user_id)
  if pet is not None:
    return pet

  user = await session.get(User, user_id)
  if user is None:
    user = User(id=user_id)
    session.add(user)
    await session.flush()

  pet = PetState(user_id=user_id, level=1, xp=0, next_level_threshold=100)
  session.add(pet)
  await session.flush()
  return pet


async def ensure_default_user(session: AsyncSession, user_id: int = 1) -> None:
  result = await session.execute(select(User).where(User.id == user_id))
  user = result.scalars().first()
  if user is None:
    session.add(User(id=user_id))
    await session.flush()
  pet = await session.get(PetState, user_id)
  if pet is None:
    session.add(PetState(user_id=user_id, level=1, xp=0, next_level_threshold=100))
    await session.flush()
