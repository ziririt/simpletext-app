/// AI 성좌 — 내 글들이 밤하늘에 별로 뜬다.
///
/// 2026-08-29. 무엇을 어떻게 잇는지는 core/constellation.dart 가 정하고,
/// 여기는 그 결과를 그리기만 한다.
///
/// ## 이 화면의 3초
///
/// 열면 별들이 흩어진 채로 시작해 제자리를 찾아간다. 그 3초가 이 기능의
/// 전부다. 정지 그림만 보여 주면 '점과 선'이지만, 모여드는 것을 보면
/// 사람은 거기서 자기 글의 지도를 본다.
///
/// 자리는 **미리 다 계산해 놓고** 그 사이를 채워 움직인다. 물리 셈을
/// 매 프레임 돌리면 별 백 개에서 손이 걸린다. 어차피 사람이 보는 것은
/// 도착점이지 중간 과정의 정확성이 아니다.
///
/// ## 외톨이 별을 버리지 않는다
///
/// 소유자 노트 110편 실측에서 서른 편은 아무와도 안 이어졌다. 그것들을
/// 안 그리면 '내 글이 사라졌다'가 되고, 한가운데 섞어 두면 그물이
/// 지저분해진다. 그래서 **바깥 둘레에 옅게** 둔다 — 아직 이웃을 못 찾은
/// 별이라는 뜻이 자리로 읽힌다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constellation.dart';

/// 별 하나가 알아야 할 것.
class Star {
  const Star({
    required this.id,
    required this.title,
    required this.source,
    required this.size,
    required this.fresh,
  });

  final String id;
  final String title;

  /// 출처 이름. 빈 글자면 직접 쓴 글이다.
  final String source;

  /// 0~1. 글이 길수록 크다.
  final double size;

  /// 0~1. 최근일수록 밝다.
  final double fresh;
}

class ConstellationView extends StatefulWidget {
  const ConstellationView({
    super.key,
    required this.stars,
    required this.points,
    required this.links,
    required this.onOpen,
    required this.colorOf,
  });

  final List<Star> stars;

  /// 0~1 로 편 자리. stars 와 같은 차례.
  final List<Pt> points;
  final List<Link> links;
  final void Function(String id) onOpen;
  final Color Function(String source) colorOf;

  @override
  State<ConstellationView> createState() => _ConstellationViewState();
}

class _ConstellationViewState extends State<ConstellationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  final _view = TransformationController();

  /// 지금 밝혀 둔 별. -1이면 다 밝다.
  int _picked = -1;

  late final List<Pt> _from = _scatter();

  List<Pt> _scatter() {
    // 시작 자리도 씨앗을 쓴다. 열 때마다 다른 데서 날아오면 같은 화면을
    // 두 번 본 느낌이 안 난다.
    final r = math.Random(11);
    return [
      for (var i = 0; i < widget.points.length; i++)
        Pt(0.5 + (r.nextDouble() - 0.5) * 1.4,
            0.5 + (r.nextDouble() - 0.5) * 1.4)
    ];
  }

  @override
  void dispose() {
    _in.dispose();
    _view.dispose();
    super.dispose();
  }

  /// 화면 위 한 점에서 가장 가까운 별. 없으면 -1.
  int _hit(Offset p, Size size) {
    final t = _in.value;
    var best = -1;
    var bestD = 34.0 * 34.0;
    for (var i = 0; i < widget.points.length; i++) {
      final o = _at(i, size, t);
      final dx = o.dx - p.dx, dy = o.dy - p.dy;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  Offset _at(int i, Size size, double t) {
    final a = _from[i], b = widget.points[i];
    // 별마다 조금씩 늦게 출발한다. 다 같이 움직이면 한 덩어리로 보인다.
    final lag = (i % 7) * 0.03;
    final k = ((t - lag) / (1 - lag)).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(k);
    const pad = 44.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    return Offset(pad + (a.x + (b.x - a.x) * e) * w,
        pad + (a.y + (b.y - a.y) * e) * h);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      return InteractiveViewer(
        transformationController: _view,
        minScale: 0.6,
        maxScale: 5,
        boundaryMargin: const EdgeInsets.all(200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final i = _hit(d.localPosition, size);
            if (i < 0) {
              if (_picked >= 0) setState(() => _picked = -1);
              return;
            }
            // 한 번 누르면 밝히고, 밝힌 별을 또 누르면 그 글로 간다.
            // 손가락으로 겨냥한 것이 맞는지 눈으로 확인한 뒤에 열리는
            // 것이라, 잘못 눌러 엉뚱한 글로 가는 일이 없다.
            if (_picked == i) {
              widget.onOpen(widget.stars[i].id);
              return;
            }
            HapticFeedback.selectionClick();
            setState(() => _picked = i);
          },
          child: AnimatedBuilder(
            animation: _in,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _SkyPainter(
                stars: widget.stars,
                links: widget.links,
                at: (i) => _at(i, size, _in.value),
                picked: _picked,
                colorOf: widget.colorOf,
                t: _in.value,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.stars,
    required this.links,
    required this.at,
    required this.picked,
    required this.colorOf,
    required this.t,
  });

  final List<Star> stars;
  final List<Link> links;
  final Offset Function(int i) at;
  final int picked;
  final Color Function(String source) colorOf;
  final double t;

  bool _near(int i) {
    if (picked < 0) return true;
    if (i == picked) return true;
    for (final l in links) {
      if (l.a == picked && l.b == i) return true;
      if (l.b == picked && l.a == i) return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── 실 ──
    //
    // 실을 먼저 그린다. 별 위에 실이 지나가면 별이 실에 꿰인 것처럼
    // 보인다. 밤하늘에서 별은 늘 실보다 앞에 있다.
    final line = Paint()..style = PaintingStyle.stroke;
    for (final l in links) {
      final on = picked < 0 || l.a == picked || l.b == picked;
      final a = at(l.a), b = at(l.b);
      // 실은 별이 자리를 잡은 뒤에 나타난다. 처음부터 그리면 날아다니는
      // 실이 화면을 뒤덮는다.
      final fade = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      line
        ..strokeWidth = 0.6 + l.w * 1.8
        ..color = Colors.white.withValues(
            alpha: (0.10 + l.w * 0.34) * fade * (on ? 1 : 0.15));
      canvas.drawLine(a, b, line);
    }

    // ── 별 ──
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final dot = Paint();
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final o = at(i);
      final on = _near(i);
      final c = colorOf(s.source);
      final r = 2.4 + s.size * 5.2 + (i == picked ? 2.2 : 0);
      final alpha = (0.45 + s.fresh * 0.55) * (on ? 1 : 0.18);
      glow.color = c.withValues(alpha: alpha * 0.40);
      canvas.drawCircle(o, r * 2.1, glow);
      dot.color = c.withValues(alpha: alpha);
      canvas.drawCircle(o, r, dot);
      // 가운데 흰 점 하나. 이게 있으면 색이 있어도 '별'로 읽힌다.
      dot.color = Colors.white.withValues(alpha: alpha * 0.75);
      canvas.drawCircle(o, r * 0.38, dot);
    }

    // ── 고른 별의 이름 ──
    if (picked >= 0 && picked < stars.length) {
      final o = at(picked);
      final tp = TextPainter(
        text: TextSpan(
          text: stars[picked].title,
          style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              color: Colors.white,
              fontWeight: FontWeight.w700),
        ),
        maxLines: 2,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 180);
      final box = Rect.fromLTWH(
          o.dx - tp.width / 2 - 8, o.dy + 14, tp.width + 16, tp.height + 10);
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(8)),
          Paint()..color = Colors.black.withValues(alpha: 0.62));
      tp.paint(canvas, Offset(box.left + 8, box.top + 5));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.t != t || old.picked != picked || old.links != links;
}
