/// 상품 이름이 스토어마다 다르다 (2026-11-09).
///
/// 아이폰·아이패드·맥은 새 계정의 Skyblue Note Pro(com.ezlong.skybluenote) 상품을
/// 사고, 안드로이드는 옛 이름을 그대로 산다. 알아보는 쪽은 둘 다 받아야 한다 —
/// 드라이브로 넘어온 다른 기기의 결제 기록을 이름 때문에 놓치면 산 사람이 산 것을 못 쓴다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/purchase_gate.dart';

void main() {
  tearDown(() => productPrefix = kGoogleProductPrefix);

  test('기본값은 안드로이드(옛 이름) — 플레이 상품은 바꾸지 않는다', () {
    expect(kProductMonthly, 'com.ziririt.simpletext.premium.monthly');
    expect(kProductLifetime, 'com.ziririt.simpletext.premium.lifetime');
  });

  test('애플 기기는 새 이름을 사고판다', () {
    productPrefix = kAppleProductPrefix;
    expect(kProductMonthly, 'com.ezlong.skybluenote.premium.monthly');
    expect(kProductAllYearly, 'com.ezlong.skybluenote.premium.all.yearly');
    expect(kPremiumProductIds, hasLength(5));
    expect(
      kPremiumProductIds.every((id) => id.startsWith(kAppleProductPrefix)),
      isTrue,
    );
    expect(kDevUsdPrice[kProductMonthly], r'$2.99');
  });

  test('알아보는 쪽은 두 이름을 다 받는다', () {
    for (final p in [kAppleProductPrefix, kGoogleProductPrefix]) {
      expect(isPremiumProduct('$p.monthly'), isTrue, reason: p);
      expect(isAllDevices('$p.all.monthly'), isTrue, reason: p);
      expect(isAllDevices('$p.lifetime'), isTrue, reason: p);
      expect(isAllDevices('$p.yearly'), isFalse, reason: p);
      expect(guardDaysFor('$p.yearly'), kYearlyGuardDays, reason: p);
      expect(guardDaysFor('$p.lifetime'), isNull, reason: p);
    }
  });

  test('남의 이름·모르는 꼬리는 우리 상품이 아니다', () {
    expect(isPremiumProduct('com.ezlong.skybluenote.premium.weekly'), isFalse);
    expect(isPremiumProduct('com.example.premium.monthly'), isFalse);
    expect(
      isPremiumProduct('com.ezlong.skybluenote.premiumX.monthly'),
      isFalse,
    );
    expect(productTail('com.ziririt.simpletext.premium'), isNull);
  });

  test('평생권은 어느 이름으로 와도 평생권이다', () {
    final e = const Entitlement().seen(
      productId: 'com.ezlong.skybluenote.premium.lifetime',
      family: kFamilyApple,
      at: DateTime(2026, 11, 9),
    );
    expect(e.lifetime, isTrue);
  });
}
