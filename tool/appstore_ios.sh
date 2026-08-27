#!/usr/bin/env bash
# 아이폰 스토어 제출용 빌드 → 아카이브 내보내기 → App Store Connect 업로드.
#
# 2026-08-28 신설. 그동안 이 일은 저장소 밖(~/development/_patch/ipaN.sh)의
# 일회용 스크립트로 했다. 한 번 쓰고 버리는 파일이라 지난번에 무엇을 실었는지
# 다음 사람이 알 수 없었고, 실제로 **키를 안 실은 판이 스토어로 갈 뻔했다.**
# 절차는 저장소 안에 있어야 한다.
#
#   bash tool/appstore_ios.sh            # 버전은 lib/version.dart 에서 읽는다
#   bash tool/appstore_ios.sh 3.8.0 202  # 직접 정하고 싶을 때
#
# ── 반드시 지키는 것 ────────────────────────────────────────────────
#
# 1) 마케팅 버전(CFBundleShortVersionString)은 **직전에 올린 것보다 커야**
#    업로드가 받아들여진다. 스토어 화면에 보이는 버전 이름(1.3 …)과는 다른
#    값이다. 지금까지 올린 것 중 가장 큰 것: 2.7.6 / 빌드 165.
# 2) 빌드 번호는 절대 안 내린다. 같은 번호는 두 번 못 올린다.
# 3) 구글 로그인 아이디를 안 실으면 **빌드는 성공하는데 로그인만 조용히
#    죽는다**(2026-08-25 사고). tool/deploy.sh 와 같은 자리에서 읽는다.
# 4) 스토어로 가는 판에만 REAL_ADS=true. 개발 기기 설치판은 테스트 광고를
#    쓴다 — 제 광고를 누르면 애드몹 계정이 정지된다.
# 5) PAID_TIER 는 안 싣는다. 유료 체계는 아직 안 켰다(lib/main.dart 의
#    kPaidTierLive 머리말 참고). 켤 때가 오면 여기 한 줄이 는다.
set -u
cd "$(dirname "$0")/.." || exit 1
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

NAME="${1:-$(sed -n "s/^const String appVersion = '\(.*\)';/\1/p" lib/version.dart)}"
NUM="${2:-$(sed -n 's/^const int appBuild = \([0-9]*\);/\1/p' lib/version.dart)}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "스토어 빌드 $NAME ($NUM)"

DEFINES="--dart-define=REAL_ADS=true"
KEYS="$HOME/development/_patch/skyblue_keys.env"
if [ -f "$KEYS" ]; then
  # shellcheck source=/dev/null
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
# 사파리에서 앱으로 되돌아오는 문. deploy.sh 와 같은 셈이다.
REV="com.googleusercontent.apps.${GOOGLE_IOS_CLIENT_ID%%.apps.googleusercontent.com}"
printf '// tool 이 만든 파일이다. 손으로 고치지 말 것.\nGOOGLE_IOS_REVERSED = %s\n' \
  "$REV" > ios/Flutter/Skyblue.xcconfig

log "flutter build ipa…"
# shellcheck disable=SC2086
flutter build ipa --release --build-name="$NAME" --build-number="$NUM" $DEFINES \
  > /tmp/appstore_ios_build.log 2>&1
RC=$?
log "빌드 끝 rc=$RC"
if [ ! -d build/ios/archive/Runner.xcarchive ]; then
  echo "아카이브가 없다. /tmp/appstore_ios_build.log 를 볼 것." >&2
  tail -20 /tmp/appstore_ios_build.log >&2
  exit 1
fi

# 서명·내보내기는 App Store Connect API 키로 한다. Xcode 에 로그인된 계정이
# 없어도 되고, 사람이 창을 열 필요도 없다.
# shellcheck source=/dev/null
. "$HOME/.appstoreconnect/asc.env"
P8="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
cat > /tmp/ExportAuto.plist <<'PLIST'
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
rm -rf build/ios/ipa
log "아카이브 내보내기…"
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist /tmp/ExportAuto.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$P8" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" > /tmp/appstore_ios_export.log 2>&1
log "내보내기 rc=$?"

IPA=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [ -z "$IPA" ]; then
  echo "IPA 가 안 나왔다. /tmp/appstore_ios_export.log 를 볼 것." >&2
  tail -20 /tmp/appstore_ios_export.log >&2
  exit 1
fi
log "올린다: $IPA"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  >> /tmp/appstore_ios_export.log 2>&1
log "업로드 rc=$?"
tail -3 /tmp/appstore_ios_export.log
log "끝. 애플이 처리하는 데 5~30분 걸린다 — python3 tool/review_status.py 로 확인."
