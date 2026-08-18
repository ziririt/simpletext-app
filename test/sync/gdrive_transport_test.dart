/// 구글 드라이브 통로 시험.
///
/// 진짜 드라이브에 붙지 않는다. 가짜 드라이브를 하나 세워 두고, 통로가
/// **무엇을 어떤 차례로 묻는지**를 본다. 로그인 없이도 통로의 셈이 맞는지
/// 지킬 수 있어야 한다 — 클라이언트 아이디가 없다고 코드가 못 자랄 이유는
/// 없다.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simpletext/core/sync_transport.dart';
import 'package:simpletext/sync/gdrive_transport.dart';

/// 아주 작은 가짜 드라이브. 파일마다 (이름, 방, 내용)을 들고 있다.
class FakeDrive {
  final Map<String, Map<String, dynamic>> files = {}; // id -> {name,dir,body}
  int _n = 0;
  int calls = 0;
  int uploads = 0;

  http.Client client() => MockClient((req) async {
        calls++;
        final u = req.url;
        final path = u.path;

        // 내용 받기: /drive/v3/files/{id}?alt=media
        if (req.method == 'GET' && u.queryParameters['alt'] == 'media') {
          final id = path.split('/').last;
          final f = files[id];
          if (f == null) return http.Response('', 404);
          return http.Response.bytes(
              utf8.encode(f['body'] as String), 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }

        // 목록: /drive/v3/files?q=...
        if (req.method == 'GET' && path.endsWith('/drive/v3/files')) {
          final q = u.queryParameters['q'] ?? '';
          final dir = RegExp(r"value = '([^']*)'").firstMatch(q)?.group(1) ?? '';
          final name = RegExp(r"name = '([^']*)'").firstMatch(q)?.group(1);
          final hit = files.entries.where((e) =>
              e.value['dir'] == dir &&
              (name == null || e.value['name'] == name));
          return http.Response(
              jsonEncode({
                'files': [
                  for (final e in hit) {'id': e.key, 'name': e.value['name']}
                ]
              }),
              200);
        }

        // 딱지 만들기
        if (req.method == 'POST' && path.endsWith('/drive/v3/files')) {
          final j = jsonDecode(req.body) as Map<String, dynamic>;
          final id = 'id${++_n}';
          files[id] = {
            'name': j['name'],
            'dir': (j['appProperties'] as Map)['dir'],
            'body': '{}',
          };
          return http.Response(jsonEncode({'id': id}), 200);
        }

        // 내용 얹기
        if (req.method == 'PATCH' && path.contains('/upload/drive/v3/files/')) {
          uploads++;
          final id = path.split('/').last;
          final f = files[id];
          if (f == null) return http.Response('', 404);
          f['body'] = req.body;
          return http.Response(jsonEncode({'id': id}), 200);
        }

        // 지우기
        if (req.method == 'DELETE') {
          files.remove(path.split('/').last);
          return http.Response('', 204);
        }

        return http.Response('', 400);
      });
}

void main() {
  group('구글 드라이브 통로', () {
    late FakeDrive drive;
    late GDriveTransport t;

    setUp(() {
      drive = FakeDrive();
      t = GDriveTransport(() async => 'tok', client: drive.client());
    });

    test('이름표는 gdrive', () {
      expect(t.id, 'gdrive');
    });

    test('토큰이 없으면 아무것도 안 한다 — 빈 곳에 쓰지 않는다', () async {
      final none = GDriveTransport(() async => null, client: drive.client());
      expect(await none.ensureDir('notes'), isFalse);
      expect(await none.exists('notes/a.json'), isFalse);
      expect((await none.read('notes/a.json')).state, ReadState.missing);
      expect(await none.readDir('notes'), isEmpty);
      await none.write('notes/a.json', {'x': 1});
      expect(drive.files, isEmpty);
    });

    test('쓰고 읽는다', () async {
      await t.write('notes/a.json', {'id': 'a', 'body': '가나'});
      final r = await t.read('notes/a.json');
      expect(r.state, ReadState.ok);
      expect(r.body!['body'], '가나');
    });

    test('한글이 깨지지 않는다', () async {
      await t.write('notes/ko.json', {'t': '표가 어긋나 있죠 😊'});
      expect((await t.read('notes/ko.json')).body!['t'], '표가 어긋나 있죠 😊');
    });

    test('두 번 써도 파일은 하나다 — 쌍둥이가 안 생긴다', () async {
      await t.write('notes/a.json', {'v': 1});
      await t.write('notes/a.json', {'v': 2});
      expect(drive.files.length, 1);
      expect((await t.read('notes/a.json')).body!['v'], 2);
    });

    test('아이디를 들고 있어 두 번째 쓰기는 찾지 않는다', () async {
      await t.write('notes/a.json', {'v': 1});
      final after = drive.calls;
      await t.write('notes/a.json', {'v': 2});
      // 두 번째는 얹기 한 번뿐이다.
      expect(drive.calls - after, 1);
    });

    test('방이 다르면 이름이 같아도 다른 파일이다', () async {
      await t.write('notes/a.json', {'where': 'notes'});
      await t.write('tombs/a.json', {'where': 'tombs'});
      expect(drive.files.length, 2);
      expect((await t.read('notes/a.json')).body!['where'], 'notes');
      expect((await t.read('tombs/a.json')).body!['where'], 'tombs');
    });

    test('방 하나를 통째로 읽는다', () async {
      await t.write('notes/a.json', {'n': 1});
      await t.write('notes/b.json', {'n': 2});
      await t.write('tombs/c.json', {'n': 3});
      final got = await t.readDir('notes');
      expect(got.map((e) => e['n']).toList()..sort((a, b) => a - b), [1, 2]);
    });

    test('없는 것을 읽으면 missing 이다. notReady 는 영영 없다', () async {
      final r = await t.read('notes/nope.json');
      expect(r.state, ReadState.missing);
      expect(r.state, isNot(ReadState.notReady));
    });

    test('지우면 사라지고, 없는 것을 지워도 조용하다', () async {
      await t.write('notes/a.json', {'v': 1});
      await t.remove('notes/a.json');
      expect(drive.files, isEmpty);
      await t.remove('notes/a.json');
      expect((await t.read('notes/a.json')).state, ReadState.missing);
    });

    test('지운 뒤 다시 쓰면 새로 만든다 — 죽은 아이디를 안 붙든다', () async {
      await t.write('notes/a.json', {'v': 1});
      await t.remove('notes/a.json');
      await t.write('notes/a.json', {'v': 9});
      expect(drive.files.length, 1);
      expect((await t.read('notes/a.json')).body!['v'], 9);
    });

    test('작은따옴표가 든 이름도 찾는다 — 검색말이 안 깨진다', () async {
      await t.write("notes/it's.json", {'v': 1});
      expect((await t.read("notes/it's.json")).body!['v'], 1);
    });

    test('ensureDir 은 방을 만들지 않는다', () async {
      expect(await t.ensureDir('notes'), isTrue);
      expect(drive.files, isEmpty);
    });

    test('json 이 아닌 것은 방 읽기에서 빠진다', () async {
      await t.write('notes/a.json', {'n': 1});
      drive.files['x'] = {'name': 'readme.txt', 'dir': 'notes', 'body': 'hi'};
      final got = await t.readDir('notes');
      expect(got.length, 1);
    });
  });
}
