from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
  """환경 변수를 기반으로 한 애플리케이션 설정."""

  ollama_url: str = 'http://localhost:11434'
  ollama_model: str = 'mistral:7b-instruct'
  admin_token: str = 'dev-admin-token'
  db_url: str = 'sqlite+aiosqlite:///./routine.db'

  model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8', extra='ignore')


def get_settings() -> Settings:
  return Settings()


settings = get_settings()
