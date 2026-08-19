/// 인쇄·PDF에 쓸 '덩어리' 나누기 — 그리는 코드는 한 줄도 넣지 않는다.
///
/// 2026-08-19. 화면에서는 rich_spans.dart 가 "몇 번째 글자부터 몇 번째까지가
/// 무엇인가"만 세고 색과 크기는 컨트롤러가 정한다. 종이도 같은 규칙을 쓴다.
/// 여기서는 **글이 어떤 덩어리로 이루어져 있는가**만 셈하고, 그 덩어리를
/// 종이 위 어디에 얼마만 한 크기로 놓을지는 pdf_service.dart 가 정한다.
///
/// 나누어 두는 값이 있다. 표를 몇 칸으로 그릴지, 목록의 들여쓰기가 몇 단인지
/// 같은 판정은 눈으로 확인하기 어렵다. 순수 함수로 떼어 두면 시험이 대신
/// 봐 준다(test/core/print_blocks_test.dart).
///
/// 화면과 다른 점이 하나 있다. 편집기는 '## '을 **지우지 않고 옅게** 만든다
/// — 글자 수가 어긋나면 커서가 튀기 때문이다. 종이에는 커서가 없다. 그래서
/// 여기서는 표시를 **걷어내고** 뜻만 남긴다. 이것이 이 앱이 처음부터 말해 온
/// "마크다운은 글에 남고, 뜻으로 그려지고, 나갈 때 벗겨진다"의 마지막 칸이다.
library;

/// 덩어리의 갈래.
enum PKind {
  h1,
  h2,
  h3,

  /// 보통 글줄. 사용자가 끊은 줄바꿈을 그대로 지킨다.
  para,

  /// 글머리표 목록.
  bullet,

  /// 번호 목록.
  numbered,

  /// 할 일. [PBlock.checked] 로 끝났는지 구분한다.
  task,

  /// 인용.
  quote,

  /// 코드 울타리 안. 손대지 않은 날것 그대로 [PBlock.text] 에 담는다.
  code,

  /// 표. [PBlock.rows] 에 칸이 들어 있다.
  table,

  /// 가로선.
  hr,

  /// 빈 줄. 문단 사이를 얼마나 띄울지 정하는 데 쓴다.
  blank,
}

/// 한 줄 안에서 굵게·기울임·코드로 갈리는 토막.
class PSpan {
  const PSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.strike = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final bool strike;

  @override
  bool operator ==(Object other) =>
      other is PSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code &&
      other.strike == strike;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, strike);

  @override
  String toString() {
    final f = [
      if (bold) 'b',
      if (italic) 'i',
      if (code) 'c',
      if (strike) 's',
    ].join();
    return f.isEmpty ? '"$text"' : '"$text"[$f]';
  }
}

class PBlock {
  const PBlock(
    this.kind, {
    this.spans = const [],
    this.text = '',
    this.indent = 0,
    this.checked = false,
    this.marker = '',
    this.rows = const [],
  });

  final PKind kind;

  /// 글이 있는 덩어리의 속살. code·table·hr·blank 는 비어 있다.
  final List<PSpan> spans;

  /// 코드 울타리 안의 날것.
  final String text;

  /// 목록의 들여쓰기 단. 0~3.
  final int indent;

  /// 할 일이 끝났는가.
  final bool checked;

  /// 번호 목록에서 사람이 적은 번호('1.', '2)').
  final String marker;

  /// 표의 칸. 첫 줄이 머리줄이다.
  final List<List<String>> rows;

  /// 이 덩어리의 글을 표시 없이 이어 붙인 것. 시험과 목차에 쓴다.
  String get plain => spans.map((s) => s.text).join();

  @override
  String toString() =>
      'PBlock(${kind.name}, indent:$indent, ${kind == PKind.code ? text : (kind == PKind.table ? rows : spans)})';
}

final RegExp _fence = RegExp(r'^\s{0,3}(```|~~~)');
final RegExp _headRe = RegExp(r'^\s{0,3}(#{1,6})\s+(.*)$');
final RegExp _hrRe = RegExp(r'^\s{0,3}([-*_])[ \t]*(?:\1[ \t]*){2,}$');
final RegExp _quoteRe = RegExp(r'^(\s*)>\s?(.*)$');
final RegExp _taskRe = RegExp(r'^(\s*)[-*+]\s+\[([ xX])\]\s*(.*)$');
final RegExp _bulletRe = RegExp(r'^(\s*)[-*+•·◦]\s+(.*)$');
final RegExp _numRe = RegExp(r'^(\s*)(\d{1,3}[.)])\s+(.*)$');
final RegExp _delimRe = RegExp(r'^\s*\|?[\s:|-]*-[\s:|-]*\|[\s:|-]*$');

/// 글 한 편을 덩어리로 나눈다.
List<PBlock> printBlocks(String body) {
  final lines = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final out = <PBlock>[];
  var i = 0;

  while (i < lines.length) {
    final raw = lines[i];
    final t = raw.trimRight();

    // --- 코드 울타리 -------------------------------------------------
    // 울타리 안에서는 아무 규칙도 보지 않는다. 코드 안의 '# '을 제목으로
    // 읽어 버리는 것이 이런 파서가 저지르는 가장 흔한 잘못이다.
    final f = _fence.firstMatch(t);
    if (f != null) {
      final mark = f.group(1)!;
      final buf = <String>[];
      i++;
      while (i < lines.length && !lines[i].trimRight().startsWith(mark)) {
        buf.add(lines[i]);
        i++;
      }
      if (i < lines.length) i++; // 닫는 줄
      out.add(PBlock(PKind.code, text: buf.join('\n')));
      continue;
    }

    // --- 표 -----------------------------------------------------------
    // 머리줄 다음에 구분줄(|---|)이 와야 표로 본다. 그냥 세로줄이 든 글을
    // 표로 착각하지 않기 위한 값이다.
    if (_isRow(t) && i + 1 < lines.length && _delimRe.hasMatch(lines[i + 1])) {
      final rows = <List<String>>[_cells(t)];
      i += 2;
      while (i < lines.length && _isRow(lines[i].trimRight())) {
        rows.add(_cells(lines[i].trimRight()));
        i++;
      }
      final w = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      for (final r in rows) {
        while (r.length < w) {
          r.add('');
        }
      }
      out.add(PBlock(PKind.table, rows: rows));
      continue;
    }

    i++;

    if (t.trim().isEmpty) {
      out.add(const PBlock(PKind.blank));
      continue;
    }

    if (_hrRe.hasMatch(t)) {
      out.add(const PBlock(PKind.hr));
      continue;
    }

    final h = _headRe.firstMatch(t);
    if (h != null) {
      final n = h.group(1)!.length;
      // 넷 이상은 셋과 같이 그린다. 화면과 같은 규칙이다(rich_spans.dart).
      out.add(PBlock(
        n == 1 ? PKind.h1 : (n == 2 ? PKind.h2 : PKind.h3),
        spans: inlineSpans(h.group(2)!.trim()),
      ));
      continue;
    }

    final q = _quoteRe.firstMatch(t);
    if (q != null) {
      out.add(PBlock(PKind.quote,
          spans: inlineSpans(q.group(2)!), indent: _step(q.group(1)!)));
      continue;
    }

    final k = _taskRe.firstMatch(t);
    if (k != null) {
      final c = k.group(2)!;
      out.add(PBlock(PKind.task,
          spans: inlineSpans(k.group(3)!),
          indent: _step(k.group(1)!),
          checked: c != ' '));
      continue;
    }

    final b = _bulletRe.firstMatch(t);
    if (b != null) {
      out.add(PBlock(PKind.bullet,
          spans: inlineSpans(b.group(2)!), indent: _step(b.group(1)!)));
      continue;
    }

    final nm = _numRe.firstMatch(t);
    if (nm != null) {
      out.add(PBlock(PKind.numbered,
          spans: inlineSpans(nm.group(3)!),
          indent: _step(nm.group(1)!),
          marker: nm.group(2)!));
      continue;
    }

    out.add(PBlock(PKind.para, spans: inlineSpans(t.trimLeft())));
  }

  while (out.isNotEmpty && out.last.kind == PKind.blank) {
    out.removeLast();
  }
  while (out.isNotEmpty && out.first.kind == PKind.blank) {
    out.removeAt(0);
  }
  return out;
}

/// 들여쓰기 칸 수를 단으로. 두 칸이 한 단, 최대 셋.
int _step(String lead) {
  final n = lead.replaceAll('\t', '  ').length ~/ 2;
  return n > 3 ? 3 : n;
}

bool _isRow(String s) {
  final t = s.trim();
  return t.startsWith('|') && t.length > 1;
}

List<String> _cells(String s) {
  var t = s.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|')) t = t.substring(0, t.length - 1);
  return t.split('|').map((c) => c.trim()).toList();
}

final RegExp _linkRe = RegExp(r'\[([^\]\n]*)\]\((\S+?)\)');
final RegExp _wordish = RegExp(r'[A-Za-z0-9]');

/// 한 줄을 굵게·기울임·코드 토막으로 쪼갠다.
List<PSpan> inlineSpans(String line) {
  final s = _links(line);
  final out = <PSpan>[];
  final buf = StringBuffer();
  var bold = false;
  var ital = false;
  var strike = false;
  var i = 0;

  void flush() {
    if (buf.isEmpty) return;
    out.add(PSpan(buf.toString(),
        bold: bold, italic: ital, strike: strike));
    buf.clear();
  }

  // 짝이 없는 표시는 표시가 아니다. 여는 쪽에서만 짝을 찾아 본다 —
  // 이걸 안 보면 'a * b' 한 줄 때문에 그 뒤가 통째로 기울어진다.
  bool pairs(String mark, int from) => s.indexOf(mark, from + mark.length) >= 0;

  while (i < s.length) {
    if (s[i] == '`') {
      final e = s.indexOf('`', i + 1);
      if (e > i + 1) {
        flush();
        out.add(PSpan(s.substring(i + 1, e), code: true));
        i = e + 1;
        continue;
      }
    }
    if (s.startsWith('**', i) || s.startsWith('__', i)) {
      final mark = s.substring(i, i + 2);
      if (bold || pairs(mark, i)) {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
    }
    if (s.startsWith('~~', i)) {
      if (strike || pairs('~~', i)) {
        flush();
        strike = !strike;
        i += 2;
        continue;
      }
    }
    final ch = s[i];
    if (ch == '*' || ch == '_') {
      // snake_case 와 a*b 를 표시로 읽지 않는다.
      final prev = i > 0 ? s[i - 1] : ' ';
      final next = i + 1 < s.length ? s[i + 1] : ' ';
      final inWord = _wordish.hasMatch(prev) && _wordish.hasMatch(next);
      if (!inWord && (ital || pairs(ch, i))) {
        flush();
        ital = !ital;
        i += 1;
        continue;
      }
    }
    buf.write(ch);
    i++;
  }
  flush();
  return out;
}

/// [글](주소) 를 사람이 읽는 모양으로. 종이에서는 눌러도 안 열리니 주소를
/// 버리면 안 된다 — 글과 주소가 같으면 하나만 남긴다.
String _links(String s) => s.replaceAllMapped(_linkRe, (m) {
      final t = m.group(1)!.trim();
      final u = m.group(2)!;
      if (t.isEmpty || t == u) return u;
      return '$t ($u)';
    });
