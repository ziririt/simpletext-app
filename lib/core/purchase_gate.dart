/// 결제 판정 — 순수 함수. 스토어 SDK도 화면 코드도 넣지 않는다(시험으로 고정).
///
/// 2026-08-26 소유자 확정:
///   · 월간 US$2.99 · 연간 US$19.99 · 평생 US$49.99(출시 기념가 US$34.99)
///     평생값이 연간의 2.5배다 — 이보다 가까우면 평생권이 구독을 잡아먹고,
///     이보다 멀면 평생권이 안 팔린다.
///   · 하루 한도(정리 3회·마법사 2회)는 **이번 판 이후 새로 깐 사람부터**.
///     1.0~1.3을 '완전 무료'로 써 온 사람에게서 쓰던 것을 뺏지 않는다.
///     뺏으면 결제가 아니라 별 하나짜리 리뷰가 돌아온다.
///   · 스토어 무료체험(구독 도입 혜택)은 붙이지 않는다. 앱이 이미 '쓴 날
///     14일' 체험을 준다 — 2주 동안 광고도 한도도 없고 3주째부터 둘 다
///     시작된다. 여기에 스토어 체험까지 겹치면 무료 기간이 한 달이 된다.
library;

/// 상품 이름. App Store Connect·Play Console에 **글자 하나까지 같게** 넣는다.
/// 어긋나면 조회가 빈 목록을 주고, 화면에는 값이 안 뜨는데 오류도 안 난다 —
/// 제일 찾기 어려운 종류의 고장이다.
const String kProductLifetime = 'com.ziririt.simpletext.premium.lifetime';
const String kProductYearly = 'com.ziririt.simpletext.premium.yearly';
const String kProductMonthly = 'com.ziririt.simpletext.premium.monthly';

const List<String> kPremiumProductIds = <String>[
  kProductLifetime,
  kProductYearly,
  kProductMonthly,
];

bool isPremiumProduct(String id) => kPremiumProductIds.contains(id);

/// 구독 권한을 한 번 확인했을 때 '언제까지 믿어 줄지'의 바깥 울타리.
///
/// 우리에게는 서버가 없다. 스토어가 주는 거래 기록에도 만료 시각이 실려
/// 오지 않는다. 그래서 만료를 **알아내는** 대신 이렇게 한다.
///
///   애플 기기는 앱을 켤 때마다 스토어에 물어 권한이 살아 있는지 본다.
///   살아 있으면 울타리를 오늘부터 다시 세운다. 결제가 끊기면 그 순간부터
///   울타리가 더는 밀리지 않고, 한 주기 남짓 뒤에 저절로 넘어간다.
///
/// 울타리를 한 주기보다 조금 넉넉히 두는 까닭은 애플의 청구 유예(billing
/// retry) 때문이다. 카드가 하루 밀렸다고 프리미엄을 뺏으면, 돈은 결국
/// 들어오는데 사람만 잃는다.
///
/// 안드로이드·윈도우·웹처럼 애플 계정을 못 보는 기기는 이 울타리를 드라이브로
/// 건네받아 산다. 그래서 "한 번 사면 모든 기기"가 빈말이 아니게 된다.
const int kMonthlyGuardDays = 35;
const int kYearlyGuardDays = 370;

/// 이 상품이 구독이면 울타리 날수, 평생권이면 null.
int? guardDaysFor(String productId) {
  switch (productId) {
    case kProductMonthly:
      return kMonthlyGuardDays;
    case kProductYearly:
      return kYearlyGuardDays;
  }
  return null;
}

/// 구독 권한을 [seenAt]에 확인했다면 언제까지 믿을 것인가(0이면 구독 아님).
int subscriptionUntilMs({required String productId, required DateTime seenAt}) {
  final d = guardDaysFor(productId);
  if (d == null) return 0;
  return seenAt.add(Duration(days: d)).millisecondsSinceEpoch;
}

/// 지금 이 사람이 프리미엄인가.
///
/// 평생권은 날짜를 보지 않는다. 구독은 울타리 안쪽일 때만이다.
bool premiumNow({
  required bool lifetime,
  required int untilMs,
  required DateTime now,
}) =>
    lifetime || untilMs > now.millisecondsSinceEpoch;

/// 하루 한도를 이 사람에게 들이대는가.
///
/// 체험 중인지는 여기서 보지 않는다 — usage_gate의 canUseNow가 본다.
/// 두 곳에서 같은 것을 보면 언젠가 한쪽만 고쳐진다.
bool limitsApply({
  required bool paidTierLive,
  required bool legacyFree,
  required bool premium,
}) {
  if (!paidTierLive) return false;
  if (legacyFree) return false;
  if (premium) return false;
  return true;
}

/// 기기끼리 맞출 때는 **가진 쪽이 이긴다.**
///
/// 규칙(늦게 쓴 쪽이 이긴다)을 그대로 쓰면, 결제를 모르는 기기가 켜지는
/// 순간 "프리미엄 아님"이 최신값이 되어 산 것을 덮어 버린다. 돈을 낸
/// 사람에게 이보다 나쁜 일은 없다.
bool mergeLifetime(bool mine, bool theirs) => mine || theirs;

int mergeUntil(int mine, int theirs) => mine > theirs ? mine : theirs;

bool mergeLegacyFree(bool mine, bool theirs) => mine || theirs;
