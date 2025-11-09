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
> **NOTE** 전역 Python을 쓸 경우 `pip install --upgrade "sqlalchemy>=1.4"`를 실행해 `async_sessionmaker`가 포함된 버전을 맞춰 주세요. 가장 안전한 방법은 위 명령처럼 프로젝트 전용 가상환경을 사용하는 것입니다.

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
모든 `/admin/*` 요청은 기본적으로 ADMIN_TOKEN을 요구하지만, 현재 데모에서는 인증을 비활성화했으므로 헤더 없이 호출해도 됩니다. 필요하면 아래처럼 토큰을 포함시킬 수 있습니다.

```bash
curl http://127.0.0.1:8000/admin/routines \
  -H "Authorization: Bearer dev-admin-token"
```

## 5. 데이터베이스
- SQLite (`DB_URL=sqlite+aiosqlite:///./routine.db`)
- 앱 시작 시 테이블이 자동 생성되어 `user_id=1` 기준 기본 `pet_state`가 준비됩니다.
