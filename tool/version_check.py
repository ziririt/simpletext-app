#!/usr/bin/env python3
"""버전 표기가 서로 어긋나지 않는지 검사 (CI에서 실행).

소유자 요청(2026-08-12): "항상 버전 업데이트를 해라. 그래야 제대로 업데이트가
반영되었는지 정확히 알 수 있다."

그런데 버전은 두 군데에 적힌다.
  - pubspec.yaml   빌드에 들어가는 값
  - lib/version.dart  화면에 보여 주는 값

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
    dart_ver, dart_build = dm.group(1), int(db.group(1))

    errors = []
    if pub_ver != dart_ver:
        errors.append(f'버전 불일치 — pubspec.yaml {pub_ver} vs lib/version.dart {dart_ver}')
    if pub_build != dart_build:
        errors.append(f'빌드 번호 불일치 — pubspec.yaml +{pub_build} vs lib/version.dart {dart_build}')

    if errors:
        for e in errors:
            print(f'실패 — {e}', file=sys.stderr)
        print('\n두 곳을 같은 값으로 맞춰 주세요. 화면에 뜨는 버전과 실제 빌드가 다르면\n'
              '버전 표시를 믿을 수 없게 됩니다.', file=sys.stderr)
        return 1

    print(f'버전 검사 통과 — {pub_ver} (빌드 {pub_build})')
    return 0


if __name__ == '__main__':
    sys.exit(main())
