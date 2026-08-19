#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""심사가 어디까지 갔는지 묻는다 — 브라우저를 안 거치고.

2026-08-20 새벽. 그동안 심사 상태는 크롬에 열어 둔 App Store Connect 탭을
읽어서 확인했다. 그런데 그 탭은 **사장님도 쓰는 탭**이다. 사장님이 다른
화면으로 옮겨 두면 뺏을 수 없으니, 그날 밤 열두 번의 확인이 통째로 건너뛰어졌다.

사람과 도구가 같은 창을 나눠 쓰면, 결국 도구가 눈을 감는다.

애플은 같은 것을 API 로도 알려 준다. 열쇠는 ~/.appstoreconnect 에 있고
저장소에는 안 들어온다. 이 파일에는 열쇠가 없다 — 열쇠를 어디서 찾는지만 있다.

  python3 tool/review_status.py            # 두 앱 다
  python3 tool/review_status.py skyblue    # 하나만
"""
import sys
from datetime import datetime, timezone

sys.path.insert(0, '/Users/ziririt/.appstoreconnect')
try:
    from asc import api
except Exception as e:  # noqa: BLE001
    print('열쇠 꾸러미를 못 읽었다(~/.appstoreconnect): %s' % e)
    raise SystemExit(2)

# 사람이 읽는 말로. 애플의 상태 이름은 대문자 스물몇 가지인데, 그중 우리가
# 실제로 보는 것은 몇 개 안 된다.
SAY = {
    'PREPARE_FOR_SUBMISSION': '아직 안 냈다 — 쓰는 중',
    'WAITING_FOR_REVIEW': '냈다. 줄 서 있다',
    'IN_REVIEW': '심사 중 — 사람이 보고 있다',
    'PENDING_DEVELOPER_RELEASE': '통과. 우리가 공개 단추를 눌러야 나간다',
    'READY_FOR_SALE': '나갔다',
    'REJECTED': '거절 — 리졸루션 센터를 볼 것',
    'METADATA_REJECTED': '글·그림에서 거절 — 앱 자체는 아니다',
    'DEVELOPER_REJECTED': '우리가 취소했다',
    'INVALID_BINARY': '빌드가 잘못됐다',
    'PROCESSING_FOR_APP_STORE': '통과. 애플이 내보내는 중',
}

WANT = (sys.argv[1].lower() if len(sys.argv) > 1 else '')


def ago(iso):
    """'2026-08-16T22:32:31-07:00' → '2일 12시간 전'. 못 읽으면 그대로 돌려준다."""
    if not iso:
        return ''
    try:
        t = datetime.fromisoformat(iso)
        d = datetime.now(timezone.utc) - t.astimezone(timezone.utc)
    except Exception:  # noqa: BLE001
        return iso
    h = int(d.total_seconds() // 3600)
    return '%d일 %d시간 전' % (h // 24, h % 24) if h >= 24 else '%d시간 전' % h


st, res = api('GET', '/v1/apps?limit=20')
if st != 200:
    print('앱 목록을 못 받았다 (%s)' % st)
    raise SystemExit(1)

for d in res.get('data', []):
    a = d.get('attributes', {})
    name, bid = a.get('name', ''), a.get('bundleId', '')
    if WANT and WANT not in name.lower() and WANT not in bid.lower():
        continue
    print('%s  (%s)' % (name, bid))

    s2, r2 = api('GET', '/v1/apps/%s/appStoreVersions?limit=4' % d['id'])
    for v in (r2.get('data') or []):
        va = v.get('attributes', {})
        state = va.get('appStoreState') or ''
        print('  %-8s %s' % (va.get('versionString'), SAY.get(state, state)))

        s3, r3 = api('GET', '/v1/appStoreVersions/%s/build' % v['id'])
        b = (r3 or {}).get('data')
        if b:
            ba = b.get('attributes', {})
            up = ba.get('uploadedDate')
            print('           빌드 %s · 올린 지 %s' % (ba.get('version'), ago(up)))
        # 거절이면 왜 거절인지가 제일 급하다. API 로는 사유 본문이 안 온다 —
        # 리졸루션 센터에만 있다. 그 사실을 여기서 말해 준다.
        if 'REJECT' in state:
            print('           사유는 API 로 안 온다. App Store Connect 의'
                  ' 리졸루션 센터를 열어 볼 것')
    print()
