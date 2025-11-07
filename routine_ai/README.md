# Routine AI

## 프로젝트 개요
Routine AI는 Flutter 웹/모바일 클라이언트, FastAPI + SQLite 백엔드, Streamlit 기반 관리자 툴을 한 번에 구동하는 루틴 코치 프로토타입입니다. 코치 챗봇, 루틴 추천, 펫 성장, 통계, 관리자 CRUD 파이프라인이 모두 연결되어 있습니다.

## 요구사항 요약
- Flutter 3.x: 홈 진입 시 펫 상태를 API로 불러오고, 실패 시 스낵바로 안내합니다.
- FastAPI(포트 8000): Ollama 연동/더미 응답, SQLite aiosqlite, ADMIN_TOKEN 인증 기반 `/admin/*` API.
- Streamlit(포트 8501): 관리자용 대시보드 + 루틴 CRUD + 펫 상태 조정 + 로그 열람.
- 공통: `.env.sample`, `requirements.txt`, `pyproject.toml` 제공, 모든 응답은 Null-safe/Pydantic 타입을 사용합니다.

## 빠른 실행 (3창)
### 0) Ollama (선택)
```bash
ollama serve
ollama pull mistral:7b-instruct
```

### 1) FastAPI 백엔드 (포트 8000)
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.sample .env
uvicorn app.main:app --reload --port 8000
```
테스트: http://127.0.0.1:8000/docs

### 2) Streamlit 관리자 (포트 8501)
```bash
cd admin_app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py --server.port 8501
```
접속: http://127.0.0.1:8501

### 3) Flutter 프론트 (Chrome 권장)
```bash
flutter pub get
flutter run -d chrome
```

## 문제 해결 가이드
- **CORS 실패**: 백엔드 `app/main.py`가 `http://localhost:*`, `http://127.0.0.1:*`를 허용합니다. 다른 호스트를 쓰면 `allow_origin_regex`를 수정하세요.
- **연결 거부**: FastAPI/Streamlit/Ollama가 각각 8000/8501/11434 포트에서 켜져 있는지 확인하세요. 이미 사용 중이면 포트 변경 후 Flutter `lib/constants.dart`의 `kApiBase`를 맞추세요.
- **JSON 파싱 실패**: 백엔드 로그와 Flutter `ApiException` 스낵바에서 "데이터 형식 오류"가 보이면 응답 스키마를 확인하고 `/docs`에서 실제 값을 테스트하세요.
- **에뮬레이터 네트워크**: Android 에뮬레이터에서는 `http://10.0.2.2:8000`을 사용해야 합니다. 필요 시 `kApiBase`를 해당 주소로 바꿔주세요.

## 디렉터리 구조
- `lib/` – Flutter UI/서비스/위젯
- `backend/` – FastAPI + SQLite + Ollama BFF
- `admin_app/` – Streamlit 관리자 툴
- `assets/` – 펫 이미지 등 정적 자산
