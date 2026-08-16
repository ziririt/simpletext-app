import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/lock.dart';

void main() {
  group('언제 잠그는가 (2026-08-16)', () {
    test('꺼 놨으면 언제나 안 잠근다', () {
      expect(
          shouldLock(enabled: false, leftAtMs: 0, nowMs: 1000, graceSec: 0),
          isFalse);
      expect(
          shouldLock(
              enabled: false, leftAtMs: 1, nowMs: 99999999, graceSec: 300),
          isFalse);
    });

    test('앱을 새로 켠 것이면 봐주는 시간과 상관없이 잠근다', () {
      // 앱이 죽었다 살아난 것이라 '잠깐 나갔다 온 것'이 아니다.
      expect(
          shouldLock(enabled: true, leftAtMs: 0, nowMs: 1000, graceSec: 300),
          isTrue);
    });

    test("'바로'는 나갔다 오면 무조건 잠근다", () {
      expect(
          shouldLock(
              enabled: true, leftAtMs: 1000, nowMs: 1001, graceSec: kLockNow),
          isTrue);
    });

    test('봐주는 시간 안에 돌아오면 안 잠근다', () {
      // 1분짜리, 59초 만에 복귀.
      expect(
          shouldLock(
              enabled: true,
              leftAtMs: 100000,
              nowMs: 100000 + 59 * 1000,
              graceSec: kLockAfter1m),
          isFalse);
    });

    test('봐주는 시간을 넘기면 잠근다 — 딱 맞는 순간도 잠근다', () {
      expect(
          shouldLock(
              enabled: true,
              leftAtMs: 100000,
              nowMs: 100000 + 60 * 1000,
              graceSec: kLockAfter1m),
          isTrue);
      expect(
          shouldLock(
              enabled: true,
              leftAtMs: 100000,
              nowMs: 100000 + 301 * 1000,
              graceSec: kLockAfter5m),
          isTrue);
    });

    test('시계를 뒤로 돌리면 잠근다 — 봐주는 시간을 우회하는 가장 쉬운 길', () {
      expect(
          shouldLock(
              enabled: true,
              leftAtMs: 100000,
              nowMs: 50000,
              graceSec: kLockAfter5m),
          isTrue);
    });
  });

  group('봐주는 시간 값 (2026-08-16)', () {
    test('모르는 값은 바로 잠금으로 떨어진다', () {
      expect(normalizeLockDelay(9999), kLockNow);
      expect(normalizeLockDelay(-1), kLockNow);
      expect(normalizeLockDelay(30), kLockNow);
    });

    test('고를 수 있는 값은 그대로', () {
      for (final v in kLockDelays) {
        expect(normalizeLockDelay(v), v);
      }
    });

    test('목록이 겹치지 않고 오름차순이다', () {
      expect(kLockDelays.toSet().length, kLockDelays.length);
      for (var i = 1; i < kLockDelays.length; i++) {
        expect(kLockDelays[i], greaterThan(kLockDelays[i - 1]));
      }
    });
  });
}
