/// 전·후 와이프의 셈. 화면은 안 그리고 손잡이가 어디로 가는지만 정한다.
///
/// ## 왜 이 기능인가 (2026-08-27 소유자 확정)
///
/// 소유자가 물었다 — "옵시디언의 그물망처럼 사람들이 입을 다물지 못할,
/// 괜히 동경하게 되는 기능이 한두 개는 필요하다."
///
/// 후보 중 이것을 첫 번째로 골랐다. 까닭이 셋이다.
///
///   지어내지 않는다   이 앱이 이미 하고 있는 일을 **보이게** 만드는 것뿐이다.
///                     광고에 거짓이 한 줄도 안 들어간다.
///   한 장으로 끝난다   앱스토어 첫 스크린샷, 미리보기 영상, 피처링 신청서.
///                     셋이 이거 하나로 채워진다.
///   공수가 감당된다    정리 전 글은 이미 노트에 남아 있다(originalBody).
///                     새로 저장할 것도, 동기화에 실을 것도 없다.
///
/// ## 손잡이의 규칙
///
/// 애플이 말하는 '살아 있는 손맛'의 핵심은 셋이다 — 손가락을 1:1로
/// 따라올 것, 언제든 붙잡아 되돌릴 수 있을 것, 놓았을 때 그 속도를
/// 이어받을 것. 정해진 시간 동안 정해진 길을 가는 애니메이션으로는
/// 그 셋을 못 한다. 그래서 이 파일은 **위치를 계산할 뿐** 시간을 안 센다.
library;

/// 손잡이가 갈 수 있는 왼쪽 끝과 오른쪽 끝.
///
/// 양 끝에 [edge] 만큼을 남긴다. 0까지 밀 수 있게 두면 한쪽 글이 완전히
/// 사라지는데, 그러면 사람은 이것이 두 겹이라는 것을 잊는다. 조금 남겨
/// 두면 '아직 저쪽이 있다'가 눈에 남는다.
(double, double) wipeRange(double w, {double edge = 28}) {
  if (w <= edge * 2) return (w / 2, w / 2);
  return (edge, w - edge);
}

double wipeClamp(double x, double w, {double edge = 28}) {
  final (lo, hi) = wipeRange(w, edge: edge);
  return x < lo ? lo : (x > hi ? hi : x);
}

/// 가장자리 저항. 끝에 닿았다고 딱 멈추면 '고장'으로 읽히고, 그냥
/// 넘어가게 두면 글이 통째로 사라진다. 더 밀수록 덜 따라오게 한다.
///
/// 셈은 애플 표본 코드의 고무줄과 같은 꼴이다.
double _band(double over, double dim, {double k = 0.55}) =>
    (over * dim * k) / (dim + k * over.abs());

/// 손가락을 1:1로 따라간다. 범위 밖에서만 저항이 붙는다.
double wipeDrag(double x, double dx, double w, {double edge = 28}) {
  final next = x + dx;
  final (lo, hi) = wipeRange(w, edge: edge);
  if (next < lo) return lo + _band(next - lo, w);
  if (next > hi) return hi + _band(next - hi, w);
  return next;
}

/// 던진 손가락이 **어디에 설 것인가.** 놓은 자리가 아니라 갈 자리로
/// 보낸다 — 이게 없으면 아무리 세게 튕겨도 손 뗀 그 자리에 선다.
///
/// 교과서의 v²/2a 가 아니라 애플이 실제로 쓰는 지수 감쇠 꼴이다.
double wipeProject(double x, double vPerSec, {double rate = 0.998}) =>
    x + (vPerSec / 1000) * rate / (1 - rate);

/// 0(왼쪽 끝)~1(오른쪽 끝)을 실제 자리로.
double wipeAt(double frac, double w, {double edge = 28}) {
  final (lo, hi) = wipeRange(w, edge: edge);
  return lo + (hi - lo) * (frac < 0 ? 0 : (frac > 1 ? 1 : frac));
}

/// 지금 자리가 0~1 중 어디쯤인가. 이름표를 옅게 할 때 쓴다.
double wipeFrac(double x, double w, {double edge = 28}) {
  final (lo, hi) = wipeRange(w, edge: edge);
  if (hi <= lo) return 0.5;
  final f = (x - lo) / (hi - lo);
  return f < 0 ? 0 : (f > 1 ? 1 : f);
}
