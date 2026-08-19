/// 메모 하나만 잠갔을 때 — 밖으로 내보내도 되는 것과 안 되는 것.
///
/// 2026-08-19 소유자 확정. 두 가지를 정했다.
///   1. **잠금은 화면만 가린다.** 본문은 지금처럼 그대로 저장되고 동기화되고
///      백업에 실린다. 이건 남이 내 기기를 집었을 때 못 보게 하는 자물쇠이지,
///      디스크 위의 글자를 암호로 바꾸는 일이 아니다(core/lock.dart가 앱
///      전체 잠금에 대해 이미 못 박아 둔 것과 같은 선이다).
///   2. **목록에서는 제목만 보이고 본문 미리보기는 가린다.** 찾을 수는
///      있어야 하되 내용은 안 보여야 한다.
///
/// ## 왜 이 파일이 따로 있나
///
/// 본문이 화면으로 새는 구멍이 넷이다 — 목록 카드, 길게 눌러 뜨는 미리보기,
/// 휴지통 목록, 그리고 검색이 뒤지는 글. 이 판정을 각 자리에 흩어 두면
/// **반드시 하나를 빠뜨린다.** 이 저장소에서 오늘만 세 번 겪은 일이다
/// (제목 갈아엎기, `#{1,3}` vs `#{1,6}`, 애플 전용 문구). 그래서 판정을
/// 순수 함수 넷으로 모으고 시험으로 못 박는다.
///
/// 빠뜨린 자리가 생기면 그건 '조금 덜 예쁜 화면'이 아니라 **잠금이 뚫린
/// 것**이다. 잠금은 뚫리는 순간 기능이 아니라 거짓말이 된다.
library;

/// 검색이 뒤질 글.
///
/// 잠긴 메모는 **본문을 안 내준다.** 안 그러면 본문에만 있는 낱말을 쳐서
/// 그 메모가 목록에 뜨는 것으로 "그 낱말이 거기 있다"를 알아낼 수 있다.
/// 글자를 안 보여 주고도 내용이 새는 길이다.
///
/// 제목·태그·출처는 그대로 둔다. 이 셋은 잠긴 메모라도 목록에 그대로
/// 보이는 것들이라 검색에서 빼 봐야 가려지는 것이 없고, 찾을 길만 막힌다.
String searchHaystack({
  required bool locked,
  required String title,
  required String body,
  required List<String> tags,
  required String source,
}) {
  final t = tags.join(' ');
  return locked ? '$title $t $source' : '$title $body $t $source';
}

/// 목록 카드의 두세 줄짜리 미리보기.
///
/// 빈 줄을 걸러 한 문단으로 이어 붙인다. 줄바꿈을 그대로 두면 짧은 줄
/// 셋으로 석 줄을 다 써 버려서 보이는 글자가 오히려 줄어든다.
String listPreview({required bool locked, required String body}) {
  if (locked) return '';
  return body
      .split('\n')
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .join('  ');
}

/// 길게 눌러 뜨는 미리보기 카드의 본문. 줄바꿈을 지킨다.
String peekBody({required bool locked, required String body}) =>
    locked ? '' : body.trim();

/// 제목이 비었을 때 목록에 무엇을 쓸 것인가.
///
/// 여태 본문 첫 줄을 제목 자리에 올려 왔다. 잠긴 메모에서 그러면 **제목
/// 줄로 본문이 샌다** — 가장 놓치기 쉬운 구멍이라 여기 따로 둔다.
/// 잠긴 메모는 제목이 없으면 빈 문자열을 돌려주고, 부르는 쪽이 '제목 없음'을
/// 쓴다.
///
/// 돌려주는 것은 **첫 줄 하나**다. 목록 카드는 예부터 본문을 한 줄로 이은
/// 것을 제목 자리에 썼는데(한 줄로 잘리니 그래도 됐다) 그건 그 자리의
/// 사정이고, '제목 줄'이라는 이름이 뜻하는 것은 첫 줄이다.
String listTitle({
  required bool locked,
  required String title,
  required String body,
}) {
  final t = title.trim();
  if (t.isNotEmpty) return t;
  if (locked) return '';
  return body
      .split('\n')
      .map((x) => x.trim())
      .firstWhere((x) => x.isNotEmpty, orElse: () => '');
}
