/// 다른 앱에서 보낸 글 받기.
///
/// 2026-08-17 — "공유 시트로 받기". 조사에서 **앱을 미완성으로 느끼게 만드는
/// 여섯 가지** 중 하나로 나왔던 것이다.
///
/// 왜 이게 그렇게 크냐면, 이 앱의 쓰임새가 정확히 그 자리이기 때문이다.
/// 사람은 브라우저나 챗봇 앱에서 답을 받고, 그 자리에서 어딘가로 보낸다.
/// 그때 목록에 우리가 없으면 **앱을 따로 열고, 새 문서를 만들고, 붙여넣는**
/// 세 걸음을 걷게 된다. 세 걸음이면 대부분은 그냥 다른 앱에 넣는다.
///
/// ## 두 길로 들어온다
///
/// **앱이 꺼져 있었으면** 시스템이 앱을 켜면서 글을 준다. 그런데 그 글이
/// 도착하는 시점은 다트가 준비되기 전일 수 있다. 그래서 네이티브 쪽이
/// 서랍에 넣어 두고, 다트가 준비되면 [take]로 가지러 온다.
///
/// **앱이 켜져 있었으면** 그냥 밀어 준다. [listen]이 그것을 받는다.
///
/// 둘 중 하나만 붙이면 "처음엔 되는데 두 번째부터 안 된다"거나 그 반대가
/// 된다. 둘 다 있어야 한다.
library;

import 'package:flutter/services.dart';

class ShareIntake {
  static const MethodChannel _ch = MethodChannel('skyblue/share');

  /// 켜질 때 한 번 가지러 간다. 없으면 null.
  ///
  /// 실패해도 앱이 죽으면 안 된다. 이 다리가 없는 플랫폼(맥·윈도우)에서는
  /// MissingPluginException이 나는 것이 정상이다.
  static Future<String?> take() async {
    try {
      final t = await _ch.invokeMethod<String>('take');
      if (t == null || t.trim().isEmpty) return null;
      return t;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 앱이 켜져 있는 동안 들어오는 것.
  static void listen(void Function(String text) onText) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'received') {
        final t = call.arguments;
        if (t is String && t.trim().isNotEmpty) onText(t);
      }
      return null;
    });
  }
}
