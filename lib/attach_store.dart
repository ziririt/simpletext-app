/// 첨부 파일이 기기 안에서 사는 자리.
///
/// 2026-08-19. 판정은 core/attach_meta.dart 에 있고, 여기는 **디스크를
/// 만지는 일**만 한다. 갈라 놓은 까닭은 늘 같다 — 디스크를 만지는 코드는
/// 시험으로 못 박기 어렵고, 판정은 못 박아야 하기 때문이다.
///
/// ## 어디에 두나
///
///   <문서 폴더>/attach/<노트 아이디>/<첨부 아이디>
///
/// 확장자를 안 붙인다. 파일 이름은 메모 쪽 메타데이터가 들고 있고, 여기
/// 이름은 찾기 위한 열쇠일 뿐이다. 확장자를 붙이면 '결산표.pdf' 같은 이름이
/// 파일 시스템에 그대로 남는데, 그건 잠긴 메모의 첨부에서 이름이 새는 길이다.
///
/// ## 왜 임시 폴더가 아닌가
///
/// 내보내기(export_service.dart)는 임시 폴더를 쓴다. 그건 사용자가 어디로
/// 보내고 나면 우리가 들고 있을 이유가 없는 물건이라서다. 첨부는 반대다 —
/// 사용자가 여기 두려고 붙인 것이라 우리가 끝까지 들고 있어야 한다.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'core/attach_meta.dart';

class AttachStore {
  AttachStore._();

  /// 이 기기의 갈래. 첨부에 적히고, 다른 기기에서 "어디로 가면 되는지"가 된다.
  static String get deviceKind {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // 아이패드와 아이폰을 코드에서 가르지 않는다. 화면 크기로 짐작하는
        // 길이 있지만, 가로로 눕힌 아이폰과 아이패드 미니는 겹친다.
        // 부르는 쪽(main.dart)이 MediaQuery 로 정해 넘긴다.
        return 'iphone';
      case TargetPlatform.macOS:
        return 'mac';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.windows:
        return 'windows';
      default:
        return 'file';
    }
  }

  static Directory? _root;

  static Future<Directory> _dirOf(String noteId) async {
    _root ??= await getApplicationDocumentsDirectory();
    final d = Directory('${_root!.path}/attach/$noteId');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// 이 기기에 그 파일이 실제로 있는가. 없으면 null.
  ///
  /// 다른 기기에서 붙인 것은 메타데이터만 건너오므로 여기서 늘 null 이다.
  /// 그게 정상이고, 화면은 그때 안내 줄을 낸다.
  static Future<File?> fileOf(String noteId, Attach a) async {
    try {
      final f = File('${(await _dirOf(noteId)).path}/${a.id}');
      return await f.exists() ? f : null;
    } catch (_) {
      return null;
    }
  }

  /// 파일을 이 기기 안으로 들인다. 성공하면 메타데이터를 돌려준다.
  ///
  /// **원본을 옮기지 않고 베낀다.** 사용자가 고른 것은 사진 앱이나 파일 앱에
  /// 있는 남의 물건이다. 그걸 우리 쪽으로 옮겨 버리면 저쪽에서 사라진다.
  static Future<Attach?> add({
    required String noteId,
    required String name,
    required Stream<List<int>> bytes,
    required String device,
    required String id,
  }) async {
    try {
      final d = await _dirOf(noteId);
      final f = File('${d.path}/$id');
      final sink = f.openWrite();
      var size = 0;
      await for (final chunk in bytes) {
        size += chunk.length;
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      return Attach(
        id: id,
        name: name,
        size: size,
        addedAt: DateTime.now().millisecondsSinceEpoch,
        device: device,
      );
    } catch (_) {
      return null;
    }
  }

  /// 파일 하나를 지운다. 없으면 조용히 넘어간다.
  static Future<void> remove(String noteId, Attach a) async {
    try {
      final f = File('${(await _dirOf(noteId)).path}/${a.id}');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// 메모 하나의 첨부를 통째로 지운다.
  ///
  /// 휴지통에서 완전히 비울 때만 부른다. 휴지통으로 보낼 때는 안 부른다 —
  /// 되살릴 수 있는 메모의 첨부를 미리 태우면 되살려도 반쪽이다.
  static Future<void> purge(String noteId) async {
    try {
      _root ??= await getApplicationDocumentsDirectory();
      final d = Directory('${_root!.path}/attach/$noteId');
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
  }

  /// 이 기기가 들고 있는 첨부가 다 해서 몇 바이트인가. 설정 화면에 쓴다.
  static Future<int> totalBytes() async {
    try {
      _root ??= await getApplicationDocumentsDirectory();
      final d = Directory('${_root!.path}/attach');
      if (!await d.exists()) return 0;
      var n = 0;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) n += await e.length();
      }
      return n;
    } catch (_) {
      return 0;
    }
  }
}
