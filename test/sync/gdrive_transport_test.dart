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
  final Map<String, Map<String, dynamic>> files = {}; // id -> {name,dir,body,at}
  int _n = 0;
  int calls = 0;
  int uploads = 0;

  /// 내용을 실제로 내려받은 횟수. 통로가 '안 바뀐 것은 안 받는다'를
  /// 지키는지 세는 자리다(2026-08-20).
  int downloads = 0;

  /// 파일을 고칠 때마다 오르는 시계. 진짜 드라이브의 modifiedTime 노릇.
  int _clock = 0;

  http.Client client() => MockClient((req) async {
        calls++;
        final u = req.url;
        final path = u.path;

        // 내용 받기: /drive/v3/files/{id}?alt=media
        if (req.method == 'GET' && u.queryParameters['alt'] == 'media') {
          downloads++;
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
                  for (final e in hit)
                    {
                      'id': e.key,
                      'name': e.value['name'],
                      'modifiedTime': e.value['at'],
                    }
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
            'at': '${++_clock}',
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
          f['at'] = '${++_clock}';
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

    test('안 바뀐 메모는 다시 안 받는다', () async {
      // 2026-08-20 소유자 신고 — "마지막으로 맞춘 때가 방금 전 시각이면
      // 동기화된 거 아니니? 계속 맞추는 중으로 나오는데 이게 맞니?"
      //
      // 30초마다 메모를 전부 다시 내려받고 있었다. 이 시험이 그 자리를
      // 못으로 박는다. 아이클라우드 쪽은 파일 읽기라 공짜였던 것이,
      // 드라이브에서는 줄마다 왕복 한 번이 된다.
      await t.write('notes/a.json', {'id': 'a'});
      await t.write('notes/b.json', {'id': 'b'});

      final first = await t.readDir('notes');
      expect(first.length, 2);
      final after1 = drive.downloads;
      expect(after1, greaterThanOrEqualTo(2));

      final second = await t.readDir('notes');
      expect(second.length, 2, reason: '내용은 그대로 나와야 한다');
      expect(drive.downloads, after1, reason: '한 번도 다시 안 받는다');
    });

    test('바뀐 메모는 다시 받는다', () async {
      await t.write('notes/a.json', {'id': 'a', 'v': 1});
      await t.readDir('notes');
      final before = drive.downloads;

      // 다른 기기가 고친 셈 치고 창고 쪽을 직접 바꾼다.
      final id = drive.files.keys.first;
      drive.files[id]!['body'] = '{"id":"a","v":2}';
      drive.files[id]!['at'] = 'nova';

      final again = await t.readDir('notes');
      expect(drive.downloads, before + 1, reason: '바뀐 것 하나만 받는다');
      expect(again.single['v'], 2);
    });

    test('지운 메모는 들고 있던 것에서도 빠진다', () async {
      await t.write('notes/a.json', {'id': 'a'});
      await t.readDir('notes');
      drive.files.clear();
      expect(await t.readDir('notes'), isEmpty,
          reason: '없어진 것을 붙들고 있으면 지운 메모가 되살아난다');
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
