# Routine AI

## 프로젝트 개요
Routine AI는 Flutter 프론트엔드, FastAPI + SQLite 백엔드, Streamlit 관리자 툴이 하나로 연결된 루틴 코치 프로토타입입니다. 사용자는 홈 화면에서 펫 상태와 코치 메시지를 확인하고, 11월 2주치 링 캘린더와 루틴 카드의 상태 토글(완료/지각/부분/미완)을 통해 진행 상황을 즉시 기록할 수 있습니다. 관리자는 Streamlit 콘솔에서 루틴과 펫 상태를 바로 수정할 수 있습니다.

## 요구사항 요약
- **Flutter 3.x**: 홈 진입 시 `GET /api/pet/state`로 펫 상태를 가져와 렌더링하며, 실패 시 스낵바로 “서버 응답이 없습니다.” 또는 “데이터 형식 오류” 메시지를 띄웁니다.
- **FastAPI (포트 8000)**: SQLite(aiosqlite) 기반으로 펫/코치/추천/루틴/통계/Admin API를 제공하며, 현재 데모에서는 ADMIN_TOKEN 검증을 비활성화해 누구나 `/admin/*`에 접근할 수 있습니다. Ollama가 없으면 자동으로 더미 응답을 제공합니다.
- **Streamlit (포트 8501)**: 관리자 대시보드, 루틴 CRUD, 펫 상태 조정, 로그 탐색을 모두 FastAPI 경유로 실행합니다.
- **공통**: `.env.sample`, `requirements.txt`, `pyproject.toml`을 제공하며 모든 코드에 주석과 타입(Null-safety/Pydantic)을 명시했습니다.
- **가상환경 권장**: 시스템 Python을 그대로 쓰면 오래된 SQLAlchemy 때문에 `async_sessionmaker` 임포트 에러가 발생할 수 있습니다. 반드시 `python -m venv .venv` 후 `pip install -r requirements.txt`를 실행하세요.

## 빠른 실행 (3개의 터미널 창)
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
- OpenAPI 문서: http://127.0.0.1:8000/docs

### 2) Streamlit 관리자 (포트 8501)
```bash
cd admin_app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py --server.port 8501
```
- 접속: http://127.0.0.1:8501
- `API_BASE`는 필수, `ADMIN_TOKEN`은 선택(입력 시 Authorization 헤더 추가)

### 3) Flutter 프론트 (Chrome 예시)
```bash
flutter pub get
flutter run -d chrome
```
- 백엔드 주소는 `lib/constants.dart`의 `kApiBase` (기본 `http://127.0.0.1:8000`)를 사용합니다.

## 문제 해결 가이드
- **CORS 실패**: FastAPI `app/main.py`에서 `http://localhost:*`, `http://127.0.0.1:*`를 허용합니다. 다른 호스트로 접근한다면 `allow_origin_regex`를 수정하세요.
- **연결 거부**: 8000(FastAPI), 8501(Streamlit), 11434(Ollama) 포트가 이미 사용 중인지 확인하고, 변경 시 Flutter `kApiBase`와 `.env`의 `OLLAMA_URL`을 함께 조정하세요.
- **JSON 파싱 오류**: Flutter에서 “데이터 형식 오류” 스낵바가 뜨면 백엔드 `/docs`에서 동일 요청을 실행해 실제 응답 구조를 점검하세요.
- **Android 에뮬레이터**: 로컬호스트 대신 `http://10.0.2.2:8000`을 사용해야 합니다. 필요 시 `kApiBase`를 해당 주소로 변경하세요.
- **`async_sessionmaker` ImportError**: `backend` 디렉터리에서 가상환경을 만들고 `pip install -r requirements.txt`로 SQLAlchemy 2.x를 설치하면 해결됩니다. 전역 Python에 설치하려면 `pip install --upgrade "sqlalchemy>=1.4"`가 필요합니다.
- **Streamlit secrets 오류**: `admin_app` 루트에서 `streamlit run app.py --server.port 8501`만 실행하면 됩니다. `ADMIN_TOKEN` 입력은 선택 사항이며, 토큰을 비워두면 공개 모드로 호출됩니다.
- **`set_page_config` 에러**: 동일한 이유로 `streamlit run app.py` 명령을 다시 실행하세요. 다른 스크립트에서 `st.set_page_config`를 중복 호출하지 말고, 관리자 앱을 그대로 사용하면 문제가 없습니다.

## 디렉터리 구조
- `lib/` – Flutter 위젯/서비스/프로바이더
- `backend/` – FastAPI + SQLite + Ollama 연동 BFF
- `admin_app/` – Streamlit 관리자 앱
- `assets/` – 펫 이미지 등 정적 리소스
