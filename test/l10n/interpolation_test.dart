/// 문구 안의 값 자리가 살아 있는지 지킨다.
///
/// 2026-08-17 — 소유자 스크린샷에서 날짜 줄에 "$src에서 $date에 가져옴"이
/// 그대로 찍히는 것이 발견됐다. 찾아보니 아홉 언어에 걸쳐 **117곳**이었다.
///
/// 다트에서 '\$n'은 값을 끼워 넣지 말고 글자 그대로 $n을 찍으라는 뜻이다.
/// 이 앱의 문구는 파이썬 패치 스크립트로 넣는데, 파이썬 문자열 안에서 $를
/// 습관적으로 \$로 적으면 그게 그대로 다트에 박힌다. 파이썬에서는 아무 뜻도
/// 없는 백슬래시가 다트에서는 뜻이 있다.
///
/// 눈으로는 117곳을 못 찾는다. 이 테스트는 한 번에 찾는다.
///
/// 진짜 달러 표시(US\$29.99)는 escape가 맞다. 그래서 **뒤에 글자가 오는
/// 경우만** 잡는다. 숫자가 오면 값이 아니라 돈이다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('문구 파일에 죽은 값 자리가 없다 (2026-08-17)', () {
    final dir = Directory('lib/l10n');
    expect(dir.existsSync(), isTrue,
        reason: 'lib/l10n 을 못 찾았다 — 테스트를 프로젝트 뿌리에서 돌려야 한다');

    // \$ 다음에 글자나 밑줄이 오면 죽은 값 자리다.
    final dead = RegExp(r'\\\$([A-Za-z_])');
    final found = <String>[];

    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (dead.hasMatch(lines[i])) {
          found.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(found, isEmpty,
        reason: '값이 안 들어가고 글자 그대로 찍힌다. \\\$를 \$로 고칠 것:\n'
            '${found.take(20).join('\n')}'
            '${found.length > 20 ? '\n… 그리고 ${found.length - 20}곳 더' : ''}');
  });

  test('진짜 달러 표시는 그대로 둔다 (2026-08-17)', () {
    // 위 테스트가 너무 세게 잡아서 가격까지 고치는 일이 없도록 못 박는다.
    // US$29.99 같은 값은 escape가 **맞다**.
    final ko = File('lib/l10n/l10n_en.dart').readAsStringSync();
    expect(ko.contains(r'US\$'), isTrue,
        reason: '가격의 달러 표시가 사라졌다 — escape를 지나치게 걷어냈다');
  });
}
