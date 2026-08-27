/// 웹 쪽 구현 — 붙여넣기 사건을 엿듣는다.
///
/// 브라우저는 아무 때나 클립보드를 읽게 해 주지 않는다. 그게 맞다 — 아무
/// 사이트나 남의 클립보드를 훔쳐보면 안 된다. 대신 **사용자가 붙여넣는 그
/// 순간**에는 무엇을 붙여넣는지 알려 준다.
///
/// 그래서 문서 전체에 귀를 하나 달아 두고, 붙여넣기가 지나갈 때 HTML
/// 조각만 주워 둔다. 글자는 안 본다 — 그건 플러터가 이미 받는다.
///
/// 주워 둔 것은 한 번 쓰면 버린다. 오래 들고 있으면 지난번 출처가 이번에
/// 손으로 친 글에 붙는다.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get supported => true;

String? _last;
bool _bound = false;

void _onPaste(web.Event e) {
  try {
    final d = (e as web.ClipboardEvent).clipboardData;
    if (d == null) return;
    final html = d.getData('text/html');
    final uri = d.getData('text/uri-list');
    // HTML 조각은 통째로 클 수 있다. 표식은 앞쪽에 있으므로 앞부분만
    // 들고 있는다 — 수 메가바이트를 쥐고 있을 이유가 없다.
    final take = html.isNotEmpty
        ? (html.length > 8000 ? html.substring(0, 8000) : html)
        : uri;
    _last = take.isEmpty ? null : take;
  } catch (_) {
    _last = null;
  }
}

void bootCapture() {
  if (_bound) return;
  _bound = true;
  // 캡처 단계에서 듣는다(true). 플러터가 사건을 삼키기 전에 지나가는
  // 자리라, 이렇게 해야 놓치지 않는다.
  web.document.addEventListener('paste', _onPaste.toJS, true.toJS);
}

Future<String?> readCapture() async {
  bootCapture();
  final v = _last;
  _last = null;
  return v;
}
