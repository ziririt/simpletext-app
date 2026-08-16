/// 무료 이용 한도 — 순수 함수. 화면·저장 코드를 넣지 않는다(테스트로 고정).
///
/// 2026-08-16 소유자 확정. 프리미엄이 '광고 제거'뿐이면 결제할 이유가 약하다는
/// 판단에서 나왔다(경쟁 앱 조사: UpNote는 메모 50개, Bear는 동기화·내보내기를
/// 유료로 건다).
///
///   무료: 정리 하루 3회 · 마법사(AI) 하루 2회
///   프리미엄: 둘 다 무제한 + 광고 없음
///   설치 직후: **쓴 날 기준 14일간 무제한**(아래 체험 항목)
///
/// 처음에는 10회/3회로 넣었다가 소유자가 3회/2회로 좁혔다(같은 날). 결제
/// 전환을 우선한 결정이다. 이 값은 출시 뒤 리뷰와 전환율을 보고 조정할
/// 여지가 크다 — 숫자를 바꿀 일이 생기면 여기 두 상수만 고치면 되고,
/// 화면·저장 쪽은 손댈 필요가 없다.
///
/// 날짜가 바뀌면 저절로 초기화된다(기기 로컬 자정 기준 — 사용자의 '하루'와
/// 같아야 한다). 따로 초기화 절차를 두지 않는 이유다.
library;

const int kFreeTidyPerDay = 3;
const int kFreeWizardPerDay = 2;

/// 설치 직후 무제한으로 열어 두는 기간. **달력 날짜가 아니라 '쓴 날'을 센다.**
///
/// 2026-08-16 소유자 제안 — "첫 2주는 제한을 없애고 많이 써보게 하면 나중에
/// 결제하지 않을까." 맞는 방향이라고 봤다. 근거는 둘이다.
///
/// 1) 이 한도는 우리 돈을 한 푼도 아껴 주지 않는다. 정리는 기기 안에서 도는
///    규칙 엔진이고, 마법사는 **사용자가 자기 API 키로** 부른다. 즉 한도는
///    비용 방어가 아니라 순수한 결제 유도 장치다. 무제한으로 열어도 비용
///    위험이 0이다.
/// 2) 자기 돈으로 키를 산 사람을 하루 2회로 묶으면 "내 돈 내고 쓰는데 왜
///    막냐"는 반발이 나온다. 체험 기간은 그 반발을 뒤로 미루는 완충재다.
///
/// **달력 14일이 아니라 쓴 날 14일**인 이유: 메모 앱은 게임처럼 매일 켜지
/// 않는다. 설치하고 두 번 쓰고 출장 갔다 오면 달력 기준으로는 체험이 끝나
/// 있다. 습관이 붙기는커녕 열어 본 적도 없이 문이 닫힌다. 실제로 연 날만
/// 하루씩 깎으면 사흘에 한 번 쓰는 사람도 온전히 14일치를 경험한다.
const int kTrialActiveDays = 14;

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

/// 한 번 더 쓸 수 있는가 — **한도만** 본다(체험·프리미엄은 canUseNow가 본다).
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

// ---------------------------------------------------------------------------
// 체험(설치 직후 무제한)
// ---------------------------------------------------------------------------

/// 오늘이 '새로 세야 할 날'이면 하루 올린다.
///
/// [trialDays]는 지금까지 앱을 연 날의 수다(오늘 포함). 하루에 몇 번을 열든
/// 한 번만 오른다 — [lastDate]가 오늘과 같으면 그대로 돌려준다.
///
/// 끝난 뒤에도 계속 세면 숫자만 무한히 자란다. 그래서 kTrialActiveDays + 1
/// 에서 멈춘다. 그 값 자체가 '끝났다'는 뜻이다.
int bumpTrialDays({
  required DateTime now,
  required String lastDate,
  required int trialDays,
}) {
  if (lastDate == usageDateKey(now)) return trialDays;
  if (trialDays > kTrialActiveDays) return trialDays;
  return trialDays + 1;
}

/// 체험이 아직 살아 있는가.
///
/// 0은 '아직 한 번도 안 열었다'라서 체험이 아니다 — bumpTrialDays가 첫 실행
/// 때 1로 올린다. 그 뒤 14일째까지가 체험이고 15가 되는 순간 끝난다.
bool trialOn(int trialDays) => trialDays >= 1 && trialDays <= kTrialActiveDays;

/// 오늘 포함 며칠 남았나. 끝났으면 0.
int trialLeft(int trialDays) =>
    trialOn(trialDays) ? kTrialActiveDays - trialDays + 1 : 0;

/// 체험이 방금 끝났고 아직 알려 주지 않았는가.
///
/// 끝난 걸 조용히 넘어가면 사람은 어느 날 갑자기 막히고, 지갑을 여는 게
/// 아니라 앱을 지운다. 한 번은 반드시 말해 줘야 한다.
bool trialJustEnded({required int trialDays, required bool noticeShown}) =>
    trialDays > kTrialActiveDays && !noticeShown;

/// 지금 한 번 더 쓸 수 있는가 — 프리미엄·체험·한도를 전부 본 최종 판단.
///
/// 화면 코드는 canUse가 아니라 **이걸** 불러야 한다. canUse는 한도만 보므로
/// 체험 중인 사람을 막아 버린다.
bool canUseNow({
  required DateTime now,
  required String savedDate,
  required int savedCount,
  required int limit,
  required bool premium,
  required int trialDays,
}) {
  if (premium) return true;
  if (trialOn(trialDays)) return true;
  return canUse(
    now: now,
    savedDate: savedDate,
    savedCount: savedCount,
    limit: limit,
    premium: false,
  );
}

/// 남은 횟수 — 체험 중이면 -1(무제한).
int remainingNow({
  required DateTime now,
  required String savedDate,
  required int savedCount,
  required int limit,
  required bool premium,
  required int trialDays,
}) {
  if (premium || trialOn(trialDays)) return -1;
  return remaining(
    now: now,
    savedDate: savedDate,
    savedCount: savedCount,
    limit: limit,
    premium: false,
  );
}
