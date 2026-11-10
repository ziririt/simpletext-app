// 노트 저장 묶음을 읽는 규칙 — 순수 함수. 플랫폼 API 를 부르지 않는다.
//
// 2026-11-11 소유자 신고 — "몇 분 만에 앱을 다시 열었는데" 노트가 환영
// 노트 하나로 돌아가 있었다. 동기화 기록도 11/9 에서 멈춰 있었다.
//
// 잰 것: 노트 600개, 묶음 16.3MB(맥의 옛 앱 보관함에서 크기만 셌다).
// 이 묶음을 통째로 SharedPreferences(아이폰은 NSUserDefaults)에 넣고
// 있었다. 그 서랍은 4MB(2^22 바이트)를 넘으면 "direct mode" 로 바뀌고,
// 디스크에 닿는 일을 **앱이 직접, 나중에** 한다. 받기가 끝나자마자
// 다른 앱으로 넘어가면 앱이 멈췄다가 정리되면서 그 '나중'이 오지 않는다.
// 노트도, 같은 서랍의 동기화 기록도 같이 사라진다. 앱을 켠 채 몇 분
// 두었을 때(07:45)는 남았다 — 그래서 '될 때도 있고 안 될 때도 있었다'.
//
// 그래서 노트는 이제 앱 전용 파일(notes.v3.json)에 쓴다. 이 파일은 그
// 파일을 읽고 고르는 규칙만 담는다. 파일을 실제로 여닫는 일은
// lib/note_file.dart 가 한다.

import 'dart:convert';

/// 읽어 낸 묶음. 노트 타입은 main.dart 에 있으므로 일반형으로 둔다.
class DecodedStore<N> {
  final List<N> notes;
  final List<Map<String, dynamic>> tombstones;
  final List<Map<String, dynamic>> trash;

  /// 읽지 못한 노트의 원본. **버리지 않고 다음 저장 때 그대로 되쓴다.**
  /// 예전에는 노트 하나가 깨져도 전체를 버리고 환영 노트만 내놓았고,
  /// 그다음 저장이 그 환영 노트로 600개를 덮어썼다.
  final List<Map<String, dynamic>> unreadable;

  const DecodedStore({
    required this.notes,
    required this.tombstones,
    required this.trash,
    required this.unreadable,
  });
}

/// [raw] 를 읽는다. 바깥 껍데기(JSON 자체)가 깨졌으면 null — 그때 부르는
/// 쪽은 그 원본을 따로 떠 두고(지우지 않고) 다른 출처를 찾는다.
DecodedStore<N>? decodeStore<N>(
  String raw,
  N Function(Map<String, dynamic>) fromJson,
) {
  Object? top;
  try {
    top = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  if (top is! Map) return null;
  final notes = <N>[];
  final bad = <Map<String, dynamic>>[];
  for (final e in (top['notes'] as List?) ?? const []) {
    if (e is! Map) continue;
    final m = e.cast<String, dynamic>();
    try {
      notes.add(fromJson(m));
    } catch (_) {
      bad.add(m);
    }
  }
  // 앞서 못 읽고 들고 있던 것도 다시 읽어 본다. 새 판이 읽을 수 있게
  // 됐으면 그때 돌아온다.
  for (final e in (top['unreadable'] as List?) ?? const []) {
    if (e is! Map) continue;
    final m = e.cast<String, dynamic>();
    try {
      notes.add(fromJson(m));
    } catch (_) {
      bad.add(m);
    }
  }
  List<Map<String, dynamic>> maps(Object? v) => [
        for (final e in (v as List?) ?? const [])
          if (e is Map) e.cast<String, dynamic>(),
      ];
  return DecodedStore<N>(
    notes: notes,
    tombstones: maps(top['tombstones']),
    trash: maps(top['trash']),
    unreadable: bad,
  );
}

/// 어디서 읽을지. 파일이 참이다. 파일이 없거나 깨졌을 때만 옛 서랍을 본다.
enum StoreSource { file, prefs, none }

StoreSource pickStoreSource({
  required bool fileReadable,
  required bool prefsReadable,
}) {
  if (fileReadable) return StoreSource.file;
  if (prefsReadable) return StoreSource.prefs;
  return StoreSource.none;
}

/// 옛 서랍의 노트를 지워도 되는가. **파일에 쓴 것을 다시 읽어 노트 수가
/// 맞을 때만.** 서랍을 비우는 까닭은 4MB 를 넘는 서랍이 설정·기록 쓰기
/// 까지 같이 불안하게 만들기 때문이다.
bool mayDropPrefsCopy({
  required int notesInPrefs,
  required int notesReadBackFromFile,
}) =>
    notesReadBackFromFile >= notesInPrefs;
