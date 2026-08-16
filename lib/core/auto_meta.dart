/// 자동 제목 — 순수 함수. 화면·저장 코드를 넣지 않는다.
///
/// 2026-08-16 소유자 제안: "제목과 태그를 저장될 때 백그라운드에서 알아서
/// 해 주고, 편집될 때마다 최종 문서 기준으로 갱신하는 것이지. 물론 수동으로
/// 만졌다면 그 이후는 자동 수정을 하면 안 되고."
///
/// 그 규칙을 그대로 옮겼다. 핵심은 **손댄 순간 손을 뗀다**는 것이다. 사용자가
/// 정한 제목을 우리가 다시 덮으면, 그건 도움이 아니라 고장이다.
///
/// ## 왜 조용해야 하나
///
/// 조사에서 반복해 확인된 것: 제안 알림은 명시적 이탈 사유다. 그래서 자동
/// 제목·태그는 **알리지 않는다.** 배지도 안 띄우고 "제목을 지어 드렸어요"
/// 같은 말도 안 한다. 그냥 제목이 있는 상태가 되어 있을 뿐이고, 그 덕은
/// 검색과 목록에서 저절로 드러난다.
library;

/// 본문에서 뽑은 제목.
///
/// 마크다운 흔적을 벗겨서 낸다. 붙여넣은 AI 답변의 첫 줄은 `## 요약`이나
/// `**결론**`인 경우가 많은데, 그걸 그대로 제목에 쓰면 목록이 기호밭이 된다.
String autoTitle(String body, {int maxLen = 40}) {
  for (final raw in body.split('\n')) {
    final t = _clean(raw);
    if (t.isEmpty) continue;
    return _cut(t, maxLen);
  }
  return '';
}

/// 한 줄에서 마크다운 표시를 벗긴다.
String _clean(String line) {
  var t = line.trim();
  if (t.isEmpty) return '';

  // 표 구분줄(|---|---|)이나 가로줄은 제목이 될 수 없다
  if (RegExp(r'^[-*_=|:\s]+$').hasMatch(t)) return '';

  // 소제목: # ~ ######
  t = t.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
  // 인용
  t = t.replaceFirst(RegExp(r'^>\s*'), '');
  // 글머리·번호
  t = t.replaceFirst(RegExp(r'^([-*+•·]|\d{1,3}[.)])\s+'), '');
  // 굵게·기울임·코드 표시
  t = t.replaceAll(RegExp(r'\*{1,3}'), '');
  t = t.replaceAll('`', '');
  t = t.replaceAll('~~', '');
  // 링크는 글자만 남긴다: [글자](주소) → 글자
  t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!);
  // 각주 번호
  t = t.replaceAll(RegExp(r'\[\d{1,2}\]'), '');
  // 끝의 콜론은 제목에 어울리지 않는다
  t = t.replaceFirst(RegExp(r'\s*[:：]\s*$'), '');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// 너무 길면 자른다. 되도록 낱말 사이에서 자른다.
///
/// 낱말 한가운데서 자르면 목록이 지저분해 보인다. 다만 한국어·중국어처럼
/// 띄어쓰기가 드문 글에서는 자를 자리가 없을 수 있어서, 그때는 그냥 자른다.
String _cut(String t, int maxLen) {
  if (t.length <= maxLen) return t;
  final head = t.substring(0, maxLen);
  final sp = head.lastIndexOf(' ');
  if (sp >= maxLen ~/ 2) return head.substring(0, sp).trimRight();
  return head.trimRight();
}

/// 자동 제목을 다시 계산해도 되는가.
///
/// [auto]가 false면 사용자가 직접 정한 제목이다 — 절대 건드리지 않는다.
/// 이 한 줄이 이 기능의 전부라고 해도 된다.
bool canRetitle({required bool auto}) => auto;

/// 사용자가 제목 칸을 만졌을 때 자동을 끌 것인가.
///
/// 비우기만 한 경우에는 끄지 않는다. 지웠다는 건 "네가 알아서 해"에 가깝지
/// "이 빈 제목을 지켜라"가 아니다.
bool stopAutoTitle(String typed) => typed.trim().isNotEmpty;
