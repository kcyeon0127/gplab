from __future__ import annotations

from typing import List

from pydantic import BaseModel, ConfigDict, Field

from .pet import PetState


class RoutineBase(BaseModel):
  title: str
  time: str
  days: List[str]
  difficulty: str = Field(default='mid')
  active: bool = Field(default=True)
  icon_key: str = Field(default='yoga')


class RoutineCreate(RoutineBase):
  user_id: int = Field(default=1, ge=1)


class RoutineUpdate(BaseModel):
  title: str | None = None
  time: str | None = None
  days: List[str] | None = None
  difficulty: str | None = None
  active: bool | None = None
  icon_key: str | None = None


class RoutineRead(RoutineBase):
  model_config = ConfigDict(from_attributes=True)

  id: int
  user_id: int


class RoutineCompleteRequest(BaseModel):
  user_id: int = Field(..., ge=1)
  routine_id: int = Field(..., ge=1)
  status: str
  started_at: str
  ended_at: str
  note: str | None = None


class RoutineCompleteResponse(BaseModel):
  pet_state: PetState
  streak: int
  coach_hint: str | None = None


class RoutineLogRead(BaseModel):
  model_config = ConfigDict(from_attributes=True)

  id: int
  user_id: int
  routine_id: int
  status: str
  started_at: str
  ended_at: str
  note: str | None = None
