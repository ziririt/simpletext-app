#!/usr/bin/env bash
# 안드로이드 기기 하나를 고른다 — 케이블이 없어도 되게.
#
# 2026-08-17 소유자 요청: "안드로이드도 앞으로는 와이파이에서도 빌드되게 해줘."
#
# 아이폰·아이패드는 이미 무선으로 넣고 있었다. 안드로이드만 케이블이었던
# 것은 기술이 없어서가 아니라 스크립트가 `adb devices`의 첫 줄을 그냥
# 집었기 때문이다. 케이블이 꽂혀 있으면 늘 그것이 첫 줄이다.
#
# 고르는 차례
#   1) 이미 붙어 있는 무선 기기 (mDNS 이름 또는 ip:port)
#   2) 케이블만 있으면 — 그 참에 무선 문을 열어 두고(tcpip 5555) 주소를
#      적어 둔다. 다음부터는 케이블 없이 붙는다
#   3) 아무것도 없으면 mDNS로 찾아 붙이고, 그래도 없으면 마지막으로
#      알던 주소로 붙여 본다
#
# 표준출력에 기기 이름 한 줄. 못 찾으면 아무것도 안 낸다.
# 다른 말(진행 상황)은 전부 표준오류로 보낸다 — 이 값은 그대로
# `flutter install -d` 에 들어가므로 한 줄이어야 한다.

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
[ -x "$ADB" ] || ADB="$(command -v adb)"
[ -x "$ADB" ] || exit 0

LAST="$HOME/.skyblue_android_wifi"

# 무선 기기: 이름이 mDNS 꼴이거나 주소:포트 꼴이다.
wifi_one() {
  "$ADB" devices | awk 'NR>1 && $2=="device" &&
    ($1 ~ /_adb-tls-connect\._tcp$/ || $1 ~ /:[0-9]+$/) {print $1; exit}'
}
usb_one() {
  "$ADB" devices | awk 'NR>1 && $2=="device" &&
    $1 !~ /_adb-tls-connect\._tcp$/ && $1 !~ /:[0-9]+$/ {print $1; exit}'
}

T=$(wifi_one)
if [ -n "$T" ]; then echo "$T"; exit 0; fi

U=$(usb_one)
if [ -n "$U" ]; then
  echo "케이블만 붙어 있다 — 무선 문을 열어 둔다" >&2
  IP=$("$ADB" -s "$U" shell ip -f inet addr show wlan0 2>/dev/null |
       awk '/inet /{split($2,a,"/"); print a[1]; exit}')
  if [ -n "$IP" ]; then
    "$ADB" -s "$U" tcpip 5555 >/dev/null 2>&1
    sleep 2
    "$ADB" connect "$IP:5555" >/dev/null 2>&1
    echo "$IP:5555" > "$LAST"
    W=$(wifi_one)
    if [ -n "$W" ]; then echo "$W"; exit 0; fi
  fi
  # 무선이 안 열렸으면 케이블로라도 간다. 되는 길을 두고 멈추지 않는다.
  echo "$U"; exit 0
fi

echo "붙어 있는 기기가 없다 — 무선으로 찾아본다" >&2
M=$("$ADB" mdns services 2>/dev/null |
    awk '/_adb-tls-connect\._tcp/{print $3; exit}')
[ -n "$M" ] && "$ADB" connect "$M" >/dev/null 2>&1
if [ -f "$LAST" ]; then
  "$ADB" connect "$(cat "$LAST")" >/dev/null 2>&1
fi
sleep 1
wifi_one
