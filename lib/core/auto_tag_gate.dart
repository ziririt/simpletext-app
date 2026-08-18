/// 조용한 자동 태그 — **언제 부를지**만 정하는 순수 함수.
///
/// 2026-08-18 소유자 지시로 되살렸다. 2026-08-17에 걷어냈던 것인데, 그때
/// 걷어낸 이유는 기능이 나빠서가 아니라 **글자를 칠 때마다 회사를 불렀기**
/// 때문이다. 그러면 남의 API 요금이 샌다.
///
/// 그래서 이번에는 규칙을 화면에서 떼어 여기 두고 시험으로 못 박는다.
/// 돈이 나가는 판단은 눈으로 봐서는 틀린 줄 모른다 — 요금 고지서가 와야
/// 안다. 그때는 이미 사용자가 떠난 뒤다.
library;

/// 태그를 뽑기에 너무 짧은 글.
const int kAutoTagMinChars = 80;

/// 지난번 뽑을 때보다 이만큼은 늘거나 줄어야 다시 부른다.
///
/// 300자를 고른 까닭: 이보다 작은 변화는 대개 오타를 고치거나 한 문장을
/// 다듬은 것이라, 그 글이 **무엇에 관한 것인지**는 안 바뀐다. 태그가 바뀔
/// 일이 없는데 회사를 부르는 것은 그냥 돈을 버리는 것이다.
const int kAutoTagDeltaChars = 300;

/// 지금 태그를 다시 뽑을 것인가.
///
/// [hasKey]      AI 키가 있는가 (없으면 아예 못 한다)
/// [enabled]     설정에서 켜 두었는가
/// [tagsAuto]    태그를 아직 사람이 안 만졌는가 — **만졌으면 영영 손 뗀다**
/// [bodyLen]     지금 본문 길이
/// [taggedLen]   지난번에 뽑을 때의 본문 길이 (-1이면 한 번도 안 뽑음)
/// [tagCount]    지금 붙어 있는 태그 수
/// [bodyChanged] 이 화면에서 본문이 실제로 바뀌었는가 (열어 보기만 한 것 제외)
bool shouldAutoTag({
  required bool hasKey,
  required bool enabled,
  required bool tagsAuto,
  required int bodyLen,
  required int taggedLen,
  required int tagCount,
  required bool bodyChanged,
}) {
  if (!hasKey || !enabled || !tagsAuto) return false;
  if (!bodyChanged) return false;
  if (bodyLen < kAutoTagMinChars) return false;
  // 아직 태그가 하나도 없으면 길이와 무관하게 한 번은 뽑는다.
  if (tagCount == 0) return true;
  if (taggedLen < 0) return true;
  return (bodyLen - taggedLen).abs() >= kAutoTagDeltaChars;
}
