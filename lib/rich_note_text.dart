/// 노트 글을 **읽기용으로** 그린다 — 표시(#, **)는 감추고 뜻만 남긴다.
///
/// 2026-08-29. 전·후 와이프와 시간 여행이 같은 그림을 필요로 했다.
/// 두 화면이 각자 그리면 어느 날 한쪽만 고쳐진다 — 이 저장소가 여러 번
/// 겪은 그 자리다. 그래서 그리는 일은 여기 하나만 안다.
///
/// 편집기와는 일부러 다르게 군다. 편집기는 커서가 놓인 줄에서만 표시를
/// 옅게 보여 준다(고칠 수 있어야 하니까). 여기는 읽기만 하는 자리라
/// 표시를 아예 안 보여 주는 편이 정직하다.
library;

import 'package:flutter/material.dart';

import 'core/rich_spans.dart';

class RichNoteText extends StatelessWidget {
  const RichNoteText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.ink,
    required this.mark,
    this.fontFamily,
  });

  final String text;
  final double fontSize;
  final double lineHeight;
  final Color ink;
  final Color mark;
  final String? fontFamily;

  TextStyle get _base => TextStyle(
        fontSize: fontSize,
        height: lineHeight,
        letterSpacing: 0,
        fontFamily: fontFamily,
      );

  TextStyle _styleOf(RichKind k) {
    switch (k) {
      case RichKind.marker:
        // 자리를 아예 안 차지하게 한다. 색만 지우면 빈칸이 남는다.
        return _base.copyWith(
            fontSize: 0.01, color: const Color(0x00000000), height: 0.01);
      case RichKind.h1:
        return _base.copyWith(
            fontSize: fontSize * 1.30,
            height: lineHeight / 1.30,
            fontWeight: FontWeight.w800,
            color: ink);
      case RichKind.h2:
        return _base.copyWith(
            fontSize: fontSize * 1.18,
            height: lineHeight / 1.18,
            fontWeight: FontWeight.w700,
            color: ink);
      case RichKind.h3:
        return _base.copyWith(
            fontSize: fontSize * 1.08,
            height: lineHeight / 1.08,
            fontWeight: FontWeight.w700,
            color: ink);
      case RichKind.bold:
        return _base.copyWith(fontWeight: FontWeight.w700, color: ink);
      case RichKind.quote:
        return _base.copyWith(color: mark, fontStyle: FontStyle.italic);
      case RichKind.box:
        return _base.copyWith(color: mark);
      case RichKind.done:
        return _base.copyWith(
            color: mark, decoration: TextDecoration.lineThrough);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spans = richSpans(text);
    final out = <TextSpan>[];
    var at = 0;
    for (final s in spans) {
      if (s.start > at) {
        out.add(TextSpan(
            text: text.substring(at, s.start), style: _base.copyWith(color: ink)));
      }
      out.add(TextSpan(
          text: text.substring(s.start, s.end), style: _styleOf(s.kind)));
      at = s.end;
    }
    if (at < text.length) {
      out.add(TextSpan(text: text.substring(at), style: _base.copyWith(color: ink)));
    }
    return Text.rich(TextSpan(children: out));
  }
}
