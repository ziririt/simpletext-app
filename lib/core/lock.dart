// 앱 잠금 규칙.
//
// 2026-08-16 로드맵 B단계 — 잠금(Face ID). 조사에서 '노트앱에 있어야 하는데
// 없으면 미완성으로 느껴지는 것' 목록에 늘 들어 있던 항목이다. 우리 앱은
// 특히 그렇다. 여기 쌓이는 것은 남에게 물어본 것들이고, 남이 내 폰을 집어
// 들었을 때 제일 먼저 열어 보는 것이 메모다.
//
// **이 잠금이 무엇이 아닌지 먼저 못 박는다.** 이건 남이 내 기기를 집었을 때
// 화면을 못 열게 하는 것이지, 디스크 안의 파일을 암호로 잠그는 것이 아니다.
// 파일을 정말 잠그려면 본문을 암호화해야 하고, 그러면 아이클라우드 병합과
// 검색이 통째로 바뀐다. 지금 그걸 하지 않기로 했으니, 설정 화면에도 그렇게
// 적는다. 안 그러면 이건 보안이 아니라 보안처럼 보이는 것이다.
//
// 여기에는 '언제 잠글 것인가'만 있다. 실제로 얼굴·지문·암호를 묻는 일은
// lib/lock_service.dart가 한다. 판단과 기기 호출을 갈라 놓아야 이 규칙을
// 테스트로 못 박을 수 있다.

/// 뒤로 갔다가 돌아왔을 때 다시 잠그기까지 봐주는 시간(초).
const int kLockNow = 0;
const int kLockAfter1m = 60;
const int kLockAfter5m = 300;

/// 고를 수 있는 값. 이 밖의 값이 저장돼 있으면 '바로'로 떨어뜨린다.
const List<int> kLockDelays = [kLockNow, kLockAfter1m, kLockAfter5m];

int normalizeLockDelay(int v) => kLockDelays.contains(v) ? v : kLockNow;

/// 지금 잠가야 하는가.
///
/// [leftAtMs]는 앱이 마지막으로 뒤로 간 시각이다. 0이면 방금 켠 것이다.
///
/// 판단이 애매한 자리에서는 **전부 잠그는 쪽**으로 기운다. 잘못 잠그면
/// 사용자가 한 번 더 확인하면 되지만, 잘못 안 잠그면 그걸로 끝이다.
bool shouldLock({
  required bool enabled,
  required int leftAtMs,
  required int nowMs,
  required int graceSec,
}) {
  if (!enabled) return false;
  // 앱을 새로 켠 것. 봐주는 시간과 상관없이 잠근다 — 앱이 죽었다 살아난
  // 것이라 '잠깐 나갔다 온 것'이 아니다.
  if (leftAtMs <= 0) return true;
  if (graceSec <= 0) return true;
  final gone = nowMs - leftAtMs;
  // 시계가 뒤로 간 경우(사용자가 시간을 바꿨거나 시간대가 바뀌었거나).
  // 봐주는 시간을 우회하는 가장 쉬운 길이라 막는다.
  if (gone < 0) return true;
  return gone >= graceSec * 1000;
}
