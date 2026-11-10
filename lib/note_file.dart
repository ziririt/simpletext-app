// 노트 묶음 파일을 여닫는다. 규칙은 core/note_store_codec.dart 에 있다.
//
// 쓸 때는 **옆 이름에 다 쓰고 나서 이름을 바꾼다.** 쓰다가 앱이 멈춰도
// 원래 파일은 온전하다. 이름 바꾸기는 한 번에 일어난다.
//
// 웹은 파일이 없다 — 여기 함수들이 null/false 를 돌려주고, Store 가 예전
// 처럼 SharedPreferences(브라우저 저장소)를 쓴다.

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;

class NoteFile {
  NoteFile._();

  static const name = 'notes.v3.json';
  static String? _path;

  static Future<String?> path() async {
    if (kIsWeb) return null;
    if (_path != null) return _path;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return _path = '${dir.path}/$name';
  }

  static Future<String?> read() async {
    final p = await path();
    if (p == null) return null;
    final f = File(p);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  /// 다 쓰고 디스크에 밀어 넣은 뒤에 이름을 바꾼다.
  static Future<bool> write(String text) async {
    final p = await path();
    if (p == null) return false;
    final tmp = File('$p.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(p);
    return true;
  }

  /// 읽지 못한 파일을 지우지 않고 옆에 떠 둔다. 나중에 사람이 꺼낼 수 있게.
  static Future<void> keepBroken(String text) async {
    final p = await path();
    if (p == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch;
    await File('$p.broken-$ms').writeAsString(text, flush: true);
  }
}
