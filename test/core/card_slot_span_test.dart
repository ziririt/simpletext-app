import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/mono_controller.dart';

// 2026-11-11: 표 카드 자리 — 첫 줄은 카드 높이만큼, 나머지는 접힌다.
void main() {
  testWidgets('카드 자리의 글자는 안 보이고 첫 줄이 높이를 갖는다', (t) async {
    const text = '앞\n```table\n| a | b |\n| - | - |\n```\n뒤';
    final c = MonoTextController(text: text);
    final start = text.indexOf('```table');
    final first = text.indexOf('\n', start);
    final end = text.indexOf('뒤');
    c.cardSlots = (_) => [CardSlot(start, first, end, 160)];
    late TextSpan span;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            span = c.buildTextSpan(
              context: ctx,
              style: const TextStyle(fontSize: 16),
              withComposing: false,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    final kids = span.children!.cast<TextSpan>();
    // 글자는 하나도 안 빠진다.
    expect(kids.map((k) => k.text).join(), text);
    final head = kids.firstWhere((k) => k.text!.contains('```table'));
    expect(head.style!.color!.a, 0);
    expect(head.style!.fontSize! * head.style!.height!, closeTo(160, 0.01));
    final tail = kids.firstWhere((k) => k.text!.contains('| a |'));
    expect(tail.style!.fontSize, 0.01);
    final after = kids.firstWhere((k) => k.text!.contains('뒤'));
    expect(after.style?.color?.a ?? 1, isNot(0));
  });
}
