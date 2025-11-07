from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import SessionLocal, init_db
from .routes import admin, coach, pet, recommend, routine, stats
from .services.pet_state_service import ensure_default_user


def _cors_regex() -> str:
  return r'http://(localhost|127\.0\.0\.1)(:\d+)?'


@asynccontextmanager
async def lifespan(app: FastAPI):
  await init_db()
  async with SessionLocal() as session:
    await ensure_default_user(session, user_id=1)
    await session.commit()
  yield


app = FastAPI(title='Routine AI Backend', version='0.1.0', lifespan=lifespan)
app.add_middleware(
  CORSMiddleware,
  allow_origin_regex=_cors_regex(),
  allow_credentials=True,
  allow_methods=['*'],
  allow_headers=['*'],
)

app.include_router(pet.router)
app.include_router(coach.router)
app.include_router(recommend.router)
app.include_router(stats.router)
app.include_router(routine.router)
app.include_router(admin.router)
