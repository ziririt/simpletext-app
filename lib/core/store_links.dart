/// 스토어·소개 주소 — 한 결정 한 곳 (2026-08-24).
///
/// 설정의 '앱 공유'와 '평가해 주세요'가 쓴다. 주소를 화면 코드에
/// 흩뿌리면 스토어 번호가 바뀌는 날 몇 군데를 고쳤는지 알 수 없게 된다.
library;

/// 앱스토어 앱 번호. 애플이 정해 준 값이라 바뀌지 않는다.
const String kAppStoreId = '6802185169';

/// 앱스토어 등록 페이지.
String appStoreUrl() => 'https://apps.apple.com/app/id$kAppStoreId';

/// 앱스토어 리뷰 작성 화면으로 바로 가는 주소.
String appStoreReviewUrl() =>
    'https://apps.apple.com/app/id$kAppStoreId?action=write-review';

/// 소개 페이지 — 스토어 등록이 없는 기기(안드로이드 테스트판·맥
/// 직배포판)에서 공유할 곳.
/// 개인정보처리방침. 결제 화면에 **반드시** 링크가 있어야 한다(애플 3.1.2).
String privacyUrl() => 'https://ezlong.com/skybluenote/privacy/';

/// 이용약관. 애플은 우리가 따로 약관을 두지 않으면 **애플 표준 EULA**를
/// 링크하는 것을 인정한다. 안드로이드·웹용 자체 약관 페이지가 생기면
/// 여기만 고치면 된다.
String appleEulaUrl() =>
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

String landingUrl() => 'https://ezlong.com/skybluenote/';

/// 공유할 주소. 앱스토어에 있는 판(iOS·iPadOS)은 스토어로, 나머지는
/// 소개 페이지로 보낸다 — 받은 사람이 바로 깔 수 있는 문이 우선이다.
String shareUrl({required bool isIOS}) =>
    isIOS ? appStoreUrl() : landingUrl();
