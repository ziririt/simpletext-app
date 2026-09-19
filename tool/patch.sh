#!/bin/bash
# 다트 고침을 스토어 심사 없이 내려보낸다 — Shorebird 덧판(patch).
#
#   bash tool/patch.sh ios          # 아이폰·아이패드
#   bash tool/patch.sh android      # 안드로이드
#   bash tool/patch.sh both
#
# 2026-09-14 소유자 결정 — "심사를 꼭 받지 않아도 되는 고침은 안 받으면 좋겠다.
# 웹앱처럼." 애플 규정 3.3.1(b)·구글 규정이 해석기 위 코드의 갱신은 허락한다.
# 다트가 그것이다. 자세한 것은 docs/셔버드.md.
#
# 덧판은 **스토어에 나가 있는 판(release)**에 붙는다. 그래서
#   · 판 이름·빌드 번호는 지금 스토어 판의 것이어야 한다 — lib/version.dart 를
#     올리지 마라. 올리면 붙일 판을 못 찾는다
#   · dart-define(REAL_ADS·구글 아이디)은 굽던 때와 같아야 한다 — 여기서 같은 값을 준다
#   · 원어 코드·자산·플러그인이 바뀌었으면 덧판이 안 된다. shorebird 가 막는다.
#     그때는 판을 새로 굽는다(appstore_ios.sh / appstore_android.sh)
#   · **새 아이콘 하나도 자산 변경이다.** 아이콘 글꼴은 쓰는 글자만 남기고 깎이므로
#     (tree-shake) 처음 쓰는 아이콘이 들어가면 글꼴 파일이 달라진다. 2026-09-19 첫 덧판이
#     Icons 하나 때문에 거절됐다. 덧판으로 낼 고침에는 앱에 이미 있는 아이콘만 쓴다
#
# 받는 쪽: 앱을 켤 때 받아 두고 **다음에 켤 때** 갈아입는다. 설정 화면 오른쪽 위
# `ver.3.19 (254) · p2` 의 p 숫자가 오르면 갈아입은 것이다.
set -u
cd "$(dirname "$0")/.." || exit 1
WORK="${TMPDIR:-$HOME/.cache/skyblue/}"
case "$WORK" in */) ;; *) WORK="$WORK/" ;; esac
mkdir -p "$WORK"
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$HOME/.shorebird/bin:$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
WHAT="${1:-both}"
NAME="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)"
NUM="$(sed -n 's/^const int appBuild = \([0-9]*\);/\1/p' lib/version.dart)"
log() { echo "[$(date '+%H:%M:%S')] $*"; }
[ -f shorebird.yaml ] || { echo "shorebird.yaml 이 없다. shorebird init 이 먼저다(docs/셔버드.md)." >&2; exit 1; }

DEFINES="--dart-define=REAL_ADS=true"
SECHOME="${SKY_SECRETS_HOME:-$HOME}"
. "$SECHOME/development/_patch/skyblue_keys.env" || exit 1
for k in GOOGLE_WEB_CLIENT_ID GOOGLE_IOS_CLIENT_ID; do
  v=$(eval "printf %s \"\${$k:-}\"")
  [ -n "$v" ] && DEFINES="$DEFINES --dart-define=$k=$v"
done
FV=$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')

one() {
  local plat="$1" extra=""
  [ "$plat" = ios ] && extra="--no-codesign"
  log "덧판 $plat → 판 $NAME+$NUM (flutter $FV)…"
  # shellcheck disable=SC2086
  printf 'y\ny\n' | shorebird patch "$plat" $extra --release-version "$NAME+$NUM" \
    $DEFINES > "${WORK}patch_$plat.log" 2>&1
  local rc=${PIPESTATUS[1]}
  if [ $rc -ne 0 ]; then
    echo "덧판 $plat 실패 rc=$rc — ${WORK}patch_$plat.log" >&2
    grep -i "error\|native\|asset\|not found\|no release" "${WORK}patch_$plat.log" | head -8 >&2
    return 1
  fi
  grep -i "patch\|✓" "${WORK}patch_$plat.log" | tail -3
  log "덧판 $plat 나갔다. 사람들이 다음에 앱을 켤 때 받는다"
}

rc=0
case "$WHAT" in
  ios) one ios || rc=1 ;;
  android) one android || rc=1 ;;
  both) one ios || rc=1; one android || rc=1 ;;
  *) echo "ios | android | both" >&2; exit 2 ;;
esac
exit $rc
