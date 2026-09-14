#!/bin/bash
# 플레이 스토어용 꾸러미(AAB)를 굽고 올린다 — 아이폰 쪽(appstore_ios.sh)의 짝.
#
#   bash tool/appstore_android.sh                 # 굽고 alpha 트랙에 올려 내보낸다
#   TRACK=production bash tool/appstore_android.sh
#   SKIP_UPLOAD=1 bash tool/appstore_android.sh   # 굽기만
#
# 2026-09-14 신설. 그전엔 인수인계서의 명령 두 줄을 손으로 쳤다.
# shorebird.yaml 이 있으면 shorebird 로 굽는다(아이폰 쪽 주석과 같은 까닭, docs/셔버드.md).
# 자바는 안드로이드 스튜디오 안의 것을 쓴다 — /usr/libexec/java_home 은 거짓말을 한다.
set -u
cd "$(dirname "$0")/.." || exit 1
WORK="${TMPDIR:-$HOME/.cache/skyblue/}"
case "$WORK" in */) ;; *) WORK="$WORK/" ;; esac
mkdir -p "$WORK"
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$HOME/.shorebird/bin:$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
NAME="${1:-$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)}"
NUM="${2:-$(sed -n 's/^const int appBuild = \([0-9]*\);/\1/p' lib/version.dart)}"
TRACK="${TRACK:-alpha}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "플레이 빌드 $NAME (빌드 $NUM)"

DEFINES="--dart-define=REAL_ADS=true"
SECHOME="${SKY_SECRETS_HOME:-$HOME}"
KEYS="$SECHOME/development/_patch/skyblue_keys.env"
if [ -f "$KEYS" ]; then
  . "$KEYS"
  for k in GOOGLE_WEB_CLIENT_ID GOOGLE_IOS_CLIENT_ID; do
    v=$(eval "printf %s \"\${$k:-}\"")
    if [ -n "$v" ]; then DEFINES="$DEFINES --dart-define=$k=$v"; fi
  done
else
  echo "키 파일이 없다($KEYS). 이대로 올리면 구글 로그인이 죽는다." >&2
  exit 1
fi

AAB=build/app/outputs/bundle/release/app-release.aab
rm -f "$AAB"
if [ -f shorebird.yaml ] && command -v shorebird >/dev/null 2>&1; then
  FV=$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')
  log "shorebird release android (flutter $FV)…"
  # shellcheck disable=SC2086
  printf 'y\ny\n' | shorebird release android --flutter-version "$FV" \
    --build-name="$NAME" --build-number="$NUM" $DEFINES \
    > ${WORK}appstore_android_build.log 2>&1
  RC=${PIPESTATUS[1]}
else
  log "flutter build appbundle…"
  # shellcheck disable=SC2086
  flutter build appbundle --release \
    --build-name="$NAME" --build-number="$NUM" $DEFINES \
    > ${WORK}appstore_android_build.log 2>&1
  RC=$?
fi
log "빌드 끝 rc=$RC"
if [ ! -f "$AAB" ]; then
  echo "AAB 가 없다. ${WORK}appstore_android_build.log 를 볼 것." >&2
  tail -20 ${WORK}appstore_android_build.log >&2
  exit 1
fi
log "AAB: $(du -h "$AAB" | cut -f1)"
if [ "${SKIP_UPLOAD:-}" = "1" ]; then log "올리지 않는다(SKIP_UPLOAD=1)"; exit 0; fi
/usr/bin/python3 tool/play_upload.py --track "$TRACK" --go --commit
