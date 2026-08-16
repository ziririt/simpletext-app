/// 휴지통 규칙 — 순수 함수. 화면·저장 코드를 넣지 않는다.
///
/// 2026-08-16. 조사에서 확인한 것: **메모가 사라지는 사건은 앱을 버리게
/// 만든다.** 다른 노트앱 포럼에는 "휴지통에도 없고 이력도 없이 노트가
/// 사라졌다"는 글이 반복해서 올라오고, 그 스레드마다 사람들이 앱을 떠난다.
/// 그래서 휴지통은 편의 기능이 아니라 신뢰 장치다.
///
/// 우리는 지금까지 삭제하면 곧바로 없앴다. 툼스톤(삭제 기록)은 있었지만
/// 그건 기기끼리 맞추기 위한 내부 장치일 뿐, 사용자가 되돌릴 방법은 없었다.
///
/// ## 왜 30일인가
///
/// 애플 메모가 30일, 구글 킵이 7일이다. 짧으면 안전망 구실을 못 하고,
/// 길면 지운 것이 계속 쌓여 있는 느낌을 준다. 사람들이 이미 30일에
/// 익숙해져 있으므로 그 관습을 따른다 — 독자 설계를 하지 않는다.
library;

/// 지운 메모를 며칠 보관할지.
const int kTrashKeepDays = 30;

const int _dayMs = 24 * 60 * 60 * 1000;

/// 보관 기간이 지났는가.
bool trashExpired({
  required int deletedAt,
  required int nowMs,
  int keepDays = kTrashKeepDays,
}) =>
    nowMs - deletedAt >= keepDays * _dayMs;

/// 완전히 지워지기까지 며칠 남았나. 화면에 "n일 뒤 삭제"로 쓴다.
///
/// 0이 아니라 최소 1을 돌려준다. "0일 뒤 삭제"는 사람이 읽을 문장이 아니고,
/// 오늘 안에 지워진다는 뜻이면 "1일"이 더 정직하다(아직 안 지워졌으므로).
int trashDaysLeft({
  required int deletedAt,
  required int nowMs,
  int keepDays = kTrashKeepDays,
}) {
  if (trashExpired(deletedAt: deletedAt, nowMs: nowMs, keepDays: keepDays)) {
    return 0;
  }
  final left = keepDays * _dayMs - (nowMs - deletedAt);
  final days = (left / _dayMs).ceil();
  return days < 1 ? 1 : days;
}

/// 기한이 지난 것을 걸러 낸다.
///
/// 타입을 밖에서 받는 이유는 이 파일이 Note를 모르게 하기 위해서다. 모르면
/// 화면·저장 코드가 여기 섞여 들어올 수 없다.
List<T> pruneTrash<T>(
  List<T> items, {
  required int Function(T) deletedAtOf,
  required int nowMs,
  int keepDays = kTrashKeepDays,
}) =>
    items
        .where((e) => !trashExpired(
            deletedAt: deletedAtOf(e), nowMs: nowMs, keepDays: keepDays))
        .toList();
