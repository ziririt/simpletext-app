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
