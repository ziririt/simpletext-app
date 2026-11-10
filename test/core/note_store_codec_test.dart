import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/note_store_codec.dart';

// 2026-11-11: 16MB 노트 묶음이 서랍에서 사라진 사고의 재발 방지 시험.
class _N {
  final String id;
  _N(this.id);
  static _N fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! String) throw const FormatException('id 없음');
    return _N(id);
  }
}

String _raw(Map<String, dynamic> m) => jsonEncode(m);

void main() {
  group('묶음 읽기', () {
    test('멀쩡한 묶음은 다 읽는다', () {
      final d = decodeStore<_N>(
        _raw({
          'v': 3,
          'notes': [
            {'id': 'a'},
            {'id': 'b'},
          ],
          'tombstones': [
            {'id': 'x', 'deletedAt': 1},
          ],
          'trash': [],
        }),
        _N.fromJson,
      )!;
      expect(d.notes.map((n) => n.id), ['a', 'b']);
      expect(d.tombstones.length, 1);
      expect(d.unreadable, isEmpty);
    });

    test('노트 하나가 깨져도 나머지는 산다 — 전체를 환영 노트로 갈지 않는다', () {
      final d = decodeStore<_N>(
        _raw({
          'notes': [
            {'id': 'a'},
            {'id': 7},
            {'id': 'c'},
          ],
        }),
        _N.fromJson,
      )!;
      expect(d.notes.map((n) => n.id), ['a', 'c']);
      expect(d.unreadable.length, 1, reason: '깨진 것은 버리지 않고 들고 있다');
    });

    test('들고 있던 깨진 노트를 새 판이 읽을 수 있으면 돌아온다', () {
      final d = decodeStore<_N>(
        _raw({
          'notes': [
            {'id': 'a'},
          ],
          'unreadable': [
            {'id': 'b'},
          ],
        }),
        _N.fromJson,
      )!;
      expect(d.notes.map((n) => n.id), ['a', 'b']);
      expect(d.unreadable, isEmpty);
    });

    test('껍데기가 깨지면 null — 부르는 쪽이 원본을 떠 둔다', () {
      expect(decodeStore<_N>('{"notes": [', _N.fromJson), isNull);
      expect(decodeStore<_N>('[]', _N.fromJson), isNull);
      expect(decodeStore<_N>('', _N.fromJson), isNull);
    });

    test('칸이 없어도 죽지 않는다', () {
      final d = decodeStore<_N>('{}', _N.fromJson)!;
      expect(d.notes, isEmpty);
      expect(d.tombstones, isEmpty);
      expect(d.trash, isEmpty);
    });

    test('16MB 묶음도 읽는다', () {
      final body = 'ㄱ' * 30000;
      final notes = [
        for (var i = 0; i < 600; i++) {'id': 'n$i', 'body': body},
      ];
      final raw = _raw({'notes': notes});
      expect(utf8.encode(raw).length, greaterThan(4 * 1024 * 1024));
      final d = decodeStore<_N>(raw, _N.fromJson)!;
      expect(d.notes.length, 600);
    });
  });

  group('어디서 읽나', () {
    test('파일이 참이다', () {
      expect(
        pickStoreSource(fileReadable: true, prefsReadable: true),
        StoreSource.file,
      );
    });
    test('파일이 없거나 깨졌을 때만 옛 서랍', () {
      expect(
        pickStoreSource(fileReadable: false, prefsReadable: true),
        StoreSource.prefs,
      );
      expect(
        pickStoreSource(fileReadable: false, prefsReadable: false),
        StoreSource.none,
      );
    });
  });

  group('옛 서랍 비우기', () {
    test('파일에서 다시 읽은 수가 모자라면 서랍을 지우지 않는다', () {
      expect(mayDropPrefsCopy(notesInPrefs: 600, notesReadBackFromFile: 599),
          isFalse);
      expect(mayDropPrefsCopy(notesInPrefs: 600, notesReadBackFromFile: 600),
          isTrue);
    });
  });
}
