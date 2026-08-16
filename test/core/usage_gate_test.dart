/// 무료 한도 규칙을 고정하는 테스트.
/// 2026-08-16 확정: 정리 하루 10회, 마법사 하루 3회. 프리미엄은 무제한.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/usage_gate.dart';

void main() {
  final today = DateTime(2026, 8, 16, 14, 30);
  final tomorrow = DateTime(2026, 8, 17, 0, 5);

  test('한도 상수는 확정값이다', () {
    expect(kFreeTidyPerDay, 10);
    expect(kFreeWizardPerDay, 3);
  });

  test('어제 쓴 횟수는 오늘로 안 넘어온다', () {
    expect(usedToday(now: today, savedDate: '2026-08-15', savedCount: 10), 0);
    expect(usedToday(now: today, savedDate: '2026-08-16', savedCount: 7), 7);
  });

  test('한도 안이면 쓸 수 있고, 채우면 막힌다', () {
    bool c(int used) => canUse(
        now: today,
        savedDate: '2026-08-16',
        savedCount: used,
        limit: kFreeTidyPerDay,
        premium: false);
    expect(c(9), isTrue);
    expect(c(10), isFalse);
    expect(c(99), isFalse);
  });

  test('자정이 지나면 다시 열린다', () {
    expect(
        canUse(
            now: tomorrow,
            savedDate: '2026-08-16',
            savedCount: 10,
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
    expect(nextCount(now: today, savedDate: '2026-08-16', savedCount: 4), 5);
    expect(nextCount(now: today, savedDate: '2026-08-15', savedCount: 9), 1);
  });

  test('남은 횟수 — 프리미엄은 -1(무제한)', () {
    expect(
        remaining(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 3,
            limit: kFreeWizardPerDay,
            premium: false),
        0);
    expect(
        remaining(
            now: today,
            savedDate: '2026-08-16',
            savedCount: 1,
            limit: kFreeWizardPerDay,
            premium: false),
        2);
    expect(
        remaining(
            now: today,
            savedDate: '',
            savedCount: 0,
            limit: kFreeTidyPerDay,
            premium: false),
        10);
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
