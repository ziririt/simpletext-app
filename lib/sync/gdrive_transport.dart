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
const String _changes = 'https://www.googleapis.com/drive/v3/changes';

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

class GDriveTransport extends SyncTransport {
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

  /// 파일 아이디 → 어느 방. 방을 다시 훑을 때 **그 방 것만** 잊기 위해서다.
  ///
  /// 2026-08-20 밤에 찾은 사고: readDir 끝의 청소가 '이번 목록에 없는
  /// 것'을 전부 지웠는데, 목록은 그 방 것뿐이다. notes 를 훑으면 tombs 의
  /// 기억이 지워지고 tombs 를 훑으면 notes 가 지워졌다 — 툼스톤이 하나라도
  /// 있으면 30초마다 전부 다시 받고 있었던 것이다. '안 바뀐 것은 안
  /// 받는다'는 시험은 방을 하나만 써서 이걸 못 잡았다.
  final Map<String, String> _dirOf = <String, String>{};

  /// 파일 아이디 → 딱지에 적힌 시각(없으면 null). 목록에서 본 것을 들고
  /// 있다가, 딱지 없는 옛 파일을 받았을 때 달아 줄지 판단하는 데 쓴다.
  final Map<String, int?> _upSeen = <String, int?>{};

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

  /// 변경 목록의 표. null 이면 아직 안 받았다.
  String? _pageToken;

  @override
  Future<bool?> probeChanged() async {
    final h = await _head();
    if (h == null) return null;
    try {
      if (_pageToken == null) {
        // 표를 처음 받는다. 이 표는 '지금부터'를 뜻하므로 이번 물음은
        // 답할 것이 없다 — false 로 두고 다음 물음부터 센다.
        //
        // spaces 를 안 붙인다. 표를 내주는 쪽은 그 낱말을 모른다(400).
        // 거르는 것은 아래 목록 쪽 일이다.
        final r = await _http.get(
            Uri.parse('$_changes/startPageToken'),
            headers: h);
        if (r.statusCode != 200) return null;
        final j = jsonDecode(r.body);
        if (j is! Map) return null;
        final t = j['startPageToken'];
        if (t is! String || t.isEmpty) return null;
        _pageToken = t;
        return false;
      }
      var token = _pageToken!;
      var changed = false;
      // 장이 여러 쪽으로 나뉠 수 있다. 사용자의 드라이브 전체가 바쁘면
      // 우리 방과 상관없는 변경으로도 쪽이 늘어난다. 다섯 쪽에서 끊는다 —
      // 짧게 묻자고 만든 물음이 길어지면 뜻이 없다. 못 넘긴 쪽은 다음
      // 물음이 이어서 본다.
      for (var page = 0; page < 5; page++) {
        final u = Uri.parse('$_changes'
            '?pageToken=${Uri.encodeQueryComponent(token)}'
            '&spaces=appDataFolder&pageSize=100'
            '&fields=newStartPageToken,nextPageToken,changes(fileId)');
        final r = await _http.get(u, headers: h);
        if (r.statusCode != 200) return null;
        final j = jsonDecode(r.body);
        if (j is! Map) return null;
        final list = j['changes'];
        if (list is List && list.isNotEmpty) changed = true;
        final next = j['nextPageToken'];
        if (next is String && next.isNotEmpty) {
          token = next;
          _pageToken = next;
          continue;
        }
        final end = j['newStartPageToken'];
        if (end is String && end.isNotEmpty) _pageToken = end;
        break;
      }
      return changed;
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
  Future<List<RemoteMeta>?> listMeta(String dir) async {
    final h = await _head();
    if (h == null) return null;
    final q = "trashed = false and "
        "appProperties has { key = 'dir' and value = '${_q(dir)}' }";
    final u = Uri.parse('$_api?spaces=appDataFolder'
        '&q=${Uri.encodeQueryComponent(q)}'
        '&fields=files(id,name,modifiedTime,appProperties)&pageSize=1000');
    try {
      final r = await _http.get(u, headers: h);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      final f = (j is Map) ? j['files'] : null;
      if (f is! List) return null;
      final out = <RemoteMeta>[];
      final alive = <String>{};
      for (final e in f) {
        if (e is! Map) continue;
        final fid = e['id'] as String?;
        final name = e['name'] as String?;
        if (fid == null || name == null || !name.endsWith('.json')) continue;
        alive.add(fid);
        _ids[dir.isEmpty ? name : '$dir/$name'] = fid;
        _dirOf[fid] = dir;
        final props = e['appProperties'];
        final up = (props is Map) ? int.tryParse('${props['up']}') : null;
        _upSeen[fid] = up;
        out.add(RemoteMeta(name.substring(0, name.length - 5), up));
      }
      _forgetDeadIn(dir, alive);
      return out;
    } catch (_) {
      // 목록을 못 받았으면 모른다고 말한다 — 부르는 쪽이 옛길로 간다.
      return null;
    }
  }

  /// 그 방에서 없어진 파일의 기억만 지운다. 다른 방 것은 남긴다.
  void _forgetDeadIn(String dir, Set<String> alive) {
    final dead = [
      for (final e in _dirOf.entries)
        if (e.value == dir && !alive.contains(e.key)) e.key
    ];
    for (final fid in dead) {
      _at.remove(fid);
      _body.remove(fid);
      _upSeen.remove(fid);
      _dirOf.remove(fid);
    }
  }

  @override
  Future<Map<String, ReadResult>> readMany(List<String> paths) async {
    final out = <String, ReadResult>{};
    final h = await _head();
    if (h == null) return out;
    const int lanes = 8;
    for (var i = 0; i < paths.length; i += lanes) {
      final slice = paths.skip(i).take(lanes).toList();
      await Future.wait(slice.map((p) async {
        final r = await _readOne(p, h);
        if (r != null) out[p] = r;
      }));
    }
    return out;
  }

  /// 한 파일. null 은 "이번에 답을 못 들었다"(그물이 끊겼다)는 뜻이다.
  ///
  /// 404 와 깨진 JSON 은 missing 으로 준다 — 부르는 쪽이 덮어써서 고칠
  /// 수 있는 상태다. 401·429·5xx 와 시간 초과는 null 이다 — 파일의
  /// 잘못이 아니니 덮어쓰면 안 된다.
  Future<ReadResult?> _readOne(String path, Map<String, String> h) async {
    final fid = _ids[path] ?? await _find(path);
    if (fid == null) return ReadResult.missing;
    try {
      final r = await _http.get(Uri.parse('$_api/$fid?alt=media'), headers: h);
      if (r.statusCode == 404) return ReadResult.missing;
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is! Map<String, dynamic>) return ReadResult.missing;
      // 딱지 없는 옛 파일이면 지금 안다 — 다음 목록부터는 안 열어 봐도
      // 되게 딱지를 달아 둔다. 실패해도 조용히 넘어간다(다음에 또 기회).
      if (_upSeen[fid] == null) {
        final stamp = _stampIn(j);
        if (stamp != null) await _tag(fid, path, stamp, h);
      }
      return ReadResult(ReadState.ok, j);
    } on FormatException {
      return ReadResult.missing;
    } catch (_) {
      return null;
    }
  }

  /// 본문에서 '언제 고쳤나'를 찾는다. 노트는 updatedAt, 툼스톤은
  /// deletedAt, 설정 종류는 stamp 다. 이 셋을 아는 곳은 여기 하나다.
  static int? _stampIn(Map<String, dynamic> body) {
    final v = body['updatedAt'] ?? body['deletedAt'] ?? body['stamp'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  /// 딱지에 시각을 적는다. 내용을 얹은 **뒤에** 불러야 한다 — 딱지가
  /// 내용보다 새것이 되면 남이 새 내용인 줄 알고 옛 내용을 받아 간다.
  /// 반대쪽(딱지가 옛것)은 안전하다: 한 번 더 열어 볼 뿐이다.
  Future<void> _tag(
      String fid, String path, int stamp, Map<String, String> h) async {
    final (dir, _) = _split(path);
    try {
      final r = await _http.patch(
        Uri.parse('$_api/$fid'),
        headers: {...h, 'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'appProperties': {'dir': dir, 'up': '$stamp'}
        }),
      );
      if (r.statusCode == 200) _upSeen[fid] = stamp;
    } catch (_) {}
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
      _dirOf[fid] = path;

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
    // 없어진 파일의 기억을 지운다 — **이 방 것만.** 전부 지우면 notes 를
    // 훑을 때 tombs 의 기억이 지워져, 툼스톤이 하나라도 있는 창고는
    // 30초마다 전부 다시 받는다(2026-08-20 밤에 실제로 그랬다).
    _forgetDeadIn(path, alive);
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
      final r = await _http.patch(
        Uri.parse('$_upload/$fid?uploadType=media'),
        headers: {...h, 'Content-Type': 'application/json; charset=UTF-8'},
        body: utf8.encode(text),
      );
      // 우리가 고쳤으니 들고 있던 것은 낡았다. 버려야 다음 바퀴에 새로
      // 받는다. 안 버리면 '내가 쓴 것'과 '창고에 있는 것'이 갈라진다.
      _at.remove(fid);
      _body.remove(fid);
      _dirOf[fid] = _split(path).$1;
      // 내용이 실제로 실렸을 때만 딱지를 단다(순서가 값이다 — _tag 참고).
      // 시각이 없는 본문은 안 단다: 딱지 없는 파일은 늘 열어 보므로 해가
      // 없고, 여기서 억지로 달면 거짓 시각이 생긴다.
      if (r.statusCode == 200) {
        _upSeen[fid] = null;
        final stamp = _stampIn(body);
        if (stamp != null) await _tag(fid, path, stamp, h);
      }
    } catch (_) {}
  }

  /// 겹쳐 보낸다. 여섯 줄로 나눠 보내는 까닭 — 받는 쪽(readMany)은
  /// 여덟인데 여기는 여섯이다. 쓰기는 읽기보다 무겁고, 구글은 같은
  /// 계정에서 쓰기가 몰리면 429(잠깐 쉬어라)를 돌려준다.
  @override
  Future<void> writeMany(Map<String, Map<String, dynamic>> items) async {
    final paths = items.keys.toList();
    const int lanes = 6;
    for (var i = 0; i < paths.length; i += lanes) {
      final slice = paths.skip(i).take(lanes).toList();
      await Future.wait(slice.map((p) => write(p, items[p]!)));
    }
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
    _dirOf.remove(fid);
    _upSeen.remove(fid);
    try {
      await _http.delete(Uri.parse('$_api/$fid'), headers: h);
    } catch (_) {}
  }

  /// 시험과 로그아웃에서 쓴다. 들고 있던 아이디를 버린다.
  void forget() {
    _ids.clear();
    _at.clear();
    _body.clear();
    _dirOf.clear();
    _upSeen.clear();
  }
}
