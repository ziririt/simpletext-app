/// 최근에 쓴 것이 맨 위로 오는 목록(MRU).
///
/// 2026-08-14 소유자 요청: 마법사에 "자주 쓰는 지시문"을 등록해 두고 골라 쓴다.
/// 그때 "최근에 이용한 것이 제일 위에 나오게" 해 달라는 조건이 붙었다.
///
/// 규칙은 셋뿐이다.
///   1) 이미 있던 것을 다시 쓰면 새로 만들지 않고 맨 위로 올린다(중복 금지)
///   2) 앞뒤 공백은 무시한다 — 같은 지시문을 두 번 등록하는 사고를 막는다
///   3) 개수 상한을 둔다. 목록이 무한정 길어지면 '고르기'가 다시 일이 된다
///
/// 화면과 분리해 둔 이유는 순서 규칙을 테스트로 고정하기 위해서다.
/// 이건 정리 엔진이 아니다 — 앱 전용이라 웹 대칭(HANDOVER 5절) 대상이 아니다.
library;

/// [item]을 [list] 맨 위로 올린다. 목록을 제자리에서 고치고 그대로 돌려준다.
List<String> mruInsert(List<String> list, String item, {int max = 30}) {
  final t = item.trim();
  if (t.isEmpty) return list;
  list.removeWhere((e) => e.trim() == t);
  list.insert(0, t);
  while (list.length > max) {
    list.removeLast();
  }
  return list;
}
