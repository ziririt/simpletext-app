/// 클립보드에 딸려 온 '어디서 복사했는지'를 읽어 온다.
///
/// 2026-08-16. 브라우저에서 글을 복사하면 클립보드에는 글자만 실리는 게
/// 아니다. 원본 주소나 HTML이 함께 실리는 경우가 많고, 거기에
/// chatgpt.com이 들어 있으면 출처는 추측이 아니라 **사실**이다.
///
/// 플러터의 Clipboard는 'text/plain'만 읽는다. 그래서 이 한 조각만 네이티브로
/// 내려간다. 스위프트 쪽 구현은 아이클라우드 다리와 같은 채널에 얹었다 —
/// 채널 하나 더 만드는 것보다 낫고, 하는 일이 '기기에 물어본다'로 같다.
///
/// 못 읽어도 아무 일도 일어나지 않는다. 주소가 없으면 글의 생김새로 추측하는
/// 2단(core/source_detect.dart)이 받는다.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ClipboardSource {
  static const MethodChannel _ch = MethodChannel('skyblue/icloud');

  static bool get supported =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// 붙여넣기 **직후에만** 부른다.
  ///
  /// 아이폰은 iOS 16부터 클립보드를 읽을 때 확인 창을 띄우는데, 사용자가
  /// 방금 붙여넣기를 눌러 글자를 읽어 온 흐름이라 그 창은 이미 지나간
  /// 뒤다. 아무 때나 부르면 뜬금없는 확인 창이 뜬다.
  static Future<String?> read() async {
    if (!supported) return null;
    try {
      return await _ch.invokeMethod<String>('clipboardSource');
    } catch (_) {
      return null;
    }
  }
}
