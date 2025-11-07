from __future__ import annotations

import os
from datetime import datetime, time
from typing import Any, Callable, Dict, List

import requests
import streamlit as st

DEFAULT_API_BASE = os.getenv('API_BASE', 'http://127.0.0.1:8000')
DEFAULT_TOKEN = os.getenv('ADMIN_TOKEN') or st.secrets.get('ADMIN_TOKEN', '')
WEEKDAYS = ['월', '화', '수', '목', '금', '토', '일']

st.set_page_config(page_title='Routine AI Admin', layout='wide')

if 'api_base' not in st.session_state:
  st.session_state.api_base = DEFAULT_API_BASE.rstrip('/')
if 'admin_token' not in st.session_state:
  st.session_state.admin_token = DEFAULT_TOKEN or ''

with st.sidebar:
  st.title('API 설정')
  api_base_input = st.text_input('API Base', value=st.session_state.api_base)
  token_input = st.text_input('Admin Token', value=st.session_state.admin_token, type='password')
  st.session_state.api_base = api_base_input.rstrip('/') or DEFAULT_API_BASE
  st.session_state.admin_token = token_input.strip()
  st.caption('ADMIN_TOKEN을 secrets.toml 또는 환경 변수로 미리 설정하면 자동으로 채워집니다.')
  if not st.session_state.admin_token:
    st.warning('관리자 토큰이 없어 일부 기능이 제한됩니다.')

st.title('Routine AI Admin Console')


def call_api(
  method: str,
  path: str,
  *,
  params: Dict[str, Any] | None = None,
  json: Dict[str, Any] | None = None,
  require_admin: bool = False,
) -> Any:
  base = st.session_state.api_base or DEFAULT_API_BASE
  token = st.session_state.admin_token
  headers = {'Content-Type': 'application/json'}
  if token:
    headers['Authorization'] = f'Bearer {token}'
  elif require_admin:
    raise RuntimeError('ADMIN_TOKEN이 필요합니다.')

  response = requests.request(
    method=method,
    url=f'{base}{path}',
    params=params,
    json=json,
    headers=headers,
    timeout=10,
  )
  if response.status_code >= 400:
    raise RuntimeError(f'{response.status_code}: {response.text or response.reason}')
  if not response.content:
    return None
  return response.json()


def safe_load(label: str, fn: Callable[[], Any], fallback: Any = None) -> Any:
  try:
    with st.spinner(label):
      return fn()
  except Exception as error:  # noqa: BLE001
    st.error(f'{label} 실패: {error}')
    return fallback


def format_time(value: time) -> str:
  return value.strftime('%H:%M')


def parse_time(value: str) -> time:
  try:
    return datetime.strptime(value, '%H:%M').time()
  except ValueError:
    return time(7, 30)


def notify_success(message: str) -> None:
  st.toast(message)
  st.rerun()


with st.container():
  st.header('Dashboard')
  col1, col2 = st.columns(2)
  with col1:
    pet_state = safe_load('펫 상태 불러오는 중', lambda: call_api('GET', '/api/pet/state', params={'user_id': 1}))
    if pet_state:
      st.metric('Level', pet_state.get('level', 1))
      st.metric('XP', f"{pet_state.get('xp', 0)} / {pet_state.get('next_level_threshold', 100)}")
    else:
      st.info('펫 상태를 불러올 수 없습니다.')
  with col2:
    stats = safe_load('주간 통계 불러오는 중', lambda: call_api('GET', '/api/stats/weekly', params={'user_id': 1}))
    if stats:
      st.metric('주간 완료율', f"{stats.get('completion_rate', 0)*100:.1f}%")
      st.metric('연속 성공', f"{stats.get('streak', 0)}일")
      st.write('성공률 높은 시간대:', ', '.join(stats.get('best_slots', [])) or '데이터 없음')
    else:
      st.info('주간 통계를 불러올 수 없습니다.')

  logs = safe_load('최근 로그 불러오는 중', lambda: call_api('GET', '/admin/logs', params={'limit': 20}, require_admin=True), fallback=[])
  st.subheader('최근 20개 로그')
  if logs:
    st.dataframe(logs, use_container_width=True)
  else:
    st.write('표시할 로그가 없습니다.')

st.divider()

with st.container():
  st.header('Routines 관리')
  routines = safe_load('루틴 목록 로딩', lambda: call_api('GET', '/admin/routines', params={'user_id': 1}, require_admin=True), fallback=[])
  if routines:
    st.dataframe(routines, use_container_width=True)
  else:
    st.info('등록된 루틴이 없습니다.')

  col_create, col_update = st.columns(2)

  with col_create:
    st.subheader('루틴 추가')
    with st.form('create_routine_form', clear_on_submit=True):
      title = st.text_input('제목')
      time_value = st.time_input('시간', value=time(7, 0), key='create_time')
      days = st.multiselect('요일', WEEKDAYS, default=['월', '수', '금'])
      difficulty = st.selectbox('난이도', ['easy', 'mid', 'hard'])
      active = st.checkbox('활성화', value=True)
      submitted = st.form_submit_button('루틴 추가')
      if submitted:
        if not title or not days:
          st.warning('제목과 요일을 입력하세요.')
        else:
          payload = {
            'user_id': 1,
            'title': title,
            'time': format_time(time_value),
            'days': days,
            'difficulty': difficulty,
            'active': active,
          }
          call_api('POST', '/admin/routines', json=payload, require_admin=True)
          notify_success('루틴이 생성되었습니다.')

  with col_update:
    st.subheader('루틴 수정 / 삭제')
    if routines:
      options = {f"{item['id']} · {item['title']}": item for item in routines}
      selected_label = st.selectbox('수정 대상', list(options.keys()))
      selected = options[selected_label]
      with st.form('update_routine_form'):
        new_title = st.text_input('제목', value=selected['title'])
        new_time = st.time_input('시간', value=parse_time(selected['time']), key=f"time_{selected['id']}")
        new_days = st.multiselect('요일', WEEKDAYS, default=selected['days'], key=f"days_{selected['id']}")
        new_difficulty = st.selectbox('난이도', ['easy', 'mid', 'hard'], index=['easy', 'mid', 'hard'].index(selected['difficulty']), key=f"diff_{selected['id']}")
        new_active = st.checkbox('활성화', value=selected.get('active', True), key=f"active_{selected['id']}")
        updated = st.form_submit_button('루틴 수정')
        if updated:
          payload = {
            'title': new_title,
            'time': format_time(new_time),
            'days': new_days,
            'difficulty': new_difficulty,
            'active': new_active,
          }
          call_api('PUT', f"/admin/routines/{selected['id']}", json=payload, require_admin=True)
          notify_success('루틴이 수정되었습니다.')
      if st.button('선택 루틴 삭제'):
        call_api('DELETE', f"/admin/routines/{selected['id']}", require_admin=True)
        notify_success('루틴이 삭제되었습니다.')
    else:
      st.info('수정할 루틴이 없습니다.')

st.divider()

with st.container():
  st.header('Pet State 조정')
  current_level = pet_state.get('level', 1) if isinstance(pet_state, dict) else 1
  current_xp = pet_state.get('xp', 0) if isinstance(pet_state, dict) else 0
  current_threshold = pet_state.get('next_level_threshold', 100) if isinstance(pet_state, dict) else 100
  with st.form('pet_state_form'):
    level_input = st.number_input('Level', min_value=1, value=current_level)
    xp_input = st.number_input('XP', min_value=0, value=current_xp)
    threshold_input = st.number_input('다음 레벨 XP', min_value=10, value=current_threshold)
    submitted = st.form_submit_button('상태 저장')
    if submitted:
      payload = {
        'user_id': 1,
        'level': int(level_input),
        'xp': int(xp_input),
        'next_level_threshold': int(threshold_input),
      }
      call_api('PATCH', '/admin/pet_state', json=payload, require_admin=True)
      notify_success('펫 상태가 업데이트되었습니다.')

st.divider()

with st.container():
  st.header('로그 탐색')
  limit = st.slider('가져올 개수', min_value=20, max_value=200, value=50, step=10)
  logs = safe_load('로그 새로고침', lambda: call_api('GET', '/admin/logs', params={'limit': limit}, require_admin=True), fallback=[])
  st.dataframe(logs, use_container_width=True)
