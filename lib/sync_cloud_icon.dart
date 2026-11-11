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

  /// 2026-11-12 셋째 판. 소유자: "가운데 화살표를 모르겠다, 구름도 구름 같지
  /// 않다. 구글 동기화 아이콘 구름으로." 외곽선을 버리고 꽉 찬 구름에 화살표를
  /// 뚫는다. 작은 크기에서는 선보다 면이 훨씬 잘 읽힌다.
  /// 왼쪽 작은 봉우리, 가운데 큰 봉우리, 오른쪽 중간 봉우리, 평평한 바닥.
  static Path cloud() {
    Path circle(double x, double y, double r) =>
        Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    var p = circle(6.3, 14.9, 4.6);
    p = Path.combine(PathOperation.union, p, circle(12.4, 10.0, 6.6));
    p = Path.combine(PathOperation.union, p, circle(18.4, 14.4, 5.1));
    p = Path.combine(
      PathOperation.union,
      p,
      Path()..addRect(const Rect.fromLTRB(6.3, 13.0, 18.4, 19.5)),
    );
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 24, 24), Paint());
    canvas.drawPath(cloud(), Paint()..color = color);

    // 도는 화살표 두 개를 구름에서 파낸다.
    const cx = 12.4, cy = 13.2, r = 3.9;
    final cut = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.butt;
    final cutFill = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: const Offset(cx, cy), radius: r);
    for (final start in [195.0, 15.0]) {
      final a0 = start * math.pi / 180;
      const sweep = 120 * math.pi / 180;
      canvas.drawArc(rect, a0, sweep, false, cut);
      final a = a0 + sweep;
      final px = cx + r * math.cos(a), py = cy + r * math.sin(a);
      // 진행 방향(시계 방향 접선)과 바깥쪽 법선.
      final dx = -math.sin(a), dy = math.cos(a);
      final nx = math.cos(a), ny = math.sin(a);
      const tip = 2.2, half = 2.0, back = 0.1;
      canvas.drawPath(
        Path()
          ..moveTo(px + dx * tip, py + dy * tip)
          ..lineTo(px + nx * half - dx * back, py + ny * half - dy * back)
          ..lineTo(px - nx * half - dx * back, py - ny * half - dy * back)
          ..close(),
        cutFill,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SyncCloudPainter old) => old.color != color;
}
