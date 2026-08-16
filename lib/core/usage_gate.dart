/// 무료 이용 한도 — 순수 함수. 화면·저장 코드를 넣지 않는다(테스트로 고정).
///
/// 2026-08-16 소유자 확정. 프리미엄이 '광고 제거'뿐이면 결제할 이유가 약하다는
/// 판단에서 나왔다(경쟁 앱 조사: UpNote는 메모 50개, Bear는 동기화·내보내기를
/// 유료로 건다). 우리는 핵심인 '정리'를 아예 막지 않는다 — 가볍게 쓰는 사람은
/// 한도에 닿지도 않고, 매일 쓰는 사람에게만 결제 이유가 생기게 한다.
///
///   무료: 정리 하루 10회 · 마법사(AI) 하루 3회
///   프리미엄: 둘 다 무제한 + 광고 없음
///
/// 날짜가 바뀌면 저절로 초기화된다(기기 로컬 자정 기준 — 사용자의 '하루'와
/// 같아야 한다). 따로 초기화 절차를 두지 않는 이유다.
library;

const int kFreeTidyPerDay = 10;
const int kFreeWizardPerDay = 3;

/// 'YYYY-MM-DD'. core/ad_gate.dart의 dateKey와 같은 규칙이다.
String usageDateKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// 오늘 몇 번 썼는가. 저장된 날짜가 오늘이 아니면 0이다(어제 것은 안 센다).
int usedToday({
  required DateTime now,
  required String savedDate,
  required int savedCount,
}) =>
    savedDate == usageDateKey(now) ? savedCount : 0;

/// 한 번 더 쓸 수 있는가.
bool canUse({
  required DateTime now,
  required String savedDate,
  required int savedCount,
  required int limit,
  required bool premium,
}) {
  if (premium) return true;
  return usedToday(now: now, savedDate: savedDate, savedCount: savedCount) < limit;
}

/// 쓰고 난 뒤의 새 횟수. 날짜가 바뀌었으면 1부터 다시 센다.
int nextCount({
  required DateTime now,
  required String savedDate,
  required int savedCount,
}) =>
    usedToday(now: now, savedDate: savedDate, savedCount: savedCount) + 1;

/// 남은 횟수(안내 문구용). 프리미엄이면 -1(무제한).
int remaining({
  required DateTime now,
  required String savedDate,
  required int savedCount,
  required int limit,
  required bool premium,
}) {
  if (premium) return -1;
  final r = limit - usedToday(now: now, savedDate: savedDate, savedCount: savedCount);
  return r < 0 ? 0 : r;
}
