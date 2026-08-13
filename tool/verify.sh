#!/usr/bin/env bash
# 푸시 전에 이거 하나만 돌리면 된다. CI가 보는 것과 같은 순서다.
#
# 왜 만들었나 — 2026-08-14에 세션 두 개가 같은 실수를 했다.
#   flutter analyze → 오류 0
#   flutter test    → 전부 통과
# 그래서 끝난 줄 알고 푸시했는데 CI가 빨간불이었다. 이 저장소에는 언어 표준
# 도구가 안 보는 자기만의 검사기가 tool/ 안에 따로 있기 때문이다.
# 검사기가 흩어져 있으면 사람은 반드시 하나를 빠뜨린다. 그래서 한 줄로 묶는다.
#
# 사용:  tool/verify.sh
#
# 주의: top-level `set -e`를 쓰지 않는다(노하우 2절) — 터미널에 붙여넣어 돌릴 때
# 오류 한 번에 창이 닫히는 것을 막기 위해서다. 실패는 아래에서 직접 센다.

cd "$(dirname "$0")/.." || exit 1

fail=0
run() {
  echo ""
  echo "── $1"
  shift
  "$@"
  if [ $? -ne 0 ]; then
    fail=$((fail + 1))
    echo "   ↑ 실패"
  fi
}

echo "심플텍스트 검사 — CI와 같은 순서"

run "다국어 정합성 (l10n_check)"   python3 tool/l10n_check.py
run "버전 표기 일치 (version_check)" python3 tool/version_check.py
run "스토어 등록정보 (store_check)"  python3 tool/store_check.py

# flutter가 있는 환경에서만 돈다. 클라우드 세션 컨테이너는 pub.dev가 막혀 있어
# flutter 명령을 못 돌린다 — 그 경우는 CI가 대신 본다(CLAUDE.md 작업 규칙).
if command -v flutter >/dev/null 2>&1; then
  run "정적 분석 (analyze)" flutter analyze --no-fatal-infos
  run "테스트 (test)"       flutter test
else
  echo ""
  echo "── flutter 없음 → analyze·test는 건너뜁니다 (푸시 후 CI가 봅니다)"
fi

echo ""
if [ "$fail" -ne 0 ]; then
  echo "검사 실패 ${fail}건 — 고치고 다시 돌리세요. 이대로 푸시하면 CI가 빨간불입니다."
  exit 1
fi
echo "전부 통과. 푸시해도 됩니다."
echo "(단, 푸시가 끝이 아니라 CI 통과가 끝입니다 — Actions에서 결과를 확인하세요)"
