from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from .config import settings
from .models.base import Base  # noqa: F401
from .models import pet_state as _pet_state  # noqa: F401
from .models import routine as _routine  # noqa: F401
from .models import routine_log as _routine_log  # noqa: F401
from .models import stats_cache as _stats_cache  # noqa: F401
from .models import user as _user  # noqa: F401

_engine = create_async_engine(settings.db_url, future=True, echo=False)
SessionLocal = async_sessionmaker(bind=_engine, expire_on_commit=False, class_=AsyncSession)


async def get_session() -> AsyncSession:
  async with SessionLocal() as session:
    yield session


async def init_db() -> None:
  async with _engine.begin() as conn:
    await conn.run_sync(Base.metadata.create_all)
