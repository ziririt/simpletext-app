#!/usr/bin/env python3
"""버전 표기가 서로 어긋나지 않는지 검사 (CI에서 실행).

소유자 요청(2026-08-12): "항상 버전 업데이트를 해라. 그래야 제대로 업데이트가
반영되었는지 정확히 알 수 있다."

2026-09-12 개편 — 소유자 지시 "앱스토어 기준으로 바꿔라". 이제 두 값은
같은 값이 아니라 **한 값에서 나온 두 값**이다.

  - lib/version.dart 의 appVersion   앱스토어에 보이는 이름(1.7). 사람이 정한다
  - lib/version.dart 의 appBuild     빌드 번호(245). 사람이 올린다
  - pubspec.yaml 의 version          3.<빌드>.0+<빌드>. **기계가 정한 꼴이다**

세 번째는 애플이 꾸러미 안의 마케팅 버전을 절대 못 내리게 하기 때문에
(ITMS-90062) 따로 두는 값이다. 빌드 번호에서 자동으로 만들어지니 사람이
정할 것이 없고, 이 검사기는 그 꼴이 맞는지만 본다.

이 둘이 어긋나면 최악이다. 화면에는 새 버전이 뜨는데 실제로는 옛 코드가
돌고 있어도 아무도 모른다. 버전 표시를 믿을 수 없게 되는 순간
"업데이트가 반영됐는지 확인하는 장치"라는 목적 자체가 사라진다.
그래서 경고가 아니라 실패로 떨어뜨린다.
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

    # 스토어 이름은 1.7 꼴이어야 한다. 3.17.22 같은 옛 계통이 남아 있으면
    # 개편이 덜 끝난 것이다 — 그대로 두면 '최신 버전 확인'이 거짓말한다.
    if not re.fullmatch(r'[0-9]+\.[0-9]+(\.[0-9]+)?', store_ver):
        errors.append(
            f"appVersion '{store_ver}' 이 앱스토어 이름 꼴이 아닙니다 (1.7 꼴)")

    if pub_build != dart_build:
        errors.append(
            f'빌드 번호 불일치 — pubspec.yaml +{pub_build} '
            f'vs lib/version.dart {dart_build}')

    want = f'3.{dart_build}.0'
    if pub_ver != want:
        errors.append(
            f'pubspec.yaml 의 version 이 {pub_ver} 인데 {want} 여야 합니다.\n'
            f'         이 값은 사람이 정하는 것이 아니라 빌드 번호에서 나옵니다 '
            f'(lib/version.dart 머리말).')

    if errors:
        for e in errors:
            print(f'실패 — {e}', file=sys.stderr)
        print('\n버전 표시를 믿을 수 없게 되면 "지금 깔린 게 새 판인지"를\n'
              '아무도 확인할 수 없습니다. 그래서 여기서 막습니다.', file=sys.stderr)
        return 1

    print(f'버전 검사 통과 — 스토어 {store_ver} · 빌드 {dart_build} '
          f'· 꾸러미 {pub_ver}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
