/// 보기 설정 — 글을 어떻게 보여 줄지 정하는 값들, 그리고 그 값이 **어디서
/// 오는지**를 정하는 셈.
///
/// 2026-09-09 소유자 지시 — "편집화면에서 바로 '보기 설정'을 하고 싶다.
/// 전자책 뷰어 앱과 다를 이유가 없다. '이 노트에만 적용'을 두고, 그걸
/// 체크하면 이 노트에만 이 값이 저장되고, 기본은 전체 노트에 적용되는
/// 것이다."
///
/// ## 두 층이다
///
/// - **전체값(global)** — 앱 설정에 하나. 늘 모든 칸이 채워져 있다.
/// - **이 노트만(override)** — 노트마다 하나, 채워진 칸만 있다.
///
/// 그래서 이 파일에는 그릇이 둘이다. [ViewSpec] 은 **해석이 끝난 값**이라
/// 빈 칸이 없고, 화면은 이것만 본다. [ViewPrefs] 는 **덮어쓸 칸만 든 값**
/// 이라 빈 칸이 있을 수 있고, 저장할 때 채워진 칸만 적힌다.
///
/// 화면이 두 층을 직접 섞지 않게 한 까닭: 섞는 자리가 늘어나면 어떤 화면은
/// 노트값을 보고 어떤 화면은 전체값을 봐서, 같은 글이 편집기와 미리보기에서
/// 다르게 보인다. 섞는 일은 [ViewPrefs.applyTo] 한 곳에서만 한다.
///
/// ## 왜 노트 안에 안 넣는가
///
/// 책갈피와 같은 까닭이다(core/read_mark.dart). 노트에 넣으면 글자 크기만
/// 바꿔도 노트가 바뀐 것이 되어 목록 맨 위로 올라오고 동기화가 돈다 —
/// 보는 방식을 바꾼 것이 쓴 것으로 둔갑한다. 그래서 앱 설정에 노트 아이디를
/// 열쇠로 담는다(AppSettings.noteViews).
library;

/// 좌우 여백(pt). 22 는 2026-08-19 소유자가 "베어 정도"라고 한 값이다.
const double kMarginMin = 8;
const double kMarginMax = 48;
const double kMarginStep = 2;
const double kMarginDefault = 22;

/// 문단 간격 — 빈 줄의 높이를 몇 배로 할지.
///
/// 1.0 이 원본(빈 줄도 다른 줄과 같은 높이)이다. 글자 크기나 줄 간격을
/// 건드리지 않고 **문단 사이만** 벌리려면 이 길뿐이다.
const double kParaGapMin = 1.0;
const double kParaGapMax = 2.5;
const double kParaGapStep = 0.25;

/// 문단 정렬. 'start' 는 왼쪽(원본), 'justify' 는 양쪽 맞춤.
const String kAlignStart = 'start';
const String kAlignJustify = 'justify';

double clampMargin(double v) =>
    v < kMarginMin ? kMarginMin : (v > kMarginMax ? kMarginMax : v);

double clampParaGap(double v) =>
    v < kParaGapMin ? kParaGapMin : (v > kParaGapMax ? kParaGapMax : v);

String safeAlign(String? v) => v == kAlignJustify ? kAlignJustify : kAlignStart;

/// 해석이 끝난 보기 값. 빈 칸이 없다 — 화면은 이것만 본다.
class ViewSpec {
  const ViewSpec({
    required this.font,
    required this.fontSize,
    required this.lineHeight,
    required this.bold,
    required this.margin,
    required this.align,
    required this.paraGap,
    required this.paper,
  });

  final String font;
  final double fontSize;
  final double lineHeight;
  final bool bold;
  final double margin;
  final String align;
  final double paraGap;
  final String paper;

  ViewSpec copyWith({
    String? font,
    double? fontSize,
    double? lineHeight,
    bool? bold,
    double? margin,
    String? align,
    double? paraGap,
    String? paper,
  }) => ViewSpec(
    font: font ?? this.font,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    bold: bold ?? this.bold,
    margin: margin ?? this.margin,
    align: align ?? this.align,
    paraGap: paraGap ?? this.paraGap,
    paper: paper ?? this.paper,
  );
}

/// 덮어쓸 칸만 든 값. 노트 하나에 하나.
class ViewPrefs {
  const ViewPrefs({
    this.font,
    this.fontSize,
    this.lineHeight,
    this.bold,
    this.margin,
    this.align,
    this.paraGap,
    this.paper,
  });

  final String? font;
  final double? fontSize;
  final double? lineHeight;
  final bool? bold;
  final double? margin;
  final String? align;
  final double? paraGap;
  final String? paper;

  static const ViewPrefs none = ViewPrefs();

  /// 덮어쓸 것이 하나도 없는가. 비면 저장하지 않는다 — 빈 껍데기가 노트
  /// 수만큼 쌓이면 설정 파일이 그것으로 채워진다.
  bool get isEmpty =>
      font == null &&
      fontSize == null &&
      lineHeight == null &&
      bold == null &&
      margin == null &&
      align == null &&
      paraGap == null &&
      paper == null;

  bool get isNotEmpty => !isEmpty;

  /// 전체값 위에 이 값을 얹는다. **섞는 일은 여기 한 곳뿐이다.**
  ViewSpec applyTo(ViewSpec base) => base.copyWith(
    font: font,
    fontSize: fontSize,
    lineHeight: lineHeight,
    bold: bold,
    margin: margin,
    align: align,
    paraGap: paraGap,
    paper: paper,
  );

  /// 전체값과 견주어, **다른 칸만** 남긴 덮어쓰기를 만든다.
  ///
  /// '이 노트에만 적용'을 켠 채 아무것도 안 바꾸면 덮어쓸 것이 없다.
  /// 그때 값을 통째로 베껴 두면, 나중에 전체 설정을 바꿔도 이 노트만
  /// 옛 값에 갇힌다 — 사람은 아무것도 안 골랐는데 갇히는 것이다.
  static ViewPrefs diff(ViewSpec now, ViewSpec base) => ViewPrefs(
    font: now.font == base.font ? null : now.font,
    fontSize: now.fontSize == base.fontSize ? null : now.fontSize,
    lineHeight: now.lineHeight == base.lineHeight ? null : now.lineHeight,
    bold: now.bold == base.bold ? null : now.bold,
    margin: now.margin == base.margin ? null : now.margin,
    align: now.align == base.align ? null : now.align,
    paraGap: now.paraGap == base.paraGap ? null : now.paraGap,
    paper: now.paper == base.paper ? null : now.paper,
  );

  Map<String, dynamic> toJson() => {
    if (font != null) 'font': font,
    if (fontSize != null) 'size': fontSize,
    if (lineHeight != null) 'lh': lineHeight,
    if (bold != null) 'bold': bold,
    if (margin != null) 'mg': margin,
    if (align != null) 'al': align,
    if (paraGap != null) 'pg': paraGap,
    if (paper != null) 'paper': paper,
  };

  /// 저장본에서 되살린다. 모양이 아니면 조용히 빈 값 — 설정 하나 때문에
  /// 앱이 안 뜨는 일은 없어야 한다.
  static ViewPrefs fromJson(Object? j) {
    if (j is! Map) return none;
    double? num1(String k) {
      final v = j[k];
      return v is num ? v.toDouble() : null;
    }

    final mg = num1('mg');
    final pg = num1('pg');
    final al = j['al'];
    return ViewPrefs(
      font: j['font'] is String ? j['font'] as String : null,
      fontSize: num1('size'),
      lineHeight: num1('lh'),
      bold: j['bold'] is bool ? j['bold'] as bool : null,
      margin: mg == null ? null : clampMargin(mg),
      align: al is String ? safeAlign(al) : null,
      paraGap: pg == null ? null : clampParaGap(pg),
      paper: j['paper'] is String ? j['paper'] as String : null,
    );
  }
}

/// 빈 줄의 자리. 문단 간격은 **빈 줄의 높이를 키워서** 만든다.
///
/// 글자 크기도 줄 간격도 안 건드리고 문단 사이만 벌리는 길은 이것뿐이다.
/// 돌려주는 것은 '빈 줄을 끝내는 줄바꿈 문자'의 자리 [i, i+1) 들이다.
///
/// 맨 끝의 빈 줄은 세지 않는다 — 끝낼 줄바꿈이 없어서 키울 대상이 없다.
List<int> blankLineBreaks(String text) {
  final out = <int>[];
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) != 0x0A) continue;
    if (i == start) out.add(i); // 이 줄은 비어 있었다
    start = i + 1;
  }
  return out;
}
