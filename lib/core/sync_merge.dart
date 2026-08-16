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

  const MergeResult({
    required this.notes,
    required this.tombstones,
    required this.pulled,
    required this.pushed,
    required this.removed,
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
      if (l != null) removed++;
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
  );
}
