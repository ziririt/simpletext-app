/// 맥 상단 메뉴의 '파일'.
///
/// 2026-08-17 소유자 신고 — "맥용 앱에서 메뉴 중 '파일'이 아예 없는데?"
///
/// 맞다. 그리고 우리가 지운 게 아니라 **플러터의 맥 틀에 처음부터 없다.**
/// 문서를 다루지 않는 앱을 전제로 빼 놓은 것이다. 그런데 우리는 문서를
/// 다루는 앱이다. 맥 사용자에게 파일 메뉴가 없다는 것은 "이 앱은 맥 앱이
/// 아니다"라는 신호나 마찬가지다 — ⌘N도 ⌘O도 안 먹는다는 뜻이니까.
///
/// ## 왜 스위프트가 아니라 여기서 이름을 넘기나
///
/// 메뉴는 네이티브가 그린다. 그렇다고 아홉 언어 문구를 스위프트에 또 한
/// 벌 두면 반드시 어긋난다(이 앱은 이미 아이클라우드 다리에서 두 벌을
/// 겪고 있다). 그래서 **글자는 다트가 넘기고 스위프트는 그리기만 한다.**
/// 언어를 바꾸면 다시 넘겨서 다시 그린다.
///
/// ## 왜 PlatformMenuBar를 안 쓰나
///
/// 플러터의 PlatformMenuBar는 메뉴 막대를 **통째로** 갈아 끼운다. 그러면
/// 지금 편집 메뉴에 들어 있는 것들 — 맞춤법, 대체, 변환, 받아쓰기, 애플
/// 글쓰기 도구 — 이 전부 사라진다. 그건 파일 메뉴 하나를 얻으려고 열을
/// 잃는 거래다. 그래서 있는 막대에 하나만 끼워 넣는다.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef MenuAction = Future<void> Function(String id);

class MacMenu {
  MacMenu._();

  static const MethodChannel _ch = MethodChannel('skyblue/menu');

  static bool get supported => !kIsWeb && Platform.isMacOS;

  /// 메뉴를 눌렀을 때 할 일. 앱이 켜질 때 한 번 정한다.
  static MenuAction? _onPick;

  /// [titles]의 열쇠는 스위프트가 아는 이름과 같아야 한다.
  ///   file · new · import · exportMd · backup · close
  static Future<void> install(Map<String, String> titles,
      {required MenuAction onPick}) async {
    if (!supported) return;
    _onPick = onPick;
    _ch.setMethodCallHandler((call) async {
      if (call.method != 'menu') return null;
      final id = call.arguments as String?;
      if (id == null) return null;
      await _onPick?.call(id);
      return null;
    });
    try {
      await _ch.invokeMethod('install', titles);
    } catch (_) {
      // 메뉴를 못 달아도 앱은 돌아야 한다. 같은 일은 화면 안에서도 전부
      // 할 수 있다('...' 메뉴).
    }
  }
}
