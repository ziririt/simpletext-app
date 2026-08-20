#!/usr/bin/env bash
# Skyblue Note — 개발자 버전 무선 배포. 2026-08-16 신설.
#
# 왜 flutter run이 아니라 flutter install인가:
#   flutter run은 (1) 설치 (2) 앱 실행 (3) 디버거 부착 을 다 한다. 무선
#   연결에서는 (3)이 자주 타임아웃 나면서 "Error running application on
#   ..."을 뱉는데, 정작 설치는 이미 끝나 있다. 우리는 개발자 버전을 기기에
#   넣기만 하면 되므로 install이면 충분하고, 훨씬 안정적이다.
#   (2026-08-16: run으로 다섯 번 연속 튕긴 뒤 install로 바꿔 한 번에 성공)
#
# 주의: --no-codesign으로 빌드해 두면 install이 실패한다(서명 없는 .app은
#   기기에 못 올린다). 반드시 서명 포함으로 빌드할 것.
#
# 사용법:
#   bash tool/deploy.sh          # 아이폰 + 아이패드 + 안드로이드 + 맥 전부
#   bash tool/deploy.sh iphone
#   bash tool/deploy.sh ipad
#   bash tool/deploy.sh android
#   bash tool/deploy.sh mac
#   bash tool/deploy.sh web      # ezlong.com/skybluenote/web/ 자리로
#
# web 은 'all' 에 안 들어간다. 나머지 넷은 내 기기에 개발판을 넣는
# 일이지만 web 은 **남이 보는 자리로 나가는 일**이다. 무게가 다르다.
set -u
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
cd ~/development/simpletext_app || exit 1

# 어느 Xcode 로 지을 것인가 — 이름으로 못 박는다.
#
# 2026-08-18 — 같은 맥에서 다른 앱 작업이 Xcode 27 베타를 나란히 깔았다.
# 공존 자체는 문제가 없다. 문제는 xcode-select 가 **맥 전체에 하나뿐인
# 설정**이라는 것이다. 저쪽에서 기본을 베타로 바꾸면 이 배포도 아무 말 없이
# 베타 도구로 지어진다.
#
# 그렇게 지어진 앱은 겉보기에 멀쩡하다. 새 SDK 로 지으면 화면 가장자리
# 처리나 시스템 메뉴 같은 것이 조용히 달라지는데, 우리는 코드를 안 건드렸으니
# 그쪽을 의심하지 않는다 — 원인을 찾기 가장 어려운 종류의 고장이다.
#
# 일부러 베타로 지어 볼 때는 밖에서 지정한다.
#   SKYBLUE_XCODE=/Applications/Xcode-beta.app bash tool/deploy.sh iphone
# **바꾸는 것과 흘러드는 것은 다르다.**
XC="${SKYBLUE_XCODE:-/Applications/Xcode.app}"
if [ -d "$XC/Contents/Developer" ]; then
  export DEVELOPER_DIR="$XC/Contents/Developer"
  echo "[Xcode] $XC — $(/usr/bin/xcodebuild -version 2>/dev/null | head -1)"
else
  echo "[Xcode] $XC 를 못 찾았다. 맥이 정한 기본을 그대로 쓴다"
fi

IPHONE=00008140-000C11100113001C   # Ziririt iPhone 16

# 구글 로그인에 쓰는 클라이언트 아이디 — 저장소 밖에서 읽는다.
#
# 2026-08-20. 이 아이디는 비밀이 아니다(앱 안에 어차피 들어간다).
# 그래도 공개 저장소에는 안 넣는다. 저장소를 그대로 복사한 사람이
# 형님 계정의 이름표를 달고 다니게 되고, 구글 쪽 사용량과 경고가
# 형님 앞으로 온다. **비밀이 아닌 것과 남에게 줘도 되는 것은 다르다.**
#
# 파일이 없으면 없는 대로 짓는다. 그렇게 지은 판은 구글 로그인만
# 안 되고 나머지는 다 된다 — 짓기 자체가 멈추는 것보다 낫다.
DEFINES=""
KEYS="$HOME/development/_patch/skyblue_keys.env"
if [ -f "$KEYS" ]; then
  # shellcheck source=/dev/null
  . "$KEYS"
  for k in GOOGLE_WEB_CLIENT_ID GOOGLE_IOS_CLIENT_ID; do
    v=$(eval "printf %s \"\${$k:-}\"")
    if [ -n "$v" ]; then DEFINES="$DEFINES --dart-define=$k=$v"; fi
  done
fi
# 애플 쪽은 --dart-define 만으로 안 된다. 로그인 창이 사파리로 열렸다가
# **앱으로 되돌아와야** 하고, 그 문은 Info.plist 에 적혀 있어야 한다.
# 그 값을 저장소에 안 넣으려고, 지을 때마다 여기서 만들어 끼운다.
#
# 되돌아올 주소는 아이디를 거꾸로 뒤집은 것이다:
#   763616465188-abc.apps.googleusercontent.com
#   → com.googleusercontent.apps.763616465188-abc
if [ -n "${GOOGLE_IOS_CLIENT_ID:-}" ]; then
  REV="com.googleusercontent.apps.${GOOGLE_IOS_CLIENT_ID%%.apps.googleusercontent.com}"
  for f in ios/Flutter/Skyblue.xcconfig macos/Runner/Configs/Skyblue.xcconfig; do
    printf '// tool/deploy.sh 가 만든 파일이다. 손으로 고치지 말 것.\nGOOGLE_IOS_REVERSED = %s\n' "$REV" > "$f"
  done
  echo "[구글] 애플 기기가 되돌아올 문을 달았다"
else
  rm -f ios/Flutter/Skyblue.xcconfig macos/Runner/Configs/Skyblue.xcconfig
  echo "[구글] iOS 아이디가 없다 — 아이폰·아이패드·맥의 구글 로그인은 안 되는 판이 된다"
fi

if [ -z "$DEFINES" ]; then
  echo "[구글] 클라이언트 아이디가 없다 — 구글 드라이브 로그인은 안 되는 판이 된다"
else
  echo "[구글] 클라이언트 아이디를 실었다"
fi
IPAD=00008027-001A64441107002E     # 김성동의 iPad pro (12.9 3세대)
WHAT="${1:-all}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

if [ "$WHAT" = "all" ] || [ "$WHAT" = "iphone" ] || [ "$WHAT" = "ipad" ]; then
  log "iOS 서명 빌드…"
  if ! flutter build ios --release $DEFINES > /tmp/dep_ios.log 2>&1; then
    log "iOS 빌드 실패 — /tmp/dep_ios.log 확인"; tail -20 /tmp/dep_ios.log; exit 1
  fi
  log "iOS 빌드 완료"
fi

# 설치하고, **기기에 되물어서** 실제로 몇 판이 올라갔는지 찍는다.
#
# 2026-08-17 사고: 아이폰만 다섯 판 뒤처진 채로 "배포 완료" 보고가 나갔다.
# 스크립트가 "설치 명령이 오류를 안 냈다"를 "설치됐다"로 옮겨 적고 있었기
# 때문이다. 둘은 다른 말이다. 이제 마지막에 기기가 스스로 말한 판 번호를
# 찍는다 — 그 줄이 없으면 그 기기는 배포된 것이 아니다.
#
# 무선 설치는 첫 시도에 자주 실패한다(아이패드에서 NWError 60 을 여러 번
# 봤다). 한 번 실패했다고 멈추면 그날 그 기기만 옛 판으로 남는다. 세 번
# 두드린다.
# 시한을 둔 설치.
#
# 2026-08-18 — 아이패드가 자고 있어서 'Waiting for ... to connect...' 에서
# 12분을 서 있었고, 그 뒤에 줄 서 있던 안드로이드와 맥이 통째로 밀렸다.
# 두 번 겪고 고친다.
#
# 한 기기가 자고 있다고 나머지 기기가 못 받는 것은 배포 도구의 흠이다.
# **기다림에도 끝이 있어야 한다.**
#
# macOS 에는 timeout 명령이 없다(2026-08-17에 확인). 뒤로 돌리고 지켜보다가
# 시한이 지나면 끊는다. flutter install 은 자식을 낳으므로 이름으로 한 번 더
# 훑어 정리한다 — 부모만 끊으면 자식이 남아 다음 기기를 또 막는다.
install_try() { # $1=udid $2=이름 $3=시한(초)
  flutter install --release -d "$1" > "/tmp/dep_$2.log" 2>&1 &
  local pid=$! w=0
  while kill -0 "$pid" 2>/dev/null && [ "$w" -lt "$3" ]; do
    sleep 3
    w=$((w + 3))
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    sleep 1
    pkill -f "flutter install --release -d $1" >/dev/null 2>&1
    echo "== $3초 안에 응답 없음 — 끊었다 ==" >> "/tmp/dep_$2.log"
    return 1
  fi
  wait "$pid"
}

# 기기에 깔린 판을 묻는다. 안 깔려 있으면 빈 글자.
installed_version() { # $1=udid
  xcrun devicectl device info apps --device "$1" \
      --bundle-id com.ziririt.simpletext 2>/dev/null |
    awk '/com.ziririt.simpletext/{print $(NF-1)"."$NF}'
}

# 기기가 대답을 하는가. 붙지도 않은 기기에 설치를 **시작조차 하지 않기**
# 위한 물음이다.
#
# 2026-08-19 밤 사고의 핵심이 여기다. 옛 코드는 곧바로 flutter install 을
# 던지고 90초 뒤에 끊었는데, 그 사이 iOS 는 이미 옛 앱을 치워 놓은 뒤였다.
# 치우고 못 넣으면 앱은 사라진다.
device_awake() { # $1=udid
  xcrun devicectl device info apps --device "$1" \
      --bundle-id com.ziririt.simpletext >/dev/null 2>&1
}

install_to() { # $1=udid $2=이름
  # (가) 아예 안 붙는 기기 — 손도 안 댄다. 이 갈래는 안전하다.
  if ! device_awake "$1"; then
    log "$2 — 기기가 대답을 안 한다(잠겼거나 그물 밖). 손도 안 댔다"
    return 1
  fi

  # 붙기는 붙었다. 여기서부터는 **앱을 잃을 수 있는 구간**이다.
  local before
  before=$(installed_version "$1")

  # 시한을 90에서 240으로 늘렸다. 무선으로 40MB짜리를 넣는 데 90초는
  # 빠듯하다 — 넉넉지 않은 시한이 곧 앱을 지우는 칼이 됐다.
  local i ok=0
  for i in 1 2 3; do
    log "$2 설치 중… (시도 $i)"
    if install_try "$1" "$2" 240 &&
       ! grep -q "Install failed" "/tmp/dep_$2.log"; then
      ok=1; break
    fi
    # (나) 붙어서 설치하다 끊겼다. **건너뛰지 않는다.** 되묻고 다시 한다.
    if grep -q "응답 없음" "/tmp/dep_$2.log"; then
      if [ -n "$before" ] && [ -z "$(installed_version "$1")" ]; then
        log "$2 ** 끊긴 자리에서 앱이 사라졌다 — 곧바로 다시 넣는다 **"
      else
        log "$2 — 시한을 넘겨 끊었다. 다시 해 본다"
      fi
    fi
    tail -3 "/tmp/dep_$2.log"
    sleep 7
  done

  # 여기가 이 함수의 존재 이유다. 명령이 아니라 기기에게 묻는다.
  local V
  V=$(installed_version "$1")
  if [ -n "$V" ]; then
    log "$2 확인: 기기가 $V 라고 답했다"
    return 0
  fi
  # 앱이 없다. 있다가 없어진 것이면 사고다 — 조용히 넘어가면 안 된다.
  if [ -n "$before" ]; then
    log "$2 ****** 앱이 기기에서 사라졌다. 손으로 확인할 것 ($before 였다) ******"
  else
    log "$2 설치 실패 — 기기에 앱이 없다"
  fi
  return 1
}

[ "$WHAT" = "all" ] || [ "$WHAT" = "iphone" ] && install_to "$IPHONE" iphone
[ "$WHAT" = "all" ] || [ "$WHAT" = "ipad" ] && install_to "$IPAD" ipad

# ── 안드로이드 ─────────────────────────────────────────────────────────
# 2026-08-17에 들어왔다. 그전까지 안드로이드는 이 파일에 없어서, 판을 낼
# 때마다 따로 스크립트를 만들어 넣고 있었다. 따로 만든 스크립트는 기기를
# 빠뜨린다 — 그날 아이폰이 그렇게 다섯 판 뒤처졌다. 네 기기를 한 파일에
# 두는 것이 이 대목의 목적이다.
#
# 기기 고르기는 tool/android_target.sh 가 한다(무선 우선, 없으면 케이블).
if [ "$WHAT" = "all" ] || [ "$WHAT" = "android" ]; then
  ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
  [ -x "$ADB" ] || ADB="$(command -v adb)"
  T=$(bash tool/android_target.sh 2>/dev/null)
  if [ -z "${T:-}" ]; then
    log "안드로이드 기기를 못 찾았다 — 건너뛴다"
  elif ! flutter build apk --release $DEFINES > /tmp/dep_apk.log 2>&1; then
    log "APK 빌드 실패 — /tmp/dep_apk.log 확인"; tail -20 /tmp/dep_apk.log
  else
    "$ADB" -s "$T" install -r build/app/outputs/flutter-apk/app-release.apk \
      > /tmp/dep_and.log 2>&1
    if grep -qi success /tmp/dep_and.log; then
      "$ADB" -s "$T" shell monkey -p com.ziririt.simpletext \
        -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
      sleep 5
      # 아이폰·아이패드와 같은 규칙 — 기기에게 되묻는다.
      AV=$("$ADB" -s "$T" shell dumpsys package com.ziririt.simpletext 2>/dev/null |
           awk -F= '/versionName/{print $2; exit}' | tr -d '\r')
      AP=$("$ADB" -s "$T" shell pidof com.ziririt.simpletext 2>/dev/null | tr -d '\r')
      log "안드로이드 확인: 기기가 ${AV:-?} 라고 답했다 (pid ${AP:-안 떴음})"
    else
      log "안드로이드 설치 실패:"; tail -4 /tmp/dep_and.log
    fi
  fi
fi

if [ "$WHAT" = "all" ] || [ "$WHAT" = "mac" ]; then
  log "맥 빌드…"
  if flutter build macos --release $DEFINES > /tmp/dep_mac.log 2>&1; then
    pkill -f "Products/Release/Skyblue Note.app" >/dev/null 2>&1
    sleep 1
    # 따옴표를 뺀 채로 두면 'Skyblue' 와 'Note.app' 두 조각으로 갈라진다.
    # 번들 이름에 공백이 있다는 것을 잊기 쉬운 자리다.
    open "$HOME/development/simpletext_app/build/macos/Build/Products/Release/Skyblue Note.app"
    # 'open' 은 열리지 않아도 조용하다. 이 한 줄이 없어서 몇 주 동안
    # "맥 재실행 완료"가 거짓말을 했다(2026-08-16). 살아 있는지 본다.
    sleep 4
    if pgrep -f "Products/Release/Skyblue Note.app" >/dev/null 2>&1; then
      log "맥 재실행 완료 (pid $(pgrep -f 'Products/Release/Skyblue Note.app' | head -1))"
    else
      log "맥 앱이 안 떴다 — 번들 이름이나 경로를 확인할 것"
    fi
  else
    log "맥 빌드 실패 — /tmp/dep_mac.log 확인"; tail -20 /tmp/dep_mac.log
  fi
fi

if [ "$WHAT" = "web" ]; then
  # 웹은 어디에 얹히는지를 빌드할 때 정해야 한다. ezlong.com 은 이 앱을
  # /skybluenote/web/ 아래에 둔다. 이 값이 틀리면 화면은 뜨는데 글꼴과
  # 그림만 404 가 난다 — 고장 난 줄도 모르고 지나치기 좋은 모양이다.
  log "웹 빌드…"
  if flutter build web --release --base-href /skybluenote/web/ $DEFINES \
      > /tmp/dep_web.log 2>&1; then
    OUT="$HOME/Developer/ezlong/skybluenote/web"
    if [ -d "$OUT" ]; then
      # --delete 를 주는 까닭: 플러터는 빌드마다 파일 이름이 바뀐다.
      # 지우지 않으면 옛 조각이 남아 어느 것이 지금 것인지 알 수 없게 된다.
      rsync -a --delete build/web/ "$OUT/"
      log "웹 올림: $(cat "$OUT/version.json" 2>/dev/null)"
      log "  ↑ 아직 사이트에는 안 나갔다. ezlong 저장소에 커밋·푸시해야 한다."
    else
      log "웹 — ezlong 자리가 없다($OUT). 짓기만 하고 안 옮겼다"
    fi
  else
    log "웹 빌드 실패 — /tmp/dep_web.log 확인"; tail -20 /tmp/dep_web.log
  fi
fi

log "끝. 버전: $(grep -m1 appVersion lib/version.dart)"

# ── 새 기기를 처음 붙일 때 (2026-08-16 아이패드에서 겪은 순서) ──────
# 세 단계에서 연달아 막혔다. 다음에 새 기기를 붙이면 그대로 밟으면 된다.
#
# 1) unpaired
#    xcrun devicectl list devices          # Identifier(UUID) 확인
#    xcrun devicectl manage pair --device <UUID>
#
# 2) 개발자 모드 꺼짐 — 원격으로는 못 켠다. 기기에서 직접:
#    설정 > 개인정보 보호 및 보안 > 개발자 모드 > 켬 > 재시동 >
#    잠금 해제 직후 뜨는 팝업에서 '켜기' + 암호.
#    이 마지막 팝업까지 해야 실제로 켜진다(여기서 한 번 헛돌았다).
#    확인: xcrun devicectl device info details --device <UUID> | grep developerModeStatus
#    주의: devicectl의 device info는 캐시가 남는다. xcrun xcdevice list 도 같이 볼 것.
#
# 3) 프로비저닝 프로파일에 그 기기가 없음
#    (a) 개발자 계정에 기기 등록 — App Store Connect API로 가능:
#        POST /v1/devices  {name, platform: "IOS", udid}
#        (udid는 flutter devices가 보여주는 00008027-... 형식)
#        ~/.appstoreconnect/asc.py 헬퍼 사용.
#    (b) 프로파일 재발급 — 여기가 함정이다.
#        xcodebuild -allowProvisioningUpdates 는 "No Accounts"로 실패한다.
#        CLI가 Xcode에 저장된 개발자 계정을 못 읽기 때문이다(계정은 분명
#        있는데도). 해결: Xcode를 GUI로 열고 실행 대상을 그 기기로 바꾼 뒤
#        Cmd+B. 그러면 "iOS Team Provisioning Profile: *"가 그 기기를
#        포함해 다시 발급된다.
#        확인: ~/Library/Developer/Xcode/UserData/Provisioning Profiles/ 의
#        .mobileprovision을 security cms -D 로 풀어 ProvisionedDevices 확인.

# ---------------------------------------------------------------------------
# 2026-08-16 — 자격(entitlement)을 추가한 뒤 서명이 깨질 때
#
# 증상:
#   Provisioning profile "iOS Team Provisioning Profile: *" doesn't include
#   the iCloud capability.
#
# 원인은 와일드카드 프로파일이다. 지금까지 개발 설치는 App ID 없이 와일드카드
# (*)로 돌고 있었는데, 와일드카드에는 iCloud 같은 자격을 붙일 수 없다. 정식
# App ID용 프로파일을 새로 받아야 한다.
#
# 그냥 -allowProvisioningUpdates만 주면 "No Accounts"로 실패한다. Xcode에
# 계정이 들어 있어도 그렇다(2026-08-15에 겪음). App Store Connect API 키로
# 인증을 붙이면 계정 없이 통과한다 — 이게 답이다:
#
#   cd ios
#   xcodebuild -workspace Runner.xcworkspace -scheme Runner \
#     -configuration Release -destination 'generic/platform=iOS' \
#     -allowProvisioningUpdates \
#     -authenticationKeyPath   ~/.appstoreconnect/private_keys/AuthKey_*.p8 \
#     -authenticationKeyID     <KEY_ID> \
#     -authenticationKeyIssuerID <ISSUER> \
#     build
#
# 한 번 성공하면 프로파일이 로컬에 저장되고, 그 뒤로는 flutter build ios가
# 그냥 된다. 자격을 또 바꾸면 이 절차를 다시 밟아야 한다.
#
# 값은 ~/.appstoreconnect/asc.py 안에 있다. import로 읽으려다 실패한 적이
# 있는데(그 파이썬에 PyJWT가 없으면 asc.py가 최상단에서 죽는다), 그러면 빈
# 문자열이 조용히 넘어가 원인 모를 실패가 된다. 정규식으로 상수만 뽑는 게 낫다.
# ---------------------------------------------------------------------------
