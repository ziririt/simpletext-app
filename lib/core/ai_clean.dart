/// AI 편집이 돌려준 글에서 HTML 을 걷어 우리 표기로 되돌린다.
///
/// 2026-09-19 소유자 신고 — "'소제목 위는 공백 2줄, 아래는 1줄, 폰트는 제목3으로'
/// 하고 시키면 `<h3 style="font-family: 제목3;">심리 지표</h3>` 처럼 태그가 그대로
/// 노출된다. 매우 불편하다."
///
/// 까닭은 둘이었다. 첫째, 모델에게 **이 노트가 무슨 표기로 쓰였는지** 말해 주지
/// 않았다. '제목3'이라는 말을 들은 모델은 웹 문서라고 짐작하고 h3 를 썼다. 둘째,
/// 돌아온 글을 그대로 본문에 꽂았다. 모델은 시킨 대로 안 할 때가 있고, 그 몫은
/// 받는 쪽이 져야 한다.
///
/// 첫째는 main.dart 의 _aiSys 가 고쳤다(표기를 알려 준다). 여기는 둘째 — 그래도
/// 태그가 오면 걷는다. 규칙은 단순하다.
///
///   `<h1>~<h3>`          → 줄 앞에 `# ` `## ` `### `  (우리 제목 표기)
///   `<h4>~<h6>`          → `### ` (우리에겐 셋까지밖에 없다)
///   `<li>`               → `- `
///   `<br>` `<p>` `<div>` → 줄바꿈
///   `<blockquote>`       → `> `
///   `<code>` `<pre>`     → 안의 글만
///   그 밖의 모든 태그     → 지운다(글은 남긴다)
///   `&amp;` `&lt;` 따위  → 원래 글자
///
/// 태그가 하나도 없으면 손대지 않는다 — 부등호를 쓴 보통 글(`a < b`)을 건드리지
/// 않기 위해서다. '태그'는 `<이름 ...>` 꼴에 이름이 진짜 HTML 요소 이름일 때만이다.
library;

/// HTML 요소 이름. 이 밖의 `<...>` 는 태그로 보지 않는다.
const Set<String> _tags = {
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'div', 'span', 'br', 'hr',
  'b', 'strong', 'i', 'em', 'u', 's', 'strike', 'del', 'ins', 'mark', 'small',
  'sub', 'sup', 'code', 'pre', 'blockquote', 'ul', 'ol', 'li', 'a', 'font',
  'table', 'thead', 'tbody', 'tr', 'td', 'th', 'html', 'body', 'head', 'style',
  'section', 'article', 'header', 'footer', 'main', 'nav', 'img',
};

final RegExp _tagRe = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9]*)\b[^<>]*?(/?)>');

/// 글에 HTML 태그가 있는가(위 목록의 요소 이름일 때만).
bool hasHtmlTags(String s) =>
    _tagRe.allMatches(s).any((m) => _tags.contains(m.group(2)!.toLowerCase()));

/// HTML 을 걷어 우리 표기로. 태그가 없으면 그대로 돌려준다.
String stripHtmlToNote(String s) {
  if (!hasHtmlTags(s)) return s;
  var out = s;
  // <style>…</style> 과 <head>…</head> 는 통째로 버린다 — 글이 아니다.
  out = out.replaceAll(
    RegExp(r'<(style|head|script)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false),
    '',
  );
  // 줄을 여는 태그 앞과 닫는 태그 뒤에는 줄바꿈이 있어야 하는데, 이미 있으면
  // 더 넣지 않는다 — 넣으면 모델이 지킨 빈 줄이 두 배가 된다(시험이 잡았다).
  String open(String mark) => '\u0001$mark';
  const close = '\u0002';
  // 제목
  out = out.replaceAllMapped(
    RegExp(r'<h([1-6])\b[^>]*>\s*', caseSensitive: false),
    (m) {
      final n = int.parse(m.group(1)!);
      return open('${'#' * (n > 3 ? 3 : n)} ');
    },
  );
  out = out.replaceAll(RegExp(r'\s*</h[1-6]\s*>', caseSensitive: false), close);
  // 목록·인용
  out = out.replaceAllMapped(
      RegExp(r'<li\b[^>]*>\s*', caseSensitive: false), (_) => open('- '));
  out = out.replaceAll(RegExp(r'\s*</li\s*>', caseSensitive: false), close);
  out = out.replaceAllMapped(
      RegExp(r'<blockquote\b[^>]*>\s*', caseSensitive: false), (_) => open('> '));
  out = out.replaceAll(
      RegExp(r'\s*</blockquote\s*>', caseSensitive: false), close);
  // 줄을 가르는 것들
  out = out.replaceAll(RegExp(r'<br\s*/?>|<hr\s*/?>', caseSensitive: false), '\n');
  out = out.replaceAllMapped(
      RegExp(r'<(p|div|ul|ol|tr)\b[^>]*>', caseSensitive: false), (_) => open(''));
  out = out.replaceAll(
      RegExp(r'</(p|div|ul|ol|tr)\s*>', caseSensitive: false), close);
  out = out.replaceAll(RegExp(r'</t[dh]\s*>', caseSensitive: false), '  ');
  // 표지를 줄바꿈으로 — 이미 줄 첫머리·줄 끝이면 넣지 않는다.
  out = out.replaceAllMapped(RegExp(r'\u0001'), (m) {
    final i = m.start;
    final prev = i == 0 ? '\n' : out[i - 1];
    return (prev == '\n' || prev == '\u0001') ? '' : '\n';
  });
  out = out.replaceAllMapped(RegExp(r'\u0002'), (m) {
    final i = m.end;
    final next = i >= out.length ? '\n' : out[i];
    return (next == '\n' || next == '\u0002') ? '' : '\n';
  });
  // 나머지 태그는 지운다 — 목록에 있는 이름만.
  out = out.replaceAllMapped(_tagRe, (m) =>
      _tags.contains(m.group(2)!.toLowerCase()) ? '' : m.group(0)!);
  // 글자 참조
  out = out
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
  // 줄마다 끝 공백을 걷고, 빈 줄이 넷 넘게 이어지면 셋으로 줄인다
  // (사람이 "위 2줄, 아래 1줄"처럼 시킨 여백은 살려야 하므로 더 줄이지 않는다).
  out = out.split('\n').map((l) => l.trimRight()).join('\n');
  out = out.replaceAll(RegExp(r'\n{5,}'), '\n\n\n\n');
  return out.trim();
}
