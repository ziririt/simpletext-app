/// 복사해 온 HTML 조각의 **지문만** 뽑는다. 글은 한 글자도 안 담는다.
///
/// ## 왜 이것이 필요한가 (2026-08-27 밤)
///
/// 소유자가 다섯 서비스에서 복사해 메일 창에 붙여넣고 사진을 보내 줬다.
/// 거기서 갈렸다.
///
///   제미나이   서식이 살아 있다 — 굵게, 겹친 글머리, 들여쓰기. HTML 이 실린다.
///   챗지피티   서식이 살아 있다 — 소제목 크기가 다르다. HTML 이 실린다.
///   그록       맨 글자다. ## 과 ** 가 글자 그대로 보인다. HTML 이 안 실린다.
///
/// 즉 제미나이와 챗지피티는 잡을 수 있는데 **내 지문표가 틀렸을 뿐**이다.
/// 그런데 무엇이 맞는지는 짐작으로 알 수 없다. 실제로 무엇이 오는지 봐야
/// 한다 — 설계 문서가 "이 실험이 기능의 성패를 가른다"고 한 그 실험이다.
///
/// ## 무엇을 담고 무엇을 안 담나
///
/// **담는 것** — 클래스 이름, id, data-* 속성 이름, 주소의 호스트.
/// 이것들은 서비스가 제 화면을 그리려고 박아 둔 것이라 사람의 글이 아니다.
///
/// **안 담는 것** — 글자. 한 글자도 안 담는다. 이 값은 기기 안에만 남는
/// 실험 기록이지만, 여기에 사람의 글이 섞이면 그건 사고다.
/// ## 2판 (2026-08-27 23:10) — 태그 뼈대와 속성 이름을 더 담는다
///
/// 1판으로 잰 결과가 이렇게 갈렸다.
///
///   제미나이   markdown-main-panel, md-content, data-path-to-node …  잡았다.
///   챗지피티   plain:4000 — 앞 4000자에 class/id/data-* 가 **하나도 없다.**
///   그록       빈 값 — 클립보드에 HTML 자체가 안 실린다.
///
/// 챗지피티가 빈손으로 보인 것은 HTML 이 없어서가 아니라 **내가 세 가지
/// 속성만 보고 있었기 때문**이다. 속성이 벗겨진 깨끗한 HTML 이라면 남는
/// 단서는 태그의 생김새와 나머지 속성 이름뿐이다. 그래서 2판은
///
///   t:  나온 태그 이름을 순서대로 (처음 14개)
///   a:  나온 속성 이름 모두 (class/id/data-* 는 이미 위에서 값까지 봤다)
///
/// 를 더 담는다. 여전히 **글자는 한 자도 안 담는다.**
String captureSignature(String? capture, {int max = 700}) {
  if (capture == null || capture.isEmpty) return '';
  final seen = <String>{};
  void add(String s) {
    final t = s.trim();
    if (t.isEmpty || t.length > 60) return;
    seen.add(t);
  }

  for (final m in RegExp(r'class="([^"]{1,300})"').allMatches(capture)) {
    for (final c in m.group(1)!.split(RegExp(r'\s+'))) {
      add(c);
    }
  }
  for (final m in RegExp(r'\sid="([^"]{1,60})"').allMatches(capture)) {
    add('#${m.group(1)}');
  }
  for (final m in RegExp(r'\s(data-[a-z0-9-]{1,40})\s*=').allMatches(capture)) {
    add(m.group(1)!);
  }
  for (final m in RegExp(r'https?://([a-z0-9.-]{1,60})', caseSensitive: false)
      .allMatches(capture)) {
    add('@${m.group(1)!.toLowerCase()}');
  }

  // 태그 뼈대 — 속성이 벗겨진 HTML 에서는 이것만 남는다.
  final tags = <String>[];
  for (final m in RegExp(r'<([a-zA-Z][a-zA-Z0-9]{0,12})[\s>/]').allMatches(capture)) {
    final t = m.group(1)!.toLowerCase();
    if (!tags.contains(t)) tags.add(t);
    if (tags.length >= 14) break;
  }

  // 속성 이름 — 값은 안 본다. 값에는 사람의 글이 들어갈 수 있다.
  final attrs = <String>{};
  for (final m in RegExp(r'\s([a-zA-Z][a-zA-Z0-9-]{0,24})\s*=\s*[\x22\x27]')
      .allMatches(capture)) {
    attrs.add(m.group(1)!.toLowerCase());
  }

  final parts = <String>[];
  if (seen.isNotEmpty) parts.add(seen.join(' '));
  if (tags.isNotEmpty) parts.add('t:${tags.join(',')}');
  if (attrs.isNotEmpty) {
    final a = attrs.toList()..sort();
    parts.add('a:${a.join(',')}');
  }
  // 아무 표식도 없으면 '맨 글자였다'는 사실 자체가 정보다.
  if (parts.isEmpty) return 'plain:${capture.length}';
  final out = parts.join(' | ');
  return out.length > max ? out.substring(0, max) : out;
}
