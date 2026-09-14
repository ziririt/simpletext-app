/// 가장자리 자동 굴림의 셈(core/edge_scroll.dart).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/edge_scroll.dart';

void main() {
  group('edgePlan — 어디에 있나', () {
    test('가운데면 굴리지 않는다', () {
      expect(edgePlan(y: 400, top: 0, bottom: 800), isNull);
    });
    test('위 띠에 들어오면 위로, 깊을수록 1에 가깝다', () {
      final p = edgePlan(y: 10, top: 0, bottom: 800)!;
      expect(p.dir, -1);
      expect(p.depth, closeTo((72 - 10) / 72, 1e-9));
    });
    test('아래 띠에 들어오면 아래로', () {
      final p = edgePlan(y: 790, top: 0, bottom: 800)!;
      expect(p.dir, 1);
      expect(p.depth, closeTo((790 - 728) / 72, 1e-9));
    });
    test('띠의 안쪽 경계에서는 깊이 0', () {
      expect(edgePlan(y: 72, top: 0, bottom: 800)!.depth, 0);
      expect(edgePlan(y: 728, top: 0, bottom: 800)!.depth, 0);
    });
    test('화면 밖으로 나가도 깊이는 1을 넘지 않는다', () {
      expect(edgePlan(y: -50, top: 0, bottom: 800)!.depth, 1);
      expect(edgePlan(y: 900, top: 0, bottom: 800)!.depth, 1);
    });
    test('창이 좁으면 띠를 반씩 나눈다', () {
      // 100 높이 → 띠 50. 가운데(50)는 위 띠의 경계이자 아래 띠의 경계.
      expect(edgePlan(y: 20, top: 0, bottom: 100)!.dir, -1);
      expect(edgePlan(y: 80, top: 0, bottom: 100)!.dir, 1);
    });
  });

  group('edgeSpeed — 얼마나 빨리', () {
    test('막 들어왔을 때는 느리다', () {
      final v = edgeSpeed(held: Duration.zero, depth: 1);
      expect(v, kEdgeSlow);
    });
    test('충분히 머물면 빠르다', () {
      final v = edgeSpeed(held: const Duration(seconds: 3), depth: 1);
      expect(v, kEdgeFast);
    });
    test('시간이 갈수록 단조롭게 빨라진다', () {
      var last = 0.0;
      for (var ms = 0; ms <= 1500; ms += 100) {
        final v = edgeSpeed(held: Duration(milliseconds: ms), depth: 1);
        expect(v, greaterThanOrEqualTo(last));
        last = v;
      }
    });
    test('처음 0.3초는 아직 느린 편이다 — 스친 손가락은 한두 줄만', () {
      final v = edgeSpeed(held: const Duration(milliseconds: 300), depth: 1);
      // smoothstep(0.2) = 0.104 → 48 + 672*0.104 ≈ 118
      expect(v, lessThan(130));
    });
    test('얕게 들어오면 같은 시간에도 느리다', () {
      final deep = edgeSpeed(held: const Duration(seconds: 1), depth: 1);
      final shallow = edgeSpeed(held: const Duration(seconds: 1), depth: 0);
      expect(shallow, closeTo(deep * 0.35, 1e-9));
    });
  });
}
