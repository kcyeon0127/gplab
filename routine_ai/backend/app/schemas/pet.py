from pydantic import BaseModel, ConfigDict, Field


class PetState(BaseModel):
  """펫 상태 응답."""

  model_config = ConfigDict(from_attributes=True)

  level: int = Field(..., ge=0)
  xp: int = Field(..., ge=0)
  next_level_threshold: int = Field(..., ge=1)


class PetStatePatch(BaseModel):
  """관리자용 펫 상태 수정 요청."""

  model_config = ConfigDict(populate_by_name=True)

  user_id: int = Field(default=1, ge=1)
  level: int | None = Field(default=None, ge=1)
  xp: int | None = Field(default=None, ge=0)
  next_level_threshold: int | None = Field(default=None, ge=1)
