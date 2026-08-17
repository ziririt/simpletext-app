/// 줄을 목록으로 만든다 — 구분점 · 대시 · 번호.
///
/// 2026-08-17 소유자 지시 — "제일 필요한 구분점 목록, 대시 목록, 번호 목록
/// 이 3가지가 필요하다. 이것은 블록 안 씌웠을 때도 필요하고, 블록을 씌운
/// 부분도 줄바꿈 되어 있다면 이 3가지 중 하나로 처리해 줘야 한다."
///
/// 화면과 떼어 놓은 이유는 하나다. 이 규칙은 **눈으로 보고는 틀린 줄
/// 모른다.** 빈 줄을 세느냐 안 세느냐, 들여쓰기를 살리느냐, 이미 붙은
/// 표시를 떼느냐 — 어느 하나가 어긋나도 화면에서는 그럴듯해 보인다.
/// 그래서 시험을 쓸 수 있는 자리로 꺼냈다.
library;

/// 목록 종류.
const String kListBullet = 'bullet';
const String kListDash = 'dash';
const String kListNumber = 'number';

/// 줄머리에 이미 붙어 있는 표시.
///
/// 종류를 넓게 잡는다. 붙여넣은 글에는 별표·엔대시·엠대시·번호가 섞여
/// 들어오고, 그걸 안 떼면 '- · 항목'처럼 두 겹이 된다.
final RegExp _mark =
    RegExp(r'^([ \t]*)(?:[•·*+\-–—]|\d+[.)])[ \t]+');

final RegExp _indent = RegExp(r'^[ \t]*');
final RegExp _numHead = RegExp(r'^\d+[.)]$');

/// 한 덩이의 줄들을 [kind] 목록으로 만든다.
///
/// 이미 그 종류로 다 되어 있으면 **뗀다.** 같은 버튼을 다시 누르면
/// 원래대로 돌아온다 — 목록 버튼은 스위치이지 도장이 아니다.
///
/// 빈 줄은 건드리지 않고 번호도 세지 않는다. 빈 줄에 '3.'이 붙으면
/// 그건 목록이 아니라 사고다.
String listify(String block, {required String kind, String bullet = '·'}) {
  final b = bullet.trim().isEmpty ? '·' : bullet.trim();
  final lines = block.split('\n');

  bool already(String line) {
    final m = _mark.firstMatch(line);
    if (m == null) return false;
    final head = line.substring(m.group(1)!.length, m.end).trimRight();
    switch (kind) {
      case kListBullet:
        return head == b;
      case kListDash:
        return head == '-';
      default:
        return _numHead.hasMatch(head);
    }
  }

  final filled = lines.where((s) => s.trim().isNotEmpty);
  final off = filled.isNotEmpty && filled.every(already);

  var n = 0;
  final out = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty) {
      out.add(line);
      continue;
    }
    final m = _mark.firstMatch(line);
    final indent =
        m != null ? m.group(1)! : _indent.firstMatch(line)!.group(0)!;
    final rest =
        m != null ? line.substring(m.end) : line.substring(indent.length);
    if (off) {
      out.add('$indent$rest');
      continue;
    }
    n++;
    final head = switch (kind) {
      kListBullet => '$b ',
      kListDash => '- ',
      _ => '$n. ',
    };
    out.add('$indent$head$rest');
  }
  return out.join('\n');
}

/// 구분점 목록에 쓸 글머리 하나.
///
/// 2026-08-17 소유자 신고 — "'·'는 -와 같은 결과가 나온다. 점 불릿이 안
/// 나오고 말이다."
///
/// 원인은 값을 잘못 빌려 온 것이었다. 구분점 목록 단추가 정리 설정의
/// '글머리 기호'(bulletChar)를 그대로 가져다 썼는데, 그 기본값이 '-'다.
/// 그래서 구분점 목록과 대시 목록이 똑같은 것을 만들었다. 설정에서
/// '그대로 두기'(keep)를 골라 뒀다면 줄머리에 'keep '이라고 적히기까지
/// 했을 것이다.
///
/// 두 설정은 뜻이 다르다. bulletChar는 "남이 쓴 글을 정리할 때 글머리를
/// 무엇으로 통일할까"이고, 이 단추는 "지금 이 줄들을 점 목록으로 바꿔라"다.
/// 단추에 그려진 점이 곧 약속이므로, 점이 아닌 값이 들어오면 점으로
/// 되돌린다. 점의 모양(·•◦)까지는 설정을 따른다 — 그건 취향이고, 어느
/// 것을 골라도 약속은 지켜진다.
String dotBullet(String setting) =>
    const ['·', '•', '◦', '∙', '‧'].contains(setting) ? setting : '·';

/// [at]가 가리키는 자리를 줄 단위로 넓힌 구간.
///
/// 줄 가운데를 골라도 그 줄 전체가 대상이다. 목록은 줄 단위의 것이지
/// 글자 단위의 것이 아니다 — 반쪽만 목록이 되는 일은 아무도 원하지 않는다.
(int, int) lineSpan(String text, int start, int end) {
  final a = start > 0 ? text.lastIndexOf('\n', start - 1) + 1 : 0;
  var e = text.indexOf('\n', end);
  if (e < 0) e = text.length;
  if (e < a) e = a;
  return (a, e);
}
