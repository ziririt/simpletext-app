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
/// 빗금(/)은 여기 없다. **'폴더 안의 폴더'를 뜻하는 글자**로 쓰기 때문이다
/// (2026-08-18). 나머지는 파일 이름에 못 쓰는 것들이라 공백으로 바꾼다.
final RegExp _badChars = RegExp(r'[\\:*?"<>|\x00-\x1f]');
final RegExp _spaces = RegExp(r'\s+');

/// 폴더 이름의 최대 길이. 이보다 길면 목록에서 줄임표만 보인다.
/// 빗금으로 이은 전체 길이를 센다.
const int kFolderNameMax = 40;

/// 몇 겹까지 허용하나.
///
/// 셋이면 '투자/미국주식/테슬라'다. 그보다 깊어지면 목록에서 이름이
/// 줄임표뿐이 되고, 깊이로 얻는 것보다 잃는 것이 많아진다. 애플 메모도
/// 사실상 이 언저리에서 쓰인다.
const int kFolderDepthMax = 3;

/// 폴더 이름을 다듬는다.
///
/// 빈 이름은 '폴더 없음'과 같은 뜻이라 빈 문자열로 돌려준다.
String normalizeFolder(String raw) {
  final cleaned = raw.replaceAll(_badChars, ' ');
  final parts = <String>[];
  for (final seg in cleaned.split('/')) {
    var t = seg.replaceAll(_spaces, ' ').trim();
    // '.'과 '..'은 파일 시스템에서 자기 자신과 부모를 뜻한다. 폴더 이름으로
    // 쓰면 내보내기가 엉뚱한 데를 가리킨다.
    if (t == '.' || t == '..') t = '';
    if (t.isEmpty) continue;
    parts.add(t);
    if (parts.length >= kFolderDepthMax) break;
  }
  var s = parts.join('/');
  if (s.length > kFolderNameMax) {
    s = s.substring(0, kFolderNameMax);
    // 자르다 빗금에서 끊기면 빈 칸이 하나 생긴다.
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    s = s.trim();
  }
  return s;
}

/// 이름을 겹으로 나눈다. 화면이 나무로 그릴 날을 위한 것.
List<String> folderParts(String name) {
  final n = normalizeFolder(name);
  return n.isEmpty ? const [] : n.split('/');
}

/// 목록에 보일 짧은 이름 — 마지막 겹만.
String folderLeaf(String name) {
  final p = folderParts(name);
  return p.isEmpty ? '' : p.last;
}

/// 파일 이름에 넣을 때 쓴다. 빗금은 파일 이름에 못 들어간다.
String folderFileName(String name) => normalizeFolder(name).replaceAll('/', ' - ');

/// 화면에 보여 줄 폴더 목록.
///
/// [used]는 메모들이 실제로 쓰고 있는 이름, [kept]는 사용자가 만들어 두었지만
/// 아직 메모가 없는 이름이다.
///
/// **둘을 합치는 이유**가 이 함수의 전부다. 만들어 둔 목록만 보면 다른
/// 기기에서 만든 폴더가 안 보이고(설정은 늦게 고친 쪽이 통째로 이긴다),
/// 쓰이는 이름만 보면 방금 만든 빈 폴더가 눈앞에서 사라진다. 둘 다 나쁘다.
///
/// **차례는 사람이 정한다** (2026-08-18 소유자 지시로 바뀐 대목).
///
/// 전에는 통째로 사전 순이었다. 사전 순은 아무도 안 정한 차례라서 늘
/// 공평해 보이지만, 열 개가 넘어가면 **자주 쓰는 폴더가 ㅎ으로 시작한다는
/// 이유만으로 맨 끝에 간다.** 폴더를 만든 사람이 그 차례를 알고 있다.
///
/// 그래서 [kept]의 차례를 그대로 쓴다. [kept]에 없는데 메모가 쓰고 있는
/// 이름(다른 기기에서 만들었거나 불러오기로 들어온 것)만 사전 순으로 뒤에
/// 붙인다 — 그것들은 아직 아무도 자리를 안 정해 준 것들이다.
List<String> folderNames(Iterable<String> used, Iterable<String> kept) {
  final out = <String>[];
  final seen = <String>{};
  void add(String raw) {
    final n = normalizeFolder(raw);
    if (n.isEmpty) return;
    if (seen.add(n.toLowerCase())) out.add(n);
  }

  for (final s in kept) {
    add(s);
  }

  final extra = <String>[];
  final extraSeen = <String>{};
  for (final s in used) {
    final n = normalizeFolder(s);
    if (n.isEmpty || seen.contains(n.toLowerCase())) continue;
    if (extraSeen.add(n.toLowerCase())) extra.add(n);
  }
  extra.sort((a, b) {
    final r = a.toLowerCase().compareTo(b.toLowerCase());
    return r != 0 ? r : a.compareTo(b);
  });
  for (final s in extra) {
    add(s);
  }
  return out;
}

/// 끌어 놓은 결과의 차례.
///
/// 화면에서 떼어 놓는 이유: ReorderableListView 의 [newIndex]는 **끌던
/// 것을 아직 뽑지 않은 상태**의 자리라서, 아래로 내릴 때 하나를 빼 줘야
/// 한다. 이 한 줄을 화면 코드 안에 두면 반드시 한 번은 틀린다.
List<String> reorderFolders(List<String> list, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= list.length) return List<String>.from(list);
  final out = List<String>.from(list);
  var to = newIndex;
  if (to > oldIndex) to -= 1;
  if (to < 0) to = 0;
  if (to > out.length - 1) to = out.length - 1;
  out.insert(to, out.removeAt(oldIndex));
  return out;
}

/// 이 이름을 새로 만들 수 있는가. 이미 있으면(대소문자 무시) 안 된다.
bool canAddFolder(String raw, Iterable<String> existing) {
  final n = normalizeFolder(raw);
  if (n.isEmpty) return false;
  final low = n.toLowerCase();
  return !existing.any((e) => normalizeFolder(e).toLowerCase() == low);
}
