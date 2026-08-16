/// 폴더 이름 규칙 — 순수 함수. 화면 코드를 넣지 않는다.
///
/// 2026-08-17. 밤샘 목록 3번.
///
/// 태그가 이미 있는데 폴더를 또 만드는 이유는, 둘이 다른 물음에 답하기
/// 때문이다. 태그는 "이 글이 무엇에 관한 것인가"이고 폴더는 "이 글을
/// 어디에 두었나"다. 하나의 글에 태그는 여럿 붙지만 폴더는 하나다.
/// 그래서 태그로는 "다 어디 갔지"가 안 풀린다.
///
/// 규칙을 화면에서 떼어 놓는 이유는 늘 같다. **이름을 다듬는 규칙은 눈으로
/// 보고는 틀린 줄 모른다.** 앞뒤 공백, 가운데 두 칸 공백, 경로에 못 쓰는
/// 글자, 너무 긴 이름 — 어느 하나가 어긋나도 화면에서는 그럴듯해 보이고,
/// 나중에 파일로 내보낼 때야 터진다.
library;

/// 폴더 이름에 쓸 수 없는 글자.
///
/// 폴더 이름은 내보내기에서 **파일 이름의 일부가 된다.** 여기서 안 막으면
/// 맥에서는 되고 윈도우에서는 안 되는 이름이 생긴다. 막는 쪽이 싸다.
final RegExp _badChars = RegExp(r'[/\\:*?"<>|\x00-\x1f]');
final RegExp _spaces = RegExp(r'\s+');

/// 폴더 이름의 최대 길이. 이보다 길면 목록에서 줄임표만 보인다.
const int kFolderNameMax = 40;

/// 폴더 이름을 다듬는다.
///
/// 빈 이름은 '폴더 없음'과 같은 뜻이라 빈 문자열로 돌려준다.
String normalizeFolder(String raw) {
  var s = raw.replaceAll(_badChars, ' ');
  s = s.replaceAll(_spaces, ' ').trim();
  if (s.length > kFolderNameMax) {
    s = s.substring(0, kFolderNameMax).trim();
  }
  // '.'과 '..'은 파일 시스템에서 자기 자신과 부모를 뜻한다. 폴더 이름으로
  // 쓰면 내보내기가 엉뚱한 데를 가리킨다.
  if (s == '.' || s == '..') return '';
  return s;
}

/// 화면에 보여 줄 폴더 목록.
///
/// [used]는 메모들이 실제로 쓰고 있는 이름, [kept]는 사용자가 만들어 두었지만
/// 아직 메모가 없는 이름이다.
///
/// **둘을 합치는 이유**가 이 함수의 전부다. 만들어 둔 목록만 보면 다른
/// 기기에서 만든 폴더가 안 보이고(설정은 늦게 고친 쪽이 통째로 이긴다),
/// 쓰이는 이름만 보면 방금 만든 빈 폴더가 눈앞에서 사라진다. 둘 다 나쁘다.
List<String> folderNames(Iterable<String> used, Iterable<String> kept) {
  final set = <String>{};
  for (final s in [...used, ...kept]) {
    final n = normalizeFolder(s);
    if (n.isNotEmpty) set.add(n);
  }
  final out = set.toList();
  // 대소문자를 무시하고 사전 순. 같으면 원래 글자로 갈라 순서를 고정한다 —
  // 순서가 그때그때 달라지면 목록이 흔들리는 것처럼 보인다.
  out.sort((a, b) {
    final r = a.toLowerCase().compareTo(b.toLowerCase());
    return r != 0 ? r : a.compareTo(b);
  });
  return out;
}

/// 이 이름을 새로 만들 수 있는가. 이미 있으면(대소문자 무시) 안 된다.
bool canAddFolder(String raw, Iterable<String> existing) {
  final n = normalizeFolder(raw);
  if (n.isEmpty) return false;
  final low = n.toLowerCase();
  return !existing.any((e) => normalizeFolder(e).toLowerCase() == low);
}
