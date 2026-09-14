/// 블록을 끌다 화면 끝에 닿았을 때의 자동 굴림 — 얼마나 빨리 굴릴지.
///
/// 2026-09-14 소유자 신고 — "본문에 블록을 씌운 채 위·아래로 더 끌어 범위를
/// 넓힐 때 스크롤 속도가 빨라서 딱 멈추기가 어렵다. 천천히 시작했다가,
/// 계속 끌 뜻이 확인되면 서서히 빨라지게 해 달라."
///
/// 그동안은 우리가 굴린 것이 아니었다. 손가락이 끝에 닿아 선택이 다음 줄로
/// 넘어가면 플러터가 캐럿을 보이게 하려고 한 줄씩 **뛰었다**(ensureVisible).
/// 손가락이 조금만 떨려도 한 줄씩 또 뛰니, 빠르고 멈추기 어렵다.
///
/// 이제는 우리가 굴린다. 손가락이 화면 위·아래 가장자리 띠 안에 있는 동안
/// 매 틱마다 조금씩 굴리고, 굴린 만큼 손가락 밑 글자로 선택을 늘린다.
/// 속도는 두 가지가 정한다.
///
///   · **얼마나 오래 머물렀나** — 처음 1.5초는 느리게, 그 뒤로 빨라진다.
///     "계속 끌 뜻"을 시간으로 읽는다. 잠깐 스친 것은 한두 줄만 움직인다
///   · **얼마나 깊이 들어갔나** — 띠의 안쪽 경계에서는 느리고 화면 끝에
///     붙을수록 빠르다. 손가락을 조금 물리면 바로 느려지므로 멈출 자리를
///     고르기 쉽다
///
/// 여기는 셈만 있다. 화면·스크롤·선택은 main.dart 가 한다(시험으로 못 박기 위해).
library;

/// 화면 위·아래에서 이만큼 안쪽이 '가장자리 띠'다.
const double kEdgeZone = 72;

/// 띠에 막 들어왔을 때의 속도(초당 픽셀). 한 줄(약 24px)을 넘기는 데 반 초쯤.
const double kEdgeSlow = 48;

/// 충분히 오래 붙들고 있을 때의 속도(초당 픽셀). 한 화면을 1.2초쯤에.
const double kEdgeFast = 720;

/// 느린 속도에서 빠른 속도까지 올라가는 데 걸리는 시간.
const Duration kEdgeRamp = Duration(milliseconds: 1500);

/// 손가락이 가장자리 띠 안에 있으면 방향과 깊이를, 아니면 null 을.
///
/// [y] 손가락의 세로 좌표, [top]·[bottom] 굴리는 창의 위·아래(같은 좌표계).
/// 방향은 -1(위로 굴림)·+1(아래로 굴림), 깊이는 0(띠의 안쪽 경계)..1(화면 끝).
({int dir, double depth})? edgePlan({
  required double y,
  required double top,
  required double bottom,
  double zone = kEdgeZone,
}) {
  if (bottom - top <= zone * 2) {
    // 창이 띠 둘보다 좁으면 반씩 나눈다. 아주 작은 창에서만 생긴다.
    zone = (bottom - top) / 2;
  }
  if (zone <= 0) return null;
  if (y <= top + zone) {
    final depth = ((top + zone - y) / zone).clamp(0.0, 1.0);
    return (dir: -1, depth: depth);
  }
  if (y >= bottom - zone) {
    final depth = ((y - (bottom - zone)) / zone).clamp(0.0, 1.0);
    return (dir: 1, depth: depth);
  }
  return null;
}

/// 초당 픽셀. [held] 는 띠에 머문 시간, [depth] 는 edgePlan 의 깊이.
double edgeSpeed({required Duration held, required double depth}) {
  final t = (held.inMilliseconds / kEdgeRamp.inMilliseconds).clamp(0.0, 1.0);
  // 부드러운 계단(smoothstep). 직선보다 처음이 더 느리고 끝이 더 완만하다.
  final ramp = t * t * (3 - 2 * t);
  final base = kEdgeSlow + (kEdgeFast - kEdgeSlow) * ramp;
  // 띠 안쪽 경계에서는 셋 중 하나, 화면 끝에서는 전부.
  return base * (0.35 + 0.65 * depth.clamp(0.0, 1.0));
}
