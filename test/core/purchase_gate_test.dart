/// 결제 판정 시험 (2026-08-26 소유자 확정 규칙).
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/purchase_gate.dart';

void main() {
  final now = DateTime(2026, 8, 26, 12);

  test('상품 이름 세 가지가 목록과 맞는다', () {
    expect(kPremiumProductIds.length, 3);
    expect(isPremiumProduct(kProductLifetime), isTrue);
    expect(isPremiumProduct(kProductYearly), isTrue);
    expect(isPremiumProduct(kProductMonthly), isTrue);
    expect(isPremiumProduct('com.ziririt.simpletext.something'), isFalse);
  });

  test('평생권은 날짜를 보지 않는다', () {
    expect(premiumNow(lifetime: true, untilMs: 0, now: now), isTrue);
  });

  test('구독은 울타리 안쪽일 때만 프리미엄이다', () {
    final inside = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final outside = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    expect(premiumNow(lifetime: false, untilMs: inside, now: now), isTrue);
    expect(premiumNow(lifetime: false, untilMs: outside, now: now), isFalse);
  });

  test('아무것도 없으면 프리미엄이 아니다', () {
    expect(premiumNow(lifetime: false, untilMs: 0, now: now), isFalse);
  });

  test('울타리는 월간 35일, 연간 370일 — 한 주기보다 조금 넉넉하다', () {
    expect(guardDaysFor(kProductMonthly), 35);
    expect(guardDaysFor(kProductYearly), 370);
    expect(guardDaysFor(kProductLifetime), isNull);

    final m = subscriptionUntilMs(productId: kProductMonthly, seenAt: now);
    expect(m, now.add(const Duration(days: 35)).millisecondsSinceEpoch);
    expect(subscriptionUntilMs(productId: kProductLifetime, seenAt: now), 0);
  });

  test('울타리는 한 주기보다 길어야 청구 유예를 버틴다', () {
    expect(kMonthlyGuardDays, greaterThan(31));
    expect(kYearlyGuardDays, greaterThan(365));
  });

  group('한도 적용', () {
    test('유료 체계가 꺼져 있으면 아무에게도 안 들이댄다', () {
      expect(
          limitsApply(paidTierLive: false, legacyFree: false, premium: false),
          isFalse);
    });

    test('예전부터 쓰던 사람은 유예된다', () {
      expect(
          limitsApply(paidTierLive: true, legacyFree: true, premium: false),
          isFalse);
    });

    test('산 사람에게는 안 들이댄다', () {
      expect(
          limitsApply(paidTierLive: true, legacyFree: false, premium: true),
          isFalse);
    });

    test('새로 깐 무료 사용자에게만 들이댄다', () {
      expect(
          limitsApply(paidTierLive: true, legacyFree: false, premium: false),
          isTrue);
    });
  });

  group('기기끼리 맞추기 — 가진 쪽이 이긴다', () {
    test('평생권은 한쪽만 있어도 남는다', () {
      expect(mergeLifetime(false, true), isTrue);
      expect(mergeLifetime(true, false), isTrue);
      expect(mergeLifetime(false, false), isFalse);
    });

    test('구독 울타리는 먼 쪽이 남는다', () {
      expect(mergeUntil(100, 900), 900);
      expect(mergeUntil(900, 100), 900);
    });

    test('유예도 한쪽만 있으면 남는다', () {
      expect(mergeLegacyFree(false, true), isTrue);
    });
  });
}
