/// 폰과 데스크톱 쪽 구현. 스위프트·코틀린이 받는다.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// 애플 쪽은 아이클라우드 다리와 같은 채널에 얹었다 — 채널을 하나 더
/// 만드는 것보다 낫고, 하는 일이 '기기에 물어본다'로 같다.
const MethodChannel _apple = MethodChannel('skyblue/icloud');

/// 안드로이드는 공유 받기 채널에 얹었다. 같은 까닭이다.
const MethodChannel _android = MethodChannel('skyblue/share');

bool get supported => Platform.isIOS || Platform.isMacOS || Platform.isAndroid;

Future<String?> readCapture() async {
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      return await _apple.invokeMethod<String>('clipboardSource');
    }
    if (Platform.isAndroid) {
      return await _android.invokeMethod<String>('clipboardSource');
    }
  } catch (_) {
    // 못 읽는 것은 고장이 아니다. 증거가 없을 뿐이다.
  }
  return null;
}

void bootCapture() {}
