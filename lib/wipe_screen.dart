/// 정리 전·후를 한 화면에서 손가락으로 밀어 견주는 자리.
///
/// 2026-08-27 소유자 확정. 왜 이 기능인지는 core/wipe.dart 머리말에 있다.
/// 여기는 그 셈을 화면으로 옮긴 것뿐이다.
///
/// ## 두 겹을 어떻게 겹치나
///
/// 같은 자리에 글을 두 벌 그리고, 위의 것을 손잡이 오른쪽만 남기고
/// 잘라 낸다. 그러면 손잡이 왼쪽은 정리 전, 오른쪽은 정리 후가 된다.
/// 스크롤은 **하나**다 — 두 벌을 따로 굴리면 아무리 맞춰도 한 줄씩
/// 어긋나고, 어긋나는 순간 이 화면의 요점이 사라진다.
///
/// 높이는 둘 중 긴 쪽이 정한다. 짧은 쪽은 아래가 비는데, 그 빈 자리가
/// 오히려 '이만큼 줄었다'를 말해 준다.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'core/wipe.dart';
import 'rich_note_text.dart';

class WipeView extends StatefulWidget {
  const WipeView({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    required this.fontSize,
    required this.lineHeight,
    this.fontFamily,
  });

  final String before;
  final String after;
  final String beforeLabel;
  final String afterLabel;
  final double fontSize;
  final double lineHeight;
  final String? fontFamily;

  @override
  State<WipeView> createState() => _WipeViewState();
}

class _WipeViewState extends State<WipeView> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  double _x = -1; // 아직 안 정해짐
  double _w = 0;

  /// 놓은 뒤 굴러가는 중. 붙잡으면 그 자리에서 멈춘다.
  Ticker? _ticker;
  double _v = 0; // 초당 화소
  double _target = 0;

  /// 처음 열 때 한 번 쓸어 보인다.
  ///
  /// 사람이 이 화면을 처음 봤을 때 '밀 수 있다'는 것을 말로 설명하지
  /// 않는다. 한 번 움직여 보이면 그것으로 끝난다. 다만 **손이 닿는
  /// 순간 멈춘다** — 보여 주는 중이라고 손가락을 무시하면 그때부터
  /// 화면이 사람 말을 안 듣는 물건이 된다.
  bool _demoDone = false;

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _stopGlide() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  /// 목표까지 미끄러진다. 시간이 아니라 **남은 거리**로 움직여서,
  /// 도중에 목표가 바뀌어도 튀지 않는다(붙잡아 되돌릴 수 있는 까닭).
  void _glideTo(double target) {
    _target = target;
    _stopGlide();
    _ticker = createTicker((_) {
      final d = _target - _x;
      if (d.abs() < 0.5) {
        setState(() => _x = _target);
        _stopGlide();
        return;
      }
      setState(() => _x += d * 0.18);
    })
      ..start();
  }

  void _demo() {
    if (_demoDone || _w <= 0) return;
    _demoDone = true;
    // 왼쪽 끝에서 시작해 오른쪽 끝까지 갔다가 가운데로.
    _x = wipeAt(0.08, _w);
    Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      _glideTo(wipeAt(0.92, _w));
      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _glideTo(wipeAt(0.5, _w));
      });
    });
  }

  TextStyle get _base => TextStyle(
        fontSize: widget.fontSize,
        height: widget.lineHeight,
        letterSpacing: 0,
        fontFamily: widget.fontFamily,
      );

  /// 정리 전 — 표시를 **그대로 보여 준다.** 이게 요점이다. 별표와
  /// 우물정이 글자로 보이는 그 꼴이 사람들이 겪는 그 꼴이다.
  /// 글 위아래 여백. 위를 넉넉히 두는 까닭은 이름표(정리 전/정리 후)가
  /// 첫 줄 위에 앉기 때문이다. 안 두면 이름표가 첫 문장을 덮는다.
  static const double _padTop = 46;
  static const double _padSide = 18;

  Widget _rawPane(Color ink, Color mark) => Padding(
        padding: const EdgeInsets.fromLTRB(_padSide, _padTop, _padSide, 40),
        child: Text(widget.before,
            style: _base.copyWith(color: ink.withValues(alpha: 0.75))),
      );

  /// 정리 후 — 앱이 실제로 그리는 그대로.
  Widget _richPane(Color ink, Color mark) {
    // 2026-08-29 소유자 신고 — "우측 화면은 왼쪽이 살짝 가려진다."
    //
    // 두 벌을 같은 자리에 그려 놓고 위의 것을 손잡이에서 잘랐더니, 오른쪽
    // 글의 **첫 글자가 손잡이 뒤에 숨었다.** '엔비디아'가 '비디아'로,
    // '매크로와 금리'가 '크로와 금리'로 보였다.
    //
    // 사진을 겹치는 와이프였다면 안 생길 일이다. 같은 그림이라 잘린 자리
    // 뒤에도 같은 것이 있으니까. 그런데 여기 두 벌은 **다른 글**이다.
    // 잘린 자리 뒤에 있는 것은 가려도 되는 것이 아니라 읽어야 할 글자다.
    //
    // 그래서 오른쪽 글은 손잡이 뒤에서 시작하지 않고, 손잡이 오른쪽에서
    // 시작한다. 손잡이를 밀면 글이 그만큼 좁아지며 다시 접힌다 — 보이는
    // 만큼만 차지하는 것이 맞다.
    return Padding(
      padding: EdgeInsets.fromLTRB(
          math.max(_padSide, _x + 16), _padTop, _padSide, 40),
      child: RichNoteText(
        text: widget.after,
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        ink: ink,
        mark: mark,
        fontFamily: widget.fontFamily,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context);
    final ink = c.textTheme.bodyMedium?.color ?? Colors.black;
    final mark = ink.withValues(alpha: 0.45);
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth;
      if (_w != w) {
        _w = w;
        if (_x < 0) {
          _x = wipeAt(0.5, w);
          WidgetsBinding.instance.addPostFrameCallback((_) => _demo());
        } else {
          _x = wipeClamp(_x, w);
        }
      }
      final frac = wipeFrac(_x, w);
      return Listener(
        // 손이 닿는 **즉시** 멈춘다. 손을 뗄 때까지 기다리면 그 사이에
        // 화면이 제멋대로 움직이고, 그러면 잡은 느낌이 안 난다.
        onPointerDown: (_) => _stopGlide(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            setState(() => _x = wipeDrag(_x, d.delta.dx, w));
          },
          onHorizontalDragEnd: (d) {
            _v = d.velocity.pixelsPerSecond.dx;
            final to = wipeClamp(wipeProject(_x, _v), w);
            _glideTo(to);
            HapticFeedback.selectionClick();
          },
          onTapUp: (d) => _glideTo(wipeClamp(d.localPosition.dx, w)),
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Stack(
                    children: [
                      _rawPane(ink, mark),
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _RightOf(_x),
                          child: Container(
                            color: c.scaffoldBackgroundColor,
                            alignment: Alignment.topLeft,
                            child: _richPane(ink, mark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _handle(context, ink),
              _tag(context, widget.beforeLabel, left: true, on: 1 - frac),
              _tag(context, widget.afterLabel, left: false, on: frac),
            ],
          ),
        ),
      );
    });
  }

  Widget _handle(BuildContext context, Color ink) {
    final accent = Theme.of(context).colorScheme.primary;
    return Positioned(
      left: _x - 22,
      top: 0,
      bottom: 0,
      width: 44,
      child: IgnorePointer(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 2, height: double.infinity, color: accent),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.code, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 어느 쪽이 무엇인지. 손잡이가 그쪽으로 갈수록 옅어진다 — 덮여
  /// 사라지는 쪽의 이름표가 끝까지 진하면 그게 거짓말이 된다.
  Widget _tag(BuildContext context, String text,
      {required bool left, required double on}) {
    final a = math.max(0.0, math.min(1.0, on));
    return Positioned(
      top: 10,
      left: left ? 14 : null,
      right: left ? null : 14,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.25 + 0.75 * a,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      ),
    );
  }
}

/// [x] 오른쪽만 남긴다.
class _RightOf extends CustomClipper<Rect> {
  const _RightOf(this.x);
  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(x, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf old) => old.x != x;
}
