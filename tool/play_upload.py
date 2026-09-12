#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""구운 AAB 를 플레이 트랙에 올린다. **커밋은 따로 시킨다.**

    /usr/bin/python3 tool/play_upload.py                 # 무엇을 할지 보기만 한다
    /usr/bin/python3 tool/play_upload.py --track internal
    /usr/bin/python3 tool/play_upload.py --track alpha --go
    /usr/bin/python3 tool/play_upload.py --track alpha --go --commit

기본값은 **아무것도 안 하는 것**이다
──────────────────────────────────────────────────────────────────────
`--go` 가 없으면 올릴 파일과 붙일 이름·노트만 찍고 끝난다.
`--commit` 이 없으면 올리기까지만 하고 **편집을 버린다** — 아무 일도 안 일어난다.

**`--commit` 이 이 파일에서 유일하게 되돌릴 수 없는 곳이다.**
누르면 그 트랙의 테스터에게 실제로 나간다. 소유자가 말했을 때만 친다.
(애플 쪽 `submit_next.py --submit` 과 같은 규칙이다. 준비는 되돌릴 수 있지만
제출은 사람의 결정이다.)

2026-09-12 에 손으로 올리며 배운 것 — 이 스크립트가 대신 막아 주는 것들
──────────────────────────────────────────────────────────────────────
· **올린 것과 그 출시 건에 붙은 것은 다르다.** 콘솔에서는 파일이 라이브러리에만
  들어가고 출시 건은 빈 채로 남을 수 있다. 실제로 그랬다. 여기서는 올리고
  트랙에 붙이는 것이 한 덩이라 그 틈이 없다.
· **트랙당 초안은 하나뿐이다.** 남은 초안이 있으면 콘솔의 '새 버전 만들기'가
  회색으로 죽어 있다. 그래서 이 스크립트는 연 편집을 반드시 버린다.
· **난독화 대응표(mapping)는 올리지 않는다.** 이 앱은 R8 을 껐다(2026-08-17,
  R8 이 Room 을 깨뜨렸다). `build/` 에 남은 mapping.txt 는 그 시절 찌꺼기라
  올리면 없느니만 못하다.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from play_api import PACKAGE, PlayError, api, err_text  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
AAB = ROOT / 'build' / 'app' / 'outputs' / 'bundle' / 'release' / 'app-release.aab'
NOTES = ROOT / 'store' / 'android' / 'ko-KR' / 'release_notes.txt'
FALLBACK_NOTES = ROOT / 'store' / 'ios' / 'ko' / 'release_notes.txt'


def repo_version():
    """lib/version.dart 에서 이름과 빌드 번호를 읽는다. 원본은 거기 하나뿐이다."""
    text = (ROOT / 'lib' / 'version.dart').read_text(encoding='utf-8')
    name = build = None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('const String appVersion'):
            name = line.split("'")[1]
        elif line.startswith('const int appBuild'):
            build = int(line.split('=')[1].strip().rstrip(';'))
    if not name or not build:
        raise PlayError('lib/version.dart 에서 버전을 읽지 못했습니다.')
    return name, build


def notes_text():
    for p in (NOTES, FALLBACK_NOTES):
        if p.exists():
            t = p.read_text(encoding='utf-8').strip()
            if t:
                return t, p
    return '', None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--track', default='internal',
                    choices=['internal', 'alpha', 'beta', 'production'])
    ap.add_argument('--go', action='store_true', help='실제로 올린다')
    ap.add_argument('--commit', action='store_true',
                    help='되돌릴 수 없다. 그 트랙에 실제로 나간다')
    a = ap.parse_args()

    try:
        name, build = repo_version()
        note, note_path = notes_text()
        release_name = '%d (%s.0)' % (build, name) if name.count('.') < 2 else '%d (%s)' % (build, name)

        print('올릴 것')
        print('  꾸러미  : %s' % AAB)
        if AAB.exists():
            print('            %.1fMB' % (AAB.stat().st_size / 1024 / 1024))
        else:
            print('            ** 없습니다. 먼저 구우십시오(HANDOFF 7절) **')
        print('  트랙    : %s' % a.track)
        print('  출시명  : %s' % release_name)
        print('  노트    : %s' % (note_path or '(없음 — 노트 없이 나갑니다)'))
        if note:
            for line in note.splitlines()[:4]:
                if line.strip():
                    print('            %s' % line.strip()[:50])

        if not a.go:
            print('\n아무것도 하지 않았습니다. 실제로 올리려면 --go 를 붙이십시오.')
            return 0
        if not AAB.exists():
            print('\n꾸러미가 없어 멈춥니다.')
            return 1

        code, edit = api('POST', '/applications/%s/edits' % PACKAGE)
        if code >= 400:
            print('\n편집을 열지 못했습니다 (HTTP %s): %s' % (code, err_text(edit)))
            return 1
        eid = edit['id']
        committed = False

        try:
            print('\n올리는 중… (77MB 면 1분쯤 걸립니다)')
            code, got = api('POST',
                            '/applications/%s/edits/%s/bundles?uploadType=media' % (PACKAGE, eid),
                            raw=AAB.read_bytes(),
                            content_type='application/octet-stream',
                            upload=True)
            if code >= 400:
                print('올리지 못했습니다 (HTTP %s): %s' % (code, err_text(got)))
                return 1
            vc = got.get('versionCode')
            print('올렸습니다. 버전 코드 %s' % vc)
            if vc != build:
                print('  ** 경고 — 저장소는 %s 인데 올라간 것은 %s 입니다. 구운 판이 낡았습니까? **'
                      % (build, vc))

            release = {'name': release_name, 'versionCodes': [str(vc)], 'status': 'completed'}
            if note:
                release['releaseNotes'] = [{'language': 'ko-KR', 'text': note}]
            code, got = api('PUT', '/applications/%s/edits/%s/tracks/%s' % (PACKAGE, eid, a.track),
                            body={'track': a.track, 'releases': [release]})
            if code >= 400:
                print('트랙에 붙이지 못했습니다 (HTTP %s): %s' % (code, err_text(got)))
                return 1
            print('%s 트랙에 붙였습니다.' % a.track)

            if not a.commit:
                print('\n--commit 이 없어 편집을 버립니다. **아무 일도 일어나지 않았습니다.**')
                print('실제로 내보내려면 같은 줄에 --commit 을 붙이십시오.')
                return 0

            code, got = api('POST', '/applications/%s/edits/%s:commit' % (PACKAGE, eid))
            if code >= 400:
                print('커밋하지 못했습니다 (HTTP %s): %s' % (code, err_text(got)))
                return 1
            committed = True
            print('\n나갔습니다. 결과는 tool/play_status.py 로 확인하십시오.')
            return 0

        finally:
            if not committed:
                api('DELETE', '/applications/%s/edits/%s' % (PACKAGE, eid))

    except PlayError as e:
        print(str(e))
        return 2


if __name__ == '__main__':
    sys.exit(main())
