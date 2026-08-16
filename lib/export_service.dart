/// 내보내기 — 파일을 만들어 시스템 공유 시트에 넘기는 쪽.
///
/// 형식(무엇을 어떤 모양으로 쓸지)은 core/export_md.dart에 있고 테스트로
/// 고정되어 있다. 여기는 그걸 파일로 떨어뜨리고 넘기는 일만 한다.
///
/// ## 왜 '저장'이 아니라 '공유'인가
///
/// 애플 기기에서는 공유 시트가 곧 저장 화면이다. 거기서 파일 앱에 저장,
/// 에어드롭, 메일, 다른 앱으로 보내기가 전부 된다. 우리가 파일 탐색기를
/// 따로 만들면 그중 하나만 되는 더 나쁜 물건이 된다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

import 'core/export_md.dart';
import 'main.dart' show Store, Note;

class ExportService {
  /// 임시 폴더에 파일을 쓴다.
  ///
  /// 앱 문서 폴더가 아니라 임시 폴더인 이유: 내보낸 파일은 사용자가 어디로
  /// 보내고 나면 우리가 들고 있을 이유가 없다. 문서 폴더에 쌓아 두면 용량만
  /// 먹고 사용자는 그게 있는 줄도 모른다.
  static Future<File> _temp(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('skyblue_export');
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  /// 메모 하나를 마크다운으로.
  static Future<bool> shareNote(Note n) async {
    try {
      final md = noteToMarkdown(
        title: n.title,
        body: n.body,
        tags: n.tags,
        source: n.source,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      );
      final name = '${safeFileName(n.title.isNotEmpty ? n.title : n.body)}.md';
      final f = await _temp(name, utf8.encode(md));
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 메모 전부를 마크다운 여러 장으로 묶어서.
  ///
  /// 압축 파일 안에서 이름이 겹치면 푸는 쪽이 조용히 하나만 남기는 경우가
  /// 있다 — 내보냈는데 메모가 사라지는, 가장 나쁜 사고다. uniqueName이
  /// 그걸 막는다(테스트로 고정).
  static Future<bool> shareAllMarkdown() async {
    try {
      final notes = Store.instance.notes;
      if (notes.isEmpty) return false;
      final archive = Archive();
      final used = <String>{};
      for (final n in notes) {
        final base = uniqueName(
            safeFileName(n.title.isNotEmpty ? n.title : n.body), used);
        final md = noteToMarkdown(
          title: n.title,
          body: n.body,
          tags: n.tags,
          source: n.source,
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
        final bytes = utf8.encode(md);
        archive.addFile(ArchiveFile('$base.md', bytes.length, bytes));
      }
      final zip = ZipEncoder().encode(archive);
      final f = await _temp('SkyblueNote-${_stamp()}.zip', zip);
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 통째로 되돌릴 수 있는 백업 한 장.
  ///
  /// 마크다운은 사람이 읽고 다른 앱으로 옮기기 위한 것이고, 이건 이 앱으로
  /// 그대로 되돌리기 위한 것이다. 둘의 쓰임이 달라서 둘 다 둔다.
  static Future<bool> shareBackup() async {
    try {
      final s = Store.instance;
      final j = jsonEncode({
        'app': 'SkyblueNote',
        'v': 3,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'notes': s.notes.map((n) => n.toJson()).toList(),
        'tombstones': s.tombstones,
        // 설정은 넣되 AI 키는 뺀다. 백업 파일이 메일이나 클라우드로 나가는
        // 물건이라 키가 거기 실리면 안 된다 — 기기 밖으로 안 나간다는
        // 약속은 백업에도 적용된다.
        'settings': _settingsWithoutKey(),
      });
      final f = await _temp('SkyblueNote-backup-${_stamp()}.json',
          utf8.encode(j));
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _settingsWithoutKey() {
    final m = Map<String, dynamic>.from(Store.instance.settings.toJson());
    m.remove('aiKey');
    m.remove('aiModels');
    return m;
  }

  static String _stamp() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}';
  }
}
