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
import 'rich_spans.dart';

class MonoTextController extends TextEditingController {
  MonoTextController({super.text});

  /// 설정의 "표를 등폭 글꼴로"가 켜져 있는지. 화면 build에서 넣어 준다.
  bool monoEnabled = true;

  /// 마크다운을 눈에 보이게 그릴지. 2026-08-18 소유자 지시로 들어왔다.
  bool richEnabled = true;

  /// 표시(#, **, - )를 옅게 그릴 색. 화면 build에서 넣어 준다.
  Color? subColor;

  /// 할 일 네모의 색. 화면 build에서 넣어 준다.
  Color? accentColor;

  /// 제목을 얼마나 키우나.
  ///
  /// 값을 1.3 위로 안 올리는 데는 까닭이 있다. 이 앱에는 **줄 쳐진 종이**가
  /// 있고(몰스킨·서리), 그 줄은 '한 줄의 높이'를 곱해서 긋는다. 글자만
  /// 키우면 줄 높이가 따라 커져서 **글과 줄이 어긋난다.**
  ///
  /// 그래서 키운 만큼 줄 간격 배수를 그만큼 줄인다(_headStyle). 그러면 줄
  /// 상자의 높이는 그대로고 글자만 커진다. 다만 그 셈에는 바닥이 있다 —
  /// 1.3배를 넘기면 남는 줄 간격이 한글 받침이 닿을 만큼 좁아진다.
  static const double h1Scale = 1.30;
  static const double h2Scale = 1.18;
  static const double h3Scale = 1.08;

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

  /// 줄 간격의 폭. 2026-08-18 소유자 지시 — "'본문 줄 간격(행 간격)' 설정도
  /// 될까? 기본값이 좋은 사람이 있겠지만, 더 좁게 또는 더 넓게 쓸 사람들이
  /// 있을테니까."
  ///
  /// 1.2 아래로는 한글의 받침과 다음 줄의 윗머리가 닿기 시작하고, 2.2를
  /// 넘으면 한 화면에 들어오는 줄이 너무 줄어 글이 흩어져 보인다.
  static const double minBodyHeight = 1.2;
  static const double maxBodyHeight = 2.2;

  /// 화면 build에서 설정값을 넣어 준다.
  double bodyFontSize = defaultBodyFontSize;

  /// 등폭 구간 크기. 표가 가로로 덜 넘치도록 본문보다 조금 작게 쓴다.
  /// 본문 크기를 바꾸면 같은 비율로 따라간다(17일 때 14.5).
  static const double _monoRatio = 14.5 / defaultBodyFontSize;
  double get monoFontSize => bodyFontSize * _monoRatio;

  /// 화면 build에서 설정값을 넣어 준다. 안 넣으면 기본값 그대로다.
  double lineHeight = bodyHeight;

  /// 크기가 달라도 **줄 높이는 본문과 같아야** 표 근처에서 줄 간격이 튀지 않는다.
  double get monoHeight => bodyFontSize * lineHeight / monoFontSize;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = monoEnabled ? monoSpans(text) : const <MonoSpan>[];
    // 코드·표 구간 안의 '**'와 '#'은 글자 그대로다. 거기서는 안 그린다.
    final rich = richEnabled
        ? richSpans(text)
            .where((r) => !spans.any((m) => r.start < m.end && m.start < r.end))
            .toList()
        : const <RichSpan>[];
    final composing =
        (withComposing && value.isComposingRangeValid) ? value.composing : null;
    if (spans.isEmpty && rich.isEmpty && composing == null) {
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
    for (final r in rich) {
      cuts.add(r.start.clamp(0, text.length));
      cuts.add(r.end.clamp(0, text.length));
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
      if (!isMono) {
        for (final r in rich) {
          if (r.start <= a && b <= r.end) segStyle = _dress(segStyle, r.kind);
        }
      }
      if (isComposing) {
        segStyle = segStyle.merge(
            const TextStyle(decoration: TextDecoration.underline));
      }
      children.add(TextSpan(text: text.substring(a, b), style: segStyle));
    }
    return TextSpan(style: style, children: children);
  }

  /// 구간 하나에 옷을 입힌다.
  TextStyle _dress(TextStyle s, RichKind k) {
    switch (k) {
      case RichKind.marker:
        // 지우지 않고 옅게. 편집기라서 글자를 없앨 수 없다(rich_spans.dart 머리말).
        return s.copyWith(
            color: (subColor ?? s.color)?.withValues(alpha: 0.45));
      case RichKind.h1:
        return _headStyle(s, h1Scale);
      case RichKind.h2:
        return _headStyle(s, h2Scale);
      case RichKind.h3:
        return _headStyle(s, h3Scale);
      case RichKind.bold:
        return s.copyWith(fontWeight: FontWeight.w700);
      case RichKind.quote:
        return s.copyWith(color: subColor ?? s.color);
      case RichKind.box:
        return s.copyWith(
            color: accentColor ?? s.color, fontWeight: FontWeight.w700);
      case RichKind.done:
        return s.copyWith(
            color: (subColor ?? s.color)?.withValues(alpha: 0.7),
            decoration: TextDecoration.lineThrough,
            decorationColor: (subColor ?? s.color)?.withValues(alpha: 0.5));
    }
  }

  /// 글자는 키우고 줄 상자는 그대로 둔다.
  ///
  /// height 는 '글자 크기의 몇 배'라서, 크기를 k배 하면서 height 를 k로
  /// 나누면 곱이 그대로다. 줄 쳐진 종이의 줄과 글이 계속 맞는 까닭이 이것이다.
  TextStyle _headStyle(TextStyle s, double k) {
    final fs = s.fontSize ?? bodyFontSize;
    final h = s.height ?? lineHeight;
    return s.copyWith(
        fontSize: fs * k, height: h / k, fontWeight: FontWeight.w700);
  }
}
