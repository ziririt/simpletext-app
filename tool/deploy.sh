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
#   bash tool/deploy.sh          # 아이폰 + 아이패드 + 맥 전부
#   bash tool/deploy.sh iphone
#   bash tool/deploy.sh ipad
#   bash tool/deploy.sh mac
set -u
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
cd ~/development/simpletext_app || exit 1

IPHONE=00008140-000C11100113001C   # Ziririt iPhone 16
IPAD=00008027-001A64441107002E     # 김성동의 iPad pro (12.9 3세대)
WHAT="${1:-all}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

if [ "$WHAT" = "all" ] || [ "$WHAT" = "iphone" ] || [ "$WHAT" = "ipad" ]; then
  log "iOS 서명 빌드…"
  if ! flutter build ios --release > /tmp/dep_ios.log 2>&1; then
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
install_to() { # $1=udid $2=이름
  local i ok=0
  for i in 1 2 3; do
    log "$2 설치 중… (시도 $i)"
    if flutter install --release -d "$1" > "/tmp/dep_$2.log" 2>&1 &&
       ! grep -q "Install failed" "/tmp/dep_$2.log"; then
      ok=1; break
    fi
    tail -3 "/tmp/dep_$2.log"
    sleep 7
  done
  [ "$ok" = 1 ] || { log "$2 설치 실패 — 세 번 다 안 됐다"; return 1; }

  # 여기가 이 함수의 존재 이유다. 명령이 아니라 기기에게 묻는다.
  local V
  V=$(xcrun devicectl device info apps --device "$1" \
        --bundle-id com.ziririt.simpletext 2>/dev/null |
      awk '/com.ziririt.simpletext/{print $(NF-1)"."$NF}')
  if [ -n "$V" ]; then
    log "$2 확인: 기기가 $V 라고 답했다"
  else
    log "$2 설치는 됐다는데 기기에 되물으니 답이 없다 — 눈으로 확인할 것"
  fi
}

[ "$WHAT" = "all" ] || [ "$WHAT" = "iphone" ] && install_to "$IPHONE" iphone
[ "$WHAT" = "all" ] || [ "$WHAT" = "ipad" ] && install_to "$IPAD" ipad

if [ "$WHAT" = "all" ] || [ "$WHAT" = "mac" ]; then
  log "맥 빌드…"
  if flutter build macos --release > /tmp/dep_mac.log 2>&1; then
    pkill -f "Products/Release/Skyblue Note.app" >/dev/null 2>&1
    sleep 1
    open ~/development/simpletext_app/build/macos/Build/Products/Release/Skyblue Note.app
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
