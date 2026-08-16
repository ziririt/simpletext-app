// 편집 화면 '종이'.
//
// 2026-08-16 소유자 요청 — "에디터 화면 배경 컬러 커스텀 지정은? 원고지 등
// 백그라운드 설정은? 굿노트처럼." 그리고 뒤이어 "몰스킨 스타일 프리셋은
// 필요하다."
//
// 자유 색상 고르개(color picker)를 주지 않는 이유가 있다. 배경을 마음대로
// 고르게 하면 사람은 반드시 글자가 안 읽히는 조합을 만든다 — 그리고 그건
// 우리 앱이 못 만든 화면으로 보인다. 그래서 배경·글자·줄 색을 한 벌로 묶어
// 미리 맞춰 둔 '종이'를 고르게 한다. 굿노트도 같은 방식이다.
//
// 색은 눈으로 고르지 않았다. 아래 모든 종이는 라이트·다크 양쪽에서 글자
// 명암비 4.5:1(WCAG AA)을 넘고, 줄 색은 1.1~3.0 사이에 둔다. 줄이 너무
// 진하면 글보다 줄이 먼저 보인다. 이 조건은 테스트로 고정돼 있으니
// (test/core/paper_test.dart) 색을 바꾸면 테스트가 먼저 알려 준다.
import 'dart:math' as math;

/// 종이를 안 쓰는 상태. 앱 테마 색을 그대로 쓴다.
const String kPaperNone = 'none';

/// 줄 모양.
const String kRulingNone = 'none';
const String kRulingLine = 'line'; // 가로줄만
const String kRulingGrid = 'grid'; // 정사각 모눈(칸 = 줄높이)
const String kRulingManuscript = 'manuscript'; // 원고지(칸 = 한글 한 글자)

class Paper {
  final String id;

  /// 라이트에서의 바탕·글자·줄.
  final int bg;
  final int ink;
  final int rule;

  /// 다크에서의 바탕·글자·줄.
  final int bgDark;
  final int inkDark;
  final int ruleDark;

  final String ruling;

  const Paper({
    required this.id,
    required this.bg,
    required this.ink,
    required this.rule,
    required this.bgDark,
    required this.inkDark,
    required this.ruleDark,
    required this.ruling,
  });

  int bgOf(bool dark) => dark ? bgDark : bg;
  int inkOf(bool dark) => dark ? inkDark : ink;
  int ruleOf(bool dark) => dark ? ruleDark : rule;
}

/// 고를 수 있는 종이. 첫째가 '기본'이고, 이 값은 색을 쓰지 않는다.
///
/// 순서가 곧 화면에 보이는 순서다. 몰스킨을 기본 바로 옆에 둔 이유는
/// 소유자가 그걸 콕 집어 요청했기 때문이다.
const List<Paper> kPapers = [
  Paper(
    id: kPaperNone,
    bg: 0, ink: 0, rule: 0,
    bgDark: 0, inkDark: 0, ruleDark: 0,
    ruling: kRulingNone,
  ),

  // 몰스킨. 저 수첩의 종이는 흰색이 아니라 아주 옅은 아이보리이고, 줄은
  // 회색이 아니라 종이보다 조금 어두운 같은 계열의 미색이다. 그래서 줄이
  // '인쇄된 선'이 아니라 '종이의 결'처럼 보인다. 그 느낌을 색으로 옮겼다.
  Paper(
    id: 'moleskine',
    bg: 0xFFF4EFE2, ink: 0xFF2B2620, rule: 0xFFD9D0BC,
    bgDark: 0xFF191714, inkDark: 0xFFE8E0D0, ruleDark: 0xFF34302A,
    ruling: kRulingLine,
  ),

  // 세피아. 오래 읽을 때를 위한 것이라 줄을 넣지 않는다 — 줄은 쓸 때
  // 도움이 되고 읽을 때는 방해가 된다.
  Paper(
    id: 'sepia',
    bg: 0xFFFBF0DA, ink: 0xFF4A3B28, rule: 0xFFEADCC0,
    bgDark: 0xFF21201D, inkDark: 0xFFD9CDB8, ruleDark: 0xFF33312C,
    ruling: kRulingNone,
  ),

  // 원고지. 칸은 한글 한 글자 폭 × 줄 높이다. 붉은 격자는 실제 원고지의
  // 색을 옅게 낮춘 것이다(원본 그대로 쓰면 글자보다 격자가 세다).
  Paper(
    id: 'manuscript',
    bg: 0xFFFCFAF5, ink: 0xFF23201C, rule: 0xFFE9BDB2,
    bgDark: 0xFF15161A, inkDark: 0xFFE6E8EC, ruleDark: 0xFF48332F,
    ruling: kRulingManuscript,
  ),

  // 모눈. 칸이 줄 높이와 같은 정사각이라 어느 글꼴에서도 정확히 맞는다.
  Paper(
    id: 'grid',
    bg: 0xFFFAFAF7, ink: 0xFF23262B, rule: 0xFFDCE3EC,
    bgDark: 0xFF15171A, inkDark: 0xFFE4E7EB, ruleDark: 0xFF2A3038,
    ruling: kRulingGrid,
  ),

  // 2026-08-17 소유자 요청으로 다섯 벌 추가. 색은 눈으로 고르지 않았다 —
  // 라이트·다크 양쪽에서 글자 명암비 9.5:1 이상(기준 4.5:1), 줄은
  // 1.17~1.36. 파이썬으로 먼저 재고 넣었다.

  // 종이. 화면 같지 않은 가장 무난한 바탕. 줄이 없어 어떤 글에도 맞는다.
  Paper(
    id: 'plain',
    bg: 0xFFF2F2F0, ink: 0xFF24262A, rule: 0xFFE0E1E3,
    bgDark: 0xFF17181A, inkDark: 0xFFE6E7EA, ruleDark: 0xFF2B2D30,
    ruling: kRulingNone,
  ),

  // 크라프트. 세피아보다 진하고 노란기가 덜하다. 세피아가 '읽는 종이'라면
  // 이쪽은 '쓰는 종이'라 줄을 넣었다.
  Paper(
    id: 'kraft',
    bg: 0xFFEFE3CE, ink: 0xFF3A2F1E, rule: 0xFFDCCBAE,
    bgDark: 0xFF1E1B16, inkDark: 0xFFE4D9C4, ruleDark: 0xFF332E25,
    ruling: kRulingLine,
  ),

  // 월넛. **라이트 모드에서도 어두운 바탕**이다. 낮에도 어두운 화면으로
  // 쓰고 싶은 사람이 있는데, 앱 전체를 어둡게 하지 않고 글 쓰는 자리만
  // 어둡게 하고 싶을 때가 그때다.
  Paper(
    id: 'walnut',
    bg: 0xFF4A3B2A, ink: 0xFFF6F0E6, rule: 0xFF604E39,
    bgDark: 0xFF2A211A, inkDark: 0xFFF0E7DA, ruleDark: 0xFF3D3128,
    ruling: kRulingNone,
  ),

  // 나이트. 거의 검정. 밤에 눈이 제일 편한 쪽이고, OLED 화면에서는
  // 전력도 덜 쓴다.
  Paper(
    id: 'night',
    bg: 0xFF101114, ink: 0xFFE9EAEC, rule: 0xFF24262B,
    bgDark: 0xFF0B0C0E, inkDark: 0xFFE9EAEC, ruleDark: 0xFF1E2024,
    ruling: kRulingNone,
  ),

  // 하늘. 앱의 주조색과 같은 계열이라 화면 전체가 한 벌로 보인다.
  Paper(
    id: 'sky',
    bg: 0xFFEAF2F8, ink: 0xFF1F2A33, rule: 0xFFD3E2EE,
    bgDark: 0xFF131A20, inkDark: 0xFFDDE8F0, ruleDark: 0xFF223039,
    ruling: kRulingLine,
  ),
];

/// 모르는 값이 들어오면 '기본'으로 떨어뜨린다.
///
/// 저장된 설정에 옛 이름이 남아 있거나, 다른 기기가 새 종이를 먼저 쓰고
/// 동기화해 왔을 때 앱이 죽지 않게 하려는 것이다.
Paper paperById(String id) =>
    kPapers.firstWhere((p) => p.id == id, orElse: () => kPapers.first);

bool paperOn(String id) => paperById(id).id != kPaperNone;

/// 가로줄을 그릴 y 좌표들.
///
/// 핵심은 **줄 간격이 글줄 높이와 정확히 같아야 한다**는 것이다. 조금이라도
/// 어긋나면 화면 아래로 갈수록 글자가 줄에서 떠오르거나 잠긴다 — 종이처럼
/// 안 보이는 가장 흔한 실패다. 그래서 간격을 눈으로 정하지 않고 글줄 높이를
/// 그대로 받아 쓴다.
///
/// [scroll]을 셈에 넣는 이유: 글 칸은 안에서 따로 스크롤한다. 배경을 가만히
/// 두면 글만 올라가고 줄은 제자리라 첫 줄부터 어긋난다.
List<double> ruleOffsets({
  required double lineHeight,
  required double viewHeight,
  required double scroll,
  required double topPad,
}) {
  if (!lineHeight.isFinite || lineHeight <= 0) return const [];
  if (!viewHeight.isFinite || viewHeight <= 0) return const [];
  final first = topPad + lineHeight; // 첫 글줄의 밑선
  var k = ((scroll - first) / lineHeight).ceil();
  if (k < 0) k = 0;
  final out = <double>[];
  // 글자가 아주 작고 화면이 아주 클 때를 대비한 상한. 화면 하나에 줄이
  // 2000개 넘게 들어갈 일은 없다 — 넘는다면 계산이 틀린 것이다.
  while (out.length < 2000) {
    final y = first + k * lineHeight - scroll;
    if (y > viewHeight) break;
    if (y >= 0) out.add(y);
    k++;
  }
  return out;
}

/// 세로줄을 그릴 x 좌표들. 칸 너비 [colWidth]마다 하나씩.
List<double> columnOffsets({
  required double colWidth,
  required double viewWidth,
}) {
  if (!colWidth.isFinite || colWidth <= 0) return const [];
  if (!viewWidth.isFinite || viewWidth <= 0) return const [];
  final out = <double>[];
  var x = colWidth;
  while (x < viewWidth && out.length < 2000) {
    out.add(x);
    x += colWidth;
  }
  return out;
}

// ---------------------------------------------------------------- 명암비
//
// 색을 눈이 아니라 숫자로 고르기 위한 것이다. WCAG의 상대 휘도 공식을
// 그대로 옮겼다. 이 앱은 이미 태그·선택 색을 이 방식으로 정해 왔고,
// 종이도 같은 잣대를 쓴다.

double _channel(int v) {
  final c = v / 255.0;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// 0xAARRGGBB 또는 0xRRGGBB 값의 상대 휘도.
double relativeLuminance(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b);
}

/// 두 색의 명암비(1.0 ~ 21.0).
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
