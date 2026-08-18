/// 마크다운 표시를 벗겨 **맨 글자**로.
///
/// 2026-08-18 소유자가 정한 이 앱의 컨셉이다.
///
/// > "내 노트에서는 볼드체로 보이되, 이것을 복사해서 다른 곳에 붙여넣을
/// >  땐 #을 제거하는 것이다."
///
/// 그래서 노트에는 마크다운을 그대로 담아 둔다(그래야 굵게 보여 줄 수
/// 있다). 대신 **복사하는 순간** 이 함수를 지나간다. 메모장에도, 워드에도,
/// 카페 게시판에도 기호 없는 글이 붙는다.
///
/// ## 무엇을 안 벗기나
///
/// 표(공백으로 칸을 맞춘 것)와 코드 블록은 건드리지 않는다. 거기 있는
/// '#'과 '*'는 표시가 아니라 **내용**이다. 파이썬 주석의 '#'을 벗기면
/// 코드가 망가진다.
library;

import 'rich_spans.dart' show boldPairs;

final RegExp _fence = RegExp(r'^\s*(```|~~~)');
final RegExp _head = RegExp(r'^(#{1,6})\s+');
final RegExp _quote = RegExp(r'^\s*>\s?');

/// 표시를 벗긴 글.
String toPlain(String md) {
  if (md.isEmpty) return md;
  final out = <String>[];
  var inFence = false;
  for (final raw in md.split('\n')) {
    if (_fence.hasMatch(raw)) {
      inFence = !inFence;
      // 울타리 줄 자체는 버린다 — 맨 글자에서 ``` 는 뜻이 없다.
      continue;
    }
    if (inFence) {
      out.add(raw);
      continue;
    }
    out.add(_line(raw));
  }
  return out.join('\n');
}

String _line(String raw) {
  var t = raw;

  // 할 일 — '- [ ] 가' → '☐ 가'. 한 글자짜리 기호라 어디에 붙여도 깨지지 않고,
  // 켰는지 껐는지가 그대로 남는다.
  final indent = t.length - t.trimLeft().length;
  final body = t.substring(indent);
  if (body.length >= 5 &&
      (body.startsWith('- [') || body.startsWith('* [')) &&
      body[4] == ']') {
    final c = body[3];
    if (c == ' ' || c == 'x' || c == 'X') {
      t = '${t.substring(0, indent)}${c == ' ' ? '☐' : '☑'}'
          '${body.substring(5)}';
    }
  }

  // 제목 — '## 가' → '가'
  t = t.replaceFirst(_head, '');
  // 인용 — '> 가' → '가'
  t = t.replaceFirst(_quote, '');
  // 굵게 — 그리는 쪽과 **같은 함수**로 짝을 찾는다(rich_spans.boldPairs).
  // 둘이 다른 셈을 하면 화면에서 굵게 보이던 것이 복사하면 안 벗겨진다.
  t = _stripBold(t);
  // 기울임 세 겹.
  t = _pairs(t, '***');
  // 취소선
  t = _pairs(t, '~~');
  // 홑따옴표 코드 — `가` → 가
  t = _pairs(t, '`');
  return t;
}

/// 짝이 맞는 '**'만 벗긴다.
String _stripBold(String line) {
  final pairs = boldPairs(line);
  if (pairs.isEmpty) return line;
  final drop = <int>{};
  for (final p in pairs) {
    drop.add(p.$1);
    drop.add(p.$2);
  }
  final sb = StringBuffer();
  var i = 0;
  while (i < line.length) {
    if (drop.contains(i)) {
      i += 2;
      continue;
    }
    sb.write(line[i]);
    i++;
  }
  return sb.toString();
}

/// 짝을 이룬 표시만 벗긴다. 짝이 안 맞으면 그대로 둔다 —
/// '2*3=6'의 별표를 지우면 글이 거짓이 된다.
String _pairs(String line, String mark) {
  if (!line.contains(mark)) return line;
  final n = mark.length;
  final sb = StringBuffer();
  var i = 0;
  while (i < line.length) {
    if (i + n <= line.length && line.substring(i, i + n) == mark) {
      final close = line.indexOf(mark, i + n);
      if (close > i + n) {
        sb.write(line.substring(i + n, close));
        i = close + n;
        continue;
      }
    }
    sb.write(line[i]);
    i++;
  }
  return sb.toString();
}
