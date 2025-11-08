from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class RoutineLog(Base):
  """루틴 실행 결과 로그."""

  __tablename__ = 'routine_logs'

  id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
  user_id: Mapped[int] = mapped_column(Integer, ForeignKey('users.id'), nullable=False)
  routine_id: Mapped[int] = mapped_column(Integer, nullable=False)
  status: Mapped[str] = mapped_column(String(20), nullable=False)
  started_at: Mapped[str] = mapped_column(String(40), nullable=False)
  ended_at: Mapped[str] = mapped_column(String(40), nullable=False)
  note: Mapped[str | None] = mapped_column(Text, nullable=True)
