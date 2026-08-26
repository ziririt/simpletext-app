/// 결제 판정 시험 — 두 등급 구조 (2026-08-26 소유자 확정).
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/purchase_gate.dart';

void main() {
  final now = DateTime(2026, 8, 26, 12);
  int after(int days) => now.add(Duration(days: days)).millisecondsSinceEpoch;
  int before(int days) =>
      now.subtract(Duration(days: days)).millisecondsSinceEpoch;

  test('상품은 다섯 가지 — 기본 둘, 모든 기기 둘, 평생 하나', () {
    expect(kPremiumProductIds.length, 5);
    expect(isPremiumProduct(kProductMonthly), isTrue);
    expect(isPremiumProduct('com.ziririt.simpletext.premium.weekly'), isFalse);

    expect(isAllDevices(kProductAllMonthly), isTrue);
    expect(isAllDevices(kProductAllYearly), isTrue);
    expect(isAllDevices(kProductLifetime), isTrue);
    expect(isAllDevices(kProductMonthly), isFalse);
    expect(isAllDevices(kProductYearly), isFalse);
  });

  test('울타리는 월간 35일, 연간 370일 — 한 주기보다 넉넉하다', () {
    expect(guardDaysFor(kProductMonthly), 35);
    expect(guardDaysFor(kProductAllMonthly), 35);
    expect(guardDaysFor(kProductYearly), 370);
    expect(guardDaysFor(kProductAllYearly), 370);
    expect(guardDaysFor(kProductLifetime), isNull);
    expect(kMonthlyGuardDays, greaterThan(31));
    expect(kYearlyGuardDays, greaterThan(365));
    expect(subscriptionUntilMs(productId: kProductLifetime, seenAt: now), 0);
  });

  group('기본 등급 — 산 스토어의 기기군 + 웹', () {
    final apple = const Entitlement()
        .seen(productId: kProductMonthly, family: kFamilyApple, at: now);

    test('애플에서 샀으면 애플 기기에서 열린다', () {
      expect(premiumHere(e: apple, family: kFamilyApple, now: now), isTrue);
    });

    test('웹에서도 열린다 — 돈 낸 사람에게 웹 광고를 보일 이유가 없다', () {
      expect(premiumHere(e: apple, family: kFamilyWeb, now: now), isTrue);
    });

    test('안드로이드에서는 안 열린다 — 그게 1달러의 값이다', () {
      expect(premiumHere(e: apple, family: kFamilyGoogle, now: now), isFalse);
    });

    test('윈도우에서도 안 열린다 — 거기는 살 스토어조차 없다', () {
      expect(premiumHere(e: apple, family: kFamilyOther, now: now), isFalse);
    });

    test('구글에서 산 경우는 반대로 맞물린다', () {
      final g = const Entitlement()
          .seen(productId: kProductYearly, family: kFamilyGoogle, at: now);
      expect(premiumHere(e: g, family: kFamilyGoogle, now: now), isTrue);
      expect(premiumHere(e: g, family: kFamilyWeb, now: now), isTrue);
      expect(premiumHere(e: g, family: kFamilyApple, now: now), isFalse);
    });

    test('양쪽 스토어에서 다 산 사람은 양쪽 다 열린다', () {
      final both = const Entitlement()
          .seen(productId: kProductMonthly, family: kFamilyApple, at: now)
          .seen(productId: kProductMonthly, family: kFamilyGoogle, at: now);
      expect(premiumHere(e: both, family: kFamilyApple, now: now), isTrue);
      expect(premiumHere(e: both, family: kFamilyGoogle, now: now), isTrue);
      // 그래도 '모든 기기'는 아니다 — 윈도우는 여전히 안 열린다.
      expect(premiumHere(e: both, family: kFamilyOther, now: now), isFalse);
      expect(tierOf(e: both, now: now), 1);
    });
  });

  group('모든 기기 등급', () {
    final all = const Entitlement()
        .seen(productId: kProductAllMonthly, family: kFamilyApple, at: now);

    test('어느 기기에서든 열린다', () {
      for (final f in [kFamilyApple, kFamilyGoogle, kFamilyWeb, kFamilyOther]) {
        expect(premiumHere(e: all, family: f, now: now), isTrue, reason: f);
      }
      expect(tierOf(e: all, now: now), 2);
    });

    test('평생권도 마찬가지이고 날짜를 보지 않는다', () {
      final life = const Entitlement()
          .seen(productId: kProductLifetime, family: kFamilyApple, at: now);
      expect(life.lifetime, isTrue);
      expect(premiumHere(e: life, family: kFamilyOther, now: now), isTrue);
      expect(tierOf(e: life, now: now), 2);
    });
  });

  group('울타리가 넘어가면', () {
    test('구독이 끊긴 뒤에는 아무 데서도 안 열린다', () {
      final lapsed = Entitlement(appleUntilMs: before(1));
      expect(premiumHere(e: lapsed, family: kFamilyApple, now: now), isFalse);
      expect(premiumHere(e: lapsed, family: kFamilyWeb, now: now), isFalse);
      expect(tierOf(e: lapsed, now: now), 0);
    });

    test('아직 남았으면 열린다', () {
      final live = Entitlement(appleUntilMs: after(1));
      expect(premiumHere(e: live, family: kFamilyApple, now: now), isTrue);
    });
  });

  group('등급 올리기 권하기', () {
    test('기본 등급 산 사람이 다른 OS 기기를 켠 자리에서만 권한다', () {
      final apple = const Entitlement()
          .seen(productId: kProductMonthly, family: kFamilyApple, at: now);
      expect(shouldOfferUpgrade(e: apple, family: kFamilyGoogle, now: now),
          isTrue);
      // 자기 기기군에서는 권하지 않는다 — 이미 쓰고 있다.
      expect(shouldOfferUpgrade(e: apple, family: kFamilyApple, now: now),
          isFalse);
      expect(
          shouldOfferUpgrade(e: apple, family: kFamilyWeb, now: now), isFalse);
    });

    test('아무것도 안 산 사람에게는 등급 올리기가 아니라 결제를 권한다', () {
      expect(
          shouldOfferUpgrade(
              e: const Entitlement(), family: kFamilyGoogle, now: now),
          isFalse);
    });

    test('이미 모든 기기면 권할 것이 없다', () {
      final all = Entitlement(allUntilMs: after(30));
      expect(
          shouldOfferUpgrade(e: all, family: kFamilyOther, now: now), isFalse);
    });
  });

  group('기기끼리 맞추기 — 가진 쪽이 이긴다', () {
    test('칸마다 큰 값이 남는다', () {
      final a = Entitlement(appleUntilMs: after(10), lifetime: false);
      final b = Entitlement(googleUntilMs: after(20), lifetime: true);
      final m = a.merge(b);
      expect(m.lifetime, isTrue);
      expect(m.appleUntilMs, after(10));
      expect(m.googleUntilMs, after(20));
    });

    test('합치기는 순서를 타지 않는다', () {
      final a = Entitlement(appleUntilMs: after(10));
      final b = Entitlement(appleUntilMs: after(3), allUntilMs: after(5));
      expect(a.merge(b), b.merge(a));
    });

    test('오간 뒤에도 값이 그대로다', () {
      final e = Entitlement(
          lifetime: true, allUntilMs: 7, appleUntilMs: 8, googleUntilMs: 9);
      expect(Entitlement.fromJson(e.toJson()), e);
    });

    test('빈 값에서 시작해도 터지지 않는다', () {
      expect(Entitlement.fromJson(null), const Entitlement());
      expect(Entitlement.fromJson(<String, dynamic>{}), const Entitlement());
    });
  });

  group('한도 적용', () {
    test('유료 체계가 꺼져 있으면 아무에게도 안 들이댄다', () {
      expect(limitsApply(paidTierLive: false, legacyFree: false, premium: false),
          isFalse);
    });

    test('예전부터 쓰던 사람은 유예된다', () {
      expect(limitsApply(paidTierLive: true, legacyFree: true, premium: false),
          isFalse);
    });

    test('산 사람에게는 안 들이댄다', () {
      expect(limitsApply(paidTierLive: true, legacyFree: false, premium: true),
          isFalse);
    });

    test('새로 깐 무료 사용자에게만 들이댄다', () {
      expect(limitsApply(paidTierLive: true, legacyFree: false, premium: false),
          isTrue);
    });
  });
}
