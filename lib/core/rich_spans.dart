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
  for (final p in boldPairs(line, from: from)) {
    out.add(RichSpan(base + p.$1, base + p.$1 + 2, RichKind.marker));
    out.add(RichSpan(base + p.$1 + 2, base + p.$2, RichKind.bold));
    out.add(RichSpan(base + p.$2, base + p.$2 + 2, RichKind.marker));
  }
}

/// [i]에서 시작하는 별표가 몇 개 이어지는가.
int _starRun(String l, int i) {
  var n = 0;
  while (i + n < l.length && l[i + n] == '*') {
    n++;
  }
  return n;
}

/// 여는 '**'가 될 수 있는가.
///
/// 뒤가 공백이거나 **닫는 문장부호**면 강조를 여는 것이 아니다.
///
/// 2026-08-18 소유자 신고로 넣은 규칙이다. 시드 메모에 이런 줄이 있었다.
///
///     별표(**), 우물 정(##), … 인사말이 **한 번에** 걷힙니다.
///
/// 앞의 '(**)' 는 별표를 **글감으로 적어 둔 것**이지 강조가 아니다. 그런데
/// 앞에서부터 아무 짝이나 맺으면 그 '**'가 다음 '**'와 짝이 되어, 문장
/// 한가운데가 굵어지고 진짜 짝의 한쪽이 홀로 남는다. 화면에 '한 번에**
/// 걷힙니다'가 그렇게 나왔다.
bool _canOpen(String l, int i) {
  final n = i + 2;
  if (n >= l.length) return false;
  final c = l[n];
  if (c.trim().isEmpty) return false;
  return !')]}>,.!?;:'.contains(c);
}

/// 닫는 '**'가 될 수 있는가. 앞이 공백이면 아니다.
bool _canClose(String l, int i) => i > 0 && l[i - 1].trim().isNotEmpty;

/// 한 줄에서 **짝이 맞는** '**'의 자리들. (여는 자리, 닫는 자리).
///
/// 그리는 쪽(_bold)과 벗기는 쪽(core/plain_text.dart)과 정리 엔진이 **같은
/// 함수**를 쓴다. 셋이 다른 셈을 하면 화면에서 굵게 보이던 것이 복사하면
/// 안 벗겨지거나, 정리가 멀쩡한 강조를 지운다.
///
/// 별표가 셋 이상 이어진 것은 건드리지 않는다 — '***'는 구분선이다.
List<(int, int)> boldPairs(String line, {int from = 0}) {
  final out = <(int, int)>[];
  var i = from;
  while (i < line.length) {
    final a = line.indexOf('**', i);
    if (a < 0) break;
    if (_starRun(line, a) != 2 || !_canOpen(line, a)) {
      i = a + _starRun(line, a);
      continue;
    }
    var b = -1;
    var k = a + 2;
    while (k < line.length) {
      final c = line.indexOf('**', k);
      if (c < 0) break;
      if (_starRun(line, c) == 2 && c > a + 2 && _canClose(line, c)) {
        b = c;
        break;
      }
      k = c + _starRun(line, c);
    }
    if (b < 0) {
      i = a + 2;
      continue;
    }
    out.add((a, b));
    i = b + 2;
  }
  return out;
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
