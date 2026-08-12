#!/usr/bin/env bash
# 스토어 스크린샷 자동 촬영 (맥에서 실행).
#
# 왜 필요한가 — 노하우 문서 6절:
#   "현지화된 스크린샷이 없으면 기본 언어의 스크린샷이 그대로 나간다.
#    경고도 없고 오류도 없다."
# 11개 로케일 × 필요한 기기 크기를 손으로 찍으면 반드시 빠지는 게 생긴다.
#
# 사용법:
#   tool/screenshots.sh                 # 기본 기기 전부
#   tool/screenshots.sh "iPhone 16 Pro Max"   # 특정 기기만
#
# 주의: top-level `set -e`를 쓰지 않는다(노하우 2절) — 터미널에 붙여넣어
# 돌릴 때 오류 한 번에 창이 닫히는 것을 막기 위해서다. 실패는 아래에서 직접 센다.

cd "$(dirname "$0")/.." || exit 1

# 애플이 요구하는 스크린샷 크기는 이 두 가지로 커버된다(2026 기준).
#   6.9인치(아이폰 프로 맥스 계열), 13인치 아이패드
# 시뮬레이터 이름은 `xcrun simctl list devices` 로 확인해 맞출 것.
DEFAULT_DEVICES=(
  "iPhone 16 Pro Max"
  "iPad Pro 13-inch (M4)"
)

if [ "$#" -gt 0 ]; then
  DEVICES=("$@")
else
  DEVICES=("${DEFAULT_DEVICES[@]}")
fi

fail=0
for dev in "${DEVICES[@]}"; do
  echo ""
  echo "=== $dev ==="
  udid=$(xcrun simctl list devices available | grep -F "$dev (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  if [ -z "$udid" ]; then
    echo "  건너뜀 — 시뮬레이터를 찾지 못했습니다: $dev"
    echo "  (xcrun simctl list devices available 로 이름을 확인하세요)"
    fail=$((fail + 1))
    continue
  fi

  xcrun simctl boot "$udid" 2>/dev/null
  # 상태 표시줄을 고정한다 — 배터리·시계가 촬영마다 달라지면 스토어 심사에서 지저분해 보인다
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 2>/dev/null

  SHOT_DEVICE="$(echo "$dev" | tr ' ()' '_' | tr -s '_')" \
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/screenshots_test.dart \
      -d "$udid"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "  실패 (종료코드 $rc): $dev"
    fail=$((fail + 1))
  fi
done

echo ""
if [ "$fail" -ne 0 ]; then
  echo "촬영 실패 $fail건 — 위 로그를 확인하세요."
  exit 1
fi

echo "촬영 완료. 결과: store/screenshots/"
find store/screenshots -name '*.png' 2>/dev/null | wc -l | xargs echo "PNG 개수:"
echo ""
echo "다음: 언어별로 빠진 것이 없는지 확인"
echo "  python3 tool/screenshot_check.py"
