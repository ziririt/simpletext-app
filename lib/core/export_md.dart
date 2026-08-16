/// 내보내기 형식 — 순수 함수. 파일·공유 코드를 넣지 않는다.
///
/// 2026-08-16. 조사에서 나온 것: **"갇힌다"는 인상은 이탈 사유다.** 2023년
/// 에버노트 가격 인상 이후로 "이 앱에서 내 글을 꺼낼 수 있나"가 리뷰의 필수
/// 체크 항목이 됐다. 한국은 더하다 — 네이버 메모 종료를 겪은 사용자들이
/// "언제 없어질지 모르는 걸 어떻게 믿고 쓰나"라고 말한다.
///
/// 그래서 내보내기는 기능이 아니라 **약속**이다. 마크다운으로 나가면 애플
/// 메모(iOS 26부터 마크다운 지원), 옵시디언, 노션 어디로든 들어간다.
library;

/// 메모 하나를 마크다운 한 장으로.
///
/// 앞머리(front matter)를 YAML로 붙인다. 옵시디언·헤드리스 CMS·정적
/// 사이트가 전부 이 관습을 읽는다 — 우리만의 형식을 만들지 않는다.
String noteToMarkdown({
  required String title,
  required String body,
  required List<String> tags,
  required String source,
  required int createdAt,
  required int updatedAt,
}) {
  final b = StringBuffer();
  b.writeln('---');
  final t = title.trim();
  if (t.isNotEmpty) b.writeln('title: ${_yamlValue(t)}');
  if (tags.isNotEmpty) {
    b.writeln('tags: [${tags.map(_yamlValue).join(', ')}]');
  }
  if (source.trim().isNotEmpty) b.writeln('source: ${_yamlValue(source)}');
  b.writeln('created: ${_iso(createdAt)}');
  b.writeln('updated: ${_iso(updatedAt)}');
  b.writeln('---');
  b.writeln();
  if (t.isNotEmpty) {
    b.writeln('# $t');
    b.writeln();
  }
  b.write(body);
  if (!body.endsWith('\n')) b.writeln();
  return b.toString();
}

/// YAML 값 감싸기. 콜론·따옴표가 들어가면 통째로 깨지므로 항상 감싼다.
String _yamlValue(String v) => '"${v.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';

String _iso(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();

/// 파일 이름으로 쓸 수 있게 다듬는다.
///
/// 윈도우가 가장 까다로워서 그 기준에 맞춘다(`\ / : * ? " < > |` 금지,
/// 끝의 점과 공백 금지). 맥·리눅스는 이 규칙을 통과하면 자동으로 안전하다.
/// 파일 하나가 안 열리는 것보다 이름이 조금 못생긴 게 낫다.
String safeFileName(String title, {String fallback = 'note', int maxLen = 60}) {
  var s = title.trim();
  // 줄바꿈·탭은 공백으로
  s = s.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  // 금지 문자
  s = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  // 제어 문자
  s = s.replaceAll(RegExp(r'[\x00-\x1f]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length > maxLen) s = s.substring(0, maxLen).trim();
  // 끝의 점·공백은 윈도우에서 파일을 못 만들게 한다
  s = s.replaceAll(RegExp(r'[. ]+$'), '');
  if (s.isEmpty) return fallback;
  // 윈도우 예약어. 확장자가 붙어도 못 쓴다.
  const reserved = {
    'con', 'prn', 'aux', 'nul',
    'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
    'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
  };
  if (reserved.contains(s.toLowerCase())) return '$s-';
  return s;
}

/// 같은 이름이 이미 있으면 뒤에 번호를 붙인다.
///
/// 제목 없는 메모가 여럿이면 파일 이름이 전부 같아진다. 압축 파일 안에서
/// 이름이 겹치면 푸는 쪽이 조용히 하나만 남기는 경우가 있다 — 내보냈는데
/// 메모가 사라지는, 가장 나쁜 종류의 사고다.
String uniqueName(String base, Set<String> used) {
  if (!used.contains(base)) {
    used.add(base);
    return base;
  }
  var i = 2;
  while (used.contains('$base-$i')) {
    i++;
  }
  final out = '$base-$i';
  used.add(out);
  return out;
}
