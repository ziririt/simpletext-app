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

import 'core/mono_controller.dart' show MonoTextController;
import 'core/sync_merge.dart';
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

  /// 애플 기기에서만 돈다. 안드로이드·윈도우는 파일 백업/복원으로 간다.
  static bool get supported =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  final ValueNotifier<SyncState> state =
      ValueNotifier<SyncState>(SyncState.unsupported);

  /// 마지막으로 맞춘 시각(밀리초). 0이면 아직 한 번도 못 맞췄다.
  final ValueNotifier<int> lastSyncMs = ValueNotifier<int>(0);

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
    if (!supported) {
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
    if (!supported) return;
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
    if (!supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => unawaited(syncNow()));
  }

  void dispose() {
    _tick?.cancel();
    _debounce?.cancel();
  }

  // -------------------------------------------------------------- 경로

  Future<String?> _rootPath() async {
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

  Future<void> syncNow() async {
    if (!supported || _busy) return;
    _busy = true;
    try {
      final root = await _rootPath();
      if (root == null) {
        state.value = _signedIn ? SyncState.off : SyncState.signedOut;
        return;
      }
      state.value = SyncState.running;
      await _run(root);
      lastSyncMs.value = DateTime.now().millisecondsSinceEpoch;
      state.value = SyncState.ok;
    } catch (_) {
      // 동기화 실패로 앱이 멈추면 안 된다. 다음 차례에 다시 해 본다.
      state.value = SyncState.off;
    } finally {
      _busy = false;
    }
  }

  Future<void> _run(String root) async {
    final store = Store.instance;
    final notesDir = Directory('$root/notes');
    final tombsDir = Directory('$root/tombs');
    await notesDir.create(recursive: true);
    await tombsDir.create(recursive: true);

    // --- 원격 읽기 ---
    final pending = <String>[]; // 아직 안 내려온 파일들
    final remoteNotes = <Note>[];
    for (final f in await _readJsonDir(notesDir, pending)) {
      try {
        remoteNotes.add(Note.fromJson(f));
      } catch (_) {
        // 다른 판이 쓴 파일이거나 쓰다 만 파일. 통째로 죽지 말고 건너뛴다.
      }
    }
    final remoteTombs = <Map<String, dynamic>>[];
    for (final f in await _readJsonDir(tombsDir, pending)) {
      final id = f['id'];
      if (id is String && id.isNotEmpty) remoteTombs.add(f);
    }
    if (pending.isNotEmpty) {
      // 아이클라우드는 파일을 '이름만' 먼저 내려 준다. 실제 내용은 요청해야
      // 온다. 이번 차례에는 못 읽으니 다음 차례에 읽는다.
      try {
        await _ch.invokeMethod('download', {'paths': pending});
      } catch (_) {}
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
        await _writeJson(File('${notesDir.path}/${n.id}.json'), n.toJson());
      }
    }
    final liveIds = {for (final n in merged.notes) n.id};
    final tombIds = <String>{};
    for (final t in merged.tombstones) {
      final id = t['id'] as String;
      tombIds.add(id);
      final tf = File('${tombsDir.path}/$id.json');
      if (!await tf.exists()) await _writeJson(tf, t);
      // 지워진 메모의 본문 파일은 치운다. 안 그러면 툼스톤이 만료된 뒤에
      // 그 파일이 '새 메모'로 되살아난다.
      if (!liveIds.contains(id)) {
        final nf = File('${notesDir.path}/$id.json');
        if (await nf.exists()) {
          try {
            await nf.delete();
          } catch (_) {}
        }
      }
    }
    // 만료된 툼스톤 파일 치우기
    for (final t in remoteTombs) {
      final id = t['id'] as String;
      if (tombIds.contains(id)) continue;
      try {
        await File('${tombsDir.path}/$id.json').delete();
      } catch (_) {}
    }

    await _syncRules(root);
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
    final f = File('$root/rules.json');

    final localBody = _rulesBody(store);
    final localSig = _sig(localBody);
    if (localSig != s.rulesSig) {
      // 이 기기에서 바뀌었다.
      s.rulesSig = localSig;
      s.rulesStamp = DateTime.now().millisecondsSinceEpoch;
      await store.persistSettingsLocalOnly();
    }

    Map<String, dynamic>? remote;
    if (await f.exists()) {
      try {
        remote = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    } else {
      // 이름만 온 상태인지 확인
      final ph = File('$root/.rules.json.icloud');
      if (await ph.exists()) {
        try {
          await _ch.invokeMethod('download', {
            'paths': [f.path]
          });
        } catch (_) {}
        return; // 다음 차례에
      }
    }

    final remoteStamp = (remote?['stamp'] as int?) ?? -1;
    if (remote != null && remoteStamp > s.rulesStamp) {
      _applyRules(store, remote);
      s.rulesStamp = remoteStamp;
      s.rulesSig = _sig(_rulesBody(store));
      await store.persistSettingsLocalOnly();
      store.bump();
    } else if (remoteStamp < s.rulesStamp) {
      await _writeJson(f, {...localBody, 'stamp': s.rulesStamp});
    }

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
    final f = File('$root/trial.json');

    Map<String, dynamic>? remote;
    if (await f.exists()) {
      try {
        remote = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }
    var changed = false;
    if (remote != null) {
      int mx(String k, int cur) {
        final v = remote![k];
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
    await _writeJson(f, {
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
      // 2026-08-18에 실은 것들 — 보이는 모양에 관한 값이다.
      'bodyFontSize': s.bodyFontSize,
      'bodyLineHeight': s.bodyLineHeight,
      'themeMode': s.themeMode,
      'paperMode': s.paperMode,
      'monoEditor': s.monoEditor,
      'previewBeforeApply': s.previewBeforeApply,
      'sortMode': s.sortMode,
      // 한 번 본 안내를 다른 기기에서 또 보여 주지 않는다.
      'pasteTipDone': s.pasteTipDone,
    };
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

    // JSON은 17을 정수로 되돌린다. pick<double>로 받으면 'double이 아니다'가
    // 되어 조용히 지금 값을 지킨다 — 안 바뀌는데 왜 안 바뀌는지 알 수 없는
    // 종류의 고장이다. 숫자는 따로 받는다.
    double pickNum(String k, double cur) {
      final v = j[k];
      return v is num ? v.toDouble() : cur;
    }

    s.bodyFontSize = pickNum('bodyFontSize', s.bodyFontSize)
        .clamp(MonoTextController.minBodyFontSize,
            MonoTextController.maxBodyFontSize);
    s.bodyLineHeight = pickNum('bodyLineHeight', s.bodyLineHeight)
        .clamp(MonoTextController.minBodyHeight,
            MonoTextController.maxBodyHeight);
    s.themeMode = pick('themeMode', s.themeMode);
    // 모르는 종이 이름이 와도 paperById가 '기본'으로 떨어뜨린다.
    s.paperMode = pick('paperMode', s.paperMode);
    s.monoEditor = pick('monoEditor', s.monoEditor);
    s.previewBeforeApply = pick('previewBeforeApply', s.previewBeforeApply);
    s.sortMode = pick('sortMode', s.sortMode);
    s.pasteTipDone = pick('pasteTipDone', s.pasteTipDone);
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

  // -------------------------------------------------------------- 파일

  /// 폴더 안의 json을 전부 읽는다. 아직 안 내려온 것은 [pending]에 담는다.
  Future<List<Map<String, dynamic>>> _readJsonDir(
      Directory dir, List<String> pending) async {
    final out = <Map<String, dynamic>>[];
    List<FileSystemEntity> items;
    try {
      items = await dir.list().toList();
    } catch (_) {
      return out;
    }
    for (final e in items) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      // 아이클라우드는 아직 안 내려받은 파일을 '.이름.icloud'로 놔둔다.
      if (name.startsWith('.') && name.endsWith('.icloud')) {
        final real = name.substring(1, name.length - '.icloud'.length);
        pending.add('${dir.path}/$real');
        continue;
      }
      if (!name.endsWith('.json')) continue;
      try {
        final j = jsonDecode(await e.readAsString());
        if (j is Map<String, dynamic>) out.add(j);
      } catch (_) {}
    }
    return out;
  }

  /// 임시 파일에 쓰고 이름을 바꾼다. 쓰는 도중에 앱이 죽어도 반쪽짜리 파일이
  /// 아이클라우드로 올라가지 않게 하기 위해서다.
  Future<void> _writeJson(File f, Map<String, dynamic> j) async {
    final tmp = File('${f.path}.tmp');
    try {
      await tmp.writeAsString(jsonEncode(j), flush: true);
      await tmp.rename(f.path);
    } catch (_) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }
}
