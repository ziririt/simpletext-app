/// 전체 규칙 + 노트 전용 규칙 합치기 셈 시험 (2026-08-24).
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tidy_engine.dart';

void main() {
  const g = [CustomRule(find: 'a', replace: '1')];
  const n = [CustomRule(find: 'b', replace: '2')];

  test('전체가 먼저, 노트가 나중 — 노트의 손질이 마지막이다', () {
    final m = mergeRules(g, n);
    expect(m.map((r) => r.find).toList(), ['a', 'b']);
  });

  test('노트 규칙이 없으면 전체 그대로', () {
    expect(mergeRules(g, const []).map((r) => r.find).toList(), ['a']);
  });

  test('빈 찾기는 쓰다 만 규칙 — 거른다', () {
    final m = mergeRules(
        [const CustomRule(find: '')], [const CustomRule(find: 'b')]);
    expect(m.map((r) => r.find).toList(), ['b']);
  });
}
