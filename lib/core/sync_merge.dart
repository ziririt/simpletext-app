/// 아이클라우드 동기화의 병합 규칙 — 순수 함수. 파일·네트워크·화면 코드를
/// 넣지 않는다(그래야 테스트로 못 박을 수 있다).
///
/// 2026-08-16. 애플 기기(아이폰·아이패드·맥)끼리 메모를 맞추기 위한 것이다.
/// 로그인 화면은 만들지 않는다 — 기기에 이미 들어와 있는 애플 계정을 그대로
/// 쓴다. 안드로이드·윈도우는 이 경로를 타지 않고 파일 백업/복원으로 간다.
///
/// ## 어떤 사고를 막으려고 이렇게 짰나
///
/// 1) **지운 메모가 되살아나는 사고.** 두 기기를 쓰면 가장 흔하다. 폰에서
///    지우고 맥을 켜면, 맥에는 그 메모가 아직 살아 있으니 "맥에만 있는 새
///    메모"로 보여 다시 올라간다. 그래서 삭제는 '없음'이 아니라 툼스톤이라는
///    기록으로 남긴다. 지운 시각이 고친 시각보다 늦으면 삭제가 이긴다.
///
/// 2) **한쪽이 통째로 날아가는 사고.** 메모 전체를 파일 하나로 올리면 두
///    기기가 서로 다른 메모를 고쳤을 때 늦게 올린 쪽이 상대의 수정을 통째로
///    덮는다. 그래서 병합 단위를 메모 하나로 잡는다. 같은 메모를 양쪽에서
///    고친 경우에만 충돌이고, 그때만 늦게 고친 쪽이 이긴다.
///
/// 3) **시계가 어긋난 기기.** updatedAt이 같으면 순서를 정할 수 없다.
///    이때는 로컬을 남긴다 — 눈앞에서 방금 친 글자를 지우지 않는 쪽이 사람이
///    납득하는 결과다.
///
/// ## 일부러 안 넣은 것
///
/// 설정(AppSettings)은 동기화하지 않는다. 거기에는 사용자의 AI 키가 들어
/// 있고, 키는 기기 밖으로 나가지 않는다는 것이 이 앱의 약속이다. 글꼴 크기
/// 같은 값도 기기마다 다른 게 맞다.
library;

/// 병합 결과. 어느 쪽이 이겼는지까지 돌려주므로 화면에 "n개 받음"을 띄울 수
/// 있고, 테스트에서 이유를 확인할 수 있다.
class MergeResult<T> {
  /// 병합 뒤 남을 메모들. 순서는 정하지 않는다(화면에서 다시 정렬한다).
  final List<T> notes;

  /// 병합 뒤 남을 툼스톤들. `{'id': String, 'deletedAt': int}`.
  final List<Map<String, dynamic>> tombstones;

  /// 원격에서 새로 받아 온(또는 원격이 이긴) 메모 수.
  final int pulled;

  /// 로컬이 이겨서 올려야 하는 메모 수.
  final int pushed;

  /// 이번 병합으로 로컬에서 사라진 메모 수.
  final int removed;

  /// 지면서 **아직 구름에 못 올라간 수정**을 품고 있던 로컬 판들.
  /// 부르는 쪽이 휴지통에 넣는다 — 글이 소리 없이 사라지면 안 된다
  /// (2026-08-21 자정, 웹의 6번 줄이 실제로 그렇게 사라졌다).
  final List<T> backups;

  const MergeResult({
    required this.notes,
    required this.tombstones,
    required this.pulled,
    required this.pushed,
    required this.removed,
    this.backups = const [],
  });

  /// 로컬에 바꿀 게 하나도 없었나. 화면을 흔들지 말지 판단하는 데 쓴다.
  bool get localUnchanged => pulled == 0 && removed == 0;
}

/// 툼스톤을 id로 접어서 가장 늦은 삭제 시각만 남긴다.
Map<String, int> foldTombstones(Iterable<Map<String, dynamic>> tombs) {
  final out = <String, int>{};
  for (final t in tombs) {
    final id = t['id'];
    if (id is! String || id.isEmpty) continue;
    final at = t['deletedAt'];
    final ms = at is int ? at : 0;
    final prev = out[id];
    if (prev == null || ms > prev) out[id] = ms;
  }
  return out;
}

/// 오래된 툼스톤을 버린다.
///
/// 안 버리면 이 목록만 영원히 자란다. [keepDays]는 넉넉히 잡는다 — 여행이나
/// 방학처럼 한 기기를 몇 주씩 안 켜는 일이 실제로 있고, 그 기기가 돌아오기
/// 전에 툼스톤을 지우면 1)의 부활 사고가 그대로 일어난다.
List<Map<String, dynamic>> pruneTombstones(
  Map<String, int> folded, {
  required int nowMs,
  int keepDays = 180,
}) {
  final cutoff = nowMs - keepDays * 24 * 60 * 60 * 1000;
  final out = <Map<String, dynamic>>[];
  folded.forEach((id, at) {
    if (at >= cutoff) out.add({'id': id, 'deletedAt': at});
  });
  out.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  return out;
}

/// 메모 병합.
///
/// [idOf]/[stampOf]로 메모 타입을 밖에서 받는다. 이 파일이 Note를 모르게
/// 해서 화면·저장 코드가 섞여 들어오지 못하게 막는 장치다.
MergeResult<T> mergeNotes<T>({
  required List<T> local,
  required List<Map<String, dynamic>> localTombs,
  required List<T> remote,
  required List<Map<String, dynamic>> remoteTombs,
  required String Function(T) idOf,
  required int Function(T) stampOf,
  required int nowMs,
  int keepDays = 180,
  String Function(T)? bodyOf,
  int syncedBeforeMs = 0,
}) {
  final tombs = foldTombstones([...localTombs, ...remoteTombs]);

  final localById = <String, T>{};
  for (final n in local) {
    localById[idOf(n)] = n;
  }
  final remoteById = <String, T>{};
  for (final n in remote) {
    remoteById[idOf(n)] = n;
  }

  final ids = <String>{...localById.keys, ...remoteById.keys};

  final notes = <T>[];
  final backups = <T>[];
  var pulled = 0, pushed = 0, removed = 0;

  for (final id in ids) {
    final l = localById[id];
    final r = remoteById[id];
    final deletedAt = tombs[id];

    // 살아 있는 쪽에서 가장 늦게 고친 시각. 삭제와 겨룰 상대다.
    final newest = [
      if (l != null) stampOf(l),
      if (r != null) stampOf(r),
    ].fold<int>(-1, (a, b) => b > a ? b : a);

    // 지운 뒤에 다시 고친 게 아니라면 삭제가 이긴다. 같으면 삭제가 이긴다
    // — 지우는 행동은 고치는 행동보다 뒤에 오는 게 보통이고, 되살아나는
    // 쪽이 사람을 더 놀라게 하기 때문이다.
    if (deletedAt != null && deletedAt >= newest) {
      if (l != null) {
        removed++;
        // 지워지는 로컬에 아직 구름에 안 올라간 수정이 있으면 백업.
        if (stampOf(l) > syncedBeforeMs) backups.add(l);
      }
      continue;
    }

    if (l == null) {
      notes.add(r as T);
      pulled++;
    } else if (r == null) {
      notes.add(l);
      pushed++;
    } else {
      final ls = stampOf(l), rs = stampOf(r);
      if (rs > ls) {
        notes.add(r);
        pulled++;
        // 로컬이 지는데, 마지막으로 끝까지 맞춘 뒤에 고친 수정이고
        // 알맹이도 다르다 — 구름에 올라간 적 없는 글일 수 있다. 백업.
        if (bodyOf != null &&
            ls > syncedBeforeMs &&
            bodyOf(l) != bodyOf(r)) {
          backups.add(l);
        }
      } else if (ls > rs) {
        notes.add(l);
        pushed++;
      } else {
        // 같은 시각 — 눈앞의 것을 남긴다. 올릴 필요도 받을 필요도 없다.
        notes.add(l);
      }
    }
  }

  return MergeResult<T>(
    notes: notes,
    tombstones: pruneTombstones(tombs, nowMs: nowMs, keepDays: keepDays),
    pulled: pulled,
    pushed: pushed,
    removed: removed,
    backups: backups,
  );
}

// ------------------------------------------------------------------ 설정
//
// 2026-08-18 소유자 신고 — "설정 값들 유지되게 해준다고 하지 않았니? 방금도
// 다시 앱이 들어오면서 설정값 초기화되었다."
//
// 이 셈을 파일 다루는 코드 안에 두었다가 틀렸다. 아이클라우드 폴더와
// 다운로드 대기와 JSON 파싱이 뒤엉킨 자리라, 정작 **누가 이기는가**라는
// 한 줄짜리 판단이 눈에 안 보였다. 밖으로 꺼내 테스트로 못 박는다.

/// 설정 맞추기에서 이 기기가 할 일.
enum RulesMove {
  /// 구름 것을 받는다.
  takeRemote,

  /// 이 기기 것을 올린다.
  pushLocal,

  /// 아무것도 안 한다.
  nothing,
}

/// 누가 이기는가.
///
/// [firstRun] 이 이 고침의 핵심이다. 새로 깐 앱은 설정이 전부 기본값인데,
/// 예전 코드는 그것을 '방금 이 기기에서 바꾼 것'으로 읽었다. 지문이 다르니까
/// (아무것도 없는 것과 기본값의 지문은 다르다) 시각을 지금으로 찍었고,
/// 그러면 구름의 것보다 새것이 되어 **기본값이 구름을 덮어썼다.**
///
/// 아무것도 없는 것과 방금 비운 것은 다르다. 시각이 0이면 이 기기는 아직
/// 아무 말도 한 적이 없고, 그때는 말할 자격이 없는 것으로 본다 — 들을
/// 차례다.
RulesMove rulesMove({
  required bool firstRun,
  required bool hasRemote,
  required int remoteStamp,
  required int localStamp,
}) {
  if (firstRun) return hasRemote ? RulesMove.takeRemote : RulesMove.pushLocal;
  if (hasRemote && remoteStamp > localStamp) return RulesMove.takeRemote;
  if (remoteStamp < localStamp) return RulesMove.pushLocal;
  return RulesMove.nothing;
}

/// AI 키를 옮길 때는 규칙과 한 가지가 다르다 — **빈 키는 값이 아니다.**
///
/// 2026-08-30 소유자 신고 — "api키도 기기간 동기화하는 것으로 체크해
/// 뒀는데, 아이폰에서 입력했는데 맥용 앱에 api키가 비어 있다."
///
/// 맥의 설정을 열어 보니 그 자리에 답이 있었다. aiKeyStamp 가 **오늘
/// 아침 시각**으로 찍혀 있었다. 맥은 키가 없는데도 '내가 제일 최근에
/// 바꿨다'고 주장하고 있었던 것이다.
///
/// 어쩌다 그렇게 됐나. 키는 설정이 아니라 키체인에 산다. 맥에서 어떤
/// 사유로 키체인 것을 잃으면 설정에는 지문(aiKeySig)만 남고 키는 빈
/// 문자열이 된다. 그러면 '지금 지문'과 '적어 둔 지문'이 달라지고, 옛
/// 코드는 그 다름을 **"이 기기에서 사람이 방금 고쳤다"**로 읽어 도장을
/// 지금 시각으로 찍었다. 그 순간부터 맥은 영영 받는 쪽이 못 된다. 올릴
/// 것도 없어서(빈 키는 안 올린다) 아무 일도 안 일어나고, 사람 눈에는
/// '동기화가 그냥 안 되는' 것으로 보인다.
///
/// 고침은 한 줄로 말할 수 있다. **없는 사람은 말할 자격이 없다.**
/// 키가 없는 기기는 언제나 듣는 쪽이다.
RulesMove keyMove({
  required bool firstRun,
  required bool hasRemote,
  required int remoteStamp,
  required int localStamp,
  required bool localEmpty,
}) {
  if (localEmpty) return hasRemote ? RulesMove.takeRemote : RulesMove.nothing;
  return rulesMove(
    firstRun: firstRun,
    hasRemote: hasRemote,
    remoteStamp: remoteStamp,
    localStamp: localStamp,
  );
}
