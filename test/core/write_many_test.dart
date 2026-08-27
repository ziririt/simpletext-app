/// 겹쳐 보내기 시험.
///
/// 2026-08-27 — 한 바퀴가 10~35초씩 걸리던 까닭이 여기 있었다. 받는 쪽은
/// 겹쳐 받는데(readMany) 보내는 쪽만 하나씩 줄을 서 있었다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_transport.dart';

/// 하나씩만 쓸 줄 아는 통로 — 기본 writeMany 가 도는지 본다.
class _Plain extends SyncTransport {
  final Map<String, Map<String, dynamic>> files = {};
  final List<String> order = [];

  @override
  String get id => 'plain';
  @override
  Future<bool> ensureDir(String path) async => true;
  @override
  Future<bool> exists(String path) async => files.containsKey(path);
  @override
  Future<ReadResult> read(String path) async {
    final b = files[path];
    return b == null ? ReadResult.missing : ReadResult(ReadState.ok, b);
  }

  @override
  Future<List<Map<String, dynamic>>> readDir(String path) async => [];
  @override
  Future<void> write(String path, Map<String, dynamic> body) async {
    order.add(path);
    files[path] = body;
  }

  @override
  Future<void> remove(String path) async => files.remove(path);
}

/// 겹쳐 쓰는 통로 — 몇 개가 동시에 떠 있었는지 센다.
class _Lanes extends _Plain {
  int live = 0;
  int peak = 0;
  final int lanes;
  _Lanes(this.lanes);

  @override
  Future<void> write(String path, Map<String, dynamic> body) async {
    live++;
    if (live > peak) peak = live;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await super.write(path, body);
    live--;
  }

  @override
  Future<void> writeMany(Map<String, Map<String, dynamic>> items) async {
    final paths = items.keys.toList();
    for (var i = 0; i < paths.length; i += lanes) {
      final slice = paths.skip(i).take(lanes).toList();
      await Future.wait(slice.map((p) => write(p, items[p]!)));
    }
  }
}

void main() {
  test('기본 통로는 하나씩 쓴다 — 왕복이 공짜인 곳은 겹칠 이유가 없다', () async {
    final t = _Plain();
    await t.writeMany({
      'a.json': {'id': 'a'},
      'b.json': {'id': 'b'},
    });
    expect(t.files.length, 2);
    expect(t.order, ['a.json', 'b.json']);
  });

  test('빈 꾸러미는 아무 일도 안 한다', () async {
    final t = _Plain();
    await t.writeMany({});
    expect(t.order, isEmpty);
  });

  test('겹쳐 쓰는 통로는 줄 수만큼 동시에 뜬다', () async {
    final t = _Lanes(6);
    await t.writeMany({
      for (var i = 0; i < 13; i++) 'n$i.json': {'id': 'n$i'},
    });
    expect(t.files.length, 13);
    expect(t.peak, 6, reason: '여섯 줄로 나눠 보내야 한다');
  });

  test('줄 수보다 적으면 그만큼만 뜬다', () async {
    final t = _Lanes(6);
    await t.writeMany({
      'a.json': {'id': 'a'},
      'b.json': {'id': 'b'},
    });
    expect(t.peak, 2);
  });

  test('겹쳐 써도 하나도 빠뜨리지 않는다 — 빠른 것이 정확한 것보다 앞설 수 없다', () async {
    final t = _Lanes(6);
    final items = {
      for (var i = 0; i < 40; i++) 'n$i.json': {'id': 'n$i'},
    };
    await t.writeMany(items);
    for (final k in items.keys) {
      expect(t.files[k], items[k], reason: '$k 이 빠졌다');
    }
  });
}
