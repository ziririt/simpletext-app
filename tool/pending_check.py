#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""확인 대기 목록을 푸시할 때마다 눈앞에 들이민다.

2026-09-11 신설. 소유자 지시: "내가 확인해 달라는 걸 못 보고 지나치는 경우가
있을 것이야. 그럴 때 니가 챙겨야 한다. 누락되지 않게 니가 챙겨줘."

왜 사람 약속이 아니라 검사기여야 하나
------------------------------------
handoff_check.py 와 같은 까닭이다. 세션은 끊기고 맥락은 압축된다. "다음에
꼭 다시 여쭙겠습니다"는 다음 세션에 남지 않는다. 파일에 적고, 푸시할 때마다
읽게 만든다.

**왜 실패로 떨어뜨리지 않나**
------------------------------
열린 항목이 있다고 푸시를 막으면, 소유자가 답을 안 준 것 때문에 개발이
멈춘다. 그건 소유자를 벌주는 장치다. 이 검사기는 막지 않는다. 대신 **늘
보이게** 한다. 막아야 할 것은 담당자의 망각이지 소유자의 침묵이 아니다.

파일이 없으면 그것만 일러 주고 통과한다 — 새 저장소에서 막히지 않게.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOC = ROOT / 'PENDING.md'


def main() -> int:
    if not DOC.exists():
        print('[확인 대기] PENDING.md 가 없다. 확인 청한 것을 여기에 적는다.')
        return 0

    text = DOC.read_text(encoding='utf-8')

    # '## 열린 것' 과 '## 지난 것' 사이만 본다.
    m = re.search(r'^##\s*열린 것\s*$(.*?)^##\s*지난 것\s*$',
                  text, re.M | re.S)
    if not m:
        print('[확인 대기] PENDING.md 에 "## 열린 것" / "## 지난 것" 두 칸이 '
              '있어야 한다. 모양을 지킨다.', file=sys.stderr)
        return 1

    open_items = re.findall(r'^###\s+(.+?)\s*$', m.group(1), re.M)
    if not open_items:
        print('[확인 대기] 없음. 깨끗하다.')
        return 0

    print('')
    print('=' * 64)
    print(' 소유자 확인을 기다리는 것 %d 건 — 다음 대화에서 먼저 내민다'
          % len(open_items))
    print('=' * 64)
    for it in open_items:
        print('  · %s' % it)
    print('=' * 64)
    print(' 침묵은 동의가 아니다. 답을 받은 것만 "지난 것"으로 옮긴다.')
    print('')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
