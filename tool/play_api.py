#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""구글 플레이 개발자 API 로 가는 문. 다른 play_*.py 가 이것만 부른다.

왜 이 파일이 따로 있나
──────────────────────────────────────────────────────────────────────
애플 쪽은 이미 이렇게 돼 있다 — `~/.appstoreconnect/asc.py` 하나가 열쇠를 들고,
`tool/review_status.py` 와 `tool/submit_next.py` 가 그것을 쓴다. 열쇠를 만지는
코드가 한 곳뿐이라 열쇠가 어디 있는지 아는 파일도 하나뿐이다.

플레이도 같은 모양으로 둔다. **열쇠를 읽는 코드는 이 파일 하나다.**

왜 구글 라이브러리를 안 쓰나
──────────────────────────────────────────────────────────────────────
`google-api-python-client` 를 깔면 편하지만, 스토어 스크립트는 반드시
`/usr/bin/python3` 로 돌아야 한다(홈브루 파이썬에는 `jwt` 가 없다 — HANDOFF 7절).
시스템 파이썬에 패키지를 새로 까는 것은 **다음 맥에서 반드시 한 번 더 막힌다.**
`jwt` 와 `cryptography` 는 이미 거기 있으니 표준 라이브러리만으로 짠다.
서비스 계정 인증은 결국 **JWT 하나를 만들어 토큰으로 바꾸는 것**이 전부다.

열쇠는 어디에 있나
──────────────────────────────────────────────────────────────────────
    ~/.appstoreconnect/play-service-account.json     (권한 600)

애플 열쇠와 **같은 자리**에 둔다. 그 폴더는 700 으로 잠겨 있다(2026-09-12).
저장소 안에는 두지 않는다 — 이 저장소는 PUBLIC 이다.
`.gitignore` 에 두 번째 그물도 쳐 두었다.

**이 파일은 열쇠의 값을 절대 찍지 않는다.** 오류 메시지에도 안 나온다.
"""

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

KEY = Path.home() / '.appstoreconnect' / 'play-service-account.json'
PACKAGE = 'com.ziririt.simpletext'

SCOPE = 'https://www.googleapis.com/auth/androidpublisher'
TOKEN_URL = 'https://oauth2.googleapis.com/token'
BASE = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
UPLOAD = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3'


class PlayError(Exception):
    """사람이 읽을 수 있는 실패. 열쇠 값은 담지 않는다."""


def _need_key():
    if not KEY.exists():
        raise PlayError(
            '플레이 서비스 계정 열쇠가 없습니다.\n'
            '  있어야 할 자리: ~/.appstoreconnect/play-service-account.json\n'
            '  만드는 법은 HANDOFF.md 의 "플레이 개발자 API 붙이기" 절에 있습니다.\n'
            '  만드는 것은 소유자만 할 수 있습니다 — 구글 클라우드 로그인이 필요합니다.')
    mode = KEY.stat().st_mode & 0o777
    if mode & 0o077:
        raise PlayError(
            '열쇠 파일이 너무 열려 있습니다(%o). 이 맥에는 계정이 둘입니다.\n'
            '  고치는 한 줄:  chmod 600 ~/.appstoreconnect/play-service-account.json' % mode)


def _token():
    """서비스 계정 JSON → 접근 토큰. 한 시간짜리라 매번 새로 받는다."""
    _need_key()
    try:
        info = json.loads(KEY.read_text(encoding='utf-8'))
    except Exception:
        raise PlayError('열쇠 파일을 읽지 못했습니다. JSON 형식이 맞는지 보십시오.')

    for field in ('client_email', 'private_key'):
        if not info.get(field):
            raise PlayError('열쇠 파일에 %s 가 없습니다. 받은 파일이 서비스 계정 열쇠가 맞습니까?' % field)

    try:
        import jwt  # PyJWT. /usr/bin/python3 에 있다.
    except ImportError:
        raise PlayError('jwt 모듈이 없습니다. /usr/bin/python3 로 돌리십시오(홈브루 파이썬 아님).')

    now = int(time.time())
    claim = {
        'iss': info['client_email'],
        'scope': SCOPE,
        'aud': TOKEN_URL,
        'iat': now,
        'exp': now + 3600,
    }
    assertion = jwt.encode(claim, info['private_key'], algorithm='RS256')

    body = urllib.parse.urlencode({
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
    }).encode()
    req = urllib.request.Request(TOKEN_URL, data=body,
                                 headers={'Content-Type': 'application/x-www-form-urlencoded'})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            got = json.loads(r.read())
    except urllib.error.HTTPError as e:
        detail = e.read().decode('utf-8', 'replace')[:400]
        if 'invalid_grant' in detail:
            raise PlayError(
                '구글이 열쇠를 거절했습니다(invalid_grant).\n'
                '  흔한 까닭 둘 — 맥 시계가 몇 분 어긋났거나, 열쇠를 만든 뒤\n'
                '  플레이 콘솔에서 그 계정에 권한을 주지 않았습니다.')
        raise PlayError('토큰을 받지 못했습니다 (HTTP %s). %s' % (e.code, detail))
    except urllib.error.URLError as e:
        raise PlayError('구글에 닿지 못했습니다: %s' % e.reason)

    if 'access_token' not in got:
        raise PlayError('토큰 응답에 access_token 이 없습니다.')
    return got['access_token']


def api(method, path, token=None, body=None, raw=None, content_type=None, upload=False):
    """플레이 API 한 번 부르기.

    돌려주는 것은 **(상태코드, 파싱된 본문)** 튜플이다.
    `asc.api()` 와 일부러 같은 모양으로 뒀다 — 애플 쪽을 아는 사람이
    여기서 다시 헷갈리지 않게 하려는 것이다(HANDOFF 6절에 그 사고가 적혀 있다).
    """
    token = token or _token()
    url = (UPLOAD if upload else BASE) + path
    headers = {'Authorization': 'Bearer ' + token}
    data = raw
    if body is not None:
        data = json.dumps(body).encode()
        headers['Content-Type'] = 'application/json'
    if content_type:
        headers['Content-Type'] = content_type
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            text = r.read().decode('utf-8', 'replace')
            return r.status, (json.loads(text) if text.strip() else {})
    except urllib.error.HTTPError as e:
        text = e.read().decode('utf-8', 'replace')
        try:
            return e.code, json.loads(text)
        except Exception:
            return e.code, {'error': {'message': text[:500]}}


def err_text(payload):
    """API 오류 본문에서 사람이 읽을 한 줄만 꺼낸다."""
    if isinstance(payload, dict):
        e = payload.get('error')
        if isinstance(e, dict):
            return e.get('message') or str(e)[:200]
        if e:
            return str(e)[:200]
    return str(payload)[:200]
