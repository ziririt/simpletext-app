import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/mono_controller.dart';

// 2026-11-11 사고의 재발 방지. 편집칸이 줄 높이를 못 박으면(forceStrutHeight)
// 카드 자리가 안 생기고 카드가 글 위에 얹힌다. strutStyle 을 풀면 키 큰 줄이
// 정확히 그 키가 되는지 잰다.
RenderEditable? _fe(RenderObject? r) {
  if (r == null) return null;
  if (r is RenderEditable) return r;
  RenderEditable? f;
  r.visitChildren((c) => f ??= _fe(c));
  return f;
}

void main() {
  for (final h in [120.0, 300.0]) {
    testWidgets('카드 자리 줄의 키 = $h', (t) async {
      const text = '앞줄\n```table\n| a | b |\n| - | - |\n```\n뒤';
      final c = MonoTextController(text: text);
      final s = text.indexOf('```table');
      final f = text.indexOf('\n', s);
      c.cardSlots = (_) => [CardSlot(s, f, text.indexOf('뒤'), h)];
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TextField(
                key: key,
                controller: c,
                maxLines: null,
                strutStyle: StrutStyle.disabled,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
        ),
      );
      final ed = _fe(key.currentContext!.findRenderObject())!;
      ed.selectionHeightStyle = ui.BoxHeightStyle.max;
      final b = ed.getBoxesForSelection(
        TextSelection(baseOffset: s, extentOffset: f),
      );
      expect(b.first.bottom - b.first.top, closeTo(h, 0.5));
    });
  }
}
