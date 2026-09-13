#!/bin/bash
# 맥 앱스토어에 올릴 판을 굽고 올린다 — 아이폰 쪽(appstore_ios.sh)을 그대로 본떴다.
#
#   bash tool/appstore_mac.sh            # 판 이름·빌드 번호는 저장소가 정한다
#   bash tool/appstore_mac.sh 3.18 251   # 손으로 줄 수도 있다
#   UPLOAD_ONLY=1 bash tool/appstore_mac.sh  # 굽지 않고 build/macos/pkg 의 것을 다시 올린다
#
# 처음 올릴 때 걸린 것(2026-09-13): "Cannot determine the Apple ID from Bundle ID
# ... and platform 'MAC_OS'". 앱 기록에 macOS 판이 하나도 없으면 애플이 받을 자리를
# 못 찾는다. **먼저 python3 tool/mac_store.py --prepare 로 맥 판을 만들고** 올려라.
#
# 그리고 한 번 올리다 죽은 빌드 번호는 **죽었어도 쓴 번호다.** 251 은 파일이
# 올라가기 전에 실패했는데도 애플 쪽에 '251 은 이미 왔다'로 남아 다음 시도가
# "must be higher than 251"로 막혔다. 실패하면 번호를 올려서 다시 굽는다
# (lib/version.dart 의 appBuild 와 pubspec.yaml 두 곳).
#
# 2026-09-13 신설. 소유자 신고 — "맥 앱스토어에 맥용 앱이 없더라." 맞는 말이었다.
# 지금까지 맥 판은 tool/deploy.sh mac 이 이 맥북에만 굽던 개발용이었다.
#
# 아이폰과 다른 곳 세 군데:
#   - 'flutter build ipa' 같은 한 방이 없다. flutter build macos 로 짓고,
#     xcodebuild archive 로 보관함을 만들고, 내보내기로 .pkg 를 뽑는다
#   - 맥 앱스토어 판은 .ipa 가 아니라 .pkg 다. 그 .pkg 는 '설치용 인증서'로
#     따로 서명된다. 없으면 -allowProvisioningUpdates 가 API 열쇠로 만들어 온다
#   - altool 의 -t 가 ios 가 아니라 macos 다
#
# 번들 id 는 아이폰과 같다(com.ziririt.simpletext). 같아야 한 번 산 사람이
# 맥에서도 그대로 쓴다(유니버설 구매). **바꾸지 마라.**
set -u
cd "$(dirname "$0")/.." || exit 1
WORK="${TMPDIR:-$HOME/.cache/skyblue/}"
case "$WORK" in */) ;; *) WORK="$WORK/" ;; esac
mkdir -p "$WORK" || { echo "임시 자리를 못 만들었다: $WORK" >&2; exit 1; }
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

NAME="${1:-$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)}"
NUM="${2:-$(sed -n 's/^const int appBuild = \([0-9]*\);/\1/p' lib/version.dart)}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "맥 스토어 빌드 $NAME (빌드 $NUM)"

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
if [ -z "${GOOGLE_IOS_CLIENT_ID:-}" ]; then
  echo "GOOGLE_IOS_CLIENT_ID 가 비었다. 멈춘다." >&2
  exit 1
fi
# 구글 로그인이 사파리에서 앱으로 되돌아오는 문. 맥도 아이폰과 같은 길이다.
REV="com.googleusercontent.apps.${GOOGLE_IOS_CLIENT_ID%%.apps.googleusercontent.com}"
printf '// tool 이 만든 파일이다. 손으로 고치지 말 것.\nGOOGLE_IOS_REVERSED = %s\n' \
  "$REV" > macos/Runner/Configs/Skyblue.xcconfig

. "$SECHOME/.appstoreconnect/asc.env"
P8="$SECHOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
AUTH="-allowProvisioningUpdates -authenticationKeyPath $P8 -authenticationKeyID $ASC_KEY_ID -authenticationKeyIssuerID $ASC_ISSUER_ID"

ARCH=build/macos/archive/Runner.xcarchive
if [ "${UPLOAD_ONLY:-}" = "1" ]; then
  PKG=$(ls build/macos/pkg/*.pkg 2>/dev/null | head -1)
  [ -n "$PKG" ] || { echo "다시 올릴 PKG 가 없다(build/macos/pkg)." >&2; exit 1; }
  log "굽지 않고 있는 것을 올린다: $PKG"
  xcrun altool --upload-app -f "$PKG" -t macos \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" > ${WORK}appstore_mac_upload.log 2>&1
  RC=$?
  tail -3 ${WORK}appstore_mac_upload.log
  [ $RC -eq 0 ] && log "올렸다. 애플이 처리하는 데 5~30분 걸린다." || log "업로드 실패 rc=$RC"
  exit $RC
fi
rm -rf "$ARCH" build/macos/pkg

# 1) 플러터가 코드를 굽고 xcconfig(판 이름·번호·dart-define)를 쓴다.
log "flutter build macos…"
flutter build macos --release \
  --build-name="$NAME" --build-number="$NUM" $DEFINES \
  > ${WORK}appstore_mac_build.log 2>&1
RC=$?
log "빌드 끝 rc=$RC"
if [ $RC -ne 0 ]; then
  echo "플러터 빌드가 실패했다. ${WORK}appstore_mac_build.log 를 볼 것." >&2
  tail -20 ${WORK}appstore_mac_build.log >&2
  exit 1
fi

# 2) 보관함. 서명은 자동 — 없는 프로파일·인증서는 API 열쇠로 만들어 온다.
log "xcodebuild archive…"
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=macOS' \
  archive -archivePath "$ARCH" $AUTH \
  > ${WORK}appstore_mac_archive.log 2>&1
log "보관함 rc=$?"
APP="$ARCH/Products/Applications/Skyblue Note.app"
if [ ! -d "$APP" ]; then
  echo "보관함이 없다. ${WORK}appstore_mac_archive.log 를 볼 것." >&2
  grep -n "error:" ${WORK}appstore_mac_archive.log | head -20 >&2
  tail -20 ${WORK}appstore_mac_archive.log >&2
  exit 1
fi
PLIST="$APP/Contents/Info.plist"
GOT_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null)
GOT_NUM=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST" 2>/dev/null)
if [ "$GOT_NAME" != "$NAME" ] || [ "$GOT_NUM" != "$NUM" ]; then
  echo "보관함 안의 판이 다르다." >&2
  echo "  바란 것: $NAME ($NUM)" >&2
  echo "  들어 있는 것: ${GOT_NAME:-없음} (${GOT_NUM:-없음})" >&2
  exit 1
fi
log "보관함 확인: $GOT_NAME ($GOT_NUM)"

# 3) 내보내기 — 맥 앱스토어용 .pkg
cat > ${WORK}ExportMac.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>ZK846VZN92</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
log "내보내기…"
xcodebuild -exportArchive -archivePath "$ARCH" -exportPath build/macos/pkg \
  -exportOptionsPlist ${WORK}ExportMac.plist $AUTH \
  > ${WORK}appstore_mac_export.log 2>&1
log "내보내기 rc=$?"
PKG=$(ls build/macos/pkg/*.pkg 2>/dev/null | head -1)
if [ -z "$PKG" ]; then
  echo "PKG 가 안 나왔다. ${WORK}appstore_mac_export.log 를 볼 것." >&2
  grep -n "error" ${WORK}appstore_mac_export.log | head -20 >&2
  tail -20 ${WORK}appstore_mac_export.log >&2
  exit 1
fi

if [ "${SKIP_UPLOAD:-}" = "1" ]; then
  log "올리지 않는다(SKIP_UPLOAD=1). 여기 있다: $PKG"
  exit 0
fi

# 4) 올리기
log "올린다: $PKG"
xcrun altool --upload-app -f "$PKG" -t macos \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  >> ${WORK}appstore_mac_export.log 2>&1
RC=$?
tail -3 ${WORK}appstore_mac_export.log
if [ $RC -ne 0 ]; then
  echo "업로드가 실패했다(rc=$RC). 맥 판이 아직 없으면 tool/mac_store.py --prepare 먼저." >&2
  exit 1
fi
log "끝. 애플이 처리하는 데 5~30분 걸린다."
