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

/// 이 줄 모양이 가로줄을 긋는가.
///
/// 2026-08-17 소유자 신고: "종이/크라프트/월넛/하늘은 모눈종이 배경이
/// 아닌데, 샘플에서는 모눈종이로 나왔다."
///
/// 원인은 판정이 **화가가 아니라 부르는 쪽에** 있었던 것이다. 편집 화면은
/// 부르기 전에 ruling != none 을 확인했지만, 설정의 견본 칩은 그 확인 없이
/// 같은 화가를 불렀다. 화가에는 none 갈래가 없어서 가로줄을 긋고 세로줄까지
/// 그어 모눈을 만들었다.
///
/// 부르는 쪽이 기억해야 하는 규칙은 언젠가 잊힌다. 그래서 판정을 종이
/// 정의 바로 옆으로 옮겼다 — 종이가 늘어날 때 같이 보이는 자리다.
bool drawsHorizontal(String ruling) => ruling != kRulingNone;

/// 세로줄까지 긋는가. 모눈과 원고지 둘뿐이다.
bool drawsVertical(String ruling) =>
    ruling == kRulingGrid || ruling == kRulingManuscript;

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

  // 모눈. 칸이 줄 높이와 같은 정사각이라 어느 글꼴에서도 정확히 맞는다.
  Paper(
    id: 'grid',
    bg: 0xFFFAFAF7, ink: 0xFF23262B, rule: 0xFFDCE3EC,
    bgDark: 0xFF15171A, inkDark: 0xFFE4E7EB, ruleDark: 0xFF2A3038,
    ruling: kRulingGrid,
  ),

  // 2026-08-17 소유자 요청으로 네 벌 추가. 색은 눈으로 고르지 않았다 —
  // 이 넷은 '줄 없는 색 종이'다. 줄이 필요한 사람은 위의 몰스킨·모눈을
  // 고른다. 처음엔 크라프트와 하늘에도 줄을 넣었는데, 소유자가 바로
  // 짚었다 — 색을 고르러 온 자리에 줄이 섞여 있으면 무엇을 고르는
  // 자리인지 흐려진다. ('나이트'는 다크 모드와 같은 것이라 뺐다.)
  //
  // 색은 라이트·다크 양쪽에서 글자 명암비 9.5:1 이상이다(기준 4.5:1).
  // 파이썬으로 먼저 재고 넣었다.

  // 종이. 화면 같지 않은 가장 무난한 바탕. 줄이 없어 어떤 글에도 맞는다.
  Paper(
    id: 'plain',
    bg: 0xFFF2F2F0, ink: 0xFF24262A, rule: 0xFFE0E1E3,
    bgDark: 0xFF17181A, inkDark: 0xFFE6E7EA, ruleDark: 0xFF2B2D30,
    ruling: kRulingNone,
  ),

  // 세피아. 2026-08-18 소유자 지시로 '종이' 오른쪽으로 옮겼다. 줄 있는
  // 종이(몰스킨·모눈)와 줄 없는 색 종이(종이·세피아·크라프트·월넛·하늘)를
  // 갈라 놓으면 고르는 사람이 한 번에 두 무리를 본다.
  // 세피아. 오래 읽을 때를 위한 것이라 줄을 넣지 않는다 — 줄은 쓸 때
  // 도움이 되고 읽을 때는 방해가 된다.
  Paper(
    id: 'sepia',
    bg: 0xFFFBF0DA, ink: 0xFF4A3B28, rule: 0xFFEADCC0,
    bgDark: 0xFF21201D, inkDark: 0xFFD9CDB8, ruleDark: 0xFF33312C,
    ruling: kRulingNone,
  ),

  // 크라프트. 세피아보다 진하고 노란기가 덜하다.
  Paper(
    id: 'kraft',
    bg: 0xFFEFE3CE, ink: 0xFF3A2F1E, rule: 0xFFDCCBAE,
    bgDark: 0xFF1E1B16, inkDark: 0xFFE4D9C4, ruleDark: 0xFF332E25,
    ruling: kRulingNone,
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

  // 하늘. 앱의 주조색과 같은 계열이라 화면 전체가 한 벌로 보인다.
  Paper(
    id: 'sky',
    bg: 0xFFEAF2F8, ink: 0xFF1F2A33, rule: 0xFFD3E2EE,
    bgDark: 0xFF131A20, inkDark: 0xFFDDE8F0, ruleDark: 0xFF223039,
    ruling: kRulingNone,
  ),
];

/// 없앤 종이가 갈 곳.
///
/// 2026-08-18 소유자 지시로 '원고지'를 뺐다. 그런데 이미 그것을 고른
/// 사람이 있다. 목록에서 없앴다고 그 사람의 설정을 '기본'으로 떨어뜨리면
/// 어느 날 갑자기 흰 화면이 되고, 그건 우리가 뺀 것이 아니라 고장으로
/// 읽힌다. 격자라는 성질이 가장 가까운 '모눈'으로 보낸다.
const Map<String, String> kRetiredPapers = {'manuscript': 'grid'};

/// 모르는 값이 들어오면 '기본'으로 떨어뜨린다.
///
/// 저장된 설정에 옛 이름이 남아 있거나, 다른 기기가 새 종이를 먼저 쓰고
/// 동기화해 왔을 때 앱이 죽지 않게 하려는 것이다.
Paper paperById(String id) {
  final key = kRetiredPapers[id] ?? id;
  return kPapers.firstWhere((p) => p.id == key, orElse: () => kPapers.first);
}

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

// ------------------------------------------------------------------ 여백
//
// 2026-08-18 소유자 지시 — "맥용 앱과 아이패드 앱(가로 모드)에서 편집화면의
// width는 고정되어있는 것은 좋은데, 그 여백의 배경색이 거슬린다. 편집화면의
// 배경색 보다 컬러계열은 같은데 톤은 한톤 옅은 컬러면 딱 좋겠다."
//
// 지금까지 여백은 앱 바탕색이었다. 종이가 세피아든 월넛이든 여백은 늘
// 같은 색이라, 글 칸이 '놓인 것'이 아니라 '뚫린 것'처럼 보였다.
//
// 낮추는 방향은 하나여야 한다. 2026-08-18 처음에는 '중간 회색 쪽으로
// 당기기'로 만들었다. 이론상 밝은 종이는 가라앉고 어두운 종이는 떠올라
// 양쪽이 다 사는데, 실제로는 다크에서 **여백이 본문보다 밝아진다.**
// 종이가 책상 위에 놓인 것이 아니라 책상이 종이보다 밝은 꼴이라 눈이
// 여백부터 본다. 소유자의 말 — "이렇게 해도 촌스럽네."
//
// 그래서 어느 종이든 낮춘다. 현실의 그림자가 한 방향인 것과 같다.
//
// 5%라는 값은 소유자가 정했다("본문 배경색 보다 5% 정도 진한 컬러").
// 다만 곱셈만으로는 어두운 종이에서 한두 칸밖에 안 움직여 없는 것과
// 같아진다(0x21의 5%는 1.65다). 그래서 최소 여섯 칸은 낮춘다 — 뜻을
// 지키려면 양 끝에서 다 지켜야 한다.
//
// 결과는 종이 여덟 벌 × 라이트·다크 열여섯 경우 모두 명암비 1.05~1.12다.
const double kMarginDarkenPct = 0.05;
const int kMarginDarkenFloor = 6;

/// 여백 색. [argb]는 종이 바탕색. 늘 그보다 조금 어둡다.
int marginTone(int argb,
    [double pct = kMarginDarkenPct, int floor = kMarginDarkenFloor]) {
  int down(int v) {
    final cut = (v * pct).round();
    final out = v - (cut > floor ? cut : floor);
    return out < 0 ? 0 : out;
  }

  final a = (argb >> 24) & 0xFF;
  return (a << 24) |
      (down((argb >> 16) & 0xFF) << 16) |
      (down((argb >> 8) & 0xFF) << 8) |
      down(argb & 0xFF);
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
