#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""플레이 트랙마다 지금 무엇이 올라가 있는지 한 화면으로 본다.

    /usr/bin/python3 tool/play_status.py

왜 만들었나
──────────────────────────────────────────────────────────────────────
2026-09-08 에 플립시계가 안드로이드 판을 내고 **나흘을 "검토 대기 중"으로
잘못 보고했다.** 실제로는 그날 12:36 에 177개국 출시가 끝나 있었다.
소유자가 화면을 캡처해 알려주셨다.

2026-09-12 에는 스카이블루가 같은 자리에서 다른 방식으로 걸렸다 —
**플레이는 저장하는 자리와 보내는 자리가 다르다.** 출시 화면의 '저장'은
게시 개요에 얹을 뿐이고 거기서 한 번 더 눌러야 나간다. 저장만 하고
끝내면 화면에 "아직 제출되지 않음"이 적힌 채 며칠이 간다.

**제출은 일의 끝이 아니라 중간이다.** 그래서 결과를 묻는 도구를 만든다.

이 도구가 답해 주는 것과 못 하는 것
──────────────────────────────────────────────────────────────────────
답해 준다 — **각 트랙에 지금 어떤 판이 실제로 올라가 있나.** 판 이름, 버전
코드, 상태(완료·진행 중·초안·중단), 몇 퍼센트에게 나갔나, 출시 노트.
"내가 낸 247 이 진짜 나갔나"에 답하는 데는 이것으로 충분하다.

못 한다 — **"지금 구글이 심사 중인가"를 직접 묻지 못한다.** 플레이 API 에는
애플의 `IN_REVIEW` 같은 칸이 없다. 심사를 통과하면 그 판이 트랙에
`completed` 로 나타나는 것으로 **결과를 보고 알 수 있을 뿐이다.**
없는 것을 있는 척 적지 않는다 — 다음 사람이 그 칸을 찾느라 시간을 버린다.

읽는 법 한 줄
──────────────────────────────────────────────────────────────────────
낸 버전 코드가 트랙에 안 보이면 **아직 안 나간 것이다.** 콘솔 게시 개요를
열어 "검토를 위해 변경사항 제출"이 남아 있는지 보라.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from play_api import PACKAGE, PlayError, api, err_text  # noqa: E402

TRACKS = ['internal', 'alpha', 'beta', 'production']
KOR = {
    'internal': '내부 테스트',
    'alpha': '비공개 테스트',
    'beta': '공개 테스트',
    'production': '프로덕션',
}
STATUS = {
    'completed': '나갔다',
    'inProgress': '나가는 중',
    'draft': '초안 — 아직 안 나갔다',
    'halted': '멈췄다',
}


def main():
    try:
        # 조회에도 '편집'을 하나 열어야 한다. 플레이 API 의 생김새다.
        # 아무것도 안 고치고 마지막에 버린다 — 커밋하지 않으면 아무 일도 안 일어난다.
        code, edit = api('POST', '/applications/%s/edits' % PACKAGE)
        if code >= 400:
            print('편집을 열지 못했습니다 (HTTP %s)' % code)
            print('  ' + err_text(edit))
            if code in (401, 403):
                print('  → 플레이 콘솔에서 이 서비스 계정에 권한을 줬는지 보십시오.')
            return 1
        eid = edit['id']

        print('구글 플레이 — %s' % PACKAGE)
        print('=' * 56)

        try:
            for t in TRACKS:
                c, tr = api('GET', '/applications/%s/edits/%s/tracks/%s' % (PACKAGE, eid, t))
                name = KOR.get(t, t)
                if c == 404:
                    print('\n· %s (%s) — 쓰지 않는 트랙' % (name, t))
                    continue
                if c >= 400:
                    print('\n· %s (%s) — 조회 실패: %s' % (name, t, err_text(tr)))
                    continue

                releases = tr.get('releases') or []
                if not releases:
                    print('\n· %s (%s) — 올라간 판이 없다' % (name, t))
                    continue

                print('\n· %s (%s)' % (name, t))
                for r in releases:
                    codes = ', '.join(str(v) for v in (r.get('versionCodes') or [])) or '(없음)'
                    st = r.get('status', '?')
                    line = '    %s · 버전 코드 %s · %s' % (
                        r.get('name', '(이름 없음)'), codes, STATUS.get(st, st))
                    frac = r.get('userFraction')
                    if frac is not None:
                        line += ' · %g%% 에게' % (float(frac) * 100)
                    print(line)
                    for note in (r.get('releaseNotes') or []):
                        head = (note.get('text') or '').strip().splitlines()
                        head = head[0] if head else ''
                        if len(head) > 40:
                            head = head[:40] + '…'
                        print('      노트 %s: %s' % (note.get('language', '?'), head))
        finally:
            # 연 편집은 반드시 버린다. 안 버리면 다음에 '새 버전 만들기'가
            # 회색으로 죽어 있는 것처럼 보인다 — 트랙당 초안은 하나뿐이다.
            api('DELETE', '/applications/%s/edits/%s' % (PACKAGE, eid))

        print('\n' + '=' * 56)
        print('낸 버전 코드가 위에 안 보이면 아직 안 나간 것입니다.')
        print('플레이 콘솔 게시 개요에서 "검토를 위해 변경사항 제출"이 남아 있는지 보십시오.')
        print('(플레이 API 에는 애플의 IN_REVIEW 같은 칸이 없습니다. 결과로만 압니다.)')
        return 0

    except PlayError as e:
        print(str(e))
        return 2


if __name__ == '__main__':
    sys.exit(main())
