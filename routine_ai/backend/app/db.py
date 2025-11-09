"""Database session/engine helpers."""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

# SQLAlchemy 1.4에서는 ``async_sessionmaker`` 가 없을 수 있으므로 안전하게 폴백한다.
try:  # pragma: no cover - 단순 임포트 가드
  from sqlalchemy.ext.asyncio import async_sessionmaker
except ImportError:  # pragma: no cover - 구버전 SQLAlchemy 대응
  from sqlalchemy.orm import sessionmaker

  def async_sessionmaker(*args, **kwargs):  # type: ignore[misc]
    """구버전 SQLAlchemy 호환용 sessionmaker."""

    kwargs.setdefault('class_', AsyncSession)
    kwargs.setdefault('expire_on_commit', False)
    return sessionmaker(*args, **kwargs)

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
    await _ensure_routine_icon_column(conn)


async def _ensure_routine_icon_column(conn) -> None:
  result = await conn.exec_driver_sql('PRAGMA table_info(routines)')
  columns = {row[1] for row in result}
  if 'icon_key' not in columns:
    await conn.exec_driver_sql("ALTER TABLE routines ADD COLUMN icon_key TEXT DEFAULT 'yoga'")
