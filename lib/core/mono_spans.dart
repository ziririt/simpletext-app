/// 본문에서 "칸을 맞춰야 하는 구간"만 찾아낸다.
///
/// 2026-08-14 소유자 요청: "표 부분만 등폭 폰트 쓰고 기본 텍스트는 기기의 기본
/// 시스템 폰트 쓸 수 있으면 좋겠다."
///
/// 왜 필요한가:
///   표는 스페이스로 칸을 맞추므로 글자 폭이 일정한 글꼴(등폭)이라야 줄이 맞는다.
///   반대로 줄글은 등폭으로 보면 읽기 불편하다 — 한글 문서는 특히 그렇다.
///   그래서 편집기 전체가 아니라 **표·코드 구간만** 등폭으로 그린다.
///
/// 이 파일은 화면(Flutter)을 모른다. 순수하게 "몇 번째 글자부터 몇 번째 글자까지가
/// 등폭 구간인가"만 계산한다. 그래야 테스트로 지킬 수 있다.
library;

/// 등폭으로 그려야 하는 구간. [start]는 포함, [end]는 미포함(문자 인덱스).
class MonoSpan {
  const MonoSpan(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is MonoSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'MonoSpan($start, $end)';
}

/// 코드 블록 울타리 (``` 또는 ~~~)
final RegExp _fence = RegExp(r'^\s*(```|~~~)');

/// 정렬 표의 머리글 아래 가로 구분선. 엔진이 찍는 그 줄이다.
final RegExp _rule = RegExp(r'^─{3,}\s*$');

/// 칸이 둘 이상이라는 표시 — 공백 2칸 이상이 열 구분자다(엔진과 같은 규칙).
final RegExp _twoSpaces = RegExp(r'\S {2,}\S');

/// [text]에서 등폭으로 그려야 하는 구간을 앞에서부터 순서대로 돌려준다.
///
/// 대상은 세 가지다.
///   1. 코드 블록 (``` … ```)
///   2. 정렬 표 — 머리글 + 가로 구분선 + 빈 줄 전까지의 행들
///   3. 아직 정리하지 않은 표 — 세로줄(|)이나 탭으로 구분된 줄이 2줄 이상 이어질 때
///
/// 3번을 넣는 이유: 붙여넣은 직후, 아직 "정리"를 누르기 전에도 표는 표로 보여야
/// 사용자가 무엇을 붙여넣었는지 알 수 있다.
List<MonoSpan> monoSpans(String text) {
  if (text.isEmpty) return const [];
  final lines = text.split('\n');
  final mono = List<bool>.filled(lines.length, false);

  // 1) 코드 블록 — 여는 울타리부터 닫는 울타리까지 포함.
  //    닫히지 않은 채 끝나면(입력 중일 수 있다) 그 뒤 전부를 코드로 보지 않는다.
  var fenceStart = -1;
  for (var i = 0; i < lines.length; i++) {
    if (!_fence.hasMatch(lines[i])) continue;
    if (fenceStart < 0) {
      fenceStart = i;
    } else {
      for (var j = fenceStart; j <= i; j++) {
        mono[j] = true;
      }
      fenceStart = -1;
    }
  }

  // 2) 정렬 표 — 구분선을 기준으로 위로 한 줄(머리글), 아래로 빈 줄 전까지.
  for (var i = 0; i < lines.length; i++) {
    if (mono[i] || !_rule.hasMatch(lines[i])) continue;
    // 장식용 가로선과 구분한다. 표라면 바로 위가 머리글(열이 둘 이상)이고
    // 바로 아래에 행이 하나는 있어야 한다. 엔진의 표 탐지와 같은 기준이다.
    if (i == 0 || i + 1 >= lines.length) continue;
    if (!_twoSpaces.hasMatch(lines[i - 1])) continue;
    if (lines[i + 1].trim().isEmpty) continue;
    mono[i - 1] = true;
    mono[i] = true;
    for (var j = i + 1; j < lines.length && lines[j].trim().isNotEmpty; j++) {
      mono[j] = true;
    }
  }

  // 3) 아직 정리하지 않은 표 — 세로줄이나 탭으로 구분된 줄이 이어질 때.
  bool looksRaw(String l) =>
      l.trim().isNotEmpty && (l.contains('|') || l.contains('\t'));
  var runStart = -1;
  for (var i = 0; i <= lines.length; i++) {
    final hit = i < lines.length && looksRaw(lines[i]);
    if (hit) {
      if (runStart < 0) runStart = i;
      continue;
    }
    // 한 줄짜리는 표가 아니다(줄글에 '|'가 한 번 나온 것일 수 있다).
    if (runStart >= 0 && i - runStart >= 2) {
      for (var j = runStart; j < i; j++) {
        mono[j] = true;
      }
    }
    runStart = -1;
  }

  // 줄 표시를 문자 구간으로 바꾼다.
  // 줄 끝의 줄바꿈 문자까지 포함한다 — 줄바꿈이 어느 쪽 글꼴에 속하느냐에 따라
  // 그 줄의 높이가 달라져서, 표 위아래 줄 간격이 들쭉날쭉해지기 때문이다.
  final out = <MonoSpan>[];
  var pos = 0;
  var spanStart = -1;
  for (var i = 0; i < lines.length; i++) {
    final hasNewline = i < lines.length - 1;
    final lineEnd = pos + lines[i].length + (hasNewline ? 1 : 0);
    if (mono[i]) {
      if (spanStart < 0) spanStart = pos;
    } else if (spanStart >= 0) {
      out.add(MonoSpan(spanStart, pos));
      spanStart = -1;
    }
    pos = lineEnd;
  }
  if (spanStart >= 0) out.add(MonoSpan(spanStart, pos));
  return out;
}
