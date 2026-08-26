/// 결제 판정 — 순수 함수. 스토어 SDK도 화면 코드도 넣지 않는다(시험으로 고정).
///
/// # 두 등급 (2026-08-26 소유자 확정)
///
/// 소유자 원안: "기본은 iOS·안드로이드 각각 월 2.99달러로 하고, 다른 OS가
/// 추가되면 1달러를 더 추가한다. 웹앱은 광고 버전만 두되, iOS든 안드로이드든
/// 하나라도 결제한 이가 웹앱을 보면 배너를 없앤다."
///
///   · **기본 등급** — 월 US$2.99 / 연 US$19.99
///     산 스토어의 기기군 + **웹**. 웹을 기본에 얹은 까닭은 위 원안 그대로다.
///     웹은 우리 사이트이자 결제 유도 창구라, 돈 낸 사람에게 광고를 보이는
///     것이 아무 이득이 없다.
///   · **모든 기기** — 월 US$3.99 / 연 US$29.99
///     위에 더해 **다른 OS의 네이티브 앱**. 애플에서 산 사람이 안드로이드·
///     윈도우에서도, 구글에서 산 사람이 아이폰·맥·윈도우에서도 쓴다.
///   · **평생** — US$49.99(출시 기념가 US$34.99). '모든 기기' 하나뿐이다.
///     평생을 두 등급으로 또 쪼개면 결제 화면에 여섯 줄이 서고, 여섯 줄이
///     선 화면에서는 아무도 고르지 못한다.
///
/// # 왜 '스토어별 울타리'를 따로 두는가
///
/// "$1 추가"는 스토어에 없는 개념이다. 애플에도 구글에도 굴러가는 구독에
/// 덧대는 상품이 없다. 그래서 같은 구독 그룹 안에 더 비싼 상품을 두고
/// **갈아타게** 한다 — 남은 기간 정산은 스토어가 해 준다.
///
/// 그리고 애플은 한 번 결제하면 같은 Apple ID의 아이폰·아이패드·맥에
/// 자동으로 다 적용한다. **'아이폰만'으로 쪼갤 수 없다.** 구글도 같은
/// 계정의 안드로이드 기기 전부가 열린다. 그러니 '기본 등급의 범위'는
/// 우리가 정하는 것이 아니라 스토어가 정한 것을 받아 적는 것이다.
///
/// 한 사람이 애플에서도 구글에서도 기본을 살 수 있다. 그래서 등급 하나와
/// '누가 줬나' 한 칸으로는 모자라고, **스토어마다 울타리를 따로** 둔다.
/// 합치는 것도 이 편이 쉽다 — 칸마다 큰 값이 이기면 그만이다.
library;

// ---------------------------------------------------------------- 기기 갈래
//
// 어느 스토어의 식구인가. 화면 코드가 판을 보고 골라 넣는다(여기는 순수하게
// 남긴다 — Platform을 부르는 순간 시험에서 못 돌린다).
const String kFamilyApple = 'apple'; // 아이폰·아이패드·맥
const String kFamilyGoogle = 'google'; // 안드로이드·크롬북
const String kFamilyWeb = 'web'; // 웹앱
const String kFamilyOther = 'other'; // 윈도우·리눅스 — 살 스토어가 없다

// ---------------------------------------------------------------- 상품 이름
//
// App Store Connect·Play Console에 **글자 하나까지 같게** 넣는다. 어긋나면
// 조회가 빈 목록을 주고, 화면에는 값이 안 뜨는데 오류도 안 난다 — 제일
// 찾기 어려운 종류의 고장이다.
const String kProductMonthly = 'com.ziririt.simpletext.premium.monthly';
const String kProductYearly = 'com.ziririt.simpletext.premium.yearly';
const String kProductAllMonthly = 'com.ziririt.simpletext.premium.all.monthly';
const String kProductAllYearly = 'com.ziririt.simpletext.premium.all.yearly';
const String kProductLifetime = 'com.ziririt.simpletext.premium.lifetime';

const List<String> kPremiumProductIds = <String>[
  kProductMonthly,
  kProductYearly,
  kProductAllMonthly,
  kProductAllYearly,
  kProductLifetime,
];

bool isPremiumProduct(String id) => kPremiumProductIds.contains(id);

/// '모든 기기' 등급의 상품인가.
bool isAllDevices(String id) =>
    id == kProductAllMonthly || id == kProductAllYearly || id == kProductLifetime;

// ---------------------------------------------------------------- 울타리
//
// 우리에게는 서버가 없다. 스토어가 주는 거래 기록에도 만료 시각이 실려
// 오지 않는다. 그래서 만료를 **알아내는** 대신 이렇게 한다.
//
//   결제한 기기는 앱을 켤 때마다 스토어에 권한이 살아 있는지 묻고, 살아
//   있으면 울타리를 오늘부터 다시 세운다. 결제가 끊기면 그 순간부터
//   울타리가 더는 밀리지 않고, 한 주기 남짓 뒤에 저절로 넘어간다.
//
// 한 주기보다 넉넉히 두는 까닭은 애플·구글의 청구 유예(billing retry) 때문
// 이다. 카드가 하루 밀렸다고 프리미엄을 뺏으면, 돈은 결국 들어오는데 사람만
// 잃는다. (2026-08-19 인계서에 적혀 있던 '35일 미끄럼 창'이 이것이다.)
const int kMonthlyGuardDays = 35;
const int kYearlyGuardDays = 370;

/// 이 상품이 구독이면 울타리 날수, 평생권이면 null.
int? guardDaysFor(String productId) {
  switch (productId) {
    case kProductMonthly:
    case kProductAllMonthly:
      return kMonthlyGuardDays;
    case kProductYearly:
    case kProductAllYearly:
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

// ---------------------------------------------------------------- 가진 것
//
// 기기 하나가 들고 다니는 결제 기록. 드라이브로 오가는 것도 이 네 값이다.
class Entitlement {
  const Entitlement({
    this.lifetime = false,
    this.allUntilMs = 0,
    this.appleUntilMs = 0,
    this.googleUntilMs = 0,
  });

  /// 평생권. 참이면 등급은 '모든 기기'이고 날짜를 보지 않는다.
  final bool lifetime;

  /// '모든 기기' 구독의 울타리.
  final int allUntilMs;

  /// 애플에서 산 **기본 등급** 구독의 울타리.
  final int appleUntilMs;

  /// 구글에서 산 **기본 등급** 구독의 울타리.
  final int googleUntilMs;

  /// 이 상품을 이 스토어에서 확인했다 — 해당 칸만 밀어 준다.
  ///
  /// [family]는 확인한 기기의 갈래다. 기본 등급은 어느 스토어가 줬는지가
  /// 뜻을 가지므로 반드시 함께 받는다.
  Entitlement seen({
    required String productId,
    required String family,
    required DateTime at,
  }) {
    if (productId == kProductLifetime) {
      return copyWith(lifetime: true);
    }
    final until = subscriptionUntilMs(productId: productId, seenAt: at);
    if (until == 0) return this;
    if (isAllDevices(productId)) {
      return copyWith(allUntilMs: _max(allUntilMs, until));
    }
    if (family == kFamilyGoogle) {
      return copyWith(googleUntilMs: _max(googleUntilMs, until));
    }
    if (family == kFamilyApple) {
      return copyWith(appleUntilMs: _max(appleUntilMs, until));
    }
    // 웹·윈도우에서는 기본 등급을 팔지 않는다. 팔 수도 없다.
    return this;
  }

  Entitlement copyWith({
    bool? lifetime,
    int? allUntilMs,
    int? appleUntilMs,
    int? googleUntilMs,
  }) =>
      Entitlement(
        lifetime: lifetime ?? this.lifetime,
        allUntilMs: allUntilMs ?? this.allUntilMs,
        appleUntilMs: appleUntilMs ?? this.appleUntilMs,
        googleUntilMs: googleUntilMs ?? this.googleUntilMs,
      );

  /// 기기끼리 맞출 때는 **가진 쪽이 이긴다.**
  ///
  /// 규칙 동기화(늦게 쓴 쪽이 이긴다)를 그대로 쓰면, 결제를 모르는 기기가
  /// 켜지는 순간 "프리미엄 아님"이 최신값이 되어 산 것을 덮어 버린다. 돈을
  /// 낸 사람에게 이보다 나쁜 일은 없다.
  Entitlement merge(Entitlement other) => Entitlement(
        lifetime: lifetime || other.lifetime,
        allUntilMs: _max(allUntilMs, other.allUntilMs),
        appleUntilMs: _max(appleUntilMs, other.appleUntilMs),
        googleUntilMs: _max(googleUntilMs, other.googleUntilMs),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'life': lifetime,
        'all': allUntilMs,
        'apple': appleUntilMs,
        'google': googleUntilMs,
      };

  static Entitlement fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Entitlement();
    int n(String k) => j[k] is int ? j[k] as int : 0;
    return Entitlement(
      lifetime: j['life'] == true,
      allUntilMs: n('all'),
      appleUntilMs: n('apple'),
      googleUntilMs: n('google'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.lifetime == lifetime &&
      other.allUntilMs == allUntilMs &&
      other.appleUntilMs == appleUntilMs &&
      other.googleUntilMs == googleUntilMs;

  @override
  int get hashCode =>
      Object.hash(lifetime, allUntilMs, appleUntilMs, googleUntilMs);
}

int _max(int a, int b) => a > b ? a : b;

/// **이 기기에서** 프리미엄인가.
///
/// 같은 사람이라도 기기마다 답이 다를 수 있다 — 그게 두 등급의 뜻이다.
///   · 평생권·'모든 기기' 구독 — 어디서든 참.
///   · 기본 등급 — 산 스토어의 기기군에서 참. 그리고 **웹에서도 참**이다
///     (어느 스토어에서 샀든 하나라도 살아 있으면).
///   · 윈도우·리눅스 — 살 스토어가 없다. '모든 기기'로만 열린다.
bool premiumHere({
  required Entitlement e,
  required String family,
  required DateTime now,
}) {
  if (e.lifetime) return true;
  final t = now.millisecondsSinceEpoch;
  if (e.allUntilMs > t) return true;
  switch (family) {
    case kFamilyApple:
      return e.appleUntilMs > t;
    case kFamilyGoogle:
      return e.googleUntilMs > t;
    case kFamilyWeb:
      return e.appleUntilMs > t || e.googleUntilMs > t;
  }
  return false;
}

/// 이 사람이 어느 등급인가 — 화면에 보여 주기 위한 값.
/// 0 없음 · 1 기본 · 2 모든 기기.
int tierOf({required Entitlement e, required DateTime now}) {
  if (e.lifetime) return 2;
  final t = now.millisecondsSinceEpoch;
  if (e.allUntilMs > t) return 2;
  if (e.appleUntilMs > t || e.googleUntilMs > t) return 1;
  return 0;
}

/// 이 기기에서 **등급 올리기**를 권해야 하는가.
///
/// 기본 등급을 산 사람이 다른 OS 기기를 켠 순간이 바로 그 자리다. 그때
/// "여기서도 쓰시려면 한 단계 올리세요"라고 말해야 뜻이 통한다. 아무
/// 맥락 없는 화면에서 등급 표를 들이밀면 아무도 안 읽는다.
bool shouldOfferUpgrade({
  required Entitlement e,
  required String family,
  required DateTime now,
}) =>
    tierOf(e: e, now: now) == 1 && !premiumHere(e: e, family: family, now: now);

/// **개발 중에만** 쓰는 값. 스토어가 아직 상품을 안 내려줄 때(시뮬레이터,
/// 상품이 심사 준비 전, 인터넷 없음) 화면이 점 세 개로 비어 보이지 않도록
/// 채워 넣는다.
///
/// 릴리스에서는 절대 쓰지 않는다 — 화면 코드가 kDebugMode 로 막는다.
/// 진짜 값은 언제나 스토어가 준 ProductDetails.price 다. 나라마다 다르고,
/// 여기 적힌 숫자는 미국 값 하나뿐이며, 기념가가 끝나는 날 어긋난다.
///
/// 2026-08-26 소유자 확정값. App Store Connect 에 실제로 등록한 값과 같다.
const Map<String, String> kDevUsdPrice = <String, String>{
  kProductMonthly: r'$2.99',
  kProductYearly: r'$19.99',
  kProductAllMonthly: r'$3.99',
  kProductAllYearly: r'$29.99',
  kProductLifetime: r'$39.99',
};

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
