#!/bin/bash
# 맥 앱스토어 스크린샷 11개 언어 × 3장. 맥에서 돌린다.
#
#   bash tool/screenshots_mac.sh
#
# 앱(integration_test/screenshots_mac_test.dart)이 화면을 차리고 want_ 파일을
# 놓으면, 여기서 창을 찍고 done_ 파일을 놓는다. 그 머리말에 까닭이 있다.
#
# 창은 1280×800 포인트로 맞춘다. 레티나 화면에서 찍으면 2560×1600 픽셀 —
# 애플이 맥 스크린샷으로 받는 네 크기 중 하나다. 다른 크기로 찍으면 안 올라간다.
set -u
cd "$(dirname "$0")/.." || exit 1
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
OUT="store/screenshots/mac"
BOX="$HOME/Library/Containers/com.ziririt.simpletext/Data/shots"
X=80; Y=60; W=1280; H=800
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# 같은 이름의 앱이 둘 떠 있으면 System Events 가 어느 창인지 못 고른다.
pkill -f "Products/Release/Skyblue Note.app" >/dev/null 2>&1
rm -rf "$BOX"; mkdir -p "$BOX" "$OUT"

log "앱을 띄운다(flutter drive)…"
# SHOT_MODE 가 없으면 열쇠고리의 창고 고르기가 살아나 진짜 노트가 섞인다(시험 머리말).
flutter drive -d macos --dart-define=SHOT_MODE=true \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_mac_test.dart \
  > /tmp/shots_mac.log 2>&1 &
DRIVE=$!

# 창이 뜰 때까지 기다렸다가 자리와 크기를 맞춘다.
placed=0
for i in $(seq 1 240); do
  if ! kill -0 $DRIVE 2>/dev/null; then break; fi
  if osascript -e 'tell application "System Events" to tell process "Skyblue Note"' \
       -e 'set frontmost to true' \
       -e "set position of window 1 to {$X, $Y}" \
       -e "set size of window 1 to {$W, $H}" \
       -e 'end tell' >/dev/null 2>&1; then
    placed=1; log "창을 맞췄다"; break
  fi
  sleep 1
done
if [ $placed -ne 1 ]; then log "창을 못 찾았다 — /tmp/shots_mac.log"; fi

n=0
while kill -0 $DRIVE 2>/dev/null; do
  for want in "$BOX"/want_*; do
    [ -e "$want" ] || continue
    name=$(cat "$want")            # ko/01_table
    flat=$(basename "$want"); flat=${flat#want_}
    mkdir -p "$OUT/$(dirname "$name")"
    sleep 0.6
    screencapture -x -R"$X,$Y,$W,$H" "$OUT/$name.png"
    rm -f "$want"; touch "$BOX/done_$flat"
    n=$((n+1)); log "찍었다: $name"
  done
  sleep 0.3
done
wait $DRIVE; rc=$?
log "앱 종료 rc=$rc, $n 장"
# 소유자가 쓰던 개발용 판을 다시 띄운다.
open "$HOME/development/simpletext_app/build/macos/Build/Products/Release/Skyblue Note.app" 2>/dev/null
if [ $n -lt 33 ]; then echo "33장이 아니다($n). /tmp/shots_mac.log 를 볼 것." >&2; exit 1; fi
sips -g pixelWidth -g pixelHeight "$OUT/ko/01_table.png" | tail -2
log "끝. 결과: $OUT"
