/// 색표에 연회색이 다시 끼어들지 못하게 막는다.
///
/// 2026-08-20 — 소유자가 **네 번** 같은 말을 했다. "연회색 폰트 사용 금지."
/// 우리 색(AppC)은 세 번째에 #26313A(13.3:1)까지 내렸는데도 화면에는
/// 계속 연회색이 남아 있었다. 우리가 색을 안 적어 준 자리에서 머티리얼이
/// 제 기본값을 꺼내 썼기 때문이다 — fromSeed 가 만드는 onSurfaceVariant
/// (#41484D, 9.3:1)와 outline(#71787E, 4.5:1). ListTile 부제, 드롭다운
/// 글자, 입력칸 이름표가 전부 그 색으로 그려지고 있었다.
///
/// theme_contrast_test.dart 는 우리가 **적은** 색을 지킨다.
/// 이 파일은 우리가 **안 적은** 자리를 지킨다. 둘은 다른 일이다.
///
/// 문턱이 10:1 인 까닭도 저쪽에 적어 둔 것과 같다. 이 글자들은 14~15px
/// 이고, WCAG 의 4.5:1·7:1 은 본문 크기(17pt)를 전제로 한 값이다.
/// 숫자를 겨우 넘기는 것과 읽히는 것은 다르다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/paper.dart' show contrastRatio;
import 'package:simpletext/main.dart' show AppC, SimpleTextApp;

int _v(Color c) => c.toARGB32();

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  final modes = <String, (Brightness, AppC)>{
    '라이트': (Brightness.light, AppC.light),
    '다크': (Brightness.dark, AppC.dark),
  };

  modes.forEach((name, m) {
    test('$name 색표에 연회색이 없다 (10:1)', () {
      final (b, c) = m;
      final s = SimpleTextApp.buildTheme(b, c).colorScheme;
      // 글자가 얹히는 판은 카드다. 바탕(c.bg)보다 카드가 밝으므로
      // 더 빡빡한 쪽으로 잰다.
      final base = c.panel;
      for (final e in <String, Color>{
        'onSurface': s.onSurface,
        'onSurfaceVariant': s.onSurfaceVariant,
        'outline': s.outline,
      }.entries) {
        final r = contrastRatio(_v(e.value), _v(base));
        expect(r, greaterThanOrEqualTo(10.0),
            reason: '$name ${e.key} ${_hex(e.value)} 가 카드 ${_hex(base)} '
                '위에서 ${r.toStringAsFixed(2)}:1 이다. '
                '색표에서 꺼낼 수 있는 연회색은 언젠가 화면에 나온다.');
      }
    });
  });
}
