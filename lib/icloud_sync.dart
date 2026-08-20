/// 아이클라우드 동기화 — 파일을 읽고 쓰는 쪽.
///
/// 무엇을 남길지 정하는 **규칙은 여기 없다.** 그건 core/sync_merge.dart에
/// 있고 테스트로 못 박혀 있다. 이 파일이 하는 일은 셋뿐이다.
///   1) 아이클라우드 폴더에서 남의 기기가 올린 것을 읽어 온다
///   2) 규칙에게 넘겨 합친 결과를 받는다
///   3) 합친 결과를 기기와 아이클라우드에 도로 쓴다
///
/// ## 어떻게 생겼나
///
///   <컨테이너>/Documents/
///     notes/<id>.json     메모 하나당 파일 하나
///     tombs/<id>.json     삭제 기록 하나당 파일 하나
///     rules.json          정리 규칙 · 자동 바꾸기 규칙
///     trial.json          체험 기록
///
/// 메모를 파일 하나에 몰아넣지 않은 이유: 두 기기가 서로 다른 메모를 고쳤을
/// 때 늦게 올린 쪽이 상대의 수정을 통째로 덮는다. 파일을 쪼개면 같은 메모를
/// 양쪽에서 고친 경우에만 충돌이고, 그때만 규칙이 판단하면 된다.
///
/// ## 로그인 화면이 없는 이유
///
/// 기기에 이미 들어와 있는 애플 계정을 그대로 쓴다. 우리 서버가 없고, 우리는
/// 사용자의 메모를 볼 수도 없다. 그래서 물어볼 것도 없다.
///
/// ## 동기화하지 않는 것 — AI 키
///
/// 사용자의 API 키는 기기 밖으로 나가지 않는다. 이건 이 앱의 약속이고,
/// 아이클라우드도 '밖'이다. 설정 화면에 그렇게 적어 두었다.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'core/key_vault.dart';
import 'core/mono_controller.dart' show MonoTextController;
import 'core/sync_merge.dart';
import 'core/sync_transport.dart';
import 'sync/gdrive_transport.dart';
import 'sync/icloud_transport.dart';
// CustomRule은 main.dart가 아니라 엔진 쪽에 산다(2026-08-16에 여기서 한 번
// 틀렸다 — analyze가 undefined_method로 잡아 줬다).
import 'core/tidy_engine.dart' show CustomRule;
import 'main.dart' show Store, Note;

/// 동기화 상태 — 화면에 한 줄로 보여 주기 위한 것.
///
/// 2026-08-16 소유자 신고: "이건 어떻게 설정하라는 건지 모르겠다." '꺼짐'
/// 하나로 뭉뚱그리면 사용자가 할 수 있는 일이 없다. 원인을 갈라서, 원인마다
/// 다음에 할 일이 다르게 보이도록 상태를 나눴다.
enum SyncState {
  /// 이 기기에서는 아예 안 쓴다(안드로이드·윈도우).
  unsupported,

  /// 기기가 아이클라우드에 로그인되어 있지 않다.
  signedOut,

  /// 로그인은 됐는데 이 앱의 아이클라우드 사용이 꺼져 있다(또는 아직 준비 중).
  off,

  /// 맞추는 중.
  running,

  /// 맞춰 놨다.
  ok,
}

class ICloudSync {
  static final ICloudSync instance = ICloudSync._();
  ICloudSync._();

  static const MethodChannel _ch = MethodChannel('skyblue/icloud');

  /// 옮기는 통로. 지금은 아이클라우드 하나뿐이지만, 구글 드라이브를 붙일
  /// 때 **여기만 갈아 끼우면 된다** — 합치는 규칙(core/sync_merge.dart)도,
  /// 아래의 셈도 그대로다.
  SyncTransport _t = const IcloudTransport(_ch);

  /// 시험과 앞으로 붙을 창고를 위한 문.
  @visibleForTesting
  set transport(SyncTransport t) => _t = t;

  /// 고른 창고에 맞는 통로를 끼운다.
  ///
  /// 2026-08-20. 이 판단을 **엔진 안에** 둔다. 밖에 두면 설정 화면이
  /// 통로를 직접 갈아 끼워야 하고, 그러면 화면이 채널 이름과 통로 종류를
  /// 알아야 한다. 어느 통로로 오갈지는 원래 엔진이 알 일이다.
  ///
  /// [driveToken] 이 없으면 구글을 골랐어도 애플 통로로 떨어진다 —
  /// 토큰을 못 구하는 판에서 구글 통로를 끼우면 조용히 아무 데도 안
  /// 오간다. 그럴 바에는 원래 쓰던 곳으로 돌려 두는 편이 정직하다.
  void useBackend(String backend, {DriveToken? driveToken}) {
    paused = backend == 'none';
    if (backend == 'gdrive' && driveToken != null) {
      _t = GDriveTransport(driveToken);
    } else {
      _t = const IcloudTransport(_ch);
    }
  }

  /// **아이클라우드**를 쓸 수 있는 기기인가. 애플 기기에서만 참이다.
  ///
  /// 이름이 그냥 supported 인 것은 창고가 하나뿐이던 시절의 흔적이다.
  /// 지금은 '동기화를 할 수 있는가'와 같은 말이 아니다 — 아래 [active].
  static bool get supported =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// 지금 끼운 통로가 애플 채널을 거치는가.
  ///
  /// 창고가 늘면 **이 한 줄만** 본다. 2026-08-20 새벽에 이 판단이 세
  /// 군데로 흩어져 있다가 안드로이드에서 동기화가 통째로 죽었다.
  bool get _viaApple => _t.id != 'gdrive';

  /// 이 기기에서, 지금 고른 창고로, 실제로 오갈 수 있는가.
  ///
  /// 2026-08-20 — 2.0.0 에서 통로 고르는 판단은 [useBackend] 로 모아
  /// 놨는데, **돌아도 되는가**를 묻는 자리들은 여전히 '애플 기기인가'만
  /// 보고 있었다. 그래서 안드로이드에서 구글 드라이브를 골라도 로그인만
  /// 되고 동기화는 한 번도 안 돌았다. 아무 말 없이 — 그게 제일 나쁘다.
  bool get active => _viaApple ? supported : true;

  final ValueNotifier<SyncState> state =
      ValueNotifier<SyncState>(SyncState.unsupported);

  /// 마지막으로 맞춘 시각(밀리초). 0이면 아직 한 번도 못 맞췄다.
  final ValueNotifier<int> lastSyncMs = ValueNotifier<int>(0);

  /// 사람이 설정에서 '동기화 안 함'을 골랐는가.
  ///
  /// 2026-08-19 — 창고 고르기(설정 → 동기화)의 뒷면이다. 여기 **한 곳만**
  /// 막는다. 올리는 길도 내리는 길도 결국 syncNow() 하나를 지나기 때문에,
  /// 부르는 자리마다 조건을 흩뿌리면 반드시 한 자리를 빠뜨린다 — 이 앱이
  /// 오늘만 여섯 번 겪은 그 자리다.
  ///
  /// 타이머는 그대로 돌게 둔다. 사람이 다시 켰을 때 30초 안에 저절로
  /// 따라잡게 하려면 시계를 죽이지 않는 편이 낫다.
  bool paused = false;

  String? _root;
  bool _rootAsked = false;
  bool _signedIn = false;

  /// 이 앱 몫의 아이클라우드 자리를 실제로 받았는가.
  ///
  /// 2026-08-16 — '로그인했는가'와 이것을 갈라 두면, 안 될 때 화면에서
  /// 무엇을 하라고 말할지가 정해진다.
  ///   로그인 X            → 기기를 아이클라우드에 로그인하십시오
  ///   로그인 O, 자리 X    → 설정에서 이 앱의 아이클라우드를 켜십시오
  ///   둘 다 O, 경로 X     → 준비 중입니다. 잠시 뒤 다시 확인하십시오
  bool _container = false;

  /// 마지막으로 물어봤을 때 시스템이 준 오류 문구. 없으면 빈 문자열.
  ///
  /// 2026-08-17 — 화면에 '해석'만 띄우다가 그 해석이 틀린 것이 드러났다.
  /// 해석이 틀리면 그 위에 쌓은 판단이 전부 틀린다. 그래서 사실을 그대로
  /// 들고 온다.
  String _err = '';

  bool get signedIn => _signedIn;
  bool get containerReady => _container;
  bool get pathReady => _root != null;
  String get lastError => _err;

  /// 화면 아래에 작게 붙이는 한 줄. 사람이 읽는 문장이 아니라 **사실**이다.
  /// 이 줄 하나면 다음에 어디를 고칠지가 정해진다.
  String get facts =>
      '계정 ${_signedIn ? "O" : "X"} · 자리 ${_container ? "O" : "X"} · '
      '경로 ${_root != null ? "O" : "X"}${_err.isEmpty ? "" : " · $_err"}';
  bool _busy = false;
  Timer? _debounce;
  Timer? _tick;

  /// 앱이 켜질 때 한 번 부른다.
  Future<void> boot() async {
    if (!active) {
      state.value = SyncState.unsupported;
      return;
    }
    await syncNow();

    // 앱이 막 켜진 직후에는 아이클라우드가 아직 준비 중이라 폴더 경로가
    // 비어 나올 수 있다. 그 한 번을 보고 '꺼짐'이라고 단정하면 멀쩡한
    // 기기에서도 꺼짐이 뜬다 — 2026-08-16 소유자 아이폰에서 실제로
    // 그렇게 보였을 가능성이 크다. 몇 초 간격으로 세 번 더 물어본다.
    for (final s in const [2, 4, 8]) {
      if (state.value == SyncState.ok) break;
      await Future<void>.delayed(Duration(seconds: s));
      forgetRoot();
      await syncNow();
    }

    // 남의 기기가 올린 것을 알아채는 방법. 파일이 도착했다는 알림을 받는
    // 정식 방법(NSMetadataQuery)은 스위프트 쪽 코드가 훨씬 커진다. 30초에
    // 한 번 폴더를 훑는 것으로 충분하다 — 메모 앱에서 30초 지연은 사람이
    // 느끼지 못하고, 훑는 비용은 파일 목록 한 번이라 사실상 공짜다.
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
  }

  /// 앱이 다시 앞으로 나올 때. 다른 기기에서 고친 게 있으면 여기서 들어온다.
  /// 사용자가 설정 앱에서 아이클라우드를 켜고 돌아오는 경로이기도 하므로,
  /// 꺼져 있던 경우에는 경로를 잊고 다시 물어본다.
  void onResume() {
    if (!active) return;
    if (state.value != SyncState.ok) forgetRoot();
    unawaited(syncNow());
  }

  /// 사용자가 '다시 확인'을 눌렀을 때.
  /// 눌렀을 때 실제로 무엇이 일어나는지: 기억해 둔 폴더 경로를 버리고
  /// 기기에 처음부터 다시 물어본다. 설정 앱에서 아이클라우드를 켜고
  /// 돌아온 직후에 쓰라고 만든 버튼이다.
  ///
  /// 2026-08-16 소유자 신고 — "무슨 기능인가? 눌러도 무반응." 두 가지가
  /// 겹쳐 있었다. 하나는 이름만 보고는 무슨 일이 일어나는지 알 수 없다는
  /// 것(화면에 한 줄 적었다). 다른 하나는 **성공하면 창이 닫히는데
  /// 실패하면 아무 일도 안 일어났다**는 것이다. 실패야말로 말을 해 줘야
  /// 하는 쪽인데 거꾸로였다.
  Future<void> recheck() async {
    forgetRoot();
    await syncNow();
  }

  /// 창고를 바꾼 직후에 부른다. 껐다 켠 것과 같다.
  ///
  /// [recheck] 로는 모자란다. 그건 경로만 잊는데, 안드로이드에서는
  /// boot() 이 첫 줄에서 돌아갔던 탓에 **30초 시계 자체가 안 걸려**
  /// 있다. 창고를 구글로 바꾼 그 순간부터 시계를 새로 건다.
  Future<void> rebind() async {
    _tick?.cancel();
    _tick = null;
    forgetRoot();
    if (!active) {
      state.value = SyncState.unsupported;
      return;
    }
    await boot();
  }

  /// 설정 앱을 연다. iCloud 항목으로 직접 뛰는 주소는 비공개 API라
  /// 심사에서 반려된다 — 여는 데까지만 하고 나머지는 글로 안내한다.
  /// 열렸으면 true. 화면은 false일 때 "직접 열어 주십시오"라고 말한다
  /// (2026-08-16 소유자 신고: "눌러도 무반응이다").
  Future<bool> openSettings() async {
    try {
      return await _ch.invokeMethod<bool>('openSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 메모를 저장할 때마다 불린다. 저장은 글자 하나마다 일어나므로 곧바로
  /// 올리면 파일을 초당 몇 번씩 쓰게 된다. 3초 쉬었다가 한 번만 올린다.
  void scheduleUp() {
    if (!supported || paused) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => unawaited(syncNow()));
  }

  void dispose() {
    _tick?.cancel();
    _debounce?.cancel();
  }

  // -------------------------------------------------------------- 경로

  Future<String?> _rootPath() async {
    // 구글 드라이브에는 뿌리가 없다. 방 이름이 그냥 딱지라서
    // (sync/gdrive_transport.dart 머리말) 길을 그대로 쓴다. 여기서
    // 애플 채널에 물으면 안드로이드에서는 아무것도 안 돌아오고,
    // 그러면 syncNow() 가 '경로 없음'으로 판단해 조용히 멈춘다.
    if (!_viaApple) return '';
    if (_rootAsked) return _root;
    _rootAsked = true;
    try {
      final r = await _ch.invokeMapMethod<String, dynamic>('root');
      _root = r?['path'] as String?;
      _signedIn = (r?['signedIn'] as bool?) ?? false;
      _container = (r?['container'] as bool?) ?? false;
      _err = (r?['error'] as String?) ?? '';
    } catch (e) {
      _root = null;
      _signedIn = false;
      _container = false;
      _err = 'channel: $e';
    }
    return _root;
  }

  /// 다음에 다시 물어보게 만든다. 사용자가 도중에 아이클라우드에 로그인할
  /// 수 있어서, 한 번 비었다고 영영 포기하면 안 된다.
  void forgetRoot() {
    _rootAsked = false;
    _root = null;
  }

  // -------------------------------------------------------------- 본체

  /// 한 바퀴에 허락하는 시간. 30초 시계보다 짧아야 한다.
  static const Duration _pass = Duration(seconds: 25);

  /// **첫** 바퀴에만 주는 시간.
  ///
  /// 2026-08-20 소유자 신고 — "로그인한지 4분 넘어도 이러네."
  ///
  /// 첫 바퀴는 창고에 있는 것을 **다 가져오는** 일이고, 그다음부터는
  /// 달라진 것만 보는 일이다. 하는 일이 다른데 같은 잣대를 댔다.
  /// 25초로는 메모가 많은 사람의 첫 맞추기가 매번 끊기고, 끊기면
  /// '꺼짐'이라고 말한다 — 되고 있는데 안 된다고 말하는 셈이다.
  static const Duration _firstPass = Duration(seconds: 120);

  Future<void> syncNow() async {
    if (!active || paused || _busy) return;
    _busy = true;
    // 빗장을 푸는 자리를 하나로 모은다. 아래에서 '일이 끝나는 자리'와
    // '기다림이 끝나는 자리'가 갈라지므로, 두 번 풀리는 일이 없게 한다.
    var freed = false;
    void free() {
      if (freed) return;
      freed = true;
      _busy = false;
    }

    // _run 을 실제로 시작했는가. 시작했으면 빗장은 그쪽이 푼다.
    var started = false;
    try {
      final root = await _rootPath();
      if (root == null) {
        state.value = _signedIn ? SyncState.off : SyncState.signedOut;
        return;
      }
      state.value = SyncState.running;
      // 한 바퀴에 허락하는 시간.
      //
      // 왕복마다 12초를 걸어 뒀지만(sync/gdrive_transport.dart) 그것만
      // 으로는 모자란다. 메모가 백 개면 왕복도 여러 번이고, 하나하나
      // 는 제때 끝나면서 전체가 한없이 길어질 수 있다.
      //
      // 30초 시계보다 짧게 둔다. 그래야 두 바퀴가 겹치지 않는다.
      //
      // 여기서 던지는 TimeoutException 은 아래 catch 가 받아 '꺼짐'으로
      // 두고, finally 가 빗장을 푼다. **빗장이 반드시 풀리는 것**이
      // 이 줄의 진짜 목적이다 — 안 풀리면 그다음 모든 바퀴가 죽는다.
      // 2026-08-20 — **Future.timeout 은 일을 멈추지 않는다.** 기다림만
      // 끊는다. 그런데 여기서 빗장까지 풀고 있었다. 버려진 바퀴가 계속
      // 도는 채로 다음 바퀴가 시작되고, 30초마다 한 겹씩 쌓인다.
      // 같은 창고를 여럿이 동시에 읽고 쓰면 서로를 밀어낸다.
      //
      // 빗장은 **진짜 일이 끝날 때** 푼다. 시간 제한은 이제 '얼마나
      // 기다렸다가 화면에 말할까'만 정한다. 일이 영영 안 끝날 걱정은
      // 없다 — 왕복 하나하나에 12초가 걸려 있으므로(gdrive_transport.dart)
      // 모든 기다림에 바닥이 있다.
      started = true;
      final work = _run(root);
      unawaited(work.then((_) {}, onError: (Object _) {}).whenComplete(free));
      await work.timeout(lastSyncMs.value == 0 ? _firstPass : _pass);
      lastSyncMs.value = DateTime.now().millisecondsSinceEpoch;
      state.value = SyncState.ok;
    } catch (_) {
      // 동기화 실패로 앱이 멈추면 안 된다. 다음 차례에 다시 해 본다.
      //
      // 여기서 빗장을 안 푼다. 시간 제한으로 왔다면 일은 아직 돌고 있고,
      // 진짜 실패로 왔다면 위의 whenComplete 이 이미 풀었다.
      state.value = SyncState.off;
    } finally {
      // _rootPath() 에서 일찍 나간 길만 여기서 푼다. 그때는 _run 이
      // 시작도 안 했으므로 풀 사람이 여기밖에 없다.
      if (!started) free();
    }
  }

  Future<void> _run(String root) async {
    final store = Store.instance;
    final notesDir = '$root/notes';
    final tombsDir = '$root/tombs';
    // 여기서 돌려주는 값을 안 보고 지나가면, 통로가 준비 안 된 판에서도
    // 아래를 다 훑고 내려가 **'맞춰 놨다'고 말한다.** 구글 로그인이 안
    // 된 상태가 정확히 그 판이다 — 토큰이 없어 모든 왕복이 빈손으로
    // 돌아오는데, 빈손과 '아무것도 없는 창고'는 코드가 구별 못 한다.
    //
    // 던지면 syncNow() 가 받아서 '꺼짐'으로 둔다. 거짓 초록불보다
    // 정직한 회색불이 낫다.
    if (!await _t.ensureDir(notesDir) || !await _t.ensureDir(tombsDir)) {
      throw StateError('통로가 아직 준비되지 않았다 (${_t.id})');
    }

    // --- 원격 읽기 ---
    //
    // 2026-08-18 — 아직 안 내려온 파일을 알아채고 당겨 오라고 이르는 일은
    // 통로가 맡는다. 그건 아이클라우드만의 사정이라, 여기서 알고 있으면
    // 구글 드라이브를 붙일 때 이 코드를 또 고쳐야 한다.
    final remoteNotes = <Note>[];
    for (final f in await _t.readDir(notesDir)) {
      try {
        remoteNotes.add(Note.fromJson(f));
      } catch (_) {
        // 다른 판이 쓴 파일이거나 쓰다 만 파일. 통째로 죽지 말고 건너뛴다.
      }
    }
    final remoteTombs = <Map<String, dynamic>>[];
    for (final f in await _t.readDir(tombsDir)) {
      final id = f['id'];
      if (id is String && id.isNotEmpty) remoteTombs.add(f);
    }

    // --- 합치기 (규칙은 core/sync_merge.dart) ---
    final now = DateTime.now().millisecondsSinceEpoch;
    final merged = mergeNotes<Note>(
      local: store.notes,
      localTombs: store.tombstones,
      remote: remoteNotes,
      remoteTombs: remoteTombs,
      idOf: (n) => n.id,
      stampOf: (n) => n.updatedAt,
      nowMs: now,
    );

    // --- 기기에 반영 ---
    if (!merged.localUnchanged) {
      store.notes = merged.notes;
      store.tombstones = merged.tombstones;
      await store.persistLocalOnly();
    } else {
      store.tombstones = merged.tombstones;
    }

    // --- 아이클라우드에 반영 ---
    final remoteById = {for (final n in remoteNotes) n.id: n};
    for (final n in merged.notes) {
      final r = remoteById[n.id];
      if (r == null || r.updatedAt < n.updatedAt) {
        await _t.write('$notesDir/${n.id}.json', n.toJson());
      }
    }
    final liveIds = {for (final n in merged.notes) n.id};
    final tombIds = <String>{};
    // 2026-08-20 — 여기서 툼스톤마다 exists() 를 물었다. 아이클라우드에서는
    // 파일이 있나 보는 것이라 공짜였지만, 드라이브에서는 **한 번마다 검색
    // 왕복 한 번**이다. 게다가 아직 없는 것은 캐시에 안 남아서, 없는 툼스톤은
    // 30초마다 영원히 다시 묻는다. 첫 맞추기가 몇 분씩 걸리고 화면이 계속
    // '맞추는 중'이던 까닭이 여기 있다.
    //
    // 그런데 우리는 이미 답을 들고 있었다 — 위에서 readDir 로 받아 둔
    // remoteTombs 가 그것이다. **물어볼 필요가 없는 것을 물었다.**
    final remoteTombIds = {
      for (final t in remoteTombs)
        if (t['id'] is String) t['id'] as String,
    };
    for (final t in merged.tombstones) {
      final id = t['id'] as String;
      tombIds.add(id);
      if (!remoteTombIds.contains(id)) {
        await _t.write('$tombsDir/$id.json', t);
      }
      // 지워진 메모의 본문 파일은 치운다. 안 그러면 툼스톤이 만료된 뒤에
      // 그 파일이 '새 메모'로 되살아난다.
      //
      // 다만 **저쪽에 있는 것만** 치운다. 없는 것을 지우라고 시키면 그것도
      // 왕복이고, 지운 메모 수만큼 매번 되풀이된다.
      if (!liveIds.contains(id) && remoteById.containsKey(id)) {
        await _t.remove('$notesDir/$id.json');
      }
    }
    // 만료된 툼스톤 파일 치우기
    for (final t in remoteTombs) {
      final id = t['id'] as String;
      if (tombIds.contains(id)) continue;
      await _t.remove('$tombsDir/$id.json');
    }

    await _syncRules(root);
    await _syncAiKey(root);
  }

  // ------------------------------------------------------ 규칙·체험 맞추기

  /// 2026-08-18 — 여기가 담는 것이 늘었다. 소유자 신고: "각종 설정 값들이
  /// 앱 업데이트하면 다 날아가나? 설정 값들 유지되게 할 수 있으면 좋겠다."
  ///
  /// 까닭은 개발 중의 설치가 업데이트가 아니라 '지우고 새로 깔기'라서다.
  /// 실사용자는 스토어 업데이트를 받으므로 안 겪는다. 그렇다고 넘길 일은
  /// 아니었다 — 기기를 바꾸거나 앱을 지웠다 다시 깔면 누구든 겪는다.
  ///
  /// 그래서 글자 크기·줄 간격·종이·화면 모드·정렬 기준까지 여기 싣는다.
  /// 예전에는 "기기마다 다른 게 자연스럽다"고 적어 두고 안 실었는데,
  /// 그건 내 짐작이었지 사용자가 그렇게 말한 적이 없다. 소유자는 반대로
  /// 말했다.
  ///
  /// 다만 둘은 끝까지 안 싣는다.
  ///   잠금(lockOn) — 잠금을 못 쓰는 기기에 켜진 값이 넘어오면 그 기기는
  ///     영영 안 열린다. 편의를 위해 문을 잠그는 일은 하지 않는다.
  ///   AI 키 — 키체인에 있고, 기기 밖으로 안 나간다(core/key_vault.dart).
  ///   광고 없는 날·필터 — 그날 그 기기의 일이다.
  ///
  /// 정리 규칙과 자동 바꾸기 규칙은 기기마다 다시 설정하게 두면 안 된다
  /// (소유자 지적). 메모와 달리 이건 합칠 수 없는 값이라 **늦게 고친 쪽이
  /// 통째로 이긴다.** 규칙 목록 두 벌을 섞으면 사용자가 지운 규칙이
  /// 되살아나는 등, 아무도 원하지 않는 결과가 나온다.
  ///
  /// '언제 고쳤나'는 따로 기록하지 않고 내용의 지문(hash)으로 알아낸다.
  /// 규칙을 바꾸는 자리가 화면 곳곳에 흩어져 있어서, 그 자리마다 시각을
  /// 찍게 하면 하나는 반드시 빠뜨린다.
  Future<void> _syncRules(String root) async {
    final store = Store.instance;
    final s = store.settings;
    final f = '$root/rules.json';

    final localBody = _rulesBody(store);
    final localSig = _sig(localBody);

    // 이 기기에 아직 아무 기록이 없다 = 앱을 새로 깐 것이다.
    // 그때는 아래 '이 기기에서 바뀌었다' 판정을 건너뛴다 — 기본값을
    // '방금 바꾼 값'으로 신고하면 그것이 구름을 덮어쓴다.
    // 자세한 사연은 core/sync_merge.dart 의 rulesMove 에 적었다.
    final firstRun = s.rulesStamp == 0;

    if (!firstRun && localSig != s.rulesSig) {
      // 이 기기에서 바뀌었다.
      s.rulesSig = localSig;
      s.rulesStamp = DateTime.now().millisecondsSinceEpoch;
      await store.persistSettingsLocalOnly();
    }

    final got = await _t.read(f);
    // 아직 안 내려온 파일이다. 통로가 당겨 오라고 일러 뒀으니 다음 차례에.
    // **여기서 '없음'으로 읽으면 이 기기 것이 구름을 덮는다.**
    if (got.state == ReadState.notReady) return;
    final remote = got.body;

    final remoteStamp = (remote?['stamp'] as int?) ?? -1;

    switch (rulesMove(
      firstRun: firstRun,
      hasRemote: remote != null,
      remoteStamp: remoteStamp,
      localStamp: s.rulesStamp,
    )) {
      case RulesMove.takeRemote:
        _applyRules(store, remote!);
        // 구름의 시각을 그대로 물려받는다. 여기서 '지금'으로 새로 찍으면
        // 받기만 하고도 이 기기가 가장 새것이 되어, 다른 기기가 그 뒤에
        // 올린 것을 도로 밀어낸다.
        s.rulesStamp = remoteStamp > 0
            ? remoteStamp
            : DateTime.now().millisecondsSinceEpoch;
        s.rulesSig = _sig(_rulesBody(store));
        await store.persistSettingsLocalOnly();
        store.bump();
      case RulesMove.pushLocal:
        if (firstRun) {
          // 구름에도 없다 — 이 기기가 처음이니 여기 것이 곧 기준이 된다.
          // 시각을 0으로 두면 영영 아무도 못 이긴다.
          s.rulesStamp = DateTime.now().millisecondsSinceEpoch;
          s.rulesSig = localSig;
          await store.persistSettingsLocalOnly();
        }
        await _t.write(f, {..._rulesBody(store), 'stamp': s.rulesStamp});
      case RulesMove.nothing:
        break;
    }

    await _syncPrefs(root);
    await _syncTrial(root);
  }

  /// 체험 기록. 규칙과 달리 '늦은 쪽'이 아니라 **많이 쓴 쪽**이 이긴다.
  ///
  /// 이렇게 하는 이유가 둘이다. 하나, 앱을 지웠다 다시 깔아도 체험이
  /// 리셋되지 않는다(그게 이걸 올리는 이유다). 둘, 두 기기를 같은 날 쓰면
  /// 각자 하루씩 세는데, 큰 쪽을 남겨야 체험이 두 배로 늘어나지 않는다.
  Future<void> _syncTrial(String root) async {
    final store = Store.instance;
    final s = store.settings;
    final f = '$root/trial.json';
    final remote = (await _t.read(f)).body;
    var changed = false;
    if (remote != null) {
      int mx(String k, int cur) {
        final v = remote[k];
        return (v is int && v > cur) ? v : cur;
      }

      final d = mx('days', s.trialDays);
      final t = mx('tidy', s.trialTidyTotal);
      final w = mx('wiz', s.trialWizTotal);
      final n = (remote['notice'] == true) || s.trialNoticeShown;
      if (d != s.trialDays ||
          t != s.trialTidyTotal ||
          w != s.trialWizTotal ||
          n != s.trialNoticeShown) {
        s.trialDays = d;
        s.trialTidyTotal = t;
        s.trialWizTotal = w;
        s.trialNoticeShown = n;
        changed = true;
      }
    }
    if (changed) {
      await store.persistSettingsLocalOnly();
      store.bump();
    }
    await _t.write(f, {
      'days': s.trialDays,
      'tidy': s.trialTidyTotal,
      'wiz': s.trialWizTotal,
      'notice': s.trialNoticeShown,
    });
  }

  Map<String, dynamic> _rulesBody(Store store) {
    final s = store.settings;
    return {
      'emphStyle': s.emphStyle,
      'hrMode': s.hrMode,
      'headingMode': s.headingMode,
      'headingSymbol': s.headingSymbol,
      'bulletChar': s.bulletChar,
      'smartDashList': s.smartDashList,
      'smartFillerHeading': s.smartFillerHeading,
      'headingPad': s.headingPad,
      'headingPadAbove': s.headingPadAbove,
      'headingPadBelow': s.headingPadBelow,
      'bulletIndent': s.bulletIndent,
      'removeCitations': s.removeCitations,
      'favPrompts': s.favPrompts,
      // 2026-08-17 — 만들어 두었지만 아직 메모가 없는 폴더. 메모가 든
      // 폴더는 메모와 함께 건너가지만, 빈 폴더는 여기 없으면 다른 기기에
      // 안 나타난다.
      'folders': s.folders,
      'customRules': s.customRules
          .map((r) => {'find': r.find, 'replace': r.replace, 'regex': r.regex})
          .toList(),
    };
  }

  /// 이 기기만의 값. 다른 기기로 안 건너간다.
  ///
  /// 2026-08-18 소유자 지시 — "폰트 사이즈는 맥은 큰 폰트로 해도 상관없지만,
  /// 그 큰 폰트로 아이폰으로 보기는 싫은 것이다."
  ///
  /// 아침에는 이걸 규칙과 같이 실었다가 되돌린다. 실어 보고 나서야 선이
  /// 어디인지 분명해졌다.
  ///
  ///   **무엇이 바뀌는가** — 정리 규칙, 바꾸기 규칙, 폴더, 자주 쓰는 지시문.
  ///     같은 글을 넣으면 어느 기기에서든 같은 결과가 나와야 한다. 기기마다
  ///     다르면 그건 규칙이 아니다.
  ///   **어떻게 보이는가** — 글자 크기, 줄 간격, 종이, 화면 모드, 정렬.
  ///     27인치 앞에 앉아 있을 때와 손에 쥐고 볼 때는 알맞은 크기가 다르다.
  ///     같게 만드는 것이 오히려 불편하다.
  ///
  /// 소유자가 2026-08-16에 규칙을 두고 "모든 기기에서 동기화되어야 한다"고
  /// 했던 것과 오늘 모양을 두고 "각각 다르게 하고 싶다"고 한 것은 모순이
  /// 아니다. 서로 다른 것을 말한 것이고, 내가 그 둘을 한 통에 담았던 것이
  /// 문제였다.
  Map<String, dynamic> _prefsBody(Store store) {
    final s = store.settings;
    return {
      'bodyFontSize': s.bodyFontSize,
      'bodyLineHeight': s.bodyLineHeight,
      'themeMode': s.themeMode,
      'paperMode': s.paperMode,
      'monoEditor': s.monoEditor,
      'previewBeforeApply': s.previewBeforeApply,
      'sortMode': s.sortMode,
      'pasteTipDone': s.pasteTipDone,
    };
  }

  void _applyPrefs(Store store, Map<String, dynamic> j) {
    final s = store.settings;
    T pick<T>(String k, T cur) {
      final v = j[k];
      return v is T ? v : cur;
    }

    // JSON은 17을 정수로 되돌린다. pick<double>로 받으면 'double이 아니다'가
    // 되어 조용히 지금 값을 지킨다 — 안 바뀌는데 왜 안 바뀌는지 알 수 없는
    // 종류의 고장이다.
    double pickNum(String k, double cur) {
      final v = j[k];
      return v is num ? v.toDouble() : cur;
    }

    s.bodyFontSize = pickNum('bodyFontSize', s.bodyFontSize).clamp(
        MonoTextController.minBodyFontSize, MonoTextController.maxBodyFontSize);
    s.bodyLineHeight = pickNum('bodyLineHeight', s.bodyLineHeight).clamp(
        MonoTextController.minBodyHeight, MonoTextController.maxBodyHeight);
    s.themeMode = pick('themeMode', s.themeMode);
    s.paperMode = pick('paperMode', s.paperMode);
    s.monoEditor = pick('monoEditor', s.monoEditor);
    s.previewBeforeApply = pick('previewBeforeApply', s.previewBeforeApply);
    s.sortMode = pick('sortMode', s.sortMode);
    s.pasteTipDone = pick('pasteTipDone', s.pasteTipDone);
  }

  /// 이 기기의 모양 값을 구름의 제 칸에 맞춘다.
  ///
  /// 칸 이름은 키체인에 둔 이름표다(core/key_vault.dart). 앱을 지웠다 깔아도
  /// 같은 이름이 나오므로 **재설치해도 그 기기 값이 돌아온다.** 이름표를
  /// 못 얻으면 아무것도 안 한다 — 남의 칸을 덮어쓰느니 안 하는 게 낫다.
  ///
  /// 누가 이기는지는 규칙과 같은 셈을 쓴다(rulesMove). 같은 칸에 쓰는 것은
  /// 이 기기뿐이라 다툴 일이 거의 없지만, '새로 깐 앱은 듣기부터 한다'는
  /// 그 셈의 핵심이 여기서도 그대로 필요하다.
  Future<void> _syncPrefs(String root) async {
    final key = await KeyVault.deviceKey();
    if (key.isEmpty) return;

    final store = Store.instance;
    final s = store.settings;
    final dir = '$root/prefs';
    if (!await _t.ensureDir(dir)) return;
    final f = '$dir/$key.json';

    final localBody = _prefsBody(store);
    final localSig = _sig(localBody);
    final firstRun = s.prefsStamp == 0;

    if (!firstRun && localSig != s.prefsSig) {
      s.prefsSig = localSig;
      s.prefsStamp = DateTime.now().millisecondsSinceEpoch;
      await store.persistSettingsLocalOnly();
    }

    final got = await _t.read(f);
    if (got.state == ReadState.notReady) return;
    final remote = got.body;

    final remoteStamp = (remote?['stamp'] as int?) ?? -1;

    switch (rulesMove(
      firstRun: firstRun,
      hasRemote: remote != null,
      remoteStamp: remoteStamp,
      localStamp: s.prefsStamp,
    )) {
      case RulesMove.takeRemote:
        _applyPrefs(store, remote!);
        s.prefsStamp = remoteStamp > 0
            ? remoteStamp
            : DateTime.now().millisecondsSinceEpoch;
        s.prefsSig = _sig(_prefsBody(store));
        await store.persistSettingsLocalOnly();
        store.bump();
      case RulesMove.pushLocal:
        if (firstRun) {
          s.prefsStamp = DateTime.now().millisecondsSinceEpoch;
          s.prefsSig = localSig;
          await store.persistSettingsLocalOnly();
        }
        await _t.write(f, {..._prefsBody(store), 'stamp': s.prefsStamp});
      case RulesMove.nothing:
        break;
    }
  }

  /// AI 키를 구글 드라이브의 우리 칸에 맞춘다.
  ///
  /// 2026-08-20 소유자 지시 — "구글 드라이브도 하자."
  ///
  /// **애플에서는 아무 일도 안 한다.** 그쪽은 키체인이 나르는데(core/
  /// key_vault.dart) 그 길은 종단간 암호화라 애플조차 못 읽는다. 이미
  /// 더 나은 길이 있는데 평문 파일을 하나 더 만들면 위험만 는다.
  ///
  /// 끄면 올려 뒀던 파일을 **치운다.** 껐는데도 남의 서버에 그대로
  /// 있으면 그 스위치는 거짓말이다. 한 번만 치우면 되므로 도장(stamp)을
  /// 0으로 되돌려 두 번 안 하게 한다.
  Future<void> _syncAiKey(String root) async {
    if (_viaApple) return;
    final store = Store.instance;
    final s = store.settings;
    final dir = '\$root/secret';
    final f = '\$dir/ai.json';

    if (!s.aiKeySync) {
      if (s.aiKeyStamp == 0) return;
      await _t.remove(f);
      s.aiKeyStamp = 0;
      s.aiKeySig = '';
      await store.persistSettingsLocalOnly();
      return;
    }

    if (!await _t.ensureDir(dir)) return;

    final localBody = <String, dynamic>{'key': s.aiKey};
    final localSig = _sig(localBody);
    final firstRun = s.aiKeyStamp == 0;

    if (!firstRun && localSig != s.aiKeySig) {
      s.aiKeySig = localSig;
      s.aiKeyStamp = DateTime.now().millisecondsSinceEpoch;
      await store.persistSettingsLocalOnly();
    }

    final got = await _t.read(f);
    if (got.state == ReadState.notReady) return;
    final remote = got.body;
    final remoteStamp = (remote?['stamp'] as int?) ?? -1;

    switch (rulesMove(
      firstRun: firstRun,
      hasRemote: remote != null,
      remoteStamp: remoteStamp,
      localStamp: s.aiKeyStamp,
    )) {
      case RulesMove.takeRemote:
        final k = remote!['key'];
        // 빈 값을 받아 멀쩡한 키를 지우지 않는다. 옛 판이 쓴 파일이나
        // 쓰다 만 파일이 그렇게 생겼다.
        if (k is! String || k.trim().isEmpty) return;
        s.aiKey = k;
        s.aiKeyStamp = remoteStamp > 0
            ? remoteStamp
            : DateTime.now().millisecondsSinceEpoch;
        s.aiKeySig = _sig(<String, dynamic>{'key': s.aiKey});
        await store.persistSettingsLocalOnly();
        store.bump();
      case RulesMove.pushLocal:
        // 아직 키를 안 넣은 기기가 빈 값을 올려 다른 기기 것을 지우는
        // 일이 없게 한다. 올릴 것이 없으면 안 올린다.
        if (s.aiKey.trim().isEmpty) break;
        if (firstRun) {
          s.aiKeyStamp = DateTime.now().millisecondsSinceEpoch;
          s.aiKeySig = localSig;
          await store.persistSettingsLocalOnly();
        }
        await _t.write(f, {'key': s.aiKey, 'stamp': s.aiKeyStamp});
      case RulesMove.nothing:
        break;
    }
  }

  void _applyRules(Store store, Map<String, dynamic> j) {
    final s = store.settings;
    T pick<T>(String k, T cur) {
      final v = j[k];
      return v is T ? v : cur;
    }

    s.emphStyle = pick('emphStyle', s.emphStyle);
    s.hrMode = pick('hrMode', s.hrMode);
    s.headingMode = pick('headingMode', s.headingMode);
    s.headingSymbol = pick('headingSymbol', s.headingSymbol);
    s.bulletChar = pick('bulletChar', s.bulletChar);
    s.smartDashList = pick('smartDashList', s.smartDashList);
    s.smartFillerHeading = pick('smartFillerHeading', s.smartFillerHeading);
    s.headingPad = pick('headingPad', s.headingPad);
    s.headingPadAbove = pick('headingPadAbove', s.headingPadAbove);
    s.headingPadBelow = pick('headingPadBelow', s.headingPadBelow);
    s.bulletIndent = pick('bulletIndent', s.bulletIndent);
    s.removeCitations = pick('removeCitations', s.removeCitations);
    final fd = j['folders'];
    if (fd is List) {
      s.folders = fd.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final fp = j['favPrompts'];
    if (fp is List) s.favPrompts = fp.map((e) => e.toString()).toList();
    final cr = j['customRules'];
    if (cr is List) {
      s.customRules = cr
          .whereType<Map>()
          .map((m) => CustomRule(
                find: (m['find'] ?? '').toString(),
                replace: (m['replace'] ?? '').toString(),
                regex: m['regex'] == true,
              ))
          .toList();
    }
  }

  /// 내용이 바뀌었는지만 알면 되므로 암호학적으로 셀 필요는 없다.
  String _sig(Map<String, dynamic> body) {
    final s = jsonEncode(body);
    var h = 0;
    for (var i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return '${s.length}:$h';
  }

}
