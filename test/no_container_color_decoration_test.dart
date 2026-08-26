/// Container에 color:와 decoration:을 함께 주면 플러터가 단언으로 막는다.
/// 릴리스 빌드는 단언을 지우고 지나가기 때문에 **스토어판에서는 멀쩡해 보이고**
/// 디버그로 돌린 순간 빨간 화면이 된다 — 2026-08-26 시뮬레이터에서 실제로
/// 그렇게 터졌다(광고 띠). 눈으로는 못 잡으니 소스를 기계가 훑는다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 여는 괄호 다음부터 짝이 맞는 닫는 괄호까지, 따옴표 안은 건너뛰며 읽는다.
int _matchParen(String s, int open) {
  var depth = 1;
  var j = open;
  while (j < s.length && depth > 0) {
    final c = s[j];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
    } else if (c == "'" || c == '"') {
      final q = c;
      j++;
      while (j < s.length) {
        if (s.codeUnitAt(j) == 92) {
          // 역슬래시 — 다음 글자는 이스케이프다
          j += 2;
          continue;
        }
        if (s[j] == q) break;
        j++;
      }
    }
    j++;
  }
  return j - 1;
}

/// 한 겹 깊이의 인자 이름만 골라낸다.
Set<String> _topKeys(String body) {
  final keys = <String>{};
  final buf = StringBuffer();
  var d = 0;
  void flush() {
    final a = buf.toString();
    final i = a.indexOf(':');
    if (i > 0) keys.add(a.substring(0, i).trim());
    buf.clear();
  }

  for (final c in body.split('')) {
    if (c == '(' || c == '[' || c == '{') d++;
    if (c == ')' || c == ']' || c == '}') d--;
    if (c == ',' && d == 0) {
      flush();
    } else {
      buf.write(c);
    }
  }
  flush();
  return keys;
}

void main() {
  test('Container에 color와 decoration을 함께 주는 자리는 없다', () {
    final re = RegExp(r'\b(Container|AnimatedContainer)\s*\(');
    final bad = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final s = f.readAsStringSync();
      for (final m in re.allMatches(s)) {
        final close = _matchParen(s, m.end);
        final keys = _topKeys(s.substring(m.end, close));
        if (keys.contains('color') && keys.contains('decoration')) {
          final line = '\n'.allMatches(s.substring(0, m.start)).length + 1;
          bad.add('${f.path}:$line');
        }
      }
    }
    expect(bad, isEmpty,
        reason: 'Container(color:...) 와 decoration: 은 같이 못 쓴다. '
            '색은 BoxDecoration 안으로 옮겨라: ${bad.join(", ")}');
  });
}
