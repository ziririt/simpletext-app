/// 아이클라우드 통로 — 파일과 폴더로 오간다.
///
/// 2026-08-18. icloud_sync.dart 안에 섞여 있던 파일 다루는 부분을 그대로
/// 옮겼다. 하는 일은 바뀌지 않았다.
///
/// 여기에만 있는 것 둘.
///   1) '.이름.icloud' — 아직 안 내려온 파일의 자리표. 이걸 못 알아보면
///      남의 기기가 올린 메모를 없는 것으로 읽는다.
///   2) 임시 파일에 쓰고 이름 바꾸기 — 쓰는 도중에 앱이 죽어도 반쪽짜리
///      파일이 구름으로 올라가지 않게.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../core/sync_transport.dart';

/// 아이클라우드가 안 내려받은 파일에 붙이는 꼬리.
const String _kPlaceholderTail = '.icloud';

class IcloudTransport implements SyncTransport {
  const IcloudTransport(this._ch);

  final MethodChannel _ch;

  @override
  String get id => 'icloud';

  @override
  Future<bool> ensureDir(String path) async {
    try {
      await Directory(path).create(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ReadResult> read(String path) async {
    final f = File(path);
    if (await f.exists()) {
      try {
        final j = jsonDecode(await f.readAsString());
        if (j is Map<String, dynamic>) return ReadResult(ReadState.ok, j);
      } catch (_) {}
      return ReadResult.missing;
    }
    // 이름만 와 있는가.
    final cut = path.lastIndexOf('/');
    final dir = cut < 0 ? '.' : path.substring(0, cut);
    final name = cut < 0 ? path : path.substring(cut + 1);
    if (await File('$dir/.$name$_kPlaceholderTail').exists()) {
      await _pull([path]);
      return ReadResult.notReady;
    }
    return ReadResult.missing;
  }

  @override
  Future<List<Map<String, dynamic>>> readDir(String path) async {
    final out = <Map<String, dynamic>>[];
    final pending = <String>[];
    List<FileSystemEntity> items;
    try {
      items = await Directory(path).list().toList();
    } catch (_) {
      return out;
    }
    for (final e in items) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      if (name.startsWith('.') && name.endsWith(_kPlaceholderTail)) {
        final real =
            name.substring(1, name.length - _kPlaceholderTail.length);
        pending.add('$path/$real');
        continue;
      }
      if (!name.endsWith('.json')) continue;
      try {
        final j = jsonDecode(await e.readAsString());
        if (j is Map<String, dynamic>) out.add(j);
      } catch (_) {}
    }
    if (pending.isNotEmpty) await _pull(pending);
    return out;
  }

  @override
  Future<void> write(String path, Map<String, dynamic> body) async {
    final tmp = File('$path.tmp');
    try {
      await tmp.writeAsString(jsonEncode(body), flush: true);
      await tmp.rename(path);
    } catch (_) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _pull(List<String> paths) async {
    try {
      await _ch.invokeMethod('download', {'paths': paths});
    } catch (_) {}
  }
}
