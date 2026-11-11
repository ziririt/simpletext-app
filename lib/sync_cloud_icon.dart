import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 2026-11-12 — 동기화 아이콘. 머티리얼 cloud_sync 는 화살표와 구름이
/// 따로 놀아 무슨 뜻인지 한눈에 안 들어왔다. 누구나 아는 모양, 구름 안에
/// 도는 화살표 두 개로 직접 그린다. 24칸 격자, 선 굵기는 머티리얼
/// 외곽선 아이콘과 비슷하게 맞췄다.
class SyncCloudIcon extends StatelessWidget {
  const SyncCloudIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SyncCloudPainter(c)),
    );
  }
}

class _SyncCloudPainter extends CustomPainter {
  _SyncCloudPainter(this.color);

  final Color color;

  /// 구름 윤곽. 원 셋과 바닥 사각형을 합쳐 외곽선만 남긴다.
  static Path cloud() {
    Path circle(double x, double y, double r) =>
        Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    var p = circle(7.0, 14.7, 3.8);
    p = Path.combine(PathOperation.union, p, circle(12.6, 10.4, 5.5));
    p = Path.combine(PathOperation.union, p, circle(17.6, 14.3, 4.2));
    p = Path.combine(
      PathOperation.union,
      p,
      Path()..addRect(const Rect.fromLTRB(7.0, 13.0, 17.6, 18.5)),
    );
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    // 11-12 "인식 어렵다, 더 크게." 24칸을 꽉 채우도록 그림 전체를 키운다.
    // 선 굵기는 키운 만큼 나눠 다른 아이콘과 같은 무게를 지킨다.
    const grow = 1.2;
    canvas.translate(12, 12.3);
    canvas.scale(grow);
    canvas.translate(-12, -11.7);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75 / grow
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cloud(), line);

    // 도는 화살표 두 개. 구름 몸통 한가운데.
    const cx = 12.3, cy = 13.1, r = 3.6;
    final arrow = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 / grow
      ..strokeCap = StrokeCap.round;
    final head = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: const Offset(cx, cy), radius: r);
    for (final start in [200.0, 20.0]) {
      final a0 = start * math.pi / 180;
      const sweep = 115 * math.pi / 180;
      canvas.drawArc(rect, a0, sweep, false, arrow);
      final a = a0 + sweep;
      final px = cx + r * math.cos(a), py = cy + r * math.sin(a);
      // 진행 방향(시계 방향 접선)과 바깥쪽 법선.
      final dx = -math.sin(a), dy = math.cos(a);
      final nx = math.cos(a), ny = math.sin(a);
      const tip = 1.75, half = 1.55, back = 0.2;
      canvas.drawPath(
        Path()
          ..moveTo(px + dx * tip, py + dy * tip)
          ..lineTo(px + nx * half - dx * back, py + ny * half - dy * back)
          ..lineTo(px - nx * half - dx * back, py - ny * half - dy * back)
          ..close(),
        head,
      );
    }
  }

  @override
  bool shouldRepaint(_SyncCloudPainter old) => old.color != color;
}
