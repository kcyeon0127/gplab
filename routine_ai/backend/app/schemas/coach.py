from pydantic import BaseModel, ConfigDict, Field


class CoachChatRequest(BaseModel):
  model_config = ConfigDict(extra='ignore')

  user_id: int = Field(..., ge=1)
  message: str = Field(..., min_length=1)


class CoachChatResponse(BaseModel):
  reply: str
