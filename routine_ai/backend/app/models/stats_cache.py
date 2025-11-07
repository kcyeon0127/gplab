from sqlalchemy import Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class StatsCache(Base):
  """주간 통계 캐시."""

  __tablename__ = 'stats_cache'

  id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
  user_id: Mapped[int] = mapped_column(Integer, ForeignKey('users.id'), nullable=False)
  week_start: Mapped[str] = mapped_column(String(20), nullable=False)
  completion_rate: Mapped[float] = mapped_column(Float, default=0.0)
  streak: Mapped[int] = mapped_column(Integer, default=0)
  insights_json: Mapped[str] = mapped_column(Text, default='[]')
  tips_json: Mapped[str] = mapped_column(Text, default='[]')
