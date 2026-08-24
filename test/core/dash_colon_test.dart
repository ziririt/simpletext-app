/// " — " → " : " 기본 규칙 시험 (2026-08-24 소유자 지시).
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tidy_engine.dart';

void main() {
  test('사이 줄표는 쌍점이 된다 — 기본값으로', () {
    final r = tidy('결론 — 오른다', TidyOptions());
    expect(r.text, '결론 : 오른다');
  });

  test('짧은 줄표(엔 대시)도 사이에 오면 같다', () {
    final r = tidy('결론 \u2013 오른다', TidyOptions());
    expect(r.text, '결론 : 오른다');
  });

  test('붙여 쓴 줄표는 범위다 — 건드리지 않는다', () {
    final r = tidy('1995\u20142000', TidyOptions());
    expect(r.text, '1995\u20142000');
  });

  test('끄면 그대로', () {
    final r = tidy('결론 — 오른다', TidyOptions(dashToColon: false));
    expect(r.text, '결론 — 오른다');
  });
}
