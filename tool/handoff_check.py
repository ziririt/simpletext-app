#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""인수인계서가 코드보다 늙었는지 본다.

2026-09-08 신설. 소유자 지시: "너도 언제 한도가 다 찰지 모른다. 다른 AI가
이어서 개발할 수 있도록 기록에 남겨라. 생활화하자."

왜 사람 약속이 아니라 검사기여야 하나
------------------------------------
2026-09-05와 09-07에 두 번, 세션이 한도에 걸려 말도 없이 끊겼다. 두 번 다
인수인계서를 못 쓰고 끝났다. 09-07 세션은 여섯 개를 커밋해 두고 끝나서
겨우 복원됐지만, 그건 운이었다. 커밋 메시지는 '무엇을 바꿨나'는 말해도
'왜 그렇게 했나, 다음에 뭘 하려 했나, 어디에 함정이 있나'는 말하지 않는다.

그러니 "끝날 때 쓰겠다"는 약속에 기대지 않는다. 세션은 자기가 언제 끊길지
모르기 때문이다. 대신 **푸시할 때마다** 인수인계서가 얼마나 늙었는지를
눈앞에 들이민다.

왜 곧바로 실패로 떨어뜨리지 않나
------------------------------
한창 고칠 때는 커밋이 연달아 나온다. 그때마다 문서를 고치라고 막으면
사람이 검사기를 꺼 버린다. 그래서 두 단계로 둔다.

  - 알림 구간: 실질 커밋 1~9개, 또는 5일 미만 → 일러만 주고 통과
  - 실패 구간: 실질 커밋 10개 이상, 또는 5일 이상 → 막는다

'실질 커밋'은 lib/, tool/, store/, pubspec.yaml 을 건드린 것만 센다.
문서만 고친 커밋은 세지 않는다.

**이 문턱을 올려서 통과시키는 것은 검사기를 죽이는 일이다**(노하우 6절).
막히면 문턱이 아니라 HANDOFF.md 를 고친다.
"""
import subprocess
import sys
import time

DOC = 'HANDOFF.md'
WATCH = ['lib', 'tool', 'store', 'pubspec.yaml']
NAG_COMMITS = 10      # 이 수 이상이면 실패
NAG_DAYS = 5          # 이 날수 이상이면 실패


def git(*args):
    try:
        out = subprocess.run(['git'] + list(args),
                             capture_output=True, text=True, timeout=20)
    except Exception:
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip()


def main():
    if git('rev-parse', '--git-dir') is None:
        print('  git 저장소가 아니다 — 건너뛴다')
        return 0

    last = git('log', '-1', '--format=%H %ct', '--', DOC)
    if not last:
        print('  %s 가 없다. 인수인계서부터 만들어라.' % DOC)
        return 1

    sha, ts = last.split()
    days = (time.time() - int(ts)) / 86400.0

    # 워치 경로를 건드린 커밋만 센다. 문서만 고친 커밋은 안 센다.
    since = git('log', '%s..HEAD' % sha, '--format=%h', '--', *WATCH) or ''
    n = len([x for x in since.split('\n') if x.strip()])

    print('  %s 는 %.1f일 전 갱신. 그 뒤 실질 커밋 %d개.' % (DOC, days, n))

    if n == 0 and days < NAG_DAYS:
        print('  최신이다.')
        return 0

    if n >= NAG_COMMITS or days >= NAG_DAYS:
        print('')
        print('  ── 인수인계서가 너무 늙었다 ──')
        print('  %s 를 지금 상태로 고친 뒤 다시 돌려라.' % DOC)
        print('  적을 것: 어디까지 됐나 / 하다 만 것과 그 상태 /')
        print('           다음 사람이 할 일 / 새로 알아낸 함정 / 건드리면 안 되는 것')
        print('  기록을 밑에 쌓지 말고 최신 한 장으로 덮어쓴다.')
        return 1

    print('  아직 통과시키지만, 오늘 안에 %s 를 손보는 게 좋다.' % DOC)
    return 0


if __name__ == '__main__':
    sys.exit(main())
