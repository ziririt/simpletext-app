/// 편집기에서 표·코드 구간만 등폭 글꼴로 그리는 컨트롤러.
///
/// TextField는 원래 글꼴이 하나뿐이지만, 컨트롤러가 buildTextSpan을 직접 만들면
/// 구간마다 다른 글꼴을 줄 수 있다. 편집 기능(커서·선택·되돌리기)은 그대로다.
///
/// 조심할 것 — 한글 입력(IME):
///   글자를 조합하는 동안 Flutter는 '조합 중' 구간에 밑줄을 그어 준다. 기본
///   buildTextSpan이 하는 일인데, 그냥 덮어써 버리면 그 밑줄이 사라진다.
///   그래서 여기서는 등폭 구간과 조합 구간을 같이 잘라서 둘 다 살린다.
library;

import 'package:flutter/material.dart';

import 'mono_spans.dart';

class MonoTextController extends TextEditingController {
  MonoTextController({super.text});

  /// 설정의 "표를 등폭 글꼴로"가 켜져 있는지. 화면 build에서 넣어 준다.
  bool monoEnabled = true;

  /// 등폭 구간에 쓸 글꼴. 한글이 영문의 정확히 2배라 공백 정렬이 성립한다.
  static const String fontFamily = 'D2Coding';

  /// 본문(줄글) 크기 — 기기 기본 글꼴을 그대로 쓴다.
  ///
  /// 2026-08-14: 처음엔 16, 다음엔 17로 고정값을 바꿔 가며 맞추려 했는데,
  /// 한 번 고칠 때마다 빌드→설치→확인 왕복이 생겨 소유자가 쓰는 다른 앱과
  /// 맞추기가 어려웠다. 그래서 고정값을 버리고 설정에서 직접 고르게 한다.
  /// (CotEditor·Xcode 같은 편집기도 글자 크기를 사용자가 정한다)
  static const double defaultBodyFontSize = 17;
  static const double minBodyFontSize = 13;
  static const double maxBodyFontSize = 24;
  static const double bodyHeight = 1.6;

  /// 화면 build에서 설정값을 넣어 준다.
  double bodyFontSize = defaultBodyFontSize;

  /// 등폭 구간 크기. 표가 가로로 덜 넘치도록 본문보다 조금 작게 쓴다.
  /// 본문 크기를 바꾸면 같은 비율로 따라간다(17일 때 14.5).
  static const double _monoRatio = 14.5 / defaultBodyFontSize;
  double get monoFontSize => bodyFontSize * _monoRatio;

  /// 크기가 달라도 **줄 높이는 본문과 같아야** 표 근처에서 줄 간격이 튀지 않는다.
  double get monoHeight => bodyFontSize * bodyHeight / monoFontSize;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = monoEnabled ? monoSpans(text) : const <MonoSpan>[];
    final composing =
        (withComposing && value.isComposingRangeValid) ? value.composing : null;
    if (spans.isEmpty && composing == null) {
      return TextSpan(text: text, style: style);
    }

    final base = style ?? const TextStyle();
    final monoStyle = base.copyWith(
      fontFamily: fontFamily,
      fontSize: monoFontSize,
      height: monoHeight,
    );

    // 구간 경계를 전부 모아 놓고 잘라 나가면, 등폭 구간과 조합 구간이 겹쳐도
    // 어긋나지 않는다.
    final cuts = <int>{0, text.length};
    for (final s in spans) {
      cuts.add(s.start.clamp(0, text.length));
      cuts.add(s.end.clamp(0, text.length));
    }
    if (composing != null) {
      cuts.add(composing.start.clamp(0, text.length));
      cuts.add(composing.end.clamp(0, text.length));
    }
    final points = cuts.toList()..sort();

    final children = <TextSpan>[];
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      if (a >= b) continue;
      final isMono = spans.any((s) => s.start <= a && b <= s.end);
      final isComposing =
          composing != null && composing.start <= a && b <= composing.end;
      var segStyle = isMono ? monoStyle : base;
      if (isComposing) {
        segStyle = segStyle.merge(
            const TextStyle(decoration: TextDecoration.underline));
      }
      children.add(TextSpan(text: text.substring(a, b), style: segStyle));
    }
    return TextSpan(style: style, children: children);
  }
}
