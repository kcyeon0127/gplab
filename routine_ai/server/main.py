from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Load environment variables from .env located next to this file.
load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
MODEL_NAME = os.getenv("MODEL", "mistral:7b-instruct")

app = FastAPI(title="Routine AI Backend", version="0.1.0")

# Allow Chrome/Flutter web running on localhost variants.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class CoachChatRequest(BaseModel):
    user_id: int = Field(..., ge=1)
    message: str
    context_flags: Optional[Dict[str, bool]] = None


class CoachChatResponse(BaseModel):
    reply: str


class RecommendRequest(BaseModel):
    user_id: int = Field(..., ge=1)
    goals: List[str] = Field(default_factory=list)
    prefer_slots: List[str] = Field(default_factory=list)
    calendar: List[Any] = Field(default_factory=list)


class RoutinePlan(BaseModel):
    title: str
    days: List[str]
    time: str
    duration_min: int
    difficulty: str
    reason: str


class RecommendResponse(BaseModel):
    plans: List[RoutinePlan]


class RoutineCompleteRequest(BaseModel):
    user_id: int = Field(..., ge=1)
    routine_id: int = Field(..., ge=1)
    status: str
    started_at: str
    ended_at: str
    note: Optional[str] = None
    sleep_hours: Optional[float] = None


class RoutineCompleteResponse(BaseModel):
    pet_state: Dict[str, int]
    streak: int
    coach_hint: Optional[str] = None


@app.on_event("startup")
async def startup_event() -> None:
    app.state.http_client = httpx.AsyncClient(
        base_url=OLLAMA_URL,
        timeout=httpx.Timeout(60.0, read=60.0, connect=10.0),
    )


@app.on_event("shutdown")
async def shutdown_event() -> None:
    client: httpx.AsyncClient = app.state.http_client
    await client.aclose()


async def call_ollama(prompt: str) -> str:
    client: httpx.AsyncClient = app.state.http_client
    try:
        response = await client.post(
            "/api/generate",
            json={"model": MODEL_NAME, "prompt": prompt, "stream": False},
        )
        response.raise_for_status()
    except httpx.HTTPError as error:
        raise HTTPException(status_code=502, detail=f"Ollama 요청 실패: {error}") from error

    data = response.json()
    text = data.get("response")
    if not text:
        raise HTTPException(status_code=502, detail="Ollama 응답에 reply가 없습니다.")
    return text.strip()


def extract_json_block(text: str) -> Dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        lines = [line for line in cleaned.splitlines() if not line.strip().startswith("```")]
        cleaned = "\n".join(lines).strip()

    match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if match:
        cleaned = match.group(0)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as error:
        raise HTTPException(status_code=502, detail=f"LLM JSON 파싱 실패: {error}") from error


@app.post("/api/coach/chat", response_model=CoachChatResponse)
async def coach_chat(request: CoachChatRequest) -> CoachChatResponse:
    prompt = (
        "당신은 친절한 한국어 루틴 코치입니다. 사용자의 고민을 듣고 간단한 조언을 3문장 이내로 답변하세요.\n"
        f"사용자 메시지: {request.message}\n"
    )
    reply = await call_ollama(prompt)
    return CoachChatResponse(reply=reply)


@app.post("/api/recommend/generate", response_model=RecommendResponse)
async def recommend_generate(request: RecommendRequest) -> RecommendResponse:
    goal_text = ", ".join(request.goals) if request.goals else "미설정"
    slot_text = ", ".join(request.prefer_slots) if request.prefer_slots else "미설정"
    prompt = (
        "당신은 루틴 전문가입니다. 아래 정보를 참고해 루틴 2~3개를 추천하고 JSON으로만 답변하세요.\n"
        f"목표: {goal_text}\n"
        f"선호 시간대: {slot_text}\n"
        "각 루틴은 title, days(요일 배열: 월~일 중 문자열), time(24시간 HH:MM), duration_min(정수), "
        "difficulty(easy/mid/hard), reason(간단한 한글 설명)을 포함해야 합니다.\n"
        '반드시 {"plans": [...]} 형식의 순수 JSON만 출력하세요. 설명 문장은 쓰지 마세요.'
    )
    response_text = await call_ollama(prompt)
    data = extract_json_block(response_text)

    plans_raw = data.get("plans")
    if not isinstance(plans_raw, list):
        raise HTTPException(status_code=502, detail="LLM이 plans 배열을 반환하지 않았습니다.")

    plans: List[RoutinePlan] = []
    for entry in plans_raw:
        if not isinstance(entry, dict):
            continue
        if not {"title", "days", "time", "duration_min", "difficulty", "reason"}.issubset(entry.keys()):
            continue
        plans.append(
            RoutinePlan(
                title=str(entry["title"]),
                days=[str(day) for day in entry.get("days", [])],
                time=str(entry["time"]),
                duration_min=int(entry["duration_min"]),
                difficulty=str(entry["difficulty"]),
                reason=str(entry["reason"]),
            )
        )

    if not plans:
        raise HTTPException(status_code=502, detail="LLM 추천 데이터를 읽어오지 못했습니다.")

    return RecommendResponse(plans=plans)


@app.get("/api/pet/state")
async def pet_state() -> Dict[str, int]:
    return {"level": 3, "xp": 45, "next_level_threshold": 100}


@app.get("/api/stats/weekly")
async def stats_weekly() -> Dict[str, Any]:
    return {
        "completion_rate": 0.7,
        "streak": 4,
        "best_slots": ["아침", "저녁"],
        "insights": ["아침 루틴 성공률이 높아요"],
        "tips": ["너무 무리하지 마세요."],
    }


@app.post("/api/routine/complete", response_model=RoutineCompleteResponse)
async def routine_complete(request: RoutineCompleteRequest) -> RoutineCompleteResponse:
    return RoutineCompleteResponse(
        pet_state={"level": 3, "xp": 50, "next_level_threshold": 100},
        streak=5,
        coach_hint="오늘도 꾸준히 이어가볼까요?",
    )



@app.get("/api/routine/recommend")
async def recommend_routine():
    return {
        "title": "아침 스트레칭",
        "icon": "yoga",
        "time": "07:00",
        "days": ["월", "수", "금"],
    }
