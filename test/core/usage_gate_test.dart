/// 무료 한도 규칙을 고정하는 테스트.
/// 2026-08-16 확정: 정리 하루 3회, 마법사 하루 2회. 프리미엄은 무제한.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/usage_gate.dart';

void main() {
  final today = DateTime(2026, 8, 16, 14, 30);
  final tomorrow = DateTime(2026, 8, 17, 0, 5);

  test('한도 상수는 소유자 확정값이다', () {
    expect(kFreeTidyPerDay, 3);
    expect(kFreeWizardPerDay, 2);
  });

  test('어제 쓴 횟수는 오늘로 안 넘어온다', () {
    expect(usedToday(now: today, savedDate: '2026-08-15', savedCount: 3), 0);
    expect(usedToday(now: today, savedDate: '2026-08-16', savedCount: 2), 2);
  });

  test('한도 안이면 쓸 수 있고, 채우면 막힌다', () {
    bool c(int used) => canUse(
        now: today,
        savedDate: '2026-08-16',
        savedCount: used,
        limit: kFreeTidyPerDay,
        premium: false);
    expect(c(0), isTrue);
    expect(c(2), isTrue);
    expect(c(3), isFalse);
    expect(c(99), isFalse);
  });

  test('마법사는 두 번까지', () {
    bool w(int used) => canUse(
        now: today,
        savedDate: '2026-08-16',
        savedCount: used,
        limit: kFreeWizardPerDay,
        premium: false);
    expect(w(1), isTrue);
    expect(w(2), isFalse);
  });

  test('자정이 지나면 다시 열린다', () {
    expect(
        canUse(
            now: tomorrow,
            savedDate: '2026-08-16',
            savedCount: 3,
            limit: kFreeTidyPerDay,
            premium: false),
        isTrue);
  });

  test('프리미엄은 몇 번을 쓰든 안 막힌다', () {
    expect(
        canUse(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 9999,
            limit: kFreeTidyPerDay,
            premium: true),
        isTrue);
  });

  test('날짜가 바뀌면 1부터 다시 센다', () {
    expect(nextCount(now: today, savedDate: '2026-08-16', savedCount: 1), 2);
    expect(nextCount(now: today, savedDate: '2026-08-15', savedCount: 3), 1);
  });

  test('남은 횟수 — 프리미엄은 -1(무제한)', () {
    expect(
        remaining(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 3,
            limit: kFreeTidyPerDay,
            premium: false),
        0);
    expect(
        remaining(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 1,
            limit: kFreeTidyPerDay,
            premium: false),
        2);
    expect(
        remaining(
            now: today,
            savedDate: '',
            savedCount: 0,
            limit: kFreeTidyPerDay,
            premium: false),
        3);
    expect(
        remaining(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 5,
            limit: kFreeTidyPerDay,
            premium: true),
        -1);
  });
}
