/// 광고 노출 판정 — 순수 함수. 화면·SDK 코드를 넣지 않는다(테스트로 고정).
///
/// 소유자 확정 규칙(2026-08-16):
///   - 무료 이용자는 최상단 배너를 본다
///   - 사용 5분이 지나면 전면 광고가 하루 한 번 나온다
///   - 전면 광고를 본 날(adFreeDate == 오늘)은 배너까지 전부 사라진다
/// 날짜가 바뀌면(자정) 자연히 다시 광고가 나온다 — 따로 초기화할 것 없음.
library;

import 'usage_gate.dart' show trialOn;

/// 'YYYY-MM-DD'. 시간대는 기기 로컬 — 사용자의 '하루' 감각과 같아야 한다.
String dateKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// 지금 이 사람에게 광고를 보여도 되는가 — **광고 쪽의 최종 판단**이다.
///
/// 2026-08-19 소유자 지시 — "2주 동안은 광고 없는 프리미엄 버전으로
/// 서비스하고, 2주 후부터 광고를 노출한다."
///
/// 앱을 켜자마자 배너가 먼저 반기는 화면은, 그 앱이 아무리 잘 만들어졌어도
/// **공짜로 얻은 것**처럼 보인다. 처음 2주를 깨끗하게 두면 사람은 먼저
/// 제품을 보고 그 다음에 값을 생각한다. 지금까지 그 순서가 뒤집혀 있었다.
///
/// 세 가지를 본다. 하나라도 걸리면 광고는 없다.
///   프리미엄 — 산 사람에게 광고를 보이는 것은 판 것을 도로 뺏는 일이다.
///   체험 기간 — 처음 2주.
///   오늘의 면제 — 전면 광고를 본 날은 그날 하루 배너까지 없다.
///
/// 화면 코드는 bannerVisible 이 아니라 **이걸** 불러야 한다. bannerVisible
/// 은 오늘의 면제만 보므로, 그것만 부르면 체험 중에도 광고가 뜬다.
bool adsOn({
  required DateTime now,
  required String adFreeDate,
  required int trialDays,
  required bool premium,
}) {
  if (premium) return false;
  if (trialOn(trialDays)) return false;
  return bannerVisible(now: now, adFreeDate: adFreeDate);
}

/// 오늘의 면제만 본다. 체험·프리미엄은 [adsOn]이 본다.
bool bannerVisible({required DateTime now, required String adFreeDate}) =>
    adFreeDate != dateKey(now);

bool interstitialDue({
  required DateTime now,
  required String adFreeDate,
  required int usedSeconds,
  int thresholdSeconds = 300,
}) =>
    adFreeDate != dateKey(now) && usedSeconds >= thresholdSeconds;
