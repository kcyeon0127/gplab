# Streamlit Admin (Routine AI)

백엔드 `/admin/*` API를 관리용으로 호출하는 Streamlit 앱입니다.

## 실행
```bash
cd admin_app
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py --server.port 8501
```

환경 변수 또는 `.streamlit/secrets.toml`에 아래 값을 설정하세요.
```
API_BASE=http://127.0.0.1:8000
ADMIN_TOKEN=dev-admin-token
```

기능
- Dashboard: 펫 상태, 주간 통계, 최근 20개 로그
- Routines: CRUD (POST/PUT/DELETE `/admin/routines`)
- Pet State: 레벨/XP 직접 조정
- Logs: `/admin/logs` 페이징 조회
