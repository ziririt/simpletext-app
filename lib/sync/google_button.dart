/// 구글이 그린 로그인 단추 — 웹에서만 실체가 있다.
///
/// 2026-08-20. 웹은 우리가 `signIn()` 을 부르는 길이 없다. 구글이 자기가
/// 그린 위젯을 페이지에 심으라고 요구하고, 사람이 그것을 누른 그 자리에서만
/// 창이 열린다(브라우저의 팝업 차단을 통과하려면 그래야 한다).
///
/// 그 위젯은 `package:google_sign_in_web` 안에 있고, 그 꾸러미는 웹이 아닌
/// 자리에서는 아예 못 읽는다. 그래서 갈래 수입(conditional import)으로
/// 가른다 — 웹에서는 진짜 단추, 나머지에서는 빈 자리.
///
/// 조건을 `dart.library.js_interop` 으로 잡는 까닭: 이건 '웹인가'를 묻는
/// 가장 정직한 물음이다. 판을 이름으로 물으면(Platform.isX) 웹에서 아예
/// 안 돌고, kIsWeb 은 **값**이라 수입을 가를 수 없다. 수입은 컴파일할 때
/// 갈라야 한다.
library;

export 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart';
