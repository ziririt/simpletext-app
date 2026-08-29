/// 글 한 편이 가진 시각은 **둘뿐이다.**
///
/// 2026-08-29 소유자 지시 — "시간은 단 2가지. 최초 작성일 또는 붙여넣기한
/// 일시, 그리고 최근 편집일이다."
///
/// ## 무엇이 잘못돼 있었나
///
/// 날짜 줄이 보여 주던 것은 **수정 시각 하나**였고, 그 옆에 '최근 업데이트'
/// 라는 셋째 시각이 붙어 있었다. 그건 이 기기가 동기화로 남의 글을 마지막
/// 으로 **받아 온** 시각이다. 이 글과는 아무 상관이 없다 — 옆방에서 일어난
/// 일을 이 글의 이력인 양 붙여 놓은 꼴이었다.
///
/// 그리고 처음 시각이 아예 없었다. 원본으로 되돌리면 수정 시각이 '지금'이
/// 되면서, **이 글이 원래 언제 온 것인지 알 길이 사라졌다.** 되돌린다는
/// 것은 원래대로 간다는 뜻인데 시각만 오늘로 남는 것은 앞뒤가 안 맞는다.
///
/// ## 규칙
///
///   시작    붙여넣은 글이면 붙여넣은 시각, 직접 쓴 글이면 만든 시각.
///           **이 값은 손대지 않는다.** 되돌리든 정리하든 그대로다.
///   고침    마지막으로 손댄 시각. 시작과 사실상 같으면 안 보여 준다 —
///           방금 만든 글에 같은 시각을 두 번 적는 것은 소음이다.
library;

/// 화면에 적을 두 시각.
class NoteTimes {
  const NoteTimes({required this.start, required this.pasted, this.edited});

  /// 붙여넣은 시각 또는 만든 시각.
  final int start;

  /// 붙여넣어서 생긴 글인가. 화면의 말이 달라진다.
  final bool pasted;

  /// 마지막으로 손댄 시각. 시작과 같다면 null 이다.
  final int? edited;

  @override
  String toString() => 'NoteTimes(start=$start, pasted=$pasted, edited=$edited)';
}

/// [gapMs] 는 '사실상 같다'고 볼 틈이다.
///
/// 1분을 준 까닭: 붙여넣으면 그 자리에서 정리가 돌고 저장이 한 번 더
/// 일어나 수정 시각이 몇 초 뒤로 찍힌다. 그 몇 초를 '고침'이라고 적으면
/// 모든 새 글에 무의미한 둘째 시각이 붙는다.
NoteTimes noteTimes({
  required int createdAt,
  required int pastedAt,
  required int updatedAt,
  int gapMs = 60 * 1000,
}) {
  final pasted = pastedAt > 0;
  // 붙여넣은 시각이 만든 시각보다 이를 수는 없다. 그런 자료가 오면
  // (남의 기기에서 온 옛 저장본) 이른 쪽을 시작으로 본다.
  var start = pasted ? pastedAt : createdAt;
  if (start <= 0) start = createdAt > 0 ? createdAt : updatedAt;
  final edited = (updatedAt - start).abs() > gapMs ? updatedAt : null;
  return NoteTimes(start: start, pasted: pasted, edited: edited);
}
