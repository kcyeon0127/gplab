from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class Routine(Base):
  """등록된 루틴."""

  __tablename__ = 'routines'

  id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
  user_id: Mapped[int] = mapped_column(Integer, ForeignKey('users.id'), nullable=False, default=1)
  title: Mapped[str] = mapped_column(String(200), nullable=False)
  time: Mapped[str] = mapped_column(String(20), nullable=False)
  days: Mapped[str] = mapped_column(String(200), nullable=False)
  difficulty: Mapped[str] = mapped_column(String(20), default='mid')
  active: Mapped[bool] = mapped_column(Boolean, default=True)
