/// 무료 한도 규칙을 고정하는 테스트.
/// 2026-08-16 확정: 정리 하루 3회, 마법사 하루 2회. 프리미엄은 무제한.
/// 같은 날 추가: 설치 직후 '쓴 날 기준 14일' 무제한 체험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/usage_gate.dart';

void main() {
  final today = DateTime(2026, 8, 16, 14, 30);
  final tomorrow = DateTime(2026, 8, 17, 0, 5);

  test('한도 상수는 소유자 확정값이다', () {
    expect(kFreeTidyPerDay, 3);
    expect(kFreeWizardPerDay, 2);
    expect(kTrialActiveDays, 14);
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

  group('체험 — 달력이 아니라 쓴 날을 센다', () {
    test('첫 실행에 1일째가 된다', () {
      expect(bumpTrialDays(now: today, lastDate: '', trialDays: 0), 1);
      expect(trialOn(1), isTrue);
      expect(trialLeft(1), 14);
    });

    test('같은 날 몇 번을 열어도 하루만 센다', () {
      // 이게 깨지면 앱을 자주 켜는 사람의 체험이 하루 만에 끝난다.
      expect(bumpTrialDays(now: today, lastDate: '2026-08-16', trialDays: 3), 3);
      final later = DateTime(2026, 8, 16, 23, 59);
      expect(bumpTrialDays(now: later, lastDate: '2026-08-16', trialDays: 3), 3);
    });

    test('안 켠 날은 안 깎인다 — 두 달 뒤에 열어도 2일째다', () {
      // 달력 기준이었다면 여기서 체험이 끝나 있다. 메모 앱에서 가장 흔한
      // 사용 방식(띄엄띄엄 쓰기)을 벌주지 않겠다는 뜻이다.
      final muchLater = DateTime(2026, 10, 20, 9, 0);
      expect(
          bumpTrialDays(now: muchLater, lastDate: '2026-08-16', trialDays: 1), 2);
      expect(trialOn(2), isTrue);
    });

    test('14일째까지 살아 있고 15가 되면 끝난다', () {
      expect(trialOn(14), isTrue);
      expect(trialLeft(14), 1); // 마지막 날
      expect(trialOn(15), isFalse);
      expect(trialLeft(15), 0);
    });

    test('끝난 뒤에는 숫자가 무한히 자라지 않는다', () {
      var d = 15;
      for (var i = 0; i < 50; i++) {
        d = bumpTrialDays(now: today, lastDate: 'x', trialDays: d);
      }
      expect(d, 15);
    });

    test('한 번도 안 연 상태(0)는 체험이 아니다', () {
      expect(trialOn(0), isFalse);
      expect(trialLeft(0), 0);
    });

    test('체험 중이면 한도를 넘겨도 안 막힌다', () {
      expect(
          canUseNow(
              now: today,
              savedDate: '2026-08-16',
              savedCount: 999,
              limit: kFreeTidyPerDay,
              premium: false,
              trialDays: 5),
          isTrue);
    });

    test('체험이 끝나면 그때부터 한도가 산다', () {
      bool c(int used) => canUseNow(
          now: today,
          savedDate: '2026-08-16',
          savedCount: used,
          limit: kFreeTidyPerDay,
          premium: false,
          trialDays: 15);
      expect(c(2), isTrue);
      expect(c(3), isFalse);
    });

    test('체험 중 남은 횟수는 -1(무제한)로 나온다', () {
      expect(
          remainingNow(
              now: today,
              savedDate: '2026-08-16',
              savedCount: 3,
              limit: kFreeTidyPerDay,
              premium: false,
              trialDays: 7),
          -1);
      expect(
          remainingNow(
              now: today,
              savedDate: '2026-08-16',
              savedCount: 1,
              limit: kFreeTidyPerDay,
              premium: false,
              trialDays: 15),
          2);
    });

    test('끝난 사실은 한 번만 알린다', () {
      // 매번 뜨면 잔소리가 되고, 한 번도 안 뜨면 배신이 된다.
      expect(trialJustEnded(trialDays: 15, noticeShown: false), isTrue);
      expect(trialJustEnded(trialDays: 15, noticeShown: true), isFalse);
      expect(trialJustEnded(trialDays: 14, noticeShown: false), isFalse);
    });
  });
}
