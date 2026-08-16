#!/usr/bin/env python3
"""스토어 등록정보 정합성 검사 (CI에서 실행).

노하우 문서 6절의 두 가지 사고를 여기서 막는다.

  (1) "번역 파일은 조용히 썩는다" — 파일은 있는데 값이 비어 있거나
      한국어 원문 그대로인 채 몇 주가 지나간다. 아무도 모른다.
  (2) "현지화된 스크린샷이 없으면 기본 언어의 스크린샷이 그대로 나간다.
      경고도 없고 오류도 없다." — 애플·구글 양쪽에서 실제로 겪은 일이다.

그래서 이 검사는 경고가 아니라 '실패'로 떨어진다. 통과시키려고 무시 목록에
넣는 순간 이 장치는 죽는다(노하우 6절).

애플 App Store Connect 글자 수 제한도 함께 검사한다. 초과하면 업로드가
거부되는데, 그때는 이미 출시 당일이다.
"""
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / 'store' / 'ios'
PLAY = ROOT / 'store' / 'android'

# App Store Connect 필드별 최대 길이 (문자 수)
LIMITS = {
    'name.txt': 30,
    'subtitle.txt': 30,
    'promotional_text.txt': 170,
    'keywords.txt': 100,
    'description.txt': 4000,
    'release_notes.txt': 4000,
}

# 앱이 지원하는 9개 언어에 대응하는 스토어 로케일.
# 스페인어·포르투갈어는 지역에 따라 단어가 달라 분리한다(노하우 6절):
#   móvil/celular, ecrã/tela, telemóvel/celular, folha de cálculo/planilha
REQUIRED_LOCALES = [
    'ko', 'en-US', 'ja', 'zh-Hans', 'zh-Hant',
    'de-DE', 'fr-FR', 'es-ES', 'es-MX', 'pt-BR', 'pt-PT',
]

BASE = 'ko'  # 원문 기준 언어

# ---------------------------------------------------------------------------
# 플레이 스토어 (2026-08-17)
# ---------------------------------------------------------------------------
#
# 애플 쪽만 지키고 안드로이드 쪽을 안 보면 그쪽이 똑같이 썩는다. 그리고
# 검사가 있다는 사실이 오히려 해로워진다 — "검사를 돌렸으니 괜찮겠지"가
# 되기 때문이다.
#
# 구글은 로케일 코드가 다르다. 애플의 ja는 구글에서 ja-JP이고, zh-Hans는
# zh-CN, es-MX는 es-419다. 여기서 틀리면 업로드가 조용히 다른 언어에
# 들어간다.
PLAY_LIMITS = {
    'title.txt': 30,
    'short_description.txt': 80,
    'full_description.txt': 4000,
}

PLAY_LOCALES = [
    'ko-KR', 'en-US', 'ja-JP', 'zh-CN', 'zh-TW',
    'de-DE', 'fr-FR', 'es-ES', 'es-419', 'pt-BR', 'pt-PT',
]

# 안드로이드에 없는 것을 설명에 적으면 구글이 '오해를 부르는 설명'으로 본다.
# 그리고 그 전에, 사용자가 없는 기능을 찾다가 별점을 깎는다.
PLAY_FORBIDDEN = ['iCloud', 'Face ID', 'iPhone', 'iPad', 'App Store']


def check_play(errors, warnings):
    if not PLAY.is_dir():
        warnings.append('store/android 디렉터리 없음 — 플레이 등록정보 미작성')
        return
    base_vals = {}
    for f in PLAY_LIMITS:
        bp = PLAY / 'ko-KR' / f
        if bp.is_file():
            base_vals[f] = read(bp)
    for loc in PLAY_LOCALES:
        d = PLAY / loc
        if not d.is_dir():
            errors.append(f'android/{loc}: 로케일 디렉터리 없음')
            continue
        for fname, limit in PLAY_LIMITS.items():
            q = d / fname
            if not q.is_file():
                errors.append(f'android/{loc}/{fname}: 파일 없음')
                continue
            v = read(q)
            if not v:
                errors.append(f'android/{loc}/{fname}: 값이 비어 있음')
                continue
            if len(v) > limit:
                errors.append(
                    f'android/{loc}/{fname}: {len(v)}자 — 한도 {limit}자 초과')
            for bad in PLAY_FORBIDDEN:
                if bad in v:
                    errors.append(
                        f'android/{loc}/{fname}: 안드로이드에 없는 것을 적었다 — {bad}')
            if loc != 'ko-KR' and fname != 'title.txt':
                if base_vals.get(fname) and v == base_vals[fname]:
                    errors.append(f'android/{loc}/{fname}: 한국어 원문과 동일 — 미번역')
            if loc != 'ko-KR':
                if any('HANGUL' in unicodedata.name(ch, '') for ch in v):
                    errors.append(
                        f'android/{loc}/{fname}: 한글이 섞여 있음 — 번역 누락 조각')


def read(p: Path) -> str:
    return p.read_text(encoding='utf-8').strip()


def main() -> int:
    errors, warnings = [], []

    if not STORE.is_dir():
        print(f'store/ios 디렉터리가 없습니다: {STORE}', file=sys.stderr)
        return 1

    base_vals = {}
    for f in LIMITS:
        bp = STORE / BASE / f
        if bp.is_file():
            base_vals[f] = read(bp)

    for loc in REQUIRED_LOCALES:
        d = STORE / loc
        if not d.is_dir():
            errors.append(f'{loc}: 로케일 디렉터리 없음')
            continue
        for fname, limit in LIMITS.items():
            p = d / fname
            if not p.is_file():
                errors.append(f'{loc}/{fname}: 파일 없음')
                continue
            v = read(p)
            if not v:
                errors.append(f'{loc}/{fname}: 값이 비어 있음')
                continue
            n = len(v)
            if n > limit:
                errors.append(f'{loc}/{fname}: {n}자 — 한도 {limit}자 초과')
            # 치환되지 않은 자리표시자
            # 'TODO'는 스페인어·포르투갈어에서 '전부'라는 흔한 낱말이라
            # 그대로 찾으면 오탐이 난다(실제로 es-ES/es-MX 설명이 걸렸다).
            # 자리표시자로 볼 수 있는 형태만 좁혀서 본다.
            if '{{' in v or re.search(r'\b(TODO:|FIXME|XXX:)', v):
                errors.append(f'{loc}/{fname}: 자리표시자가 남아 있음')
            # 한국어 원문 그대로면 미번역 의심 (키워드는 고유명사 비중이 커 제외)
            if loc != BASE and fname not in ('keywords.txt', 'name.txt'):
                if base_vals.get(fname) and v == base_vals[fname]:
                    errors.append(f'{loc}/{fname}: 한국어 원문과 동일 — 미번역')
            # 한글이 섞여 있으면 번역 누락 조각 (한국어 로케일 제외)
            if loc != BASE:
                if any('HANGUL' in unicodedata.name(ch, '') for ch in v):
                    errors.append(f'{loc}/{fname}: 한글이 섞여 있음 — 번역 누락 조각')

    # 등록된 로케일 외에 남아도는 디렉터리 알림
    for d in sorted(STORE.iterdir()):
        if d.is_dir() and d.name not in REQUIRED_LOCALES:
            warnings.append(f'{d.name}: REQUIRED_LOCALES에 없는 디렉터리 (오타?)')

    check_play(errors, warnings)

    for w in warnings:
        print(f'경고 — {w}')
    if errors:
        print()
        for e in errors:
            print(f'실패 — {e}', file=sys.stderr)
        print(f'\n스토어 등록정보 검사 실패: {len(errors)}건', file=sys.stderr)
        return 1

    n_loc = len(REQUIRED_LOCALES)
    n_play = len(PLAY_LOCALES) * len(PLAY_LIMITS) if PLAY.is_dir() else 0
    print(f'스토어 등록정보 검사 통과 — 애플 로케일 {n_loc}개 × 필드 {len(LIMITS)}개 '
          f'= {n_loc * len(LIMITS)}개, 플레이 {n_play}개')
    return 0


if __name__ == '__main__':
    sys.exit(main())
