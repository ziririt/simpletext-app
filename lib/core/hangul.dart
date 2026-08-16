/// 한글 초성 검색 — 순수 함수. 화면·저장 코드를 넣지 않는다.
///
/// 2026-08-16. 한국 사용자에게 초성 검색은 '있으면 좋은 기능'이 아니라
/// **기본 기대치**다. "ㅌㅅㄹ"을 치면 "테슬라"가 나와야 한다. 세계적인
/// 노트앱들이 이걸 전부 놓치고 있다 — 옵시디언조차 서드파티 플러그인을
/// 깔아야 된다. 국내에서는 이것 하나로 체감이 갈린다.
///
/// ## 어떻게 매치하나
///
/// 질의에 자음(ㄱ~ㅎ)이 하나도 없으면 평범한 부분일치로 간다. 이게 대부분의
/// 경우이고 훨씬 빠르다.
///
/// 자음이 섞여 있으면 글자 단위로 비교하되, 자음 한 글자는 **그 자음을
/// 초성으로 갖는 음절**과도 맞는 것으로 친다. 그래서 "ㅌㅅㄹ"이 "테슬라"에
/// 맞고, "테ㅅㄹ"처럼 섞어 쳐도 맞는다.
///
/// ## 일부러 안 한 것
///
/// 중성·종성 분해는 안 한다. "ㅌㅔㅅㅡㄹㅏ" 같은 입력은 실제로 아무도 치지
/// 않는다. 넣으면 코드만 두 배가 되고 오탐이 늘어난다.
library;

/// 초성 19자. 순서가 유니코드 계산식과 맞아야 한다 — 바꾸지 말 것.
const String kChoseong = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';

const int _syllableStart = 0xAC00; // '가'
const int _syllableEnd = 0xD7A3; // '힣'

/// 중성 21 × 종성 28 = 588. 음절 블록에서 초성 하나가 차지하는 칸 수다.
const int _blockPerChoseong = 588;

/// 한글 음절 한 글자의 초성. 음절이 아니면 null.
///
/// '테' → 'ㅌ', 'a' → null, 'ㅌ'(자음 자체) → null(이미 초성이라 변환 불필요).
String? choseongOf(String ch) {
  if (ch.isEmpty) return null;
  final c = ch.codeUnitAt(0);
  if (c < _syllableStart || c > _syllableEnd) return null;
  return kChoseong[(c - _syllableStart) ~/ _blockPerChoseong];
}

/// 초성으로 쓸 수 있는 자음인가.
///
/// ㄳ·ㄵ 같은 겹받침 자모는 초성이 될 수 없으므로 여기서 false다. 그런
/// 글자는 그냥 글자 그대로 비교된다.
bool isChoseongJamo(String ch) => ch.isNotEmpty && kChoseong.contains(ch);

/// 질의에 초성 자음이 섞여 있는가. 있으면 느린 경로를 타야 한다.
bool hasChoseongJamo(String query) {
  for (var i = 0; i < query.length; i++) {
    if (isChoseongJamo(query[i])) return true;
  }
  return false;
}

/// 문자열 전체의 초성 뽑기. 디버깅과 테스트용이고, 검색은 이걸 안 쓴다
/// (미리 만들어 두면 메모를 고칠 때마다 다시 만들어야 해서 오히려 손해다).
String choseongLine(String text) {
  final b = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    b.write(choseongOf(text[i]) ?? text[i]);
  }
  return b.toString();
}

/// [text] 안에 [query]가 들어 있는가 — 초성을 감안해서.
///
/// 대소문자는 무시한다. 빈 질의는 언제나 참이다(필터를 안 건 것과 같다).
bool hangulContains(String text, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;

  final lowT = text.toLowerCase();
  final lowQ = q.toLowerCase();

  // 빠른 길. 자음이 없으면 그냥 부분일치다 — 메모 수천 개를 훑을 때
  // 이 분기가 있고 없고가 체감을 가른다.
  if (!hasChoseongJamo(lowQ)) return lowT.contains(lowQ);

  final n = lowT.length;
  final m = lowQ.length;
  if (m > n) return false;

  for (var i = 0; i + m <= n; i++) {
    var ok = true;
    for (var k = 0; k < m; k++) {
      final qc = lowQ[k];
      final tc = lowT[i + k];
      if (tc == qc) continue;
      if (isChoseongJamo(qc) && choseongOf(tc) == qc) continue;
      ok = false;
      break;
    }
    if (ok) return true;
  }
  return false;
}
