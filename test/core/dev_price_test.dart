/// 개발용 값이 상품을 하나도 빠뜨리지 않았는지 본다.
///
/// 빠지면 그 줄만 점 세 개로 남는데, 디버그에서만 보이는 자리라 눈으로는
/// 잘 안 잡힌다. 그리고 그 상태로 심사용 스크린샷을 찍으면 그대로 애플에
/// 넘어간다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/purchase_gate.dart';

void main() {
  test('개발용 값이 상품 다섯 개를 모두 덮는다', () {
    for (final id in kPremiumProductIds) {
      expect(kDevUsdPrice[id], isNotNull, reason: id);
      expect(kDevUsdPrice[id], startsWith(r'$'), reason: id);
    }
    expect(kDevUsdPrice.length, kPremiumProductIds.length);
  });

  test('등급 사이의 값 차이가 소유자가 정한 대로다', () {
    // 기본과 모든 기기의 월간 차이는 1달러 — "다른 OS가 추가되면 1달러 더".
    expect(kDevUsdPrice[kProductMonthly], r'$2.99');
    expect(kDevUsdPrice[kProductAllMonthly], r'$3.99');
    // 평생(기념가)은 모든기기 연간보다 10달러 위 — 둘 다 팔리게 벌린 값이다.
    expect(kDevUsdPrice[kProductAllYearly], r'$29.99');
    expect(kDevUsdPrice[kProductLifetime], r'$39.99');
  });
}
