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

# 로그와 임시 plist 자리. 예전에는 /tmp 에 고정 이름으로 뒀는데, 이 맥은
# 계정이 둘이라(HANDOFF.md 2.1절) 다른 계정이 먼저 만든 /tmp/appstore_ios_*.log
# 를 덮어쓰지 못해 **빌드가 시작도 못 하고 죽었다**(2026-09-09).
# macOS 의 TMPDIR 은 계정마다 다른 자리라 부딪히지 않는다. 다만 nohup 으로
# 띄우면 TMPDIR 이 비어 있을 수 있어, 그때는 /tmp 가 아니라 홈 밑으로 간다.
WORK="${TMPDIR:-$HOME/.cache/skyblue/}"
case "$WORK" in */) ;; *) WORK="$WORK/" ;; esac
mkdir -p "$WORK" || { echo "임시 자리를 못 만들었다: $WORK" >&2; exit 1; }
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

NAME="${1:-$(sed -n "s/^const String appVersion = '\(.*\)';/\1/p" lib/version.dart)}"
NUM="${2:-$(sed -n 's/^const int appBuild = \([0-9]*\);/\1/p' lib/version.dart)}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "스토어 빌드 $NAME ($NUM)"

# ── 굽기 전 그물: kStoreVersion 이 이번에 붙을 판 이름과 맞는가 ────────
#
# 2026-09-11 신설. 설정의 '최신 버전 확인'은 lib/version.dart 의
# kStoreVersion 을 애플이 알려 주는 스토어 이름과 견준다. 그 상수가
# 틀린 채 구워지면 **이미 최신인 사람에게 "새 판이 있다"고 말하는 앱**이
# 나간다. 앱이 거짓말을 하는 것이라 값이 싸지 않다.
#
# 굽기 전이 유일하게 값싸게 고칠 수 있는 자리다. 올린 뒤에는 다시 구워
# 올리는 수밖에 없다. 그래서 여기서 멈춘다.
#
# 애플에 못 물어보면(열쇠 없음·네트워크 없음) 막지 않는다 — 빌드를
# 네트워크에 매다는 쪽이 더 나쁘다. 대신 못 봤다고 말한다.
STOREV="$(sed -n "s/^const String kStoreVersion = '\(.*\)';/\1/p" lib/version.dart)"
WANT="$(/usr/bin/python3 tool/submit_next.py --nextname 2>/dev/null | tail -1 | tr -d '[:space:]')"
if [ -z "$WANT" ]; then
  log "판 이름을 애플에 못 물어봤다 — kStoreVersion($STOREV) 검사는 건너뛴다"
elif [ "$STOREV" != "$WANT" ]; then
  echo "" >&2
  echo "멈춘다. lib/version.dart 의 kStoreVersion 이 '$STOREV' 인데," >&2
  echo "이번에 스토어에 붙을 판 이름은 '$WANT' 다." >&2
  echo "" >&2
  echo "설정의 '최신 버전 확인'이 이 값을 쓴다. 이대로 구우면 이미 최신인" >&2
  echo "사람에게 새 판이 있다고 말하는 앱이 된다." >&2
  echo "" >&2
  echo "  lib/version.dart 의 kStoreVersion 을 '$WANT' 로 고치고 다시 친다." >&2
  echo "" >&2
  exit 1
else
  log "kStoreVersion $STOREV — 이번에 붙을 판 이름과 맞다"
fi

DEFINES="--dart-define=REAL_ADS=true"
# 열쇠가 다른 계정 홈에 있을 때(예: aladin 이 돌리고 열쇠는 ziririt) 덮어쓸 수 있게.
SECHOME="${SKY_SECRETS_HOME:-$HOME}"
KEYS="$SECHOME/development/_patch/skyblue_keys.env"
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

# 옛 아카이브를 먼저 지운다. 남겨 두면 이번 빌드가 실패해도 '아카이브가
# 있다'가 되어 **지난번 판이 스토어로 나간다**(2026-09-09 사고, 아래).
rm -rf build/ios/archive

log "flutter build ipa…"
# --no-codesign 인 까닭 (2026-09-09):
#   flutter build ipa 는 아카이브를 만든 뒤 제 손으로 서명까지 하려 든다.
#   그때 맥의 Xcode 에 로그인된 개발 계정과 유효한 Apple Development 인증서를
#   찾는다. 이 맥에는 둘 다 없다 —
#     Signing certificate ... is not valid for code signing.
#     No Accounts: Add a new account in Accounts settings.
#   그런데 우리는 그 서명이 필요 없다. 스토어로 갈 서명은 바로 아래에서
#   App Store Connect API 키로 한다. 그래서 여기서는 아예 서명하지 않는다.
# shellcheck disable=SC2086
flutter build ipa --release --no-codesign \
  --build-name="$NAME" --build-number="$NUM" $DEFINES \
  > ${WORK}appstore_ios_build.log 2>&1
RC=$?
log "빌드 끝 rc=$RC"
if [ ! -d build/ios/archive/Runner.xcarchive ]; then
  echo "아카이브가 없다. ${WORK}appstore_ios_build.log 를 볼 것." >&2
  tail -20 ${WORK}appstore_ios_build.log >&2
  exit 1
fi

# ── 아카이브가 정말 이번 것인지 확인한다 (2026-09-09 사고) ────────────
#
# 그날 무슨 일이 있었나. flutter build ipa 가 서명에서 실패했는데 이 자리의
# 검사가 '폴더가 있느냐' 하나뿐이었다. 이틀 전 아카이브가 남아 있었고,
# 그래서 검사를 통과했다. 그 옛 판이 내보내져 스토어로 올라갔고 **애플
# 심사까지 통과해 출시됐다.** 그 안에는 그날 고친 코드가 없었다.
#
# 올라간 뒤에야 알았다 — App Store Connect 에서 빌드 224 의 버전 문자열이
# 3.17.2 가 아니라 223 과 같은 3.17.1 이었다.
#
# 빌드가 실패하는 것은 괜찮다. 고치면 된다. **실패했는데 성공한 것처럼
# 보이는 것**이 값비싸다. 그러니 여기서 판을 직접 열어 확인한다.
PLIST=build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist
GOT_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null)
GOT_NUM=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST" 2>/dev/null)
if [ "$GOT_NAME" != "$NAME" ] || [ "$GOT_NUM" != "$NUM" ]; then
  echo "아카이브 안의 판이 다르다. 지난 아카이브를 올릴 뻔했다." >&2
  echo "  바란 것: $NAME ($NUM)" >&2
  echo "  들어 있는 것: ${GOT_NAME:-없음} (${GOT_NUM:-없음})" >&2
  echo "  ${WORK}appstore_ios_build.log 를 볼 것." >&2
  tail -20 ${WORK}appstore_ios_build.log >&2
  exit 1
fi
log "아카이브 확인: $GOT_NAME ($GOT_NUM)"

# 서명·내보내기는 App Store Connect API 키로 한다. Xcode 에 로그인된 계정이
# 없어도 되고, 사람이 창을 열 필요도 없다.
# shellcheck source=/dev/null
. "$SECHOME/.appstoreconnect/asc.env"
P8="$SECHOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
cat > ${WORK}ExportAuto.plist <<'PLIST'
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
  -exportOptionsPlist ${WORK}ExportAuto.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$P8" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" > ${WORK}appstore_ios_export.log 2>&1
log "내보내기 rc=$?"

IPA=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [ -z "$IPA" ]; then
  echo "IPA 가 안 나왔다. ${WORK}appstore_ios_export.log 를 볼 것." >&2
  tail -20 ${WORK}appstore_ios_export.log >&2
  exit 1
fi
log "올린다: $IPA"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  >> ${WORK}appstore_ios_export.log 2>&1
log "업로드 rc=$?"
tail -3 ${WORK}appstore_ios_export.log
log "끝. 애플이 처리하는 데 5~30분 걸린다 — python3 tool/review_status.py 로 확인."
