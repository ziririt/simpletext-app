// 웹판의 노트 그릇: IndexedDB. 사연은 note_file.dart 머리말.
//
// 데이터베이스 하나(skyblue_note), 칸 하나(store), 열쇠 두 개:
//   'notes.v3'          노트 묶음 글자 그대로
//   'notes.v3.broken'   읽지 못한 묶음을 지우지 않고 떠 둔 것
//
// 이 그릇을 못 여는 브라우저(사생활 보호 창의 일부 등)에서는 read 가
// null, write 가 false 를 돌려준다. 그러면 Store 가 옛 서랍으로 돌아간다
// — 옛날과 똑같이 되는 것이지 더 나빠지지는 않는다.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class NoteFile {
  NoteFile._();

  static const name = 'notes.v3';
  static const _db = 'skyblue_note';
  static const _store = 'store';

  static Future<web.IDBDatabase?>? _opening;

  static Future<String?> path() async => null;

  static Future<web.IDBDatabase?> _open() => _opening ??= _openOnce();

  static Future<web.IDBDatabase?> _openOnce() async {
    try {
      final req = web.window.indexedDB.open(_db, 1);
      req.onupgradeneeded = ((web.Event _) {
        final db = req.result as web.IDBDatabase;
        if (!db.objectStoreNames.contains(_store)) {
          db.createObjectStore(_store);
        }
      }).toJS;
      final r = await _wait(req);
      return r as web.IDBDatabase?;
    } catch (_) {
      // 다음에 다시 열어 보게 둔다.
      _opening = null;
      return null;
    }
  }

  static Future<JSAny?> _wait(web.IDBRequest req) {
    final c = Completer<JSAny?>();
    req.onsuccess = ((web.Event _) {
      if (!c.isCompleted) c.complete(req.result);
    }).toJS;
    req.onerror = ((web.Event _) {
      if (!c.isCompleted) {
        c.completeError(StateError('indexedDB: ${req.error?.name ?? '?'}'));
      }
    }).toJS;
    return c.future;
  }

  /// 쓰기는 '요청이 끝났다'가 아니라 **거래가 끝났다**를 기다린다.
  /// 요청 성공 뒤에도 거래가 디스크에 닿기 전에 깨질 수 있다.
  static Future<void> _done(web.IDBTransaction tx) {
    final c = Completer<void>();
    tx.oncomplete = ((web.Event _) {
      if (!c.isCompleted) c.complete();
    }).toJS;
    tx.onerror = ((web.Event _) {
      if (!c.isCompleted) {
        c.completeError(StateError('indexedDB: ${tx.error?.name ?? '?'}'));
      }
    }).toJS;
    tx.onabort = ((web.Event _) {
      if (!c.isCompleted) {
        c.completeError(StateError('indexedDB: ${tx.error?.name ?? 'abort'}'));
      }
    }).toJS;
    return c.future;
  }

  static Future<String?> _get(String key) async {
    final db = await _open();
    if (db == null) return null;
    final tx = db.transaction(_store.toJS, 'readonly');
    final r = await _wait(tx.objectStore(_store).get(key.toJS));
    if (r == null || r.isUndefinedOrNull) return null;
    return (r as JSString).toDart;
  }

  static Future<bool> _put(String key, String text) async {
    final db = await _open();
    if (db == null) return false;
    final tx = db.transaction(_store.toJS, 'readwrite');
    tx.objectStore(_store).put(text.toJS, key.toJS);
    await _done(tx);
    return true;
  }

  static Future<String?> read() async {
    try {
      return await _get(name);
    } catch (_) {
      return null;
    }
  }

  /// 그릇이 없으면 false — Store 가 옛 서랍에 쓴다. 그릇은 있는데 쓰다가
  /// 실패하면 던진다. 그걸 false 로 삼키면 16MB 를 다시 서랍에 밀어 넣어
  /// 오늘의 사고를 그대로 되풀이한다.
  static Future<bool> write(String text) => _put(name, text);

  static Future<void> keepBroken(String text) async {
    try {
      await _put('$name.broken', text);
    } catch (_) {}
  }
}
