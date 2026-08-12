#!/usr/bin/env python3
"""촬영된 스토어 스크린샷에 빠진 언어가 없는지 검사 (맥에서 촬영 후 실행).

노하우 문서 6절에서 실제로 겪은 사고를 막는 장치다.
  "현지화된 스크린샷이 없으면 기본 언어의 스크린샷이 그대로 나간다.
   경고도 없고 오류도 없다. 애플과 구글 양쪽 다."

한 언어만 빠져도 그 나라 사용자 전원이 한국어 화면을 보게 된다. 그런데
빠졌다는 사실이 어디에도 표시되지 않는다. 그래서 사람 눈 대신 이걸로 센다.

PNG 자체는 저장소에 넣지 않는다(노하우 10절 — 생성 파일을 커밋하면
저장소가 부풀고 모든 git 작업이 느려진다). 촬영 직후 로컬에서 돌리는 검사다.

사용:
  tool/screenshots.sh && python3 tool/screenshot_check.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / 'store' / 'screenshots'

# store_check.py의 REQUIRED_LOCALES와 같아야 한다.
REQUIRED_LOCALES = [
    'ko', 'en-US', 'ja', 'zh-Hans', 'zh-Hant',
    'de-DE', 'fr-FR', 'es-ES', 'es-MX', 'pt-BR', 'pt-PT',
]

# screenshots_test.dart가 찍는 장면
EXPECTED_SHOTS = ['01_list', '02_table', '03_records']


def main() -> int:
    if not SHOTS.is_dir():
        print('아직 촬영된 스크린샷이 없습니다. 먼저 맥에서 tool/screenshots.sh 를 실행하세요.')
        return 0

    devices = sorted(d for d in SHOTS.iterdir() if d.is_dir())
    if not devices:
        print(f'{SHOTS} 아래에 기기 폴더가 없습니다.', file=sys.stderr)
        return 1

    missing, empty = [], []
    for dev in devices:
        for loc in REQUIRED_LOCALES:
            for shot in EXPECTED_SHOTS:
                p = dev / loc / f'{shot}.png'
                if not p.is_file():
                    missing.append(f'{dev.name}/{loc}/{shot}.png')
                elif p.stat().st_size < 1024:
                    # 1KB 미만이면 검은 화면·빈 파일일 가능성이 높다
                    empty.append(f'{dev.name}/{loc}/{shot}.png ({p.stat().st_size}B)')

    total = len(devices) * len(REQUIRED_LOCALES) * len(EXPECTED_SHOTS)
    ok = total - len(missing)
    print(f'기기 {len(devices)}개 × 로케일 {len(REQUIRED_LOCALES)}개 × 장면 {len(EXPECTED_SHOTS)}개 '
          f'= {total}장 중 {ok}장 확인')

    if empty:
        print()
        for e in empty:
            print(f'의심 — 파일이 너무 작음: {e}', file=sys.stderr)
    if missing:
        print()
        for m in missing[:40]:
            print(f'없음 — {m}', file=sys.stderr)
        if len(missing) > 40:
            print(f'... 외 {len(missing) - 40}건', file=sys.stderr)
        print(f'\n빠진 스크린샷 {len(missing)}장. 이대로 올리면 해당 언어 사용자는 '
              f'기본 언어 화면을 보게 됩니다.', file=sys.stderr)
        return 1
    if empty:
        return 1

    print('빠진 언어 없음.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
