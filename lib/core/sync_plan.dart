/// 무엇을 받고 무엇을 올릴지 — 딱지(메타)만 보고 정하는 셈.
///
/// 2026-08-20 밤. 앱을 켤 때마다 창고의 노트를 전부 다시 내려받아 첫
/// 맞추기가 몇 분씩 걸렸다. 까닭은 "어느 노트가 바뀌었나"를 알 길이
/// **본문을 열어 보는 것**뿐이었다는 것 — 그래서 다 열어 봤다.
///
/// 이제 드라이브 파일마다 딱지(appProperties)에 '언제 고쳤나(up)'를 적어
/// 둔다(sync/gdrive_transport.dart). 목록 한 번이면 딱지가 다 오므로,
/// 여기서는 그 딱지와 이 기기의 시각만 견줘 **받을 것**과 **올릴 것**을
/// 고른다.
///
/// 이 셈을 icloud_sync.dart 안에 두지 않고 밖으로 꺼낸 까닭은 설정 셈
/// (rulesMove)과 같다 — 판단은 시험으로 못 박을 수 있어야 하고, 파일과
/// 왕복이 뒤엉킨 자리에서는 판단이 눈에 안 보인다.
library;

import 'sync_transport.dart';

/// 받아 와야 하는 노트 아이디들.
///
/// 받는 조건 셋. 어느 하나면 받는다.
///  - 딱지가 없다(옛 파일) — 얼마나 새것인지 모르니 열어 봐야 안다.
///  - 이 기기에 없다 — 남이 만든 노트다.
///  - 딱지가 이 기기 것보다 새것이다 — 남이 고쳤다.
///
/// 딱지가 이 기기 것과 **같으면 안 받는다.** 옛길에서는 이때도 본문을
/// 받아서 합치기에 넘겼지만, 합치기는 같은 시각이면 눈앞의 것을 남긴다
/// (core/sync_merge.dart) — 받으나 안 받으나 결과가 같으니 받지 않는다.
List<String> pickFetch({
  required Map<String, int> localStamp,
  required List<RemoteMeta> metas,
}) =>
    [
      for (final m in metas)
        if (m.up == null ||
            localStamp[m.id] == null ||
            m.up! > localStamp[m.id]!)
          m.id,
    ];

/// 이 노트를 창고에 올릴 것인가.
///
/// **모르면 안 올린다.** 저쪽에 있는 것은 아는데(목록에 나왔다) 얼마나
/// 새것인지 모르는 판(딱지도 없고 받기도 실패)에서 올려 버리면, 남이
/// 방금 고친 것을 이쪽의 옛것으로 덮을 수 있다. 그런 판은 이번 차례를
/// 거른다 — 다음 바퀴가 다시 받아 본다.
///
/// [corrupt] 는 열어 봤는데 읽을 수 없던 자리다(쓰다 만 파일, 깨진
/// JSON). 그건 덮어써서 고치는 것이 맞다 — 옛길도 그렇게 스스로 나았다.
bool shouldUpload({
  required bool exists,
  required bool corrupt,
  required int? remoteStamp,
  required int localStamp,
}) {
  if (!exists || corrupt) return true;
  if (remoteStamp == null) return false;
  return remoteStamp < localStamp;
}

/// 편집 화면 밑으로 새 판이 도착했을 때 화면이 할 일.
///
/// 합치기는 원격이 이기면 저장소 목록에 **원격 인스턴스를 꽂는다**
/// (core/sync_merge.dart). 그 순간 열려 있는 편집 화면이 물고 있는 옛
/// 객체는 목록에서 떨어져 나간다. 화면이 이를 모르면 두 가지가 생긴다.
///
///   1) 낡은 글을 계속 보여준다 — "기기마다 글이 다르다"로 보인다
///      (2026-08-20 저녁, 맥·안드로이드·웹 세 곳에서 실제로 겪었다).
///   2) 그 화면에서 한 글자라도 치면 낡은 글에 새 도장이 찍혀
///      남의 최신 수정을 덮는다.
///
/// 그래서 화면은 저장소 변화를 듣다가 이 셈에 따라 움직인다.
enum EditorRefresh {
  /// 같은 객체다 — 내 손이 만졌거나 남의 일이다. 할 일 없다.
  keep,

  /// 새 판이 왔는데 알맹이가 화면의 것과 똑같다. 객체만 갈아 끼운다 —
  /// 글자도 시각도 건드리지 않는다.
  ///
  /// 2026-08-27 사건이 여기서 났다. 이 갈래가 없어서 '똑같은 글'이
  /// 들어와도 assertMine 으로 빠졌고, 그때마다 시각이 새로 찍혀 창고에
  /// 올라갔다. 저쪽 기기도 똑같이 되받아쳐서 두 기기가 30초마다 서로를
  /// 밀어냈다. 그 사이에 다른 기기에서 쓴 진짜 새 글은 계속 밀려났다.
  rebind,

  /// 새 판이 왔고 이 화면에서 치던 글이 없다 — 갈아 그린다.
  adopt,

  /// 새 판이 왔는데 이 화면에서 치던 중이다 — 눈앞의 글이 이긴다.
  /// 사람이 지금 보면서 만지는 글을 소리 없이 갈아치우는 것이
  /// 가장 나쁘기 때문이다. 새 객체에 화면의 글을 도장 찍어 되쓴다.
  assertMine,
}

/// 짧은 물음의 간격 — 지금 몇 초마다 문을 두드릴까.
///
/// 2026-08-27. 3초마다 묻는 것은 사람이 글을 주고받는 동안에만 값어치가
/// 있다. 아무도 안 쓰는 새벽 세 시에도 3초마다 두드리면, 그건 배터리와
/// 구글의 하루치 몫을 태우는 짓이다. 우리 앱 하나만 보면 티가 안 나지만
/// 손님이 천 명이면 구글이 문을 닫는다.
///
/// 그래서 '뜨거운 동안'만 빠르게 묻는다. 뜨거워지는 순간은 둘 —
/// 이 기기에서 글이 바뀌었을 때, 그리고 남의 글이 도착했을 때다.
/// 둘 다 '지금 누군가 쓰고 있다'는 신호다. 그 뒤 2분 동안 빠르게 묻고,
/// 잠잠해지면 느리게 돌아간다.
///
/// 느린 쪽도 15초다. 예전의 30초 훑기보다 여전히 두 배 빠르다.
Duration probeEvery({
  required int hotUntilMs,
  required int nowMs,
  Duration hot = const Duration(seconds: 3),
  Duration cool = const Duration(seconds: 15),
}) =>
    nowMs < hotUntilMs ? hot : cool;

/// 뜨거운 시간이 얼마나 가나.
const int kProbeHotMs = 2 * 60 * 1000;

EditorRefresh editorRefresh({
  required bool sameObject,
  required bool editing,
  required bool sameContent,
}) {
  if (sameObject) return EditorRefresh.keep;
  // 알맹이가 같으면 다툴 것이 없다. 이 한 줄이 2026-08-27 의 되받아치기를
  // 끊는다.
  if (sameContent) return EditorRefresh.rebind;
  return editing ? EditorRefresh.assertMine : EditorRefresh.adopt;
}

/// 목록 위에 '동기화 중입니다' 띠를 보일까.
///
/// 2026-08-27 소유자 신고 — "로그인 직후 아직 동기화가 안 된 경우에
/// 샘플 문서 하나만 딸랑 있는데, 이때 사람들이 '왜 로그인했는데도
/// 동기화가 안 되지?'라는 의문을 가진다. 아무것도 안 나오고 텅 비어
/// 있으니 에러 난 줄 아는 사람이 많다."
///
/// 맞는 말이다. **사람은 침묵을 고장으로 읽는다.** 특히 방금 무언가를
/// 허락한 직후에는 더 그렇다 — 내가 한 일이 통했는지 아닌지를 확인하고
/// 싶은데 화면이 아무 말도 안 하면, 통하지 않았다고 결론 내린다.
///
/// 이 띠는 **이 기기에서 첫 동기화가 끝나기 전까지만** 나온다. 한 번이라도
/// 끝난 기기에서는 다시 안 나온다. 앱을 켤 때마다 몇 초씩 뜨면 그건
/// 안내가 아니라 잔소리다.
bool showSyncingBanner({
  required bool active,
  required bool paused,
  required bool everSynced,
  required bool running,
}) {
  if (!active || paused) return false;
  if (everSynced) return false;
  return running;
}

/// 동기화가 잠들었을 때 목록 위에 눕는 안내 띠 — 무엇을 보일까.
///
/// 2026-08-20 소유자 지적: 허락이 만료된 사실을 설정 구석에서 기다리게
/// 하면 안 된다. 일반 이용자는 설정에 가지 않는다 — 글은 쓰이는데
/// 소리 없이 안 올라가는 상태를 본인만 모른 채 지나간다. 알림은
/// 사용자가 있는 자리(목록 맨 위)에서 해야 한다.
///
/// 브라우저 규칙상 드라이브 허락은 사용자의 손짓으로만 다시 받을 수
/// 있다. 띠를 누르는 것이 바로 그 손짓이 된다.
enum SyncBanner {
  /// 정상이거나 구글 창고가 아니다 — 띠 없음(0px).
  none,

  /// 계정은 붙어 있는데 허락만 만료 — 누르면 바로 허락 창.
  wake,

  /// 로그인이 풀렸다 — 누르면 동기화 시트(웹 로그인 단추는 구글이
  /// 그리는 것이라 시트 안에만 있다).
  signIn,
}

SyncBanner syncBanner({
  required bool gdrive,
  required bool healthy,
  required bool signedIn,
  required bool authExpired,
}) {
  if (!gdrive || healthy) return SyncBanner.none;
  if (signedIn && authExpired) return SyncBanner.wake;
  if (!signedIn) return SyncBanner.signIn;
  return SyncBanner.none;
}
