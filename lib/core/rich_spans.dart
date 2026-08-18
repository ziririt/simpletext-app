/// 편집기에서 마크다운을 **눈에 보이게** — 어디를 어떻게 그릴지만 셈한다.
///
/// 2026-08-18 소유자 지시. 지인들이 베어와 견주며 "디자인이 후지다"고 한
/// 것의 절반은 이것이었을 가능성이 크다. 색이나 여백의 문제가 아니라
/// **글이 구조 없이 보이는** 문제다. AI 답변은 대부분 마크다운으로 오는데,
/// 정리한 결과가 여전히 평평한 글자 덩어리로 보이면 정리한 보람이 없다.
///
/// ## 표시를 지우지 않는 이유
///
/// '## '을 감추고 큰 글씨만 남기면 더 예쁘다. 그런데 이건 **편집기**다.
/// 글자를 지워 그리면 커서 자리와 글자 수가 어긋나서, 화살표 한 번에
/// 커서가 엉뚱한 데로 뛴다. 그래서 표시는 그 자리에 두고 **옅게** 만든다.
/// 베어도 같은 길을 간다.
///
/// ## 화면을 모른다
///
/// mono_spans.dart 와 같은 규칙이다. 여기서는 "몇 번째 글자부터 몇 번째
/// 글자까지가 무엇인가"만 센다. 색과 크기는 컨트롤러가 정한다. 그래야
/// 시험으로 지킬 수 있다.
library;

enum RichKind {
  /// 표시 자체 — '#', '**', '- '. 옅게.
  marker,

  /// 제목. 크고 굵게.
  h1,
  h2,
  h3,

  /// **굵게** 안쪽.
  bold,

  /// '> ' 인용 줄.
  quote,

  /// 할 일의 네모 — '[ ]' 또는 '[x]'.
  box,

  /// 끝낸 할 일의 글. 줄 긋고 옅게.
  done,
}

class RichSpan {
  const RichSpan(this.start, this.end, this.kind);

  final int start;
  final int end;
  final RichKind kind;

  @override
  bool operator ==(Object other) =>
      other is RichSpan &&
      other.start == start &&
      other.end == end &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'RichSpan($start, $end, ${kind.name})';
}

final RegExp _head = RegExp(r'^(#{1,3})\s');

/// [text]에서 꾸며 그릴 자리를 앞에서부터 돌려준다.
List<RichSpan> richSpans(String text) {
  if (text.isEmpty) return const [];
  final out = <RichSpan>[];
  var base = 0;
  for (final line in text.split('\n')) {
    _one(line, base, out);
    base += line.length + 1;
  }
  return out;
}

void _one(String line, int base, List<RichSpan> out) {
  if (line.isEmpty) return;

  // --- 제목 -------------------------------------------------
  final h = _head.firstMatch(line);
  if (h != null) {
    final n = h.group(1)!.length;
    out.add(RichSpan(base, base + h.end, RichKind.marker));
    if (h.end < line.length) {
      out.add(RichSpan(base + h.end, base + line.length,
          n == 1 ? RichKind.h1 : (n == 2 ? RichKind.h2 : RichKind.h3)));
    }
    _bold(line, base, out, from: h.end);
    return;
  }

  // --- 인용 -------------------------------------------------
  if (line.startsWith('> ')) {
    out.add(RichSpan(base, base + 2, RichKind.marker));
    out.add(RichSpan(base + 2, base + line.length, RichKind.quote));
    return;
  }

  // --- 할 일 ------------------------------------------------
  final indent = line.length - line.trimLeft().length;
  final rest = line.substring(indent);
  if (rest.length >= 5 &&
      (rest.startsWith('- [') || rest.startsWith('* [')) &&
      rest[4] == ']') {
    final c = rest[3];
    if (c == ' ' || c == 'x' || c == 'X') {
      final at = base + indent;
      out.add(RichSpan(at, at + 2, RichKind.marker));
      out.add(RichSpan(at + 2, at + 5, RichKind.box));
      if (c != ' ' && at + 5 < base + line.length) {
        out.add(RichSpan(at + 5, base + line.length, RichKind.done));
      }
      _bold(line, base, out, from: indent + 5);
      return;
    }
  }

  _bold(line, base, out);
}

/// **굵게** 를 찾는다. 표시 두 쌍은 옅게, 사이는 굵게.
void _bold(String line, int base, List<RichSpan> out, {int from = 0}) {
  var i = from;
  while (true) {
    final a = line.indexOf('**', i);
    if (a < 0) return;
    final b = line.indexOf('**', a + 2);
    if (b < 0) return;
    // 빈 '****'는 굵게가 아니다.
    if (b > a + 2) {
      out.add(RichSpan(base + a, base + a + 2, RichKind.marker));
      out.add(RichSpan(base + a + 2, base + b, RichKind.bold));
      out.add(RichSpan(base + b, base + b + 2, RichKind.marker));
    }
    i = b + 2;
  }
}

/// 이 줄이 할 일 줄이면 네모의 자리를 준다. 아니면 null.
///
/// 화면에서 '네모를 눌러 켜고 끄기'에 쓴다. 규칙을 여기 두는 이유는
/// 위와 같다 — 그리는 쪽과 누르는 쪽이 다른 규칙을 쓰면 **보이는 것과
/// 눌리는 것이 어긋난다.**
({int markStart, int boxAt, bool done})? todoAt(String text, int lineStart) {
  var end = text.indexOf('\n', lineStart);
  if (end < 0) end = text.length;
  final line = text.substring(lineStart, end);
  final indent = line.length - line.trimLeft().length;
  final rest = line.substring(indent);
  if (rest.length < 5) return null;
  if (!(rest.startsWith('- [') || rest.startsWith('* ['))) return null;
  if (rest[4] != ']') return null;
  final c = rest[3];
  if (c != ' ' && c != 'x' && c != 'X') return null;
  return (
    markStart: lineStart + indent,
    boxAt: lineStart + indent + 3,
    done: c != ' ',
  );
}
