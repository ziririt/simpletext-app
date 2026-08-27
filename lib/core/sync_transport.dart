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

  /// 여러 파일을 쓴다.
  ///
  /// 2026-08-27 — 한 바퀴가 10~35초씩 걸리고 있었다(동기화 기록). 까닭은
  /// 올리기를 하나씩 차례로 했기 때문이다. 드라이브에서는 파일 하나에
  /// 왕복이 둘(내용 한 번, 딱지 한 번)이라, 노트 넷이면 여덟 번을 줄
  /// 세워 기다렸다.
  ///
  /// 받는 쪽은 이미 겹쳐 받고 있었다(readMany). 보내는 쪽만 줄을 서 있던
  /// 것은 그냥 빠뜨린 것이다.
  ///
  /// 기본은 하나씩이다. 왕복이 공짜인 통로(아이클라우드)는 겹칠 이유가
  /// 없다.
  Future<void> writeMany(Map<String, Map<String, dynamic>> items) async {
    for (final e in items.entries) {
      await write(e.key, e.value);
    }
  }

  /// 방 안의 목록만 — 본문 없이 (이름표, 딱지의 시각).
  ///
  /// null 은 "이 통로는 딱지를 모른다"는 뜻이다. 그때 부르는 쪽은
  /// 예전처럼 readDir 로 통째로 읽는다. 아이클라우드가 그쪽이다 —
  /// 파일 읽기가 공짜라 딱지가 필요 없다.
  Future<List<RemoteMeta>?> listMeta(String dir) async => null;

  /// 창고에 새로 바뀐 것이 있나 — **짧은 한 번의 물음**.
  ///
  /// 목록 훑기와 다르다. 훑기는 방 안의 모든 이름을 받아 오지만, 이건
  /// '지난번에 받아 둔 표 이후로 무엇이 바뀌었나'만 묻는다. 바뀐 게
  /// 없으면 답이 빈 봉투라, 2~3초마다 물어도 부담이 없다.
  ///
  /// 이 물음이 있어야 '30초마다 훑기'를 그만둘 수 있다. 사람은 남이 쓴
  /// 글을 30초 뒤에 보고 싶어 하지 않는다.
  ///
  ///   true  — 바뀐 게 있다. 한 바퀴 돌아라.
  ///   false — 없다. 가만히 있어라.
  ///   null  — 모른다. 이 통로는 이 물음을 못 하거나, 물었는데 답을
  ///           못 들었다. 그때는 시계에 맡긴다.
  ///
  /// **내가 올린 것도 변경으로 잡힌다.** 그래서 올린 직후 한 바퀴가 더
  /// 도는데, 그 바퀴는 오갈 것이 없어 금방 끝난다. 내 것을 걸러 내는
  /// 길도 있지만 그 대조가 한 번 틀리면 **남의 글을 영영 못 받는다.**
  /// 헛바퀴 하나가 훨씬 싸다.
  Future<bool?> probeChanged() async => null;

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
