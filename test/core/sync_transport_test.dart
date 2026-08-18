// 통로의 약속을 못 박는다.
//
// 2026-08-18. 진짜 아이클라우드는 시험에서 못 부른다. 대신 **약속 자체**를
// 지키는 가짜 통로를 하나 만들어 두면, 앞으로 붙일 구글 드라이브 통로가
// 무엇을 지켜야 하는지가 코드로 남는다.
//
// 이 파일이 진짜로 막는 사고: 새 통로를 만들면서 '없는 파일'과 '아직 안
// 내려온 파일'을 같게 다루는 것. 그러면 남의 기기가 올린 메모를 없는
// 것으로 읽고 삭제 기록을 쓴다 — 메모가 사라진다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_transport.dart';

/// 머릿속에만 있는 통로. 시험과 문서를 겸한다.
class MemoryTransport implements SyncTransport {
  final Map<String, Map<String, dynamic>> files = {};
  final Set<String> dirs = {};

  /// 아직 안 내려온 것으로 칠 경로들(아이클라우드 흉내).
  final Set<String> notReady = {};

  @override
  String get id => 'memory';

  @override
  Future<bool> ensureDir(String path) async {
    dirs.add(path);
    return true;
  }

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<ReadResult> read(String path) async {
    if (notReady.contains(path)) return ReadResult.notReady;
    final b = files[path];
    return b == null ? ReadResult.missing : ReadResult(ReadState.ok, b);
  }

  @override
  Future<List<Map<String, dynamic>>> readDir(String path) async {
    final out = <Map<String, dynamic>>[];
    for (final e in files.entries) {
      final k = e.key;
      if (!k.startsWith('$path/')) continue;
      if (k.substring(path.length + 1).contains('/')) continue;
      if (notReady.contains(k)) continue;
      out.add(e.value);
    }
    return out;
  }

  @override
  Future<void> write(String path, Map<String, dynamic> body) async {
    files[path] = Map<String, dynamic>.from(body);
  }

  @override
  Future<void> remove(String path) async {
    files.remove(path);
  }
}

void main() {
  group('통로의 약속', () {
    late MemoryTransport t;
    setUp(() => t = MemoryTransport());

    test('쓴 것을 그대로 읽는다', () async {
      await t.write('/r/notes/a.json', {'id': 'a', 'body': '가'});
      final got = await t.read('/r/notes/a.json');
      expect(got.ok, isTrue);
      expect(got.body!['body'], '가');
    });

    test('없는 것은 missing 이지 notReady 가 아니다', () async {
      final got = await t.read('/r/notes/none.json');
      expect(got.state, ReadState.missing);
    });

    test('안 내려온 것은 notReady — 이 둘을 섞으면 메모가 사라진다', () async {
      t.notReady.add('/r/rules.json');
      final got = await t.read('/r/rules.json');
      expect(got.state, ReadState.notReady);
      expect(got.body, isNull);
    });

    test('폴더째 읽기는 그 폴더의 것만 준다', () async {
      await t.write('/r/notes/a.json', {'id': 'a'});
      await t.write('/r/notes/b.json', {'id': 'b'});
      await t.write('/r/tombs/c.json', {'id': 'c'});
      await t.write('/r/notes/sub/d.json', {'id': 'd'});
      final got = await t.readDir('/r/notes');
      expect(got.map((e) => e['id']).toSet(), {'a', 'b'});
    });

    test('폴더째 읽기에서 안 내려온 것은 빠진다', () async {
      await t.write('/r/notes/a.json', {'id': 'a'});
      await t.write('/r/notes/b.json', {'id': 'b'});
      t.notReady.add('/r/notes/b.json');
      final got = await t.readDir('/r/notes');
      expect(got.map((e) => e['id']).toList(), ['a']);
    });

    test('지운 뒤에는 없다. 없는 것을 지워도 안 죽는다', () async {
      await t.write('/r/notes/a.json', {'id': 'a'});
      await t.remove('/r/notes/a.json');
      expect(await t.exists('/r/notes/a.json'), isFalse);
      await t.remove('/r/notes/a.json');
    });

    test('덮어쓰면 앞의 것은 안 남는다', () async {
      await t.write('/r/x.json', {'v': 1, 'old': true});
      await t.write('/r/x.json', {'v': 2});
      final got = await t.read('/r/x.json');
      expect(got.body, {'v': 2});
    });
  });
}
