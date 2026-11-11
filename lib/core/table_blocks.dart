// 본문 속 '가로로 미는 표' 자리 찾기 — 순수 함수(2026-11-11).
//
// 본문은 글상자 하나라 그 안에 표 카드를 끼울 수 없다. 그래서 글은 그대로
// 두고, 이름표 붙은 울타리(```table … ```) 구간을 찾아 그 자리의 글자를
// 안 보이게 접고(mono_controller.dart) 그 위에 표 카드를 얹는다
// (lib/table_card.dart). 이 파일은 '어디서 어디까지가 그 구간인가'와
// '그 안의 표가 무엇인가'만 안다.

import 'tidy_engine.dart';

class ScrollTableBlock {
  /// 여는 울타리 줄의 첫 글자 자리.
  final int start;

  /// 여는 울타리 줄의 끝(줄바꿈 바로 앞). 이 줄의 높이가 카드 높이가 된다.
  final int firstLineEnd;

  /// 닫는 울타리 줄의 끝(줄바꿈 바로 앞, 글 끝이면 글 길이).
  final int end;

  /// 울타리 안의 표. 읽을 수 없으면 null — 그때는 카드를 안 띄우고 글을
  /// 그대로 보여 준다. 망가진 표를 빈 카드로 덮으면 고칠 길이 없어진다.
  final TableGrid? grid;

  const ScrollTableBlock({
    required this.start,
    required this.firstLineEnd,
    required this.end,
    required this.grid,
  });
}

final RegExp _open = RegExp(r'^\s*```\s*' + kScrollTableFence + r'\s*$');
final RegExp _close = RegExp(r'^\s*```\s*$');

/// [text] 안의 가로 스크롤 표 구간들. 닫히지 않은 울타리는 표가 아니다.
List<ScrollTableBlock> findScrollTables(String text) {
  final out = <ScrollTableBlock>[];
  var pos = 0;
  int? openStart;
  int? openEnd;
  var inOtherFence = false;
  while (pos <= text.length) {
    var nl = text.indexOf('\n', pos);
    if (nl < 0) nl = text.length;
    final line = text.substring(pos, nl);
    if (openStart == null) {
      if (!inOtherFence && _open.hasMatch(line)) {
        openStart = pos;
        openEnd = nl;
      } else if (RegExp(r'^\s*```').hasMatch(line)) {
        // 다른 코드 울타리 안의 '```table' 은 글자일 뿐이다.
        inOtherFence = !inOtherFence;
      }
    } else if (_close.hasMatch(line)) {
      final inner = text.substring(
        (openEnd! + 1).clamp(0, text.length),
        pos > openEnd + 1 ? pos - 1 : openEnd + 1,
      );
      out.add(
        ScrollTableBlock(
          start: openStart,
          firstLineEnd: openEnd,
          end: nl,
          grid: parseScrollTable(inner),
        ),
      );
      openStart = null;
      openEnd = null;
    }
    if (nl >= text.length) break;
    pos = nl + 1;
  }
  return out;
}

/// 울타리 안 글 → 표. 머리줄과 몸줄이 하나 이상 있어야 표다.
TableGrid? parseScrollTable(String inner) {
  if (inner.trim().isEmpty) return null;
  try {
    final r = extractTables(inner);
    if (r.tables.isEmpty) return null;
    final t = r.tables.first;
    if (t.header.length < 2 || t.rows.isEmpty) return null;
    return t;
  } catch (_) {
    return null;
  }
}
