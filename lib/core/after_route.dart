/// 화면이 밀려 들어오는 동안에는 무거운 일을 시작하지 않는다.
///
/// 2026-09-09 소유자 신고 — "메뉴와 편집화면 왔다갔다하는 슬라이딩이 너무
/// 버벅거린다. 드르르르하는 듯."
///
/// 화면 녹화를 60fps 로 받아 중복 프레임을 걷어내고 새 프레임 사이의 간격을
/// 재 봤다. 미는 구간이 두 번 있었는데 둘 다 같은 모양이었다.
///
///   83 · 17 · 32 · 33 · 17…17 · 33 · 67 · 67 · 50 · 83 · 33 · 17…
///   67 · 17 · 17 · 33 · 33 · 17…17 · 83 · 67 · 33
///
/// 17ms 가 60fps 다. 미는 동안 대부분은 멀쩡한데 두 군데서 무너진다.
/// 하나는 첫 프레임(60~83ms), 다른 하나는 **밀기가 끝날 무렵**이다.
/// 뒤엣것의 정체는 화면이 뜨자마자 도는 일들이었다 — 첨부 파일이 실제로
/// 있는지 디스크 뒤지기, iCloud 한 바퀴, 그리고 광고 배너(네이티브 뷰)를
/// 새로 만들기. 셋 다 밀기가 아직 끝나지 않았는데 시작한다.
///
/// 그래서 '들어오는 애니메이션이 끝났는가'를 한 곳에서 판단한다.
/// addPostFrameCallback 은 **첫 프레임 다음**이라 여기서는 너무 이르다.
/// 우리가 기다려야 하는 것은 프레임이 아니라 **전환**이다.
///
/// ── 여기서 한 번 속았다 (2026-09-09) ──────────────────────────────────
///
/// 처음엔 이렇게 짰다 — "지금 상태가 completed 면 애니메이션이 없는
/// 화면이니 바로 시작한다." 검사가 전부 떨어졌다. 미는 도중인데도 일이
/// 시작됐다. 상태를 찍어 보니 이랬다.
///
///   didChangeDependencies 시점 = completed
///   그 직후                    = forward   ← 진짜 신호는 여기서 온다
///   첫 프레임 뒤               = forward
///
/// 까닭은 ModalRoute.animation 이 **ProxyAnimation** 이기 때문이다. 화면이
/// 만들어지는 순간에는 아직 진짜 컨트롤러가 안 꽂혀 있고, 그 자리를
/// kAlwaysCompleteAnimation 이 지키고 있다. 그래서 '끝났다'고 답한다.
/// **한 번 읽은 상태를 믿으면 안 된다.** 신호를 듣고 판단해야 한다.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// 이 화면이 밀려 들어오는 애니메이션이 끝나면 [run] 을 한 번 부른다.
///
/// - 애니메이션이 아예 없는 화면(첫 화면, 두 칸 화면의 오른쪽 칸)이면
///   두 프레임 뒤에 부른다. 지금 이 자리에서 곧바로 부르면 build 도중
///   setState 가 되어 터진다.
/// - 화면이 사라지면 부르지 않는다. [isAlive] 로 확인한다(보통 State.mounted).
/// - 어떤 까닭으로든 끝났다는 신호가 안 오면 [fallback] 뒤에 그냥 부른다.
///   광고가 영영 안 뜨는 것보다는 늦게라도 뜨는 게 낫다.
///
/// **돌려주는 것을 dispose 에서 반드시 불러라.** 안 부르면 기다리던 타이머가
/// 화면보다 오래 산다. 위젯 검사는 그걸 실패로 잡는다("A Timer is still
/// pending even after the widget tree was disposed") — 검사가 까다로운 게
/// 아니라, 사라진 화면의 일을 붙들고 있는 것이 실제로 새는 것이기 때문이다.
VoidCallback afterRouteSettled(
  BuildContext context,
  bool Function() isAlive,
  VoidCallback run, {
  Duration fallback = const Duration(milliseconds: 900),
}) {
  var done = false;
  var sawMotion = false;
  Timer? timer;
  AnimationStatusListener? listener;
  final anim = ModalRoute.of(context)?.animation;

  void cleanup() {
    timer?.cancel();
    timer = null;
    if (listener != null && anim != null) {
      anim.removeStatusListener(listener!);
    }
    listener = null;
  }

  void fire() {
    if (done) return;
    done = true;
    cleanup();
    if (isAlive()) run();
  }

  void fireNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => fire());
  }

  if (anim == null) {
    fireNextFrame();
    return () {
      done = true;
      cleanup();
    };
  }

  listener = (AnimationStatus s) {
    if (s == AnimationStatus.forward || s == AnimationStatus.reverse) {
      sawMotion = true;
    } else if (s == AnimationStatus.completed && sawMotion) {
      // 끝난 그 프레임에 바로 일을 시작하면 마지막 프레임이 길어진다.
      // 한 프레임 더 보내고 시작한다.
      fireNextFrame();
    }
  };
  anim.addStatusListener(listener!);

  // 애니메이션이 아예 없는 화면인지는 **두 프레임 뒤에** 판단한다.
  // 그때까지도 움직인 적이 없고 여전히 끝나 있으면 진짜로 없는 것이다.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!sawMotion && anim.status == AnimationStatus.completed) fire();
    });
  });

  timer = Timer(fallback, fire);

  return () {
    done = true;
    cleanup();
  };
}
