/// 가져오기 — 파일을 골라 읽어 오는 쪽.
///
/// 규칙(무엇을 제목으로 삼고 앞머리를 어떻게 떼는지)은 core/import_text.dart에
/// 있고 테스트로 고정되어 있다. 여기는 파일 고르기와 저장만 한다.
library;

import 'dart:convert';

import 'package:file_selector/file_selector.dart';

import 'core/import_text.dart';
import 'main.dart' show Store, Note;

class ImportService {
  /// 열 수 있는 파일 종류.
  ///
  /// 확장자만 주면 아이폰에서 거의 모든 파일이 회색으로 비활성화된다 —
  /// iOS는 확장자가 아니라 UTI로 고른다. 안드로이드는 MIME을 본다. 셋을
  /// 다 적어야 어느 기기에서든 파일이 눌린다.
  static const XTypeGroup _texts = XTypeGroup(
    label: 'text',
    extensions: kTextExtensions,
    uniformTypeIdentifiers: [
      'public.plain-text',
      'public.text',
      'net.daringfireball.markdown',
      'public.json',
      'public.comma-separated-values-text',
    ],
    mimeTypes: [
      'text/plain',
      'text/markdown',
      'application/json',
      'text/csv',
    ],
  );

  /// 파일 여러 개를 메모 여러 개로. 만든 개수를 돌려준다.
  static Future<int> importFiles() async {
    final files = await openFiles(acceptedTypeGroups: const [_texts]);
    if (files.isEmpty) return 0;
    final store = Store.instance;
    var made = 0;
    for (final f in files) {
      String content;
      try {
        content = await f.readAsString();
      } catch (_) {
        // 텍스트가 아니었다. 깨진 글자로 메모를 만드는 것보다 건너뛰는 게 낫다.
        continue;
      }
      if (f.name.toLowerCase().endsWith('.json')) {
        final n = _restoreBackup(content);
        if (n > 0) {
          made += n;
          continue;
        }
      }
      final p = parseTextFile(f.name, content);
      final now = DateTime.now().millisecondsSinceEpoch;
      store.notes.insert(
        0,
        Note(
          id: 'i$now-$made-${now % 997}',
          title: p.title,
          body: p.body,
          originalBody: p.body,
          tags: p.tags,
          source: p.source,
          createdAt: now,
          updatedAt: now,
        ),
      );
      made++;
    }
    if (made > 0) await store.persist();
    return made;
  }

  /// 지금 메모 끝에 붙일 글. 사용자가 취소했거나 못 읽으면 null.
  static Future<String?> pickAppendText() async {
    final f = await openFile(acceptedTypeGroups: const [_texts]);
    if (f == null) return null;
    try {
      return appendBlock(f.name, await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// 우리가 만든 백업 파일이면 되살린다. 아니면 0.
  ///
  /// **이미 있는 메모는 절대 덮지 않는다.** 백업을 실수로 두 번 넣거나 옛
  /// 백업을 넣었을 때 지금 글이 옛 글로 되돌아가면, 그건 되돌릴 수 없는
  /// 손실이다. 없는 것만 더한다.
  static int _restoreBackup(String content) {
    try {
      final j = jsonDecode(content);
      if (j is! Map || j['app'] != 'SkyblueNote') return 0;
      final list = (j['notes'] as List?) ?? const [];
      final store = Store.instance;
      final have = {for (final n in store.notes) n.id};
      var added = 0;
      for (final e in list) {
        if (e is! Map) continue;
        final m = e.cast<String, dynamic>();
        final id = m['id'];
        if (id is! String || have.contains(id)) continue;
        try {
          store.notes.add(Note.fromJson(m));
          have.add(id);
          added++;
        } catch (_) {}
      }
      return added;
    } catch (_) {
      return 0;
    }
  }
}
