# Routine AI Backend

FastAPI + SQLite 백엔드입니다. BFF 역할을 하며 Flutter 앱과 Streamlit 관리자 툴 모두가 동일한 API를 사용합니다.

## 1. 환경 준비
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.sample .env
```
`.env`에서 Ollama URL, 모델, ADMIN_TOKEN, DB_URL을 조정할 수 있습니다.

## 2. 개발 서버 실행
```bash
uvicorn app.main:app --reload --port 8000
```
문서: http://127.0.0.1:8000/docs

## 3. 샘플 요청
```bash
# 펫 상태 조회
curl "http://127.0.0.1:8000/api/pet/state?user_id=1"

# 코치 메시지
curl -X POST http://127.0.0.1:8000/api/coach/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"message":"아침 루틴 추천해줘"}'

# 추천 생성
curl -X POST http://127.0.0.1:8000/api/recommend/generate \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"goals":["운동"],"prefer_slots":["morning"],"calendar":[]}'
```

## 4. 관리자 엔드포인트 사용
모든 `/admin/*` 요청에는 `Authorization: Bearer <ADMIN_TOKEN>` 헤더가 필요합니다.

```bash
curl http://127.0.0.1:8000/admin/routines \
  -H "Authorization: Bearer dev-admin-token"
```

## 5. 데이터베이스
- SQLite (`DB_URL=sqlite+aiosqlite:///./routine.db`)
- 앱 시작 시 테이블이 자동 생성되어 `user_id=1` 기준 기본 `pet_state`가 준비됩니다.
