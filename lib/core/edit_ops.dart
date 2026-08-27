/// 글 칸에서 한 번 누르면 일어나는 일들 — 제목·인용·굵게·코드·링크·들여쓰기.
///
/// 2026-08-27 소유자 지시. 조사해 보니 세계가 합의한 '기본 여섯'(깃허브의
/// markdown-toolbar-element)이 굵게·제목·기울임·인용·코드·링크인데, 우리
/// 도구 막대에는 목록 셋과 체크박스뿐이었다.
///
/// ## 왜 화면과 떼어 놓았나
///
/// core/listify.dart 와 같은 까닭이다. 이 규칙들은 **눈으로 보고는 틀린 줄
/// 모른다.** 고른 글 밖에 붙은 별표를 떼느냐, 여러 줄에 걸친 인용을 한
/// 번에 끄느냐, 빈 줄에도 표시를 붙이느냐 — 어느 하나가 어긋나도 화면에서는
/// 그럴듯해 보인다.
///
/// ## 모두 스위치다
///
/// 같은 단추를 다시 누르면 원래대로 돌아온다. 목록 단추가 이미 그렇고
/// (listify), 여기도 같게 맞춘다. **한 앱 안에서 어떤 단추는 스위치이고
/// 어떤 단추는 도장이면, 사람은 둘 다 못 믿는다.**
library;

/// 고친 글과 그 뒤 커서 자리.
class EditResult {
  final String text;
  final int start;
  final int end;

  const EditResult(this.text, this.start, [int? end]) : end = end ?? start;

  bool get collapsed => start == end;

  @override
  bool operator ==(Object other) =>
      other is EditResult &&
      other.text == text &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(text, start, end);

  @override
  String toString() => 'EditResult(${text.replaceAll('\n', '⏎')}, $start..$end)';
}

/// 고른 자리가 걸친 줄들의 처음과 끝.
({int from, int to}) blockSpan(String text, int start, int end) {
  final a = start.clamp(0, text.length);
  final b = end.clamp(0, text.length);
  final lo = a < b ? a : b;
  final hi = a < b ? b : a;
  final nl = text.lastIndexOf('\n', lo > 0 ? lo - 1 : 0);
  final from = (nl < 0 || lo == 0) ? 0 : nl + 1;
  var to = text.indexOf('\n', hi);
  if (to < 0) to = text.length;
  return (from: from, to: to);
}

/// 줄마다 [f] 를 먹인다. 고른 자리는 고친 덩이 전체로 둔다 — 줄 길이가
/// 바뀌었는데 옛 자리를 그대로 쓰면 커서가 글자 한가운데로 떨어진다.
EditResult _mapLines(
    String text, int start, int end, String Function(String) f) {
  final s = blockSpan(text, start, end);
  final block = text.substring(s.from, s.to);
  final out = block.split('\n').map(f).join('\n');
  return EditResult(text.replaceRange(s.from, s.to, out), s.from, s.from + out.length);
}

final RegExp _head = RegExp(r'^(#{1,6}) ');

/// 제목 — 없음 → # → ## → ### → 없음.
///
/// 네 번째 자리에서 없음으로 돌아오는 까닭. 마크다운은 여섯 단계까지
/// 있지만, 사람이 실제로 쓰는 것은 셋이다. 여섯 번을 눌러야 원래대로
/// 돌아오는 단추는 스위치가 아니라 미로다.
EditResult cycleHeading(String text, int start, int end) {
  final s = blockSpan(text, start, end);
  final first = text.substring(s.from, text.indexOf('\n', s.from) < 0
      ? s.to
      : (text.indexOf('\n', s.from) < s.to ? text.indexOf('\n', s.from) : s.to));
  final m = _head.firstMatch(first.trimLeft());
  final now = m == null ? 0 : m.group(1)!.length;
  final next = now >= 3 ? 0 : now + 1;
  return _mapLines(text, start, end, (line) {
    if (line.trim().isEmpty) return line;
    final indent = line.length - line.trimLeft().length;
    final body = line.substring(indent).replaceFirst(_head, '');
    final head = next == 0 ? '' : '${'#' * next} ';
    return '${line.substring(0, indent)}$head$body';
  });
}

/// 인용 — 다 붙어 있으면 떼고, 아니면 붙인다.
EditResult toggleQuote(String text, int start, int end) {
  final s = blockSpan(text, start, end);
  final lines = text.substring(s.from, s.to).split('\n');
  final filled = lines.where((l) => l.trim().isNotEmpty);
  // 빈 줄만 있으면 붙이는 쪽이다. 아무것도 없는데 '다 붙어 있다'고
  // 판정하면 첫 누름이 아무 일도 안 하는 것처럼 보인다.
  final off = filled.isNotEmpty &&
      filled.every((l) => l.trimLeft().startsWith('> '));
  return _mapLines(text, start, end, (line) {
    if (line.trim().isEmpty) return line;
    final indent = line.length - line.trimLeft().length;
    final body = line.substring(indent);
    if (off) {
      return '${line.substring(0, indent)}${body.substring(2)}';
    }
    return '${line.substring(0, indent)}> $body';
  });
}

/// 별표·백틱처럼 앞뒤를 감싸는 표시. 이미 감싸져 있으면 벗긴다.
///
/// 밖과 안을 둘 다 본다. 사람이 '**굵게**'를 통째로 고르고 누를 수도,
/// 별표 안쪽의 '굵게'만 고르고 누를 수도 있다. 둘 다 벗기는 뜻이다.
EditResult toggleWrap(String text, int start, int end, String mark) {
  final a = start < end ? start : end;
  final b = start < end ? end : start;
  final n = mark.length;

  if (a == b) {
    // 고른 것이 없으면 표시만 놓고 그 사이에 커서를 둔다.
    final ins = '$mark$mark';
    return EditResult(text.replaceRange(a, a, ins), a + n);
  }

  final inner = text.substring(a, b);

  // 밖에 이미 있다.
  if (a >= n &&
      b + n <= text.length &&
      text.substring(a - n, a) == mark &&
      text.substring(b, b + n) == mark) {
    final out = text.replaceRange(b, b + n, '').replaceRange(a - n, a, '');
    return EditResult(out, a - n, b - n);
  }

  // 안에 이미 있다.
  if (inner.length >= n * 2 &&
      inner.startsWith(mark) &&
      inner.endsWith(mark)) {
    final bare = inner.substring(n, inner.length - n);
    return EditResult(text.replaceRange(a, b, bare), a, a + bare.length);
  }

  final wrapped = '$mark$inner$mark';
  return EditResult(text.replaceRange(a, b, wrapped), a + n, a + n + inner.length);
}

/// 코드 — 한 줄이면 백틱, 줄이 넘어가면 울타리.
///
/// 갈래를 나누는 까닭. AI 답변에는 두 가지가 다 온다. 문장 안의
/// `flutter build` 같은 낱말과, 여러 줄짜리 코드 덩이. 같은 단추가
/// 상황을 보고 맞는 쪽을 골라 주지 않으면 사람이 둘을 외워야 한다.
EditResult toggleCode(String text, int start, int end) {
  final a = start < end ? start : end;
  final b = start < end ? end : start;
  final inner = text.substring(a, b);
  if (!inner.contains('\n')) return toggleWrap(text, a, b, '`');

  final s = blockSpan(text, a, b);
  final block = text.substring(s.from, s.to);
  final lines = block.split('\n');
  final fenced = lines.length >= 2 &&
      lines.first.trimRight().startsWith('```') &&
      lines.last.trimRight() == '```';
  if (fenced) {
    final bare = lines.sublist(1, lines.length - 1).join('\n');
    return EditResult(
        text.replaceRange(s.from, s.to, bare), s.from, s.from + bare.length);
  }
  final out = '```\n$block\n```';
  return EditResult(
      text.replaceRange(s.from, s.to, out), s.from, s.from + out.length);
}

/// 링크 — 고른 글이 있으면 그것이 이름이 되고 커서는 주소 자리로 간다.
/// 고른 것이 없으면 이름 자리로 간다. **다음에 칠 글자가 갈 곳**에 커서를
/// 두는 것이 규칙이다.
EditResult makeLink(String text, int start, int end) {
  final a = start < end ? start : end;
  final b = start < end ? end : start;
  final inner = text.substring(a, b);
  final ins = '[$inner]()';
  final out = text.replaceRange(a, b, ins);
  // 이름이 있으면 주소 자리(괄호 안), 없으면 이름 자리(대괄호 안).
  final caret = inner.isEmpty ? a + 1 : a + ins.length - 1;
  return EditResult(out, caret);
}

/// 들여쓰기 — 줄머리에 빈칸을 넣는다.
///
/// 커서 자리에 빈칸을 꽂던 옛 방식과 다르다. 그건 줄 한가운데를 누르면
/// 글자 사이에 빈칸이 끼는 짓이었다. 들여쓰기는 **줄에 하는 일**이다.
EditResult indentLines(String text, int start, int end, {int by = 2}) =>
    _mapLines(text, start, end, (line) => line.isEmpty ? line : '${' ' * by}$line');

/// 내어쓰기 — 줄머리의 빈칸을 [by] 칸까지 걷는다. 탭 하나도 한 칸으로 친다.
///
/// 들여쓰기만 있고 이것이 없었다. 한 번 들여쓰면 되돌릴 길이 없는
/// 도구 막대였다. 애플도 오브시디언도 이 둘은 반드시 짝으로 둔다.
EditResult outdentLines(String text, int start, int end, {int by = 2}) =>
    _mapLines(text, start, end, (line) {
      if (line.startsWith('\t')) return line.substring(1);
      var n = 0;
      while (n < by && n < line.length && line[n] == ' ') {
        n++;
      }
      return line.substring(n);
    });

/// 찾은 자리들. 정규식이 틀렸으면 빈 목록 — 화면이 죽는 것보다 낫다.
List<({int start, int end})> findAll(String text, String find,
    {bool regex = false}) {
  if (find.isEmpty) return const [];
  final out = <({int start, int end})>[];
  if (regex) {
    try {
      for (final m in RegExp(find).allMatches(text)) {
        // 길이 0 짜리를 담으면 '다음'이 제자리에서 맴돈다.
        if (m.end > m.start) out.add((start: m.start, end: m.end));
      }
    } catch (_) {
      return const [];
    }
    return out;
  }
  var i = text.indexOf(find);
  while (i >= 0) {
    out.add((start: i, end: i + find.length));
    i = text.indexOf(find, i + find.length);
  }
  return out;
}

/// [from] 자리 뒤의 첫 자리. 뒤에 없으면 **처음으로 돌아간다.**
///
/// 맴도는 까닭 — 글 끝에서 '다음'을 눌렀는데 아무 일도 안 일어나면
/// 사람은 찾기가 고장 났다고 읽는다. 처음으로 돌아가는 편이 '더 없다'를
/// 훨씬 분명하게 말한다.
({int start, int end})? findNextAfter(String text, String find, int from,
    {bool regex = false}) {
  final all = findAll(text, find, regex: regex);
  if (all.isEmpty) return null;
  for (final m in all) {
    if (m.start >= from) return m;
  }
  return all.first;
}
