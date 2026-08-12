#!/usr/bin/env python3
"""다국어 파일 정합성 검사 (CI에서 실행).

노하우 문서 6절: "번역 파일은 조용히 썩는다."
Dart 테스트(test/l10n/l10n_test.dart)가 값 수준을 검사하고,
이 스크립트는 소스 파일 수준에서 다음을 검사한다.

하드 실패:
  1. l10n.dart의 추상 getter가 all 맵에 등록되지 않음 (또는 그 반대)
  2. 언어 파일에 빈 문자열 값('' 또는 "")이 존재

경고(빌드는 통과):
  3. 한국어 원문과 완전히 동일한 번역 값 (미번역 의심)

새 언어 추가 시 체크리스트(노하우 6절 — "고쳐야 할 곳은 코드 말고도 있다"):
  - lib/l10n/l10n_<lang>.dart 작성 + l10n.dart의 forLocale/supportedLocales/allTranslations
  - ios/Runner/Info.plist, macos/Runner/Info.plist 의 CFBundleLocalizations
  - test/l10n/l10n_test.dart 의 언어 수·용어집 기대값
  - (출시 후) 스토어 등록정보의 현지화 스크린샷 — 없으면 기본 언어 것이 그대로 나간다!
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT / 'lib' / 'l10n'

def parse_abstract_getters(text: str) -> set:
    # 추상 선언:  String get name;
    return set(re.findall(r'String get (\w+);', text))

def parse_all_map_keys(text: str) -> set:
    m = re.search(r'Map<String, String> get all => \{(.*?)\n\s*\};', text, re.S)
    if not m:
        return set()
    return set(re.findall(r"'(\w+)':", m.group(1)))

def parse_getter_values(text: str) -> dict:
    """한 줄짜리 getter만 파싱: String get key => '...'; 또 "...";"""
    values = {}
    for m in re.finditer(r"String get (\w+) =>\s*(['\"])((?:\\.|(?!\2).)*)\2;", text):
        values[m.group(1)] = m.group(3)
    return values

def main() -> int:
    errors = []
    warnings = []

    base = (L10N_DIR / 'l10n.dart').read_text(encoding='utf-8')
    abstract = parse_abstract_getters(base)
    registered = parse_all_map_keys(base)

    abstract.discard('localeTag')  # 메타 키 — all 맵 대상 아님
    missing_in_map = abstract - registered
    extra_in_map = registered - abstract
    if missing_in_map:
        errors.append(f'all 맵에 미등록된 추상 getter: {sorted(missing_in_map)}')
    if extra_in_map:
        errors.append(f'all 맵에만 있고 추상 선언이 없는 키: {sorted(extra_in_map)}')

    lang_files = sorted(p for p in L10N_DIR.glob('l10n_*.dart'))
    if len(lang_files) < 9:
        errors.append(f'언어 파일이 9개 미만: {[p.name for p in lang_files]}')

    ko_values = {}
    per_lang = {}
    for p in lang_files:
        text = p.read_text(encoding='utf-8')
        vals = parse_getter_values(text)
        per_lang[p.name] = vals
        for key, v in vals.items():
            if v.strip() == '' and key != 'localeTag':
                # savedRuleSuffix처럼 앞 공백이 의미 있는 키가 있어 strip 후 판단
                errors.append(f'{p.name}: {key} 값이 비어 있음')
        if p.name == 'l10n_ko.dart':
            ko_values = vals

    for name, vals in per_lang.items():
        if name == 'l10n_ko.dart':
            continue
        same = [k for k, v in vals.items()
                if k in ko_values and v == ko_values[k] and k != 'localeTag'
                and len(v) > 2]  # 기호 수준(예: 날짜 포맷)은 제외
        if same:
            warnings.append(f'{name}: 한국어 원문과 동일한 값 {len(same)}건 (미번역 의심): {same[:10]}')

    for w in warnings:
        print(f'[경고] {w}')
    if errors:
        for e in errors:
            print(f'[실패] {e}', file=sys.stderr)
        return 1
    print(f'l10n 검사 통과 — 추상 키 {len(abstract)}개, all 맵 {len(registered)}개, 언어 파일 {len(lang_files)}개')
    return 0

if __name__ == '__main__':
    sys.exit(main())
