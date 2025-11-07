from typing import List

from pydantic import BaseModel, Field


class Plan(BaseModel):
  title: str
  days: List[str]
  time: str
  duration_min: int = Field(..., ge=5)
  difficulty: str
  reason: str


class RecommendRequest(BaseModel):
  user_id: int = Field(..., ge=1)
  goals: List[str] = Field(default_factory=list)
  prefer_slots: List[str] = Field(default_factory=list, alias='prefer_slots')
  calendar: List[dict] = Field(default_factory=list)


class RecommendResponse(BaseModel):
  plans: List[Plan]
