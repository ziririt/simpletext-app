/// 웹에서만 한글 글꼴을 우리가 심는다.
///
/// 2026-08-20 소유자 지적 — "웹앱의 경우 시스템 기본 폰트라야 할 것 같다.
/// 맥의 기본 시스템 폰트가 아니라서 매우 조악하다. 이게 무슨 폰트지?"
///
/// ## 무슨 글꼴이었나
///
/// 로보토(라틴)와 노토 산스 KR(한글)이 섞여 있었다. 둘 다 우리가 고른
/// 것이 아니다.
///
/// 웹 판은 CanvasKit 으로 그린다. **CanvasKit 은 글자를 스스로 그린다** —
/// 브라우저에게 맡기지 않는다. 그래서 맥에 깔린 글꼴(SF Pro, Apple SD
/// Gothic Neo)이 아예 안 보인다. 우리가 테마에 적어 둔 fontFamilyFallback
/// (['Apple SD Gothic Neo', 'Noto Sans KR', 'Malgun Gothic'])도 웹에서는
/// **이름만 있고 실체가 없다.** 폰과 맥 앱에서는 그 이름들이 진짜 글꼴을
/// 가리키지만 웹에서는 아무것도 안 가리킨다.
///
/// 그러면 CanvasKit 이 제 기본값(로보토)으로 그리고, 로보토에 없는 한글은
/// gstatic 에서 노토를 내려받아 메운다. 두 글꼴의 굵기와 폭이 안 맞으니
/// 섞인 줄이 어색하다. 사장님이 '조악하다'고 한 것이 그 어긋남이다.
///
/// ## 왜 프리텐다드인가
///
/// 애플 SF Pro 와 Apple SD Gothic Neo 를 닮도록 만든 한글 글꼴이다.
/// 라틴 쪽도 함께 들어 있어서 **한 글꼴로 한 줄이 그려진다** — 섞이지
/// 않는 것 자체가 절반이다.
///
/// ## 왜 자산(assets)이 아니라 실어 오는가
///
/// pubspec 의 fonts: 에 적으면 **아이폰·안드로이드 앱에도 3MB가 실린다.**
/// 그 기기들은 이미 제 시스템 글꼴이 있어서 쓸 일이 없는데도 무게만 는다.
/// 자산은 판별로 골라 담을 수가 없다.
///
/// 그래서 웹의 `web/fonts/` 에 두고 여기서 받아 온다. 그 폴더는 웹 빌드에만
/// 딸려 가고, 우리 사이트에서 우리가 내주므로 남의 CDN에 매이지도 않는다.
///
/// 실패하면 그냥 넘어간다. 글꼴을 못 받은 것이 앱을 못 여는 이유가 될 수는
/// 없다 — 그때는 예전처럼 로보토+노토로 그려진다.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// 웹에서 이 이름으로 글꼴을 심는다. 테마가 이 이름을 부른다.
const String kWebFontFamily = 'Pretendard';

bool _done = false;

/// 앱이 뜨기 전에 한 번 부른다. 두 번 불러도 한 번만 한다.
///
/// 굵기 둘만 받는다(400·700). 이 앱이 화면에서 쓰는 굵기가 그 둘이고,
/// 나머지는 플러터가 사이를 메운다. 아홉 굵기를 다 받으면 14MB다.
Future<void> loadWebFont() async {
  if (!kIsWeb || _done) return;
  _done = true;
  try {
    final loader = FontLoader(kWebFontFamily);
    for (final name in const ['Pretendard-Regular.otf', 'Pretendard-Bold.otf']) {
      loader.addFont(http
          .readBytes(Uri.base.resolve('fonts/$name'))
          .then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
    }
    await loader.load();
  } catch (_) {
    // 못 받아도 앱은 뜬다.
  }
}
