from typing import List

from pydantic import BaseModel, Field


class StatsWeeklyResponse(BaseModel):
  completion_rate: float = Field(..., ge=0)
  streak: int = Field(..., ge=0)
  best_slots: List[str]
  insights: List[str]
  tips: List[str]
