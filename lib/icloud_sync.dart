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
import 'package:shared_preferences/shared_preferences.dart';

import 'core/key_vault.dart';
import 'core/mono_controller.dart' show MonoTextController;
import 'core/purchase_gate.dart';
import 'core/sync_merge.dart';
import 'core/sync_log.dart';
import 'core/sync_plan.dart';
import 'core/sync_transport.dart';
import 'sync/gdrive_transport.dart';
import 'sync/icloud_transport.dart';
// CustomRule은 main.dart가 아니라 엔진 쪽에 산다(2026-08-16에 여기서 한 번
// 틀렸다 — analyze가 undefined_method로 잡아 줬다).
import 'core/tidy_engine.dart' show CustomRule;
import 'main.dart' show Store, Note, deviceFamily;

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

  /// 마지막으로 **끝까지** 맞춘 시각 — 기기에 남는다(앱을 껐다 켜도).
  ///
  /// 병합에서 "지는 로컬의 이 수정이 구름에 올라간 적 있는가"를 가르는
  /// 기준이다. 이 시각보다 새 도장의 로컬이 지면 휴지통에 백업한다.
  /// 값을 아직 못 읽었으면 0 — 백업이 더 후해질 뿐, 잃는 쪽으로는
  /// 절대 틀리지 않는다.
  int _syncedUpTo = 0;
  bool _syncedUpToLoaded = false;

  Future<void> _loadSyncedUpTo() async {
    if (_syncedUpToLoaded) return;
    _syncedUpToLoaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      _syncedUpTo = p.getInt('syncedUpTo') ?? 0;
    } catch (_) {}
  }

  /// 이 기기에서 한 바퀴라도 끝난 적이 있나.
  ///
  /// 앱을 껐다 켜면 lastSyncMs 는 0 으로 돌아가지만 _syncedUpTo 는 남는다.
  /// 둘 중 하나라도 서 있으면 '처음'이 아니다.
  bool get everSynced => _syncedUpTo > 0 || lastSyncMs.value > 0;

  Future<void> _saveSyncedUpTo(int ms) async {
    _syncedUpTo = ms;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('syncedUpTo', ms);
    } catch (_) {}
  }

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

  // --------------------------------------------------- 짧게 묻는 시계
  //
  // 2026-08-27 소유자 지시 — "'동기화'가 가장 빠르고 정확한 노트 앱이
  // 되고 싶다." 30초마다 방을 훑는 것으로는 그 말에 못 미친다. 남이 쓴
  // 글을 30초 뒤에 보는 앱을 빠르다고 부를 수는 없다.
  //
  // 그렇다고 훑기를 3초로 당길 수는 없다. 훑기는 방 안의 모든 이름을
  // 받아 오는 일이라 값이 비싸다. 대신 **'바뀐 게 있나'만 묻는 짧은
  // 물음**이 따로 있다(core/sync_transport.dart 의 probeChanged).
  // 바뀐 게 없으면 답이 빈 봉투다. 그건 3초마다 물어도 된다.
  //
  // 그래서 두 시계를 나란히 둔다. 짧은 물음이 3초마다 문을 두드리고,
  // 훑기는 30초에 한 번 그물을 던진다 — 짧은 물음이 못 잡는 통로
  // (아이클라우드)와 물음이 실패하는 판을 위한 바닥이다.
  //
  // 짧은 물음은 앱이 앞에 있을 때만 돈다. 뒤로 물러난 앱에서 3초마다
  // 그물을 던지는 것은 배터리를 태우는 짓이고, 어차피 모바일에서는
  // 시계가 얼어붙는다.
  // 얼마나 자주 물을지는 core/sync_plan.dart 의 probeEvery 가 정한다 —
  // 뜨거운 동안(누군가 쓰고 있는 동안)만 3초, 잠잠하면 15초.
  Timer? _probe;
  bool _probing = false;
  int _hotUntil = 0;

  /// 지금 누군가 쓰고 있다 — 한동안 빠르게 묻는다.
  void markHot() {
    _hotUntil = DateTime.now().millisecondsSinceEpoch + kProbeHotMs;
  }

  void _startProbe() {
    _probe?.cancel();
    if (!active || paused) return;
    // 되풀이 시계(periodic)가 아니라 한 번짜리를 이어 건다. 간격이
    // 도중에 바뀌기 때문이다 — 뜨거워지면 다음 물음부터 곧바로 빨라진다.
    _probe = Timer(
      probeEvery(
          hotUntilMs: _hotUntil, nowMs: DateTime.now().millisecondsSinceEpoch),
      () async {
        await _probeOnce();
        _startProbe();
      },
    );
  }

  void _stopProbe() {
    _probe?.cancel();
    _probe = null;
  }

  /// 짧은 물음을 지금 곧바로 한 번. 뜨겁게 만들고 시계를 다시 건다.
  void wakeProbe() {
    markHot();
    _startProbe();
  }

  Future<void> _probeOnce() async {
    // 한 바퀴가 도는 중이면 물어볼 것도 없다. 그 바퀴가 어차피 다 본다.
    if (!active || paused || _busy || _probing) return;
    _probing = true;
    try {
      if (await _t.probeChanged() == true) await syncNow();
    } catch (_) {
      // 물음이 실패해도 조용히 지나간다. 30초 시계가 바닥을 받친다.
    } finally {
      _probing = false;
    }
  }

  // ------------------------------------------------------- 동기화 기록
  //
  // 2026-08-27 소유자 요청. 무엇이 언제 오갔는지를 남긴다. 자세한 까닭은
  // core/sync_log.dart 머리말에 있다. 여기는 세고 적기만 한다.
  //
  // 세는 자리를 _run() 안에 두지 않고 밖에 둔 까닭 — _run 은 도중에
  // 던질 수 있다. 던진 바퀴도 '거기까지는 옮겼다'가 기록으로 남아야
  // 어디서 끊겼는지 알 수 있다.

  /// 화면이 듣는다. 값이 바뀌면 기록 화면이 다시 그려진다.
  final ValueNotifier<int> logRevision = ValueNotifier<int>(0);

  SyncLog _log = SyncLog();
  bool _logLoaded = false;
  int _roundUp = 0;
  int _roundDown = 0;

  SyncLog get log => _log;

  Future<void> _loadLog() async {
    if (_logLoaded) return;
    _logLoaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      _log = SyncLog.decode(p.getString('syncLog'));
      logRevision.value++;
    } catch (_) {}
  }

  /// 한 바퀴가 끝났다고 알린다. 적을 것이 없으면 아무 일도 안 한다.
  void _noteRound(int startedMs, Object? err) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final e = SyncEvent(
      atMs: now,
      up: _roundUp,
      down: _roundDown,
      ms: now - startedMs,
      // 예외 문구를 그대로 담지 않는다. 창고 주소나 파일 이름이 섞여
      // 들어올 수 있고, 이 기록은 사람에게 그대로 보인다.
      err: err == null ? null : _shortErr(err),
    );
    if (!_log.add(e)) return;
    // 오간 것이 있었다 = 누군가 쓰고 있다. 한동안 빠르게 묻는다.
    if (e.up > 0 || e.down > 0) wakeProbe();
    logRevision.value++;
    unawaited(_persistLog());
  }

  static String _shortErr(Object err) {
    if (err is TimeoutException) return 'timeout';
    if (err is StateError) return 'not-ready';
    if (err is SocketException) return 'network';
    return err.runtimeType.toString();
  }

  Future<void> _persistLog() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('syncLog', _log.encode());
    } catch (_) {}
  }

  /// 앱이 켜질 때 한 번 부른다.
  Future<void> boot() async {
    await _loadSyncedUpTo();
    await _loadLog();
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
    _startProbe();
  }

  /// 앱이 다시 앞으로 나올 때. 다른 기기에서 고친 게 있으면 여기서 들어온다.
  /// 사용자가 설정 앱에서 아이클라우드를 켜고 돌아오는 경로이기도 하므로,
  /// 꺼져 있던 경우에는 경로를 잊고 다시 물어본다.
  void onResume() {
    if (!active) return;
    if (state.value != SyncState.ok) forgetRoot();
    unawaited(syncNow());
    // 뒤로 물러날 때 껐던 짧은 시계를 다시 건다. 돌아온 직후는 늘
    // 뜨겁게 본다 — 자리를 비운 동안 남이 썼을 가능성이 가장 큰 순간이다.
    wakeProbe();
  }

  /// 앱이 뒤로 물러날 때. 짧은 시계를 끈다 — 안 보이는 앱이 3초마다
  /// 그물을 던지면 배터리만 탄다. 모바일에서는 어차피 시계가 얼지만,
  /// 맥과 웹은 창을 가려도 계속 돌기 때문에 여기서 명시적으로 끈다.
  void onPause() {
    _stopProbe();
    flushUp();
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
    _stopProbe();
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
  /// 올리면 파일을 초당 몇 번씩 쓰게 된다. 잠시 쉬었다가 한 번만 올린다.
  ///
  /// 2026-08-27 — 3초에서 1초로 줄인다. 저장 자체가 이미 0.7초를 모으고
  /// 있어서(Store.touch), 3초를 더 얹으면 마지막 글자에서 올라가기까지
  /// 3.7초가 걸렸다. 그 사이에 손을 멈추면 **문장 중간까지만** 남의
  /// 기기로 건너갔다 — 소유자가 08-27 아침에 겪은 그 일이다.
  ///
  /// 1초라도 모으는 까닭은 남아 있다. 안 모으면 타자 한 번에 파일 하나가
  /// 올라간다.
  void scheduleUp() {
    if (!supported || paused) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () => unawaited(syncNow()));
    // 내가 쓰고 있다. 저쪽에서도 쓰고 있을 때가 많다 — 빠르게 묻는다.
    markHot();
  }

  /// 떠나기 전에 부친다 (2026-08-26).
  ///
  /// 3초 모으기가 아직 남아 있으면 기다리지 않고 지금 올린다. 맥에서
  /// 앱이 뒤로 물러나면 macOS 낮잠(App Nap)이 타이머를 얼려, 쓴 글이
  /// 창고에 못 간 채 잠드는 일이 실제로 있었다(8/25 밤 수사). 물러나는
  /// 순간이 보낼 수 있는 마지막 기회다.
  ///
  /// 모으기가 없으면 아무것도 안 한다 — 창을 오갈 때마다 공연히 한
  /// 바퀴 돌 이유는 없다.
  void flushUp() {
    if (!supported || paused) return;
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(syncNow());
    }
  }

  void dispose() {
    _tick?.cancel();
    _debounce?.cancel();
    _stopProbe();
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
      final roundStartMs = DateTime.now().millisecondsSinceEpoch;
      _roundUp = 0;
      _roundDown = 0;
      final work = _run(root);

      // **결과는 일 쪽이 정한다.**
      //
      // 2026-08-20 소유자 신고 — "금방 되었다가 또 금방 꺼지고", 그리고
      // "앱을 계속 켜놓으니까 금방 저절로 켜짐 상태가 되었다."
      //
      // 저절로 돌아온다는 말이 답이었다. 로그인이 풀린 것이라면 저절로
      // 돌아올 수 없다. 어떤 바퀴는 제때 끝나고 어떤 바퀴는 안 끝나는데,
      // 우리가 **안 끝난 바퀴를 '꺼짐'이라고 불렀다.**
      //
      // 시간이 넘은 것과 일이 실패한 것을 한 통에 담았던 것이다. 시간
      // 제한은 '얼마나 기다렸다가 화면에 말할까'를 정하는 것이라고 바로
      // 위에 적어 놓고도, 정작 그 말을 '꺼짐'으로 했다.
      unawaited(work.then((_) {
        lastSyncMs.value = DateTime.now().millisecondsSinceEpoch;
        unawaited(_saveSyncedUpTo(lastSyncMs.value));
        state.value = SyncState.ok;
        _noteRound(roundStartMs, null);
      }, onError: (Object e) {
        state.value = SyncState.off;
        _noteRound(roundStartMs, e);
      }).whenComplete(free));

      try {
        await work.timeout(lastSyncMs.value == 0 ? _firstPass : _pass);
      } on TimeoutException {
        // 오래 걸리는 것은 실패가 아니다. 일은 계속 돈다 — 끝나면 위의
        // then 이 '켜짐'으로 바꾼다. 여기서는 기다리기만 그만둔다.
        state.value = SyncState.running;
      }
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
    // 두 길이 있다.
    //
    // **딱지 길(구글 드라이브).** 목록 한 번이면 파일마다 '언제 고쳤나'가
    // 딱지로 온다(sync/gdrive_transport.dart). 그 딱지를 이 기기의 시각과
    // 견줘 **바뀐 것만** 받는다(core/sync_plan.dart). 예전에는 어느 노트가
    // 바뀌었는지 알 길이 본문을 열어 보는 것뿐이라 켤 때마다 전부 다시
    // 받았고, 그 몇 분 동안 화면이 '맞추는 중'이었다(2026-08-20).
    //
    // **옛길(아이클라우드).** 파일 읽기가 공짜라 딱지가 필요 없다.
    // listMeta 가 null 이면 예전처럼 통째로 읽는다. 아직 안 내려온 파일을
    // 당겨 오라고 이르는 일은 통로가 맡는다(2026-08-18) — 아이클라우드만의
    // 사정을 여기서 알면 통로를 갈 때마다 이 코드를 또 고쳐야 한다.
    final remoteNotes = <Note>[];
    final remoteTombs = <Map<String, dynamic>>[];
    // 저쪽에 있는 모든 아이디 — 본문을 안 받은 것도 여기에는 있다.
    Set<String> remoteIds;
    Set<String> remoteTombIds;
    // 저쪽 것의 시각. 딱지로 알았든 본문으로 알았든. 없으면 모르는 것이다.
    final remoteStamp = <String, int>{};
    // 열어 봤는데 읽을 수 없던 자리 — 덮어써서 고친다.
    final corrupt = <String>{};

    final noteMetas = await _t.listMeta(notesDir);
    final tombMetas = noteMetas == null ? null : await _t.listMeta(tombsDir);

    if (noteMetas == null || tombMetas == null) {
      for (final f in await _t.readDir(notesDir)) {
        try {
          remoteNotes.add(Note.fromJson(f));
        } catch (_) {
          // 다른 판이 쓴 파일이거나 쓰다 만 파일. 통째로 죽지 말고 건너뛴다.
        }
      }
      for (final f in await _t.readDir(tombsDir)) {
        final id = f['id'];
        if (id is String && id.isNotEmpty) remoteTombs.add(f);
      }
      remoteIds = {for (final n in remoteNotes) n.id};
      remoteTombIds = {for (final t in remoteTombs) t['id'] as String};
      for (final n in remoteNotes) {
        remoteStamp[n.id] = n.updatedAt;
      }
    } else {
      remoteIds = {for (final m in noteMetas) m.id};
      remoteTombIds = {for (final m in tombMetas) m.id};
      for (final m in noteMetas) {
        if (m.up != null) remoteStamp[m.id] = m.up!;
      }
      final need = pickFetch(
        localStamp: {for (final n in store.notes) n.id: n.updatedAt},
        metas: noteMetas,
      );
      final got =
          await _t.readMany([for (final id in need) '$notesDir/$id.json']);
      for (final id in need) {
        final r = got['$notesDir/$id.json'];
        if (r == null) {
          // 답을 못 들었다(그물이 끊겼다). 받지도 올리지도 않는다 —
          // 시각을 지워 두면 아래 올리기 셈이 이번 차례를 거른다.
          remoteStamp.remove(id);
          continue;
        }
        if (r.ok) {
          try {
            final n = Note.fromJson(r.body!);
            remoteNotes.add(n);
            // 본문이 딱지보다 참이다 — 딱지 달기가 실패한 적이 있으면
            // 둘이 어긋날 수 있다.
            remoteStamp[n.id] = n.updatedAt;
          } catch (_) {
            corrupt.add(id);
            remoteStamp.remove(id);
          }
        } else {
          // 없거나 깨졌다 — 덮어써서 고친다. 옛길도 이렇게 스스로 나았다.
          corrupt.add(id);
          remoteStamp.remove(id);
        }
      }
      // 툼스톤은 딱지가 곧 내용이다({id, deletedAt}). 딱지가 있으면 열어
      // 보지 않고 그대로 만들고, 없는 옛 툼스톤만 받아 본다.
      final tombNeed = <String>[];
      for (final m in tombMetas) {
        if (m.up != null) {
          remoteTombs.add(<String, dynamic>{'id': m.id, 'deletedAt': m.up});
        } else {
          tombNeed.add(m.id);
        }
      }
      final tgot =
          await _t.readMany([for (final id in tombNeed) '$tombsDir/$id.json']);
      for (final r in tgot.values) {
        if (!r.ok) continue;
        final id = r.body!['id'];
        if (id is String && id.isNotEmpty) remoteTombs.add(r.body!);
      }
    }

    // --- 합치기 (규칙은 core/sync_merge.dart) ---
    //
    // 받아 온 파일 수를 세지 않고, 합친 뒤에 **이 기기의 글이 실제로
    // 바뀐 개수**를 센다(아래). 통로마다 읽는 방식이 달라서다 — 딱지
    // 길은 바뀐 것만 받아 오고, 옛길은 매번 전부 받아 온다. 파일 수를
    // 세면 같은 일을 두고 아이폰과 맥이 다른 숫자를 말하게 된다.
    final beforeStamp = {for (final n in store.notes) n.id: n.updatedAt};
    final now = DateTime.now().millisecondsSinceEpoch;
    final merged = mergeNotes<Note>(
      local: store.notes,
      localTombs: store.tombstones,
      remote: remoteNotes,
      remoteTombs: remoteTombs,
      idOf: (n) => n.id,
      stampOf: (n) => n.updatedAt,
      nowMs: now,
      bodyOf: (n) => n.body,
      syncedBeforeMs: _syncedUpTo,
    );

    _roundDown = 0;
    for (final n in merged.notes) {
      final was = beforeStamp[n.id];
      if (was == null || was != n.updatedAt) _roundDown++;
    }

    // --- 기기에 반영 ---
    // 지는 판에 아직 구름에 못 올라간 수정이 있었다면 휴지통에 백업한다.
    // 글이 소리 없이 사라지는 일만은 없어야 한다 — 휴지통은 신뢰다.
    for (final b in merged.backups) {
      store.trash.insert(0, {'note': b.toJson(), 'deletedAt': now});
    }
    if (!merged.localUnchanged) {
      store.notes = merged.notes;
      store.tombstones = merged.tombstones;
      await store.persistLocalOnly();
    } else {
      store.tombstones = merged.tombstones;
    }

    // --- 창고에 반영 ---
    //
    // 2026-08-27 — 하나씩 줄 세워 보내던 것을 한꺼번에 모아 겹쳐 보낸다.
    // 드라이브는 파일 하나에 왕복이 둘이라, 넷을 줄 세우면 여덟 번을
    // 기다린다. 받는 쪽은 이미 겹쳐 받고 있었다.
    final toWrite = <String, Map<String, dynamic>>{};
    for (final n in merged.notes) {
      // 올릴지는 딱지 셈이 정한다(core/sync_plan.dart). 핵심 하나 —
      // **모르면 안 올린다.** 있는 건 아는데 얼마나 새것인지 모르는
      // 판에서 올리면, 남이 방금 고친 것을 이쪽의 옛것으로 덮는다.
      if (shouldUpload(
        exists: remoteIds.contains(n.id),
        corrupt: corrupt.contains(n.id),
        remoteStamp: remoteStamp[n.id],
        localStamp: n.updatedAt,
      )) {
        toWrite['$notesDir/${n.id}.json'] = n.toJson();
        // 기록에 적는 '올림'은 메모 수다. 삭제 기록(툼스톤)은 안 센다 —
        // 사람이 보는 숫자는 사람이 쓴 것의 수여야 한다.
        _roundUp++;
      }
    }
    final liveIds = {for (final n in merged.notes) n.id};
    final tombIds = <String>{};
    // 원격 툼스톤 아이디는 위의 목록 읽기가 이미 안다(remoteTombIds).
    // 예전에 여기서 exists() 를 하나씩 묻던 사고는 08-20 아침에 고쳤고,
    // 딱지 길에서는 목록 자체가 그 답이다.
    for (final t in merged.tombstones) {
      final id = t['id'] as String;
      tombIds.add(id);
      if (!remoteTombIds.contains(id)) {
        toWrite['$tombsDir/$id.json'] = t;
      }
      // 지워진 메모의 본문 파일은 치운다. 안 그러면 툼스톤이 만료된 뒤에
      // 그 파일이 '새 메모'로 되살아난다.
      //
      // 다만 **저쪽에 있는 것만** 치운다. 없는 것을 지우라고 시키면 그것도
      // 왕복이고, 지운 메모 수만큼 매번 되풀이된다.
      if (!liveIds.contains(id) && remoteIds.contains(id)) {
        await _t.remove('$notesDir/$id.json');
      }
    }
    // 모아 둔 것을 한꺼번에 보낸다.
    if (toWrite.isNotEmpty) await _t.writeMany(toWrite);

    // 만료된 툼스톤 파일 치우기
    for (final t in remoteTombs) {
      final id = t['id'] as String;
      if (tombIds.contains(id)) continue;
      await _t.remove('$tombsDir/$id.json');
    }

    // 규칙과 AI 키는 매 바퀴마다 볼 것이 아니다.
    //
    // 2026-08-27 — 한 바퀴가 8~16초 걸리고 있었다(동기화 기록에 찍혔다).
    // 메모 쪽은 목록 두 번이면 끝나는데, 여기서 왕복이 서너 번 더 붙는다.
    // 그런데 규칙이나 AI 키는 하루에 몇 번 바뀌는 것도 아니다. 30초마다
    // 물어볼 이유가 없다.
    //
    // 메모가 몇 초 늦는 것은 사람이 알아채지만, 규칙이 1분 늦는 것은
    // 아무도 모른다. 늦어도 되는 것을 늦추고, 그 값으로 메모를 당긴다.
    final sideNow = DateTime.now().millisecondsSinceEpoch;
    if (sideNow - _sideMs >= _sideEvery) {
      _sideMs = sideNow;
      await _syncRules(root);
      await _syncAiKey(root);
    }
  }

  /// 곁들이를 마지막으로 본 시각. 0 이면 아직 한 번도 안 봤다 —
  /// 첫 바퀴에서는 반드시 본다.
  int _sideMs = 0;
  static const int _sideEvery = 60 * 1000;

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
      // 결제 기록도 같은 파일에 싣는다. 여기만이 '가진 쪽이 이긴다'로
      // 도는 자리이기 때문이다 — 규칙 동기화(늦은 쪽이 이긴다)에 실으면
      // 결제를 모르는 기기가 켜지는 순간 산 것을 덮어 버린다.
      final en = s.ent.merge(
          Entitlement.fromJson(remote['ent'] as Map<String, dynamic>?));
      final lg = s.legacyFree || remote['legacy'] == true;
      if (d != s.trialDays ||
          t != s.trialTidyTotal ||
          w != s.trialWizTotal ||
          n != s.trialNoticeShown ||
          en != s.ent ||
          lg != s.legacyFree) {
        s.trialDays = d;
        s.trialTidyTotal = t;
        s.trialWizTotal = w;
        s.trialNoticeShown = n;
        s.ent = en;
        s.legacyFree = lg;
        s.premium = premiumHere(
          e: en,
          family: deviceFamily(),
          now: DateTime.now(),
        );
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
      'ent': s.ent.toJson(),
      'legacy': s.legacyFree,
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
      // 2026-08-20 소유자 신고 — "'API키도 기기끼리 옮기기'를 켰는데도
      // 안드로이드폰에서는 동기화 안 된 듯."
      //
      // 이 스위치를 '이 기기만의 값'으로 뒀던 것이 잘못이다. 소유자는
      // "동기화하자"고 했지 "기기마다 각각 켜겠다"고 한 적이 없다.
      //
      // 여기(규칙)로 옮기는 까닭: 규칙은 '어느 기기에서 하든 같은 결과가
      // 나와야 하는 것'이다. 키를 창고에 둘지 말지는 기기의 취향이 아니라
      // **사람의 결정**이라 이쪽이 맞다.
      //
      // 끄는 것도 함께 건너간다. 한 기기에서 껐다는 것은 '내 키를 더는
      // 드라이브에 두지 않겠다'는 뜻이지 '이 기기만 빠지겠다'가 아니다.
      'aiKeySync': s.aiKeySync,
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
    // 2026-08-20 — 키를 창고에 둘지 말지는 기기의 취향이 아니라
    // 사람의 결정이다. 그래서 규칙과 함께 건너간다.
    s.aiKeySync = pick('aiKeySync', s.aiKeySync);
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
