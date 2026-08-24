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
String landingUrl() => 'https://ezlong.com/skybluenote/';

/// 공유할 주소. 앱스토어에 있는 판(iOS·iPadOS)은 스토어로, 나머지는
/// 소개 페이지로 보낸다 — 받은 사람이 바로 깔 수 있는 문이 우선이다.
String shareUrl({required bool isIOS}) =>
    isIOS ? appStoreUrl() : landingUrl();
