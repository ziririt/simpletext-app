#!/usr/bin/env python3
"""버전 표기가 서로 어긋나지 않는지 검사 (CI에서 실행).

소유자 요청(2026-08-12): "항상 버전 업데이트를 해라. 그래야 제대로 업데이트가
반영되었는지 정확히 알 수 있다."

2026-09-12 개편 — 소유자 지시 "앱스토어 기준으로 바꿔라", 그리고 같은 날
오후 "완전히 다 일치시키는 것이지". 이제 값은 **하나**다.

  - lib/version.dart 의 appVersion   앱스토어 이름이자 꾸러미 값(3.18)
  - lib/version.dart 의 appBuild     빌드 번호(246)
  - pubspec.yaml 의 version          3.18.0+246 — 위 둘을 그대로 옮겨 적은 것

애플은 세 자리를 원하므로 pubspec 에서만 끝에 .0 을 붙인다. 그 말고는
다른 값이 없다. 이 검사기는 셋이 한 값인지 본다.

한 가지 함정: 애플은 꾸러미 값을 못 내리게 하고(ITMS-90062) 자리마다
숫자로 견준다. 3.3 은 3.17.22 보다 **작다**(둘째 자리 3 < 17). 그래서
새 이름을 정할 때는 반드시 지금까지 올린 것보다 커야 한다 —
tool/appstore_ios.sh 가 굽기 전에 애플에게 물어 확인한다.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    pub = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
    m = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$', pub, re.M)
    if not m:
        print('pubspec.yaml의 version: 을 읽지 못했습니다 (형식: 1.2.3+4)', file=sys.stderr)
        return 1
    pub_ver, pub_build = m.group(1), int(m.group(2))

    dart = (ROOT / 'lib' / 'version.dart').read_text(encoding='utf-8')
    dm = re.search(r"appVersion\s*=\s*'([^']+)'", dart)
    db = re.search(r'appBuild\s*=\s*([0-9]+)', dart)
    if not dm or not db:
        print('lib/version.dart의 appVersion/appBuild를 읽지 못했습니다', file=sys.stderr)
        return 1
    store_ver, dart_build = dm.group(1), int(db.group(1))

    errors = []

    # 3.18 또는 3.18.0 꼴. 사람이 읽고 말하는 그 이름이다.
    if not re.fullmatch(r'[0-9]+\.[0-9]+(\.[0-9]+)?', store_ver):
        errors.append(
            f"appVersion '{store_ver}' 이 버전 꼴이 아닙니다 (3.18 꼴)")

    if pub_build != dart_build:
        errors.append(
            f'빌드 번호 불일치 — pubspec.yaml +{pub_build} '
            f'vs lib/version.dart {dart_build}')

    want = store_ver if store_ver.count('.') >= 2 else f'{store_ver}.0'
    if pub_ver != want:
        errors.append(
            f'pubspec.yaml 의 version 이 {pub_ver} 인데 {want} 여야 합니다.\n'
            f'         버전은 lib/version.dart 의 appVersion 하나입니다 — '
            f'pubspec 은 그것을 옮겨 적을 뿐입니다(애플이 세 자리를 원해서 '
            f'끝에 .0 만 붙습니다).')

    if errors:
        for e in errors:
            print(f'실패 — {e}', file=sys.stderr)
        print('\n버전 표시를 믿을 수 없게 되면 "지금 깔린 게 새 판인지"를\n'
              '아무도 확인할 수 없습니다. 그래서 여기서 막습니다.', file=sys.stderr)
        return 1

    print(f'버전 검사 통과 — {store_ver} (빌드 {dart_build})')
    return 0


if __name__ == '__main__':
    sys.exit(main())
