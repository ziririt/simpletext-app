/// 텍스트 파일 가져오기 규칙 — 순수 함수. 파일 고르기·저장 코드를 넣지 않는다.
///
/// 2026-08-16 소유자 요청: "다른 LLM에서 내보내기한 md 파일을 참고로 붙일 수
/// 있으면 좋겠다. 처음부터 텍스트 파일 불러오기도 되면 어떨까?"
///
/// ## 왜 '첨부'가 아니라 '가져오기'인가
///
/// 우리 앱에서 텍스트 파일의 값어치는 그 안의 **글**이다. 파일을 통째로
/// 덩어리째 붙여 두면 검색도 안 되고, 정리도 못 하고, AI 편집에도 못 넣는다.
/// 그리고 **동기화도 안 된다** — 지금 아이클라우드로 오가는 것은 메모 json
/// 뿐이고, 안드로이드에는 동기화 자체가 없다.
///
/// 글로 들여놓으면 그 순간부터 검색·정리·AI 편집·동기화가 전부 공짜로 된다.
/// 그래서 가져오기를 먼저 만든다.
///
/// ## 마크다운을 안 벗기는 이유
///
/// 가져올 때 자동으로 정리하지 않는다. 원본을 그대로 들여놓고, 정리는
/// 사용자가 '정리'를 눌렀을 때 한다. 들어오자마자 손대면 원본이 사라지고,
/// 그건 되돌릴 수 없는 종류의 손실이다.
library;

/// 우리가 열어 볼 만한 확장자.
///
/// 바이너리를 열면 글자가 깨진 채로 메모가 하나 생긴다 — 사용자는 그걸
/// 버그로 읽는다. 그래서 목록을 좁게 잡는다.
const List<String> kTextExtensions = [
  'md', 'markdown', 'mdown', 'txt', 'text', 'csv', 'tsv',
  'json', 'log', 'rtf', 'org', 'rst', 'yaml', 'yml',
];

bool isTextFileName(String name) {
  final i = name.lastIndexOf('.');
  if (i < 0 || i == name.length - 1) return false;
  return kTextExtensions.contains(name.substring(i + 1).toLowerCase());
}

/// 파일 이름에서 확장자를 뗀 것. 제목으로 쓴다.
String titleFromFileName(String name) {
  final i = name.lastIndexOf('.');
  final base = i > 0 ? name.substring(0, i) : name;
  final t = base.trim();
  return t.isEmpty ? name : t;
}

/// 마크다운 앞머리(YAML front matter)를 떼어 낸다.
///
/// 우리가 내보낸 파일에도, 옵시디언·정적 사이트가 만든 파일에도 붙어 있다.
/// 그대로 두면 본문 맨 위에 `---`와 메타데이터가 그대로 보여서 흉하다.
/// 뗀 값 중 title/tags/source는 메모에 옮겨 담는다.
class ParsedText {
  final String title;
  final String body;
  final List<String> tags;
  final String source;
  const ParsedText({
    required this.title,
    required this.body,
    this.tags = const [],
    this.source = '',
  });
}

ParsedText parseTextFile(String fileName, String content) {
  var text = content.replaceAll('\r\n', '\n');
  var title = '';
  var tags = <String>[];
  var source = '';

  if (text.startsWith('---\n')) {
    final end = text.indexOf('\n---', 4);
    if (end > 0) {
      final head = text.substring(4, end);
      text = text.substring(end + 4).replaceFirst(RegExp(r'^\n+'), '');
      for (final line in head.split('\n')) {
        final c = line.indexOf(':');
        if (c <= 0) continue;
        final k = line.substring(0, c).trim().toLowerCase();
        final v = _unquote(line.substring(c + 1).trim());
        if (k == 'title') {
          title = v;
        } else if (k == 'source') {
          source = v;
        } else if (k == 'tags') {
          tags = _parseTagList(v);
        }
      }
    }
  }

  // 앞머리에 제목이 없으면 맨 위 `# 제목`을 쓴다. 있으면 본문에서 뗀다 —
  // 제목이 두 번 보이는 것을 막기 위해서다.
  final h1 = RegExp(r'^#\s+(.+)$', multiLine: false);
  final firstLine = text.split('\n').first;
  final m = h1.firstMatch(firstLine);
  if (m != null) {
    if (title.isEmpty) title = m.group(1)!.trim();
    text = text.substring(firstLine.length).replaceFirst(RegExp(r'^\n+'), '');
  }

  if (title.isEmpty) title = titleFromFileName(fileName);
  return ParsedText(
      title: title, body: text.trimRight(), tags: tags, source: source);
}

String _unquote(String v) {
  if (v.length >= 2 &&
      ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'")))) {
    return v
        .substring(1, v.length - 1)
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }
  return v;
}

/// `[a, b]` 또는 `a, b` 둘 다 받는다. 도구마다 쓰는 모양이 달라서다.
List<String> _parseTagList(String v) {
  var s = v.trim();
  if (s.startsWith('[') && s.endsWith(']')) {
    s = s.substring(1, s.length - 1);
  }
  return s
      .split(',')
      .map((e) => _unquote(e.trim()))
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 지금 메모 끝에 파일을 이어 붙일 때 쓸 문단.
///
/// 어디서 온 글인지 한 줄 남긴다. 안 남기면 한 달 뒤에 자기가 쓴 글과
/// 가져온 글이 구분되지 않는다.
String appendBlock(String fileName, String content) {
  final body = content.replaceAll('\r\n', '\n').trimRight();
  return '\n\n--- $fileName ---\n\n$body\n';
}
