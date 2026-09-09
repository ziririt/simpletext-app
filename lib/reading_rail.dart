/// 읽기 눈금 — 오른쪽 가장자리에 서 있는, 지금 어디쯤인지 말해 주는 자.
///
/// 2026-09-09 소유자 신고 — "스크롤 위치를 모르겠다. 문서가 길 때 몇 %정도
/// 남았지를 알고 싶은데, 그리고 지금 읽고 있는 걸 이따 이어서 읽어야지 할 때
/// 현재 위치가 글의 어느 정도 되는지 아는 게 중요하다."
///
/// iOS 기본 스크롤 표시는 **길잡이가 아니라 잔상**이다. 굴릴 때만 잠깐
/// 나타났다 사라지고, 뒤에 아무 눈금도 없어서 '어디쯤'을 말해 주지 못한다.
/// 손잡이 하나만 떠 있으면 사람은 그것이 위쪽인지 아래쪽인지밖에 못 읽는다.
///
/// 그래서 셋을 둔다.
///   1. **눈금(track)** — 글 전체. 늘 보인다. 이것이 있어야 손잡이의 자리가
///      뜻을 갖는다. 눈금이 없는 손잡이는 좌표 없는 점이다.
///   2. **손잡이(thumb)** — 지금 보고 있는 창. **길이가 곧 분량이다.**
///      짧으면 긴 글이고 길면 짧은 글이다. 숫자를 안 읽어도 손이 안다.
///   3. **숫자 딱지** — 굴리는 동안만 뜬다. 62% 처럼.
///
/// 그리고 **책갈피 표시**. core/read_mark.dart 참고.
///
/// 눈금은 잡아서 끌 수 있다(스크러빙). 애플 지침의 직접 조작 원칙대로,
/// 잡은 자리를 그대로 물고 간다 — 손잡이 가운데로 홱 당겨 붙이지 않는다.
/// 그렇게 하면 잡는 순간 글이 튀어서, 조작이 아니라 사고처럼 느껴진다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/read_mark.dart';
import 'main.dart' show AppC, AppColorsX;

class ReadingRail extends StatefulWidget {
  const ReadingRail({
    super.key,
    required this.controller,
    required this.child,
    this.topInset = 0,
    this.bottomInset = 0,
    this.mark,
    this.banner,
    this.enabled = true,
  });

  final ScrollController controller;
  final Widget child;

  /// 유리 머리가 덮는 만큼. 눈금이 그 밑에서 시작해야 딱지가 안 가린다.
  final double topInset;
  final double bottomInset;

  /// 이 글에 끼워 둔 책갈피. 없으면 null.
  final ReadMark? mark;

  /// 머리 밑에 잠깐 뜨는 알림 — '책갈피 62%에서 이어 읽기' 같은 것.
  /// 눈금 위에 얹혀야 해서 여기로 받는다. 없으면 null.
  final Widget? banner;

  /// 끌 수 있게 두는가. 잠긴 메모나 좁은 자리에서는 끈다.
  final bool enabled;

  @override
  State<ReadingRail> createState() => ReadingRailState();
}

class ReadingRailState extends State<ReadingRail> {
  /// 손가락이 닿을 수 있는 폭. 눈에 보이는 것은 3pt 뿐이지만, 3pt 를 겨냥해
  /// 누르라고 하면 아무도 못 잡는다(애플 권장 44 의 절반 남짓까지 줄인 것은
  /// 이것이 화면 맨 가장자리라 바깥쪽으로 빗나갈 일이 없어서다).
  static const double railW = 26;
  static const double trackW = 3;
  static const double thumbW = 3;
  static const double thumbWDrag = 5;
  static const double minThumb = 40;
  static const double pad = 8;

  double _px = 0;
  double _max = 0;
  double _view = 0;

  /// 굴리는 중이거나 잡고 있는 중. 숫자 딱지가 이때만 뜬다.
  bool _hot = false;
  bool _drag = false;
  double _grab = 0;
  Timer? _cool;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_read);
    // 붙기 전에는 물을 수 없다. 첫 배치가 끝난 다음 프레임에 한 번 읽는다 —
    // 이게 없으면 긴 글을 열고 가만히 있을 때 눈금이 안 뜬다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  @override
  void dispose() {
    _cool?.cancel();
    widget.controller.removeListener(_read);
    super.dispose();
  }

  void _read() {
    if (!mounted || !widget.controller.hasClients) return;
    final p = widget.controller.position;
    final px = p.pixels;
    final mx = p.maxScrollExtent;
    final vw = p.viewportDimension;
    if (px == _px && mx == _max && vw == _view) return;
    setState(() {
      _px = px;
      _max = mx;
      _view = vw;
    });
  }

  void _warm() {
    _cool?.cancel();
    if (!_hot) setState(() => _hot = true);
    // 멈추고 나서도 잠깐 남긴다. 굴리기를 멈춘 그 순간이 바로 '지금 어디지'를
    // 묻는 순간이라, 그때 숫자가 사라져 있으면 아무 쓸모가 없다.
    _cool = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_drag) setState(() => _hot = false);
    });
  }

  double get _frac => _max <= 0 ? 0 : (_px / _max).clamp(0.0, 1.0);

  int get _percent =>
      ReadMark(pixels: _px, extent: _max <= 0 ? 1 : _max, at: 0).percent;

  /// 눈금을 보여 줄 만큼 긴 글인가.
  ///
  /// 한 화면 반이 안 되면 굴려 봐야 손가락 한 번이라, 눈금이 도움이 아니라
  /// 장식이다. 글 쓰는 화면에 장식은 두지 않는다.
  bool get _worth => _max > _view * 0.6 && _view > 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      // 글이 길어지거나 글자 크기가 바뀌면 눈금의 뜻이 달라진다. 굴리지
      // 않아도 알아야 한다.
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _read());
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification || n is ScrollStartNotification) {
            _warm();
          }
          _read();
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            Positioned(
              top: widget.topInset,
              bottom: widget.bottomInset,
              right: 0,
              width: railW,
              child: _rail(context),
            ),
            if (widget.banner != null)
              Positioned(
                top: widget.topInset + 8,
                left: 12,
                right: 12,
                child: Center(child: widget.banner),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    if (!_worth) return const SizedBox.shrink();
    final c = context.c;
    final quiet = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(
      builder: (ctx, box) {
        final h = box.maxHeight;
        final trackH = h - pad * 2;
        if (trackH <= minThumb) return const SizedBox.shrink();
        final ratio = _view / (_max + _view);
        var thumbH = trackH * ratio;
        if (thumbH < minThumb) thumbH = minThumb;
        final travel = trackH - thumbH;
        final thumbTop = pad + travel * _frac;

        double? markCenter;
        final m = widget.mark;
        if (m != null && _max > 0) {
          final mf = (m.offsetIn(_max) / _max).clamp(0.0, 1.0);
          markCenter = pad + travel * mf + thumbH / 2;
        }

        void jumpTo(double centerY) {
          final top = (centerY - _grab).clamp(pad, pad + travel);
          if (travel <= 0) return;
          widget.controller.jumpTo(((top - pad) / travel) * _max);
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (d) {
            // 책갈피 표시를 누르면 그 자리로 간다. 눈금 아무 데나 눌러
            // 뛰게 하지는 않는다 — 읽던 자리를 잃는 실수가 너무 쉽다.
            final mc = markCenter;
            if (mc == null) return;
            if ((d.localPosition.dy - mc).abs() > 16) return;
            _goToMark();
          },
          onVerticalDragStart: widget.enabled
              ? (d) {
                  final y = d.localPosition.dy;
                  // 손잡이 밖을 잡았으면 그 자리를 손잡이 가운데로 삼는다.
                  // 손잡이를 잡았으면 **잡은 그 자리를 그대로 물고 간다.**
                  final inThumb = y >= thumbTop && y <= thumbTop + thumbH;
                  _grab = inThumb ? y - thumbTop : thumbH / 2;
                  setState(() {
                    _drag = true;
                    _hot = true;
                  });
                  _cool?.cancel();
                  HapticFeedback.selectionClick();
                  if (!inThumb) jumpTo(y);
                }
              : null,
          onVerticalDragUpdate: widget.enabled
              ? (d) => jumpTo(d.localPosition.dy)
              : null,
          onVerticalDragEnd: widget.enabled
              ? (_) {
                  setState(() => _drag = false);
                  _warm();
                }
              : null,
          onVerticalDragCancel: widget.enabled
              ? () {
                  setState(() => _drag = false);
                  _warm();
                }
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 눈금. 늘 있다 — 이것이 '글 전체'다.
              Positioned(
                top: pad,
                height: trackH,
                right: (railW - trackW) / 2,
                width: trackW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.sub.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(trackW / 2),
                  ),
                ),
              ),
              // 책갈피. 눈금 위에 얹힌 작은 표.
              if (markCenter != null)
                Positioned(
                  top: markCenter - 4,
                  right: (railW - 9) / 2,
                  width: 9,
                  height: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 1.5),
                    ),
                  ),
                ),
              // 손잡이. 길이가 곧 분량이다.
              AnimatedPositioned(
                duration: quiet || _drag
                    ? Duration.zero
                    : const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                top: thumbTop,
                height: thumbH,
                right: (railW - (_drag ? thumbWDrag : thumbW)) / 2,
                width: _drag ? thumbWDrag : thumbW,
                child: AnimatedOpacity(
                  duration: quiet
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  opacity: _hot ? 1.0 : 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _drag ? c.accent : c.guideInk,
                      borderRadius: BorderRadius.circular(thumbWDrag / 2),
                    ),
                  ),
                ),
              ),
              // 숫자 딱지. 손잡이 가운데에 맞춰 왼쪽으로 붙인다.
              Positioned(
                top: (thumbTop + thumbH / 2 - 13).clamp(0.0, h - 26),
                right: railW - 2,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: quiet
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    opacity: _hot ? 1 : 0,
                    child: _chip(c),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(AppC c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: c.panel,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: c.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      '$_percent%',
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: c.guideInk,
        // 숫자가 8 에서 9 로 갈 때 딱지 폭이 흔들리면 눈에 거슬린다.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );

  /// 책갈피 자리로 간다. 밖에서도 부를 수 있게 열어 둔다.
  void goToMark() => _goToMark();

  void _goToMark() {
    final m = widget.mark;
    if (m == null || !widget.controller.hasClients) return;
    final max = widget.controller.position.maxScrollExtent;
    if (max <= 0) return;
    HapticFeedback.selectionClick();
    widget.controller.animateTo(
      m.offsetIn(max),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }
}
