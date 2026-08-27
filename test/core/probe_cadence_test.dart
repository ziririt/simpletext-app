import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';

void main() {
  group('짧은 물음의 간격', () {
    test('뜨거운 동안은 3초', () {
      expect(probeEvery(hotUntilMs: 1000, nowMs: 0), const Duration(seconds: 3));
      expect(probeEvery(hotUntilMs: 1000, nowMs: 999),
          const Duration(seconds: 3));
    });

    test('식으면 15초 — 아무도 안 쓰는 새벽에 3초마다 두드리지 않는다', () {
      expect(
          probeEvery(hotUntilMs: 1000, nowMs: 1000), const Duration(seconds: 15));
      expect(probeEvery(hotUntilMs: 0, nowMs: 0), const Duration(seconds: 15));
    });

    test('식은 쪽도 옛 30초 훑기보다 두 배 빠르다', () {
      expect(probeEvery(hotUntilMs: 0, nowMs: 1).inSeconds,
          lessThan(30));
    });

    test('뜨거운 시간은 2분 — 한 문장 주고받기에 넉넉하다', () {
      expect(kProbeHotMs, 2 * 60 * 1000);
    });
  });
}
