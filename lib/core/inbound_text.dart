/// 붙여넣은 글을 **먼저 매만진다** — 순수 함수.
///
/// 2026-08-18 소유자 신고로 찾아낸 것이다. 그록 답변을 붙여넣고 정리했더니
/// 이런 것이 생겼다.
///
/// ```
/// 향후 12시간 영향 예상
/// -
///   - • : •
/// ```
///
/// ## 무엇이 잘못됐나
///
/// 그록(과 챗GPT)은 목록을 **탭·글머리표·탭**으로 낸다.
///
///     [탭]•[탭]Home Depot(HD) Q2 실적 발표…
///
/// 우리 엔진은 탭을 **칸 구분자**로 읽는다(표를 알아보려고 그렇게 만들었다).
/// 그래서 이 줄이 세 칸짜리 표의 한 행이 되고, 그런 줄이 둘 이상 이어지면
/// 표로 확정되어 머리글과 구분선을 새로 그린다. 위의 '-'와 '• : •'가 바로
/// 그 구분선과 머리글이다.
///
/// 편집기도 같은 오해를 했다. 탭이 있는 줄이 이어지면 등폭 글꼴로 그렸다 —
/// 소유자가 "굳이 새로 라인 맞출 게 없는데 고정폭"이라고 한 그 화면이다.
///
/// ## 또 하나 — 보이지 않는 줄바꿈
///
/// 그 글에는 U+2028(LINE SEPARATOR)이 열 개 들어 있었다. 눈으로는 줄이
/// 바뀐 것처럼 보이는데 '\n'이 아니라서 우리 셈에는 **한 줄**이다. 줄
/// 단위로 도는 규칙이 전부 어긋난다.
///
/// ## 그래서 여기서 하는 일
///
/// 표시를 해석하기 **전에** 글의 뼈대를 바로잡는다. 줄바꿈은 줄바꿈으로,
/// 목록은 목록으로. 이 함수를 지나온 글만 엔진에 들어간다.
library;

/// 눈에 안 보이는 줄바꿈들.
///   U+2028 LINE SEPARATOR · U+2029 PARAGRAPH SEPARATOR · U+0085 NEL
final RegExp _oddBreaks = RegExp('[\u2028\u2029\u0085]');

/// 눈에는 공백인데 정규식에는 공백이 아닌 것들.
///   U+00A0 NBSP · U+3000 이덕 공백
final RegExp _oddSpaces = RegExp('[\u00a0\u3000]');

/// 탭으로 감싼 글머리표. 그록·챗GPT가 목록을 낼 때 쓰는 모양이다.
final RegExp _tabBullet =
    RegExp('^[ \\t]*([\u2022\u00b7\u25aa\u2023\u25e6*+-]|\\d{1,3}[.)])\\t+');

/// 글머리표 없이 탭으로만 들여쓴 줄.
final RegExp _leadTabs = RegExp(r'^\t+');

/// 붙여넣은 글의 뼈대를 바로잡는다.
String normalizeInbound(String raw) {
  if (raw.isEmpty) return raw;
  var t = raw.replaceAll(RegExp(r'\r\n?'), '\n');
  t = t.replaceAll(_oddBreaks, '\n');
  t = t.replaceAll(_oddSpaces, ' ');

  final out = <String>[];
  for (final line in t.split('\n')) {
    final m = _tabBullet.firstMatch(line);
    if (m != null) {
      final mark = m.group(1)!;
      // 번호 목록은 번호를 살린다. 그 밖은 '- '로 통일한다 — 엔진이
      // 글머리표를 다루는 자리가 이미 있고, 거기 한 모양으로 보내야 한다.
      final head = RegExp(r'^\d').hasMatch(mark) ? '$mark ' : '- ';
      out.add(head + line.substring(m.end));
      continue;
    }
    // 남은 앞머리 탭은 들여쓰기다. 두 칸씩으로 바꾼다.
    final lt = _leadTabs.firstMatch(line);
    if (lt != null) {
      out.add('  ' * lt.end + line.substring(lt.end));
      continue;
    }
    out.add(line);
  }
  return out.join('\n');
}
