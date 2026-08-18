/// 광고 노출 규칙을 고정하는 테스트.
/// "전면 광고를 하루 한 번 보면 그날은 배너까지 사라진다" (2026-08-16 확정)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/ad_gate.dart';

void main() {
  _trialAds();
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

// 2026-08-19 — 처음 2주는 광고가 없다. 소유자 지시로 붙인 규칙이라
// 여기서 못 박는다. 이 고장은 화면을 봐도 안 보인다 — 광고가 안 뜨는
// 것과 광고를 못 불러온 것이 눈으로는 똑같다.
void _trialAds() {
  group('체험 2주 동안은 광고가 없다 (2026-08-19)', () {
    final now = DateTime(2026, 8, 19, 10);

    test('체험 첫날 — 광고 없음', () {
      expect(
          adsOn(now: now, adFreeDate: '', trialDays: 1, premium: false), isFalse);
    });

    test('체험 마지막 날(14일째) — 아직 광고 없음', () {
      expect(adsOn(now: now, adFreeDate: '', trialDays: 14, premium: false),
          isFalse);
    });

    test('15일째 — 이제 광고가 나온다', () {
      expect(
          adsOn(now: now, adFreeDate: '', trialDays: 15, premium: false), isTrue);
    });

    test('프리미엄은 체험이 끝나도 광고 없음', () {
      expect(
          adsOn(now: now, adFreeDate: '', trialDays: 99, premium: true), isFalse);
    });

    test('전면 광고를 본 날은 그날 하루 광고 없음', () {
      expect(
          adsOn(
              now: now,
              adFreeDate: dateKey(now),
              trialDays: 99,
              premium: false),
          isFalse);
    });

    // 아직 한 번도 안 연 상태(0)는 체험이 아니다. load()가 켤 때 1로
    // 올리므로 실제로는 화면에 닿기 전에 1이 된다.
    test('0일째는 체험이 아니다 — 화면에 닿기 전 값이다', () {
      expect(
          adsOn(now: now, adFreeDate: '', trialDays: 0, premium: false), isTrue);
    });
  });
}
