/// 동기화의 **옮기는 통로**.
///
/// 2026-08-18. 무엇이 이기는지 정하는 일은 core/sync_merge.dart 가 한다.
/// 이 약속이 맡는 것은 그 결과를 **어디에 어떻게 놓느냐** 하나다.
///
/// ## 왜 갈라 놓는가
///
/// 창고가 둘이 될 것이기 때문이다 — 애플 기기는 아이클라우드, 그 밖은
/// 구글 드라이브. 그때 합치는 규칙까지 두 벌이 되면 반드시 한쪽만 고치는
/// 날이 온다. **그날의 증상은 "아이폰에서는 되는데 안드로이드에서는
/// 메모가 사라진다"이고, 그때는 어느 쪽이 옳은지 아무도 모른다.**
///
/// 그래서 규칙은 한 벌로 두고 통로만 갈아 끼운다.
///
/// ## 길이 짧다
///
/// 통로가 할 줄 알아야 하는 일은 여섯뿐이다. 폴더 만들기, 있나 보기,
/// 하나 읽기, 폴더째 읽기, 쓰기, 지우기. 아이클라우드든 드라이브든
/// 이 여섯으로 다 된다.
///
/// ## '아직 안 내려왔다'가 따로 있는 이유
///
/// 아이클라우드는 파일을 **이름만 먼저** 내려 준다. 내용은 달라고 해야
/// 온다. 그 상태를 '없음'으로 읽으면 남의 기기가 올린 메모를 없는 것으로
/// 보고 삭제 기록을 쓴다 — 메모가 사라진다. 그래서 [ReadState] 에
/// [ReadState.notReady] 를 따로 뒀다. 구글 드라이브에는 이 상태가 없고,
/// 그 통로는 이 값을 영영 안 돌려주면 된다.
library;

/// 한 파일을 읽어 본 결과의 종류.
enum ReadState {
  /// 읽었다.
  ok,

  /// 없다. 또는 깨져서 못 읽는다 — 둘을 가르지 않는 이유는 부르는 쪽이
  /// 할 일이 같기 때문이다(이쪽 것을 올린다).
  missing,

  /// 있는 것은 아는데 아직 안 내려왔다. **이번 차례는 건너뛴다.**
  notReady,
}

class ReadResult {
  const ReadResult(this.state, [this.body]);

  final ReadState state;
  final Map<String, dynamic>? body;

  static const ReadResult missing = ReadResult(ReadState.missing);
  static const ReadResult notReady = ReadResult(ReadState.notReady);

  bool get ok => state == ReadState.ok;
}

/// 방 목록의 한 줄 — 본문 없이 아는 것들.
///
/// [up] 은 파일 딱지(appProperties)에 적어 둔 '언제 고쳤나'다. 노트는
/// updatedAt, 툼스톤은 deletedAt, 설정 종류는 stamp 가 그 값이다.
/// 옛 파일에는 딱지가 없어서 null 이다 — 그때는 열어 봐야 안다.
class RemoteMeta {
  const RemoteMeta(this.id, this.up);

  /// 파일 이름에서 .json 을 뗀 것. 노트·툼스톤에서는 노트 아이디다.
  final String id;
  final int? up;
}

abstract class SyncTransport {
  const SyncTransport();

  /// 'icloud' · 'gdrive'. 기록과 화면에 쓴다.
  String get id;

  /// 폴더가 있게 만든다. 못 만들면 false.
  Future<bool> ensureDir(String path);

  /// 파일이 있는가. 내려왔는지까지는 안 본다.
  Future<bool> exists(String path);

  /// 한 파일. 안 내려온 것이면 [ReadState.notReady] 를 주고, 통로가
  /// 알아서 당겨 오라고 이른다 — 부르는 쪽은 다음 차례에 다시 오면 된다.
  Future<ReadResult> read(String path);

  /// 폴더 안의 json 전부. 못 읽은 것은 조용히 빠진다.
  Future<List<Map<String, dynamic>>> readDir(String path);

  /// 통째로 덮어쓴다. **중간에 끊겨도 반쪽짜리가 남으면 안 된다.**
  Future<void> write(String path, Map<String, dynamic> body);

  /// 없어도 조용히 넘어간다.
  Future<void> remove(String path);

  /// 방 안의 목록만 — 본문 없이 (이름표, 딱지의 시각).
  ///
  /// null 은 "이 통로는 딱지를 모른다"는 뜻이다. 그때 부르는 쪽은
  /// 예전처럼 readDir 로 통째로 읽는다. 아이클라우드가 그쪽이다 —
  /// 파일 읽기가 공짜라 딱지가 필요 없다.
  Future<List<RemoteMeta>?> listMeta(String dir) async => null;

  /// 여러 파일을 읽는다. 답은 (경로 → 결과) 지도다.
  ///
  /// **지도에 없는 경로는 "이번에 답을 못 들었다"는 뜻이다** — 없는
  /// 것(missing)과 다르다. 부르는 쪽은 그 경로를 이번 차례에서 걸러야
  /// 한다. 기본은 하나씩 차례로 읽는다. 왕복이 비싼 통로(드라이브)는
  /// 겹쳐 받도록 덮어쓴다.
  Future<Map<String, ReadResult>> readMany(List<String> paths) async {
    final out = <String, ReadResult>{};
    for (final p in paths) {
      out[p] = await read(p);
    }
    return out;
  }
}
