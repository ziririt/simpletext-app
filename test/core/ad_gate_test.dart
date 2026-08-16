/// 광고 노출 규칙을 고정하는 테스트.
/// "전면 광고를 하루 한 번 보면 그날은 배너까지 사라진다" (2026-08-16 확정)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/ad_gate.dart';

void main() {
  final today = DateTime(2026, 8, 16, 14, 30);

  test('dateKey는 자릿수를 채운다 (8월 → 08)', () {
    expect(dateKey(DateTime(2026, 8, 6)), '2026-08-06');
  });

  test('아무 광고도 안 본 날에는 배너가 보인다', () {
    expect(bannerVisible(now: today, adFreeDate: ''), isTrue);
  });

  test('오늘 전면 광고를 봤으면 배너가 사라진다', () {
    expect(bannerVisible(now: today, adFreeDate: '2026-08-16'), isFalse);
  });

  test('어제 봤던 것은 소용없다 — 자정이 지나면 배너가 돌아온다', () {
    expect(bannerVisible(now: today, adFreeDate: '2026-08-15'), isTrue);
  });

  test('전면 광고는 사용 5분(300초)을 채워야 나온다', () {
    expect(interstitialDue(now: today, adFreeDate: '', usedSeconds: 299), isFalse);
    expect(interstitialDue(now: today, adFreeDate: '', usedSeconds: 300), isTrue);
  });

  test('오늘 이미 봤으면 5분이 지나도 다시 나오지 않는다 (하루 한 번)', () {
    expect(
        interstitialDue(now: today, adFreeDate: '2026-08-16', usedSeconds: 9999),
        isFalse);
  });
}
