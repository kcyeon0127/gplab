from sqlalchemy import ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class PetState(Base):
  """사용자의 펫 상태."""

  __tablename__ = 'pet_state'

  user_id: Mapped[int] = mapped_column(ForeignKey('users.id'), primary_key=True)
  level: Mapped[int] = mapped_column(Integer, default=1)
  xp: Mapped[int] = mapped_column(Integer, default=0)
  next_level_threshold: Mapped[int] = mapped_column(Integer, default=100)
