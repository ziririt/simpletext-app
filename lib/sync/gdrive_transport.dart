/// 구글 드라이브 통로 — 앱 전용 칸에 오간다.
///
/// 2026-08-19. 아이클라우드가 애플 기기끼리만 오가는 데 반해, 안드로이드와
/// 윈도와 웹에는 공통으로 쓸 창고가 없다. 구글 드라이브가 그나마 가장 널리
/// 깔린 자리다.
///
/// ## 왜 appDataFolder 인가
///
/// 구글 드라이브에는 **앱마다 파 주는 숨은 칸**이 있다. 이 앱은 자기가 넣은
/// 것만 보고, 사람의 사진·문서·시트는 목록조차 못 본다. 드라이브 화면에도
/// 안 보이고, 설정에서 앱을 지우면 그 칸이 통째로 사라진다.
///
/// 남의 파일을 볼 수 있는 범위를 달라고 하면 구글 심사를 받아야 하고,
/// 무엇보다 **볼 수 있으면 언젠가 본다.** 안 보는 가장 확실한 방법은
/// 볼 수 없게 만드는 것이다.
///
/// ## 폴더를 안 만든다
///
/// 아이클라우드 쪽은 진짜 파일 시스템이라 'notes/'라는 폴더가 있다.
/// 드라이브의 이름은 그냥 딱지라서, 폴더를 흉내 내려면 폴더 하나마다
/// 아이디를 찾아 붙이는 왕복이 늘어난다.
///
/// 그래서 폴더는 안 만들고 **appProperties 에 어느 방인지를 적어 둔다.**
/// [ensureDir] 는 아무 일도 안 하고 참을 돌려준다. [readDir] 는 이름으로
/// 훑지 않고 그 딱지로 찾는다 — 이름으로 훑으면 'notes'와 'notes2'가
/// 섞인다.
///
/// ## 안 내려온 상태가 없다
///
/// 드라이브는 이름만 먼저 주는 일이 없다. 달라고 하면 내용까지 온다.
/// 그래서 이 통로는 [ReadState.notReady] 를 영영 안 돌려준다
/// (core/sync_transport.dart 머리말).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/sync_transport.dart';

/// 이 앱이 달라고 하는 유일한 범위.
const String kDriveScope = 'https://www.googleapis.com/auth/drive.appdata';

/// 지금 쓸 수 있는 토큰을 주는 함수. 없으면 null.
///
/// 로그인과 토큰 새로 받기는 이 통로가 안 한다. 통로는 옮기기만 한다 —
/// 로그인을 여기 섞으면 시험할 때 화면이 필요해진다.
typedef DriveToken = Future<String?> Function();

const String _api = 'https://www.googleapis.com/drive/v3/files';
const String _upload = 'https://www.googleapis.com/upload/drive/v3/files';

/// 나가는 왕복마다 같은 시간 제한을 거는 껍데기.
///
/// 2026-08-20 소유자 신고 — "당겼다 놓으면 업데이트되는 동그라미가
/// 2분이 넘도록 계속 돌고 있다."
///
/// 이 파일의 왕복 일곱 곳 어디에도 시간 제한이 없었다. 요청 하나가
/// 멈추면(와이파이↔LTE 전환, 신호 약한 자리) 그 자리에서 **영영**
/// 기다린다. 동그라미는 그 기다림을 정직하게 보여 주고 있었다.
///
/// 더 나쁜 것은 그다음이다. 멈춘 채로 있으면 syncNow() 의 빗장
/// (_busy) 이 풀릴 자리가 안 온다. 그때부터 30초마다 도는 자동
/// 동기화가 전부 문 앞에서 되돌아간다 — 앱을 껐다 켜기 전까지
/// 동기화가 죽는다.
///
/// 부르는 자리마다 .timeout 을 붙일 수도 있었다. 그러면 같은 판단이
/// 일곱 군데에 적히고, 여덟 번째 왕복을 만드는 날 반드시 하나를
/// 빠뜨린다. **나가는 문을 하나로 두고 거기에 건다.**
class _Timed extends http.BaseClient {
  _Timed(this._inner, this._wait);
  final http.Client _inner;
  final Duration _wait;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(_wait);

  @override
  void close() => _inner.close();
}

class GDriveTransport implements SyncTransport {
  GDriveTransport(this._token, {http.Client? client})
      : _http = _Timed(client ?? http.Client(), _wait);

  /// 왕복 하나에 허락하는 시간.
  ///
  /// 30초마다 한 바퀴가 도는데 그보다 길게 잡으면 다음 바퀴가 밀린다.
  /// 짧게 잡으면 신호가 약한 데서 멀쩡한 요청을 끊는다. 12초는 그
  /// 사이다 — 한 바퀴에 왕복이 두어 번 겹쳐도 25초(icloud_sync.dart의
  /// 한 바퀴 제한) 안에 든다.
  static const Duration _wait = Duration(seconds: 12);

  final DriveToken _token;
  final http.Client _http;

  /// 길 → 드라이브 아이디. 한 번 찾은 것은 들고 있는다.
  ///
  /// 드라이브는 같은 이름의 파일을 여럿 만들 수 있다. 쓸 때마다 이름으로
  /// 찾아 만들면 **끊긴 요청 하나가 쌍둥이 파일을 남긴다.** 아이디를
  /// 붙들고 있으면 그다음부터는 덮어쓴다.
  final Map<String, String> _ids = <String, String>{};

  /// 한 번 받은 것은 들고 있는다 — 파일 아이디 → (언제 고쳤나, 내용).
  ///
  /// 2026-08-20 소유자 신고 — "계속 맞추는 중으로 나오는데 이게 맞니?"
  /// 30초마다 메모를 전부 다시 내려받고 있었다. 백 개면 30초마다 백 번을
  /// 오간다. 한 바퀴가 30초를 넘으면 다음 바퀴가 곧바로 이어지니 화면은
  /// 영원히 '맞추는 중'이 된다.
  ///
  /// 까닭은 통로를 옮겨 심으면서 **비용이 다르다는 것을 안 봤다**는 것이다.
  /// 아이클라우드 쪽 readDir 은 그냥 파일 읽기라 공짜였다. 같은 모양을
  /// 드라이브로 옮기면 한 줄마다 왕복 한 번이 된다. 모양은 옮겼는데 값은
  /// 안 옮겼다.
  ///
  /// 드라이브는 목록만 줘도 modifiedTime 을 같이 준다. 그 값이 그대로면
  /// 내용도 그대로다.
  final Map<String, String> _at = <String, String>{};
  final Map<String, Map<String, dynamic>> _body =
      <String, Map<String, dynamic>>{};

  @override
  String get id => 'gdrive';

  /// 길을 방 이름과 파일 이름으로 가른다. 'a/b/c.json' → ('a/b', 'c.json').
  static (String, String) _split(String path) {
    final i = path.lastIndexOf('/');
    if (i < 0) return ('', path);
    return (path.substring(0, i), path.substring(i + 1));
  }

  Future<Map<String, String>?> _head() async {
    final t = await _token();
    if (t == null || t.isEmpty) return null;
    return {'Authorization': 'Bearer $t'};
  }

  /// 드라이브 검색말의 따옴표를 막는다.
  static String _q(String s) => s.replaceAll('\\', r'\\').replaceAll("'", r"\'");

  /// 이 길에 해당하는 파일의 아이디. 없으면 null.
  Future<String?> _find(String path) async {
    final cached = _ids[path];
    if (cached != null) return cached;
    final h = await _head();
    if (h == null) return null;
    final (dir, name) = _split(path);
    final q = "name = '${_q(name)}' and trashed = false and "
        "appProperties has { key = 'dir' and value = '${_q(dir)}' }";
    final u = Uri.parse('$_api?spaces=appDataFolder'
        '&q=${Uri.encodeQueryComponent(q)}'
        '&fields=files(id,name)&pageSize=10');
    try {
      final r = await _http.get(u, headers: h);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j is! Map) return null;
      final files = j['files'];
      if (files is! List || files.isEmpty) return null;
      final got = (files.first as Map)['id'] as String?;
      if (got != null) _ids[path] = got;
      return got;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> ensureDir(String path) async {
    // 방을 안 만든다. 머리말 참고.
    return await _head() != null;
  }

  @override
  Future<bool> exists(String path) async => await _find(path) != null;

  /// 파일 하나를 받아 온다. 실패는 null 이다 — 하나가 안 와도 나머지는 와야 한다.
  Future<Map<String, dynamic>?> _fetch(
      String fid, String? at, Map<String, String> h) async {
    try {
      final r = await _http.get(Uri.parse('$_api/$fid?alt=media'), headers: h);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is! Map<String, dynamic>) return null;
      // 시각을 안 주는 판에서는 안 들고 있는다. 들고 있으면 영영
      // 안 새로 받는 길이 생긴다.
      if (at != null) {
        _at[fid] = at;
        _body[fid] = j;
      }
      return j;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReadResult> read(String path) async {
    final h = await _head();
    if (h == null) return ReadResult.missing;
    final fid = await _find(path);
    if (fid == null) return ReadResult.missing;
    try {
      final r = await _http.get(Uri.parse('$_api/$fid?alt=media'), headers: h);
      if (r.statusCode != 200) return ReadResult.missing;
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map<String, dynamic>) return ReadResult(ReadState.ok, j);
    } catch (_) {}
    return ReadResult.missing;
  }

  @override
  Future<List<Map<String, dynamic>>> readDir(String path) async {
    final out = <Map<String, dynamic>>[];
    final h = await _head();
    if (h == null) return out;
    final q = "trashed = false and "
        "appProperties has { key = 'dir' and value = '${_q(path)}' }";
    final u = Uri.parse('$_api?spaces=appDataFolder'
        '&q=${Uri.encodeQueryComponent(q)}'
        '&fields=files(id,name,modifiedTime)&pageSize=1000');
    List<dynamic> files;
    try {
      final r = await _http.get(u, headers: h);
      if (r.statusCode != 200) return out;
      final j = jsonDecode(r.body);
      final f = (j is Map) ? j['files'] : null;
      if (f is! List) return out;
      files = f;
    } catch (_) {
      return out;
    }
    final alive = <String>{};
    // 받아야 할 것만 모았다가 한꺼번에 간다. (fid, 고친 시각)
    final need = <MapEntry<String, String?>>[];
    for (final e in files) {
      if (e is! Map) continue;
      final fid = e['id'] as String?;
      final name = e['name'] as String?;
      if (fid == null || name == null || !name.endsWith('.json')) continue;
      alive.add(fid);
      _ids[path.isEmpty ? name : '$path/$name'] = fid;

      // 언제 고쳤는지가 그대로면 내용도 그대로다. 안 받는다.
      final at = e['modifiedTime'] as String?;
      final kept = _body[fid];
      if (at != null && kept != null && _at[fid] == at) {
        out.add(kept);
        continue;
      }
      need.add(MapEntry(fid, at));
    }

    // 2026-08-20 소유자 신고 — "로그인한지 4분 넘어도 이러네."
    //
    // 여기서 파일을 **한 줄로 하나씩** 받고 있었다. 메모가 백 개면 왕복
    // 백 번을 차례로 기다린다. 하나에 0.2초만 잡아도 20초다.
    //
    // 아이클라우드에서는 이 자리가 그냥 파일 읽기라 공짜였다. 통로를
    // 옮기면서 모양은 가져왔는데 **값이 달라졌다는 것**을 또 안 봤다.
    // 오늘 아침에 '30초마다 전부 다시 받던' 것을 고치면서 다시 받는
    // 횟수는 줄였지만, 한 번에 하나씩은 그대로 뒀다.
    //
    // 여덟씩 묶는다. 더 늘리면 구글이 429(너무 잦다)를 던지기 시작하고,
    // 그러면 빨라지기는커녕 다시 받느라 느려진다.
    const int lanes = 8;
    for (var i = 0; i < need.length; i += lanes) {
      final slice = need.skip(i).take(lanes).toList();
      final got =
          await Future.wait(slice.map((n) => _fetch(n.key, n.value, h)));
      for (final g in got) {
        if (g != null) out.add(g);
      }
    }
    // 없어진 파일까지 붙들고 있으면 지운 메모가 되살아난다.
    _at.removeWhere((k, _) => !alive.contains(k));
    _body.removeWhere((k, _) => !alive.contains(k));
    return out;
  }

  @override
  Future<void> write(String path, Map<String, dynamic> body) async {
    final h = await _head();
    if (h == null) return;
    final text = jsonEncode(body);
    var fid = await _find(path);
    if (fid == null) {
      // 딱지부터 만들고, 내용은 그다음에 얹는다.
      //
      // 한 번에 보내는 방법(multipart)도 있지만 경계 문자열을 손으로
      // 짜야 해서 시험이 어려워진다. 왕복 한 번은 새 파일을 만들 때만
      // 늘고, 그다음부터는 아이디를 들고 있으므로 한 번이다.
      final (dir, name) = _split(path);
      try {
        final r = await _http.post(
          Uri.parse('$_api?fields=id'),
          headers: {...h, 'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'name': name,
            'parents': ['appDataFolder'],
            'appProperties': {'dir': dir},
          }),
        );
        if (r.statusCode != 200 && r.statusCode != 201) return;
        final j = jsonDecode(r.body);
        fid = (j is Map) ? j['id'] as String? : null;
        if (fid == null) return;
        _ids[path] = fid;
      } catch (_) {
        return;
      }
    }
    try {
      await _http.patch(
        Uri.parse('$_upload/$fid?uploadType=media'),
        headers: {...h, 'Content-Type': 'application/json; charset=UTF-8'},
        body: utf8.encode(text),
      );
      // 우리가 고쳤으니 들고 있던 것은 낡았다. 버려야 다음 바퀴에 새로
      // 받는다. 안 버리면 '내가 쓴 것'과 '창고에 있는 것'이 갈라진다.
      _at.remove(fid);
      _body.remove(fid);
    } catch (_) {}
  }

  @override
  Future<void> remove(String path) async {
    final h = await _head();
    if (h == null) return;
    final fid = await _find(path);
    _ids.remove(path);
    if (fid == null) return;
    _at.remove(fid);
    _body.remove(fid);
    try {
      await _http.delete(Uri.parse('$_api/$fid'), headers: h);
    } catch (_) {}
  }

  /// 시험과 로그아웃에서 쓴다. 들고 있던 아이디를 버린다.
  void forget() {
    _ids.clear();
    _at.clear();
    _body.clear();
  }
}
