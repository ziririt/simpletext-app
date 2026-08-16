/// 광고 노출 판정 — 순수 함수. 화면·SDK 코드를 넣지 않는다(테스트로 고정).
///
/// 소유자 확정 규칙(2026-08-16):
///   - 무료 이용자는 최상단 배너를 본다
///   - 사용 5분이 지나면 전면 광고가 하루 한 번 나온다
///   - 전면 광고를 본 날(adFreeDate == 오늘)은 배너까지 전부 사라진다
/// 날짜가 바뀌면(자정) 자연히 다시 광고가 나온다 — 따로 초기화할 것 없음.
library;

/// 'YYYY-MM-DD'. 시간대는 기기 로컬 — 사용자의 '하루' 감각과 같아야 한다.
String dateKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

bool bannerVisible({required DateTime now, required String adFreeDate}) =>
    adFreeDate != dateKey(now);

bool interstitialDue({
  required DateTime now,
  required String adFreeDate,
  required int usedSeconds,
  int thresholdSeconds = 300,
}) =>
    adFreeDate != dateKey(now) && usedSeconds >= thresholdSeconds;
