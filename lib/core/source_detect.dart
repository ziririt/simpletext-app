/// 붙여넣은 글의 출처 알아내기 — 순수 함수. 화면·클립보드 코드를 넣지 않는다.
///
/// 2026-08-16 소유자 제안: "LLM마다 독특한 개성이 있지? 그걸 감지해서 자동으로
/// 하면 좋겠다. 확신이 안 되는 경우에는 'ChatGPT(추정)'이라고 하면 되겠다."
///
/// ## 2026-08-17 — 짐작을 걷어내고 실제 원문으로 다시 짰다
///
/// 소유자 신고 — "여러 LLM의 답변을 붙여넣기 해 봤더니 출처 분석을 자동으로
/// 하나도 못하네? 퍼플렉시티조차도 인식하지 못하는 건 문제가 있지 않니?"
///
/// 그래서 다섯 모델의 **실제 답변**을 하나씩 받아 재 봤다. 결과는 이랬다.
///
/// ```
///                chatgpt   claude   gemini    grok  perplexity
/// utm=chatgpt.com      8        0        0       0        0
/// 마크다운 링크        15        0        0       0        0
/// '•' 글머리            0        0        0      14        0
/// '#' 소제목            0        0       12       3        0
/// '**굵게**'            1        0       27       5        0
/// '---' 구분선          0        0        8       0        0
/// 표                    0        0        6       0        0
/// 들여쓴 글머리          0        0        0       0       34
/// 글머리 비율        0.34     0.38     0.28    0.54     0.73
/// 긴 줄글 문단 수        4        6        1       0        1
/// ```
///
/// 옛 규칙이 보던 것은 **각주(`[1]`)였는데 다섯 원문 모두 각주가 0이었다.**
/// 엉뚱한 데를 보고 있었다. 그리고 별표 글머리만 보고 제미나이로 찍는 규칙
/// 때문에 **퍼플렉시티 원문이 제미나이로 판정됐다** — 못 잡는 것보다 나쁘다.
///
/// 위 표에서 갈라지는 자리는 분명하다.
///
///   ChatGPT     인용 링크에 utm_source=chatgpt.com이 붙어 온다. 이건 표식이다
///   Grok        글머리가 '•' 글자 그 자체. 나머지 넷은 이 글자를 안 낸다
///   Gemini      '#' 소제목 + '---' + 표 + 굵게, 꾸밈이 전부 들어 있다
///   Perplexity  '*' 글머리가 깊게 겹치고 꾸밈은 하나도 없다
///   Claude      꾸밈 없이 '*' 글머리 + 긴 줄글 문단이 여럿
///
/// 다섯 원문은 test/core/llm_samples.dart에 그대로 굳혀 두었다. 규칙을
/// 건드릴 때마다 이 다섯이 제대로 나오는지 자동으로 확인된다.
///
/// ## 정확도에 대해 정직하게
///
/// 이건 다섯 편으로 맞춘 규칙이다. 같은 모델이라도 물어보는 방식이 달라지면
/// 생김새가 달라진다 — 예컨대 웹 검색을 안 켠 ChatGPT는 링크가 없어 Claude와
/// 구별하기 어렵다. 그래서 **점수 차이가 벌어질 때만 이름을 말한다.**
/// 애매하면 아무 말도 하지 않는다. 틀린 출처를 조용히 박아 두는 것은
/// 안 하느니만 못하다.
library;

/// 화면과 저장에 쓰는 이름. 편집 화면 출처 목록의 값과 정확히 같아야 한다.
const String kChatGpt = 'ChatGPT';
const String kClaude = 'Claude';
const String kGemini = 'Gemini';
const String kGrok = 'Grok';
const String kPerplexity = 'Perplexity';

class SourceGuess {
  /// 알아낸 이름. 모르면 빈 문자열.
  final String name;

  /// 표식으로 확인됐는가. true면 '(추정)'을 붙이지 않는다.
  final bool certain;

  const SourceGuess(this.name, {this.certain = false});

  static const SourceGuess unknown = SourceGuess('');

  bool get isKnown => name.isNotEmpty;
}

// ---------------------------------------------------------------------------
// 1단 — 복사한 순간에 딸려 온 증거
// ---------------------------------------------------------------------------

/// 주소에서 곧바로 갈리는 것들. 이건 추측이 아니다.
const Map<String, List<String>> _domains = {
  kChatGpt: [
    'chatgpt.com',
    'chat.openai.com',
    'openai.com/share',
    'oaiusercontent.com',
    'utm_source=chatgpt.com',
    'utm_source=openai',
  ],
  kClaude: [
    'claude.ai',
    'anthropic.com/share',
    'utm_source=claude',
  ],
  kGemini: [
    'gemini.google.com',
    'bard.google.com',
    'g.co/gemini',
    'aistudio.google.com',
    'utm_source=gemini',
  ],
  kPerplexity: [
    'perplexity.ai',
    'pplx.ai',
    'utm_source=perplexity',
  ],
  kGrok: [
    'grok.com',
    'x.com/i/grok',
    'x.ai/grok',
    'grok.x.ai',
    'utm_source=grok',
  ],
};

/// HTML 조각에 박혀 있는 이름들. 화면을 그리려고 서비스가 박아 둔 것이라
/// 사용자가 어떻게 물어보든 바뀌지 않는다.
///
/// **여기 넣을 자격**: 그 서비스에서만 나오는 이름이어야 한다. `prose` 는
/// 테일윈드 기본값이라 챗지피티에도 퍼플렉시티에도 있다 — 그런 것은 넣지
/// 않는다. 넣으면 못 잡는 것보다 나쁜 일(엉뚱하게 확정)이 일어난다.
const Map<String, List<String>> _htmlMarks = {
  kChatGpt: [
    // 2026-08-27 23:00 실측 — **여기 있는 것 중 하나도 안 왔다.**
    //
    // 챗지피티가 클립보드에 싣는 HTML 은 화면에 그려 둔 그 덩어리가
    // 아니었다. 앞 4000자에 class 도 id 도 data-* 도 하나도 없는,
    // 속성이 벗겨진 깨끗한 HTML 이었다. 즉 아래 다섯은 화면에서는
    // 맞을지 몰라도 **복사물에는 안 실린다.**
    //
    // 그래서 이 다섯은 남겨 두되(웹 붙여넣기 경로에서는 화면 조각이
    // 그대로 올 수도 있다) 여기에 기대지 않는다. 무엇으로 잡을지는
    // 지문 기록기 2판(태그 뼈대와 속성 이름)의 다음 실측을 본다.
    'data-message-author-role',
    'data-message-id',
    'text-token-text-primary',
    'result-streaming',
    'agent-turn',
  ],
  kClaude: [
    'font-claude-message',
    'font-claude-response',
    'data-is-streaming',
    'standard-markdown',
  ],
  kGemini: [
    // 2026-08-27 23:01 실측. 맥앱에 실제로 붙여넣은 조각에서 뽑았다.
    //
    // 여기 있던 넷(model-response-text, response-container-content,
    // message-content-id, gemini-response)은 **전부 내 짐작이었고 전부
    // 틀렸다.** 실제 조각에는 하나도 없었다. 소유자가 "디텍팅이 거의 안
    // 된다"고 한 까닭이 이것이다. 짐작한 이름은 지웠다.
    'markdown-main-panel',
    'model-response-message-content',
    'enable-luminous-fast-follows',
    'enable-updated-hr-color',
    'data-path-to-node',
    'data-index-in-node',
  ],
  kPerplexity: [
    'pplx-',
    'perplexity',
  ],
  kGrok: [
    'grok-response',
    'data-grok',
  ],
};

/// 딸려 온 증거(주소 또는 HTML 조각)에서 출처를 찾는다.
///
/// 두 서비스의 표식이 함께 보이면 **아무 말도 안 한다.** 사용자가 여러
/// 창에서 긁어모은 글일 수 있고, 그때 하나를 골라 박으면 그건 거짓이다.
SourceGuess sourceFromCapture(String? capture) {
  if (capture == null || capture.isEmpty) return SourceGuess.unknown;
  final t = capture.toLowerCase();

  final hit = <String>{};
  _domains.forEach((who, marks) {
    if (marks.any(t.contains)) hit.add(who);
  });
  if (hit.length == 1) return SourceGuess(hit.first, certain: true);
  if (hit.length > 1) return SourceGuess.unknown;

  _htmlMarks.forEach((who, marks) {
    if (marks.any(t.contains)) hit.add(who);
  });
  if (hit.length == 1) return SourceGuess(hit.first, certain: true);
  return SourceGuess.unknown;
}

/// 옛 이름. 부르는 자리가 여럿이라 남겨 둔다.
SourceGuess sourceFromUrl(String? urlOrHtml) => sourceFromCapture(urlOrHtml);

/// **본문 글자 안에 박힌 링크**에서 찾는다.
///
/// 2026-08-27 저녁, 소유자가 다섯 서비스를 하나씩 붙여넣어 재 봤다. 거기서
/// 알게 된 것 — **요즘 AI 앱의 '복사' 단추는 마크다운 글자만 넣는다.**
/// HTML 이 아예 안 실린다. 그러면 1단(클립보드 증거)이 볼 것이 없다.
///
/// 그때 남는 유일한 증거가 본문에 박힌 링크다. 웹 검색을 켠 답변에는
/// 출처 링크가 본문에 그대로 들어오고, 그 주소가 어느 서비스인지 말해 준다.
///
/// **주소 꼴일 때만 센다.** 그냥 'perplexity' 라는 낱말이 글에 나온다고
/// 퍼플렉시티일 리 없다. 오늘 이 앱을 만들며 쓴 설계 문서에는 다섯 이름이
/// 모두 나온다 — 그런 글에 아무 이름이나 박으면 그게 제일 나쁘다.
///
/// 그래서 둘 이상이 보이면 아무 말도 안 한다. 설계 문서 같은 글이 정확히
/// 그 경우다.
SourceGuess sourceFromBody(String text) {
  if (text.isEmpty) return SourceGuess.unknown;
  final t = text.toLowerCase();
  final hit = <String>{};
  _domains.forEach((who, marks) {
    for (final m in marks) {
      // utm 표식은 그 자체가 주소 안에만 산다.
      if (m.startsWith('utm_')) {
        if (t.contains(m)) {
          hit.add(who);
          break;
        }
        continue;
      }
      // 나머지는 주소 꼴일 때만 센다.
      if (t.contains('://$m') ||
          t.contains('://www.$m') ||
          t.contains('/$m') && t.contains('http')) {
        hit.add(who);
        break;
      }
    }
  });
  if (hit.length == 1) return SourceGuess(hit.first, certain: true);
  return SourceGuess.unknown;
}

/// 붙여넣기로 새로 들어온 덩이만 떼어 낸다.
///
/// 2026-08-17 — 편집 화면에서 붙여넣어도 출처를 찍으려면, 글 전체가 아니라
/// **방금 들어온 부분**을 봐야 한다. 이미 있던 글이 섞이면 그쪽 생김새가
/// 판정을 끌고 간다.
///
/// 앞에서부터 같은 만큼, 뒤에서부터 같은 만큼을 걷어내면 가운데 남는 것이
/// 새로 들어온 것이다. 붙여넣기는 한 자리에 한 덩이로 들어오므로 이 방법이
/// 맞는다.
String insertedChunk(String before, String after) {
  if (after.length <= before.length) return '';
  var head = 0;
  final maxHead = before.length;
  while (head < maxHead && before.codeUnitAt(head) == after.codeUnitAt(head)) {
    head++;
  }
  var tail = 0;
  final maxTail = before.length - head;
  while (tail < maxTail &&
      before.codeUnitAt(before.length - 1 - tail) ==
          after.codeUnitAt(after.length - 1 - tail)) {
    tail++;
  }
  return after.substring(head, after.length - tail);
}

// ---------------------------------------------------------------------------
// 각주 세기 — 있을 때는 아주 강한 단서다. 다만 늘 있지는 않다.
// ---------------------------------------------------------------------------

final RegExp _citeBracket = RegExp(r'\[\d{1,3}\]');
final RegExp _citeFootnote = RegExp(r'\[\^\d{1,3}\]');
final RegExp _citeSuper = RegExp(r'[¹²³⁰⁴-⁹]');
final RegExp _citeTagged =
    RegExp(r'\[(?:web|post|x|news|video):\s*\d{1,3}\]', caseSensitive: false);

/// 글 끝에 붙는 '출처' 뭉치의 줄 수. `1. https://…` 또는 `[1] https://…`.
final RegExp _srcLine =
    RegExp(r'^\s*(?:\[\d{1,3}\]|\d{1,3}[.)])\s*https?://', multiLine: true);

/// 출처 목록의 머리말 줄.
final RegExp _srcHeading = RegExp(
    r'^\s*(출처|참고|참고자료|인용|sources?|references?|citations?)\s*[:：]?\s*$',
    multiLine: true,
    caseSensitive: false);

/// 이 글에 각주가 몇 개나 있는가. 모양을 가리지 않는다.
int citationCount(String text) =>
    _citeBracket.allMatches(text).length +
    _citeFootnote.allMatches(text).length +
    _citeSuper.allMatches(text).length +
    _citeTagged.allMatches(text).length;

// ---------------------------------------------------------------------------
// 생김새
// ---------------------------------------------------------------------------

/// ChatGPT가 인용 링크에 붙여 보내는 표식. 우리가 만든 규칙이 아니라
/// OpenAI가 스스로 찍는 것이라, 이건 추측이 아니라 사실이다.
final RegExp _utmChatGpt =
    RegExp(r'utm_source=chatgpt\.com', caseSensitive: false);

final RegExp _mdLink = RegExp(r'\[[^\]\n]{1,80}\]\(https?://');
final RegExp _nestedBullet = RegExp(r'^[ \t]{2,}[*\-•] ', multiLine: true);
final RegExp _heading = RegExp(r'^#{1,6}\s', multiLine: true);
final RegExp _bold = RegExp(r'\*\*[^*\n]{2,}\*\*');
final RegExp _blankLine = RegExp(r'\n\s*\n');

/// 2단 — 글의 생김새로 추측.
///
/// ## 2026-08-27 — 더 이상 이 값을 화면에 쓰지 않는다
///
/// 소유자가 다섯 서비스를 하나씩 붙여넣어 재 봤다. 결과가 이랬다.
///
/// ```
///   실제        탐지        어떻게
///   Grok        Gemini      생김새   ← 틀림
///   ChatGPT     Gemini      생김새   ← 틀림
///   Gemini      (못 잡음)
///   Perplexity  Perplexity  증거     ← 맞음
///   Claude      Claude      증거     ← 맞음
/// ```
///
/// 증거로 잡은 둘은 맞았고, **생김새로 찍은 둘은 다 틀렸다. 그것도 둘 다
/// 같은 이름(Gemini)으로.** 까닭은 분명하다 — 제미나이 규칙이 '소제목 여럿
/// + 표 + 굵게'인데, **2026년 8월 현재 다섯 모델이 전부 그렇게 쓴다.**
/// 열흘 전(08-17) 다섯 편으로 맞춘 규칙이 열흘 만에 낡았다.
///
/// 실제 수치. ChatGPT 편은 소제목이 29개였고 Grok 편은 표가 10줄이었다.
/// 옛 규칙에서 그건 제미나이의 표식이었다.
///
/// **그래서 붙여넣을 때 이 함수를 부르지 않는다.** 틀린 이름을 조용히 박는
/// 것은 아무 말도 안 하는 것보다 나쁘다. 사람은 앱이 박아 준 이름을 나중에
/// 의심하지 않는다.
///
/// 함수와 시험은 남겨 둔다. 언젠가 실기기 표본을 충분히 모아 confusion
/// matrix 를 그리면 그때 다시 쓸 자리가 있을 수 있다. 다만 그때까지는
/// **증거만 말한다.**
SourceGuess guessSource(String text) {
  // 2026-08-17 — 문턱을 200자에서 140자로 내렸다. 200자는 한국어 한 문단이
  // 넘는 길이라, 짧게 묻고 짧게 받은 답이 통째로 빠져나갔다.
  if (text.trim().length < 140) {
    // 그래도 아주 짧은 글은 어느 모델이 써도 비슷하게 생겼다. 찍으면 틀린다.
    return SourceGuess.unknown;
  }

  // --- ChatGPT의 표식이 있으면 여기서 끝. 추측이 아니다.
  if (_utmChatGpt.hasMatch(text)) {
    return const SourceGuess(kChatGpt, certain: true);
  }

  final lines = text.split('\n');

  int bullets(String mark) =>
      lines.where((l) => l.trimLeft().startsWith('$mark ')).length;
  final star = bullets('*');
  final hyphen = bullets('-');
  final dot = bullets('•');
  final bulletLines = star + hyphen + dot;
  final nested = _nestedBullet.allMatches(text).length;

  final headings = _heading.allMatches(text).length;
  final bolds = _bold.allMatches(text).length;
  final hr = lines.where((l) {
    final t = l.trim();
    return t == '---' || t == '***' || t == '___';
  }).length;
  final tableRows = lines.where((l) => '|'.allMatches(l).length >= 2).length;
  final code = '```'.allMatches(text).length;
  final mdLinks = _mdLink.allMatches(text).length;

  final cites = citationCount(text);
  final tagged = _citeTagged.allMatches(text).length;
  final srcLines = _srcLine.allMatches(text).length;
  final hasSourceList = _srcHeading.hasMatch(text);

  // 줄글 문단만 골라 평균 길이를 잰다. 소제목·글머리 줄은 빼야 한다 —
  // 넣으면 평균이 끌어내려져 긴 줄글이 짧아 보인다.
  final prose = text
      .split(_blankLine)
      .map((p) => p.trim())
      .where((p) =>
          p.length >= 40 &&
          !p.startsWith('#') &&
          !p.startsWith('*') &&
          !p.startsWith('-') &&
          !p.startsWith('•'))
      .toList();
  final proseAvg = prose.isEmpty
      ? 0
      : prose.fold<int>(0, (a, p) => a + p.length) ~/ prose.length;
  final bulletRatio = lines.isEmpty ? 0.0 : bulletLines / lines.length;

  // --- 문턱: AI 답변처럼 생기지 않았으면 아예 찍지 않는다.
  //
  // 2026-08-16에 이걸 안 두고 만들었다가, 사람이 직접 쓴 평범한 회의 메모가
  // Claude로 판정되는 것을 테스트가 잡아 줬다. 문단이 길고 불릿이 없다는
  // 이유만으로 이름을 붙인 것이다 — 사람이 쓴 글이 원래 그렇다.
  //
  // 놓치는 쪽이 틀리는 쪽보다 낫다.
  final looksFormatted = headings > 0 ||
      bolds > 0 ||
      bulletLines >= 2 ||
      hr > 0 ||
      cites >= 3 ||
      srcLines >= 2 ||
      mdLinks >= 3 ||
      tableRows >= 2;
  if (!looksFormatted) return SourceGuess.unknown;

  final score = <String, int>{
    kChatGpt: 0,
    kClaude: 0,
    kGemini: 0,
    kGrok: 0,
    kPerplexity: 0,
  };

  void add(String who, int n) => score[who] = score[who]! + n;

  // --- 글머리 글자가 가장 힘센 단서다.
  //
  //   '•' → Grok. 나머지 넷은 이 글자를 글머리로 내지 않는다.
  //   '*' → Gemini·Perplexity·Claude·ChatGPT (넷이 겹치므로 다른 것으로 가른다)
  //   '-' → 예전 ChatGPT
  if (dot >= 3) add(kGrok, 5);
  if (dot >= 8) add(kGrok, 2);

  // --- 웹 검색을 켠 ChatGPT는 문장 끝마다 마크다운 링크를 단다.
  if (mdLinks >= 5) add(kChatGpt, 5);
  if (mdLinks >= 10) add(kChatGpt, 2);

  // --- 제미나이는 꾸밈이 전부 들어 있다. 소제목·구분선·표·코드·굵게.
  final ornament = (hr >= 2 ? 1 : 0) +
      (tableRows >= 3 ? 1 : 0) +
      (code >= 2 ? 1 : 0) +
      (bolds >= 10 ? 1 : 0);
  if (headings >= 3 && ornament >= 1) add(kGemini, 5);
  if (headings >= 3 && ornament >= 3) add(kGemini, 2);

  // --- 퍼플렉시티는 글머리를 깊게 겹치면서 꾸밈은 하나도 안 쓴다.
  if (nested >= 5 && headings == 0 && bolds == 0) add(kPerplexity, 5);
  if (bulletRatio >= 0.6) add(kPerplexity, 2);

  // --- Claude는 꾸밈 없이 긴 줄글 문단을 여럿 쓴다.
  //
  // 링크가 없어야 한다는 조건이 중요하다. 웹 검색을 안 켠 ChatGPT가 이 모양에
  // 가까운데, 그쪽은 링크가 붙어 오는 경우가 많아서 그걸로 갈린다.
  if (prose.length >= 3 &&
      proseAvg >= 200 &&
      headings == 0 &&
      bolds == 0 &&
      hr == 0 &&
      nested == 0 &&
      mdLinks == 0 &&
      bulletLines >= 5) {
    add(kClaude, 5);
  }

  // 글머리를 거의 안 쓰고 줄글로만 가는 판도 있다. 위 규칙은 글머리가
  // 다섯 줄 넘게 있을 때만 걸리므로, 그 반대쪽을 따로 본다.
  if (prose.length >= 3 &&
      proseAvg >= 200 &&
      bulletRatio < 0.15 &&
      bolds == 0 &&
      hr == 0 &&
      mdLinks == 0 &&
      dot == 0) {
    add(kClaude, 4);
  }

  // --- 각주는 있을 때 아주 강하다. 다섯 원문에는 하나도 없었지만,
  //     검색을 켜고 물으면 붙어 오는 경우가 있다.
  if (tagged >= 1) add(kGrok, 4);
  final inline = cites - tagged;
  if (inline >= 3) add(kPerplexity, 4);
  if (inline >= 3 && hasSourceList) add(kPerplexity, 2);
  if (srcLines >= 3) add(kPerplexity, 4);

  // --- 번호 목록의 굵은 머리말: `1. **항목** — 설명`. 예전 ChatGPT의 모양이다.
  //     다만 제미나이도 쓰므로, 소제목이 많으면 세지 않는다.
  final boldLead =
      RegExp(r'^\s*\d+\.\s+\*\*', multiLine: true).allMatches(text).length;
  if (boldLead >= 2 && headings < 3) add(kChatGpt, 2);

  // --- 맺음말: "원하시면 ~해 드릴까요?" 류는 ChatGPT가 즐겨 붙인다.
  if (RegExp(r'(원하시면|필요하시면|would you like me to|shall i|want me to)',
          caseSensitive: false)
      .hasMatch(text)) {
    add(kChatGpt, 1);
  }

  // --- 하이픈 글머리만 쓰고 별표를 안 쓰면 예전 ChatGPT 쪽.
  if (hyphen >= 3 && star == 0 && dot == 0) add(kChatGpt, 1);

  // --- 판정: 1등과 2등의 차이가 확실할 때만 이름을 말한다.
  final ranked = score.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = ranked.first;
  final second = ranked.length > 1 ? ranked[1].value : 0;
  if (top.value >= 4 && top.value - second >= 2) {
    return SourceGuess(top.key);
  }
  return SourceGuess.unknown;
}

/// 화면에 쓸 이름. 추측이면 뒤에 '(추정)'을 붙인다.
///
/// [uncertainSuffix]는 언어별로 다르므로 밖에서 받는다('(추정)', '(guess)' …).
String sourceLabel(SourceGuess g, String uncertainSuffix) {
  if (!g.isKnown) return '';
  return g.certain ? g.name : '${g.name}$uncertainSuffix';
}

// ---------------------------------------------------------------------------
// 신선도
// ---------------------------------------------------------------------------

/// AI 답변이 낡았다고 볼 기간(일).
///
/// 왜 이 기능이 있나: **AI 답변은 썩는다.** 모델이 바뀌면 석 달 전 답이 틀린
/// 답이 된다. 그런데 어떤 노트앱도 이걸 모른다 — 그 앱들에게 메모는 그냥
/// 글자이기 때문이다. 우리는 언제 받은 답인지 알고 있으니 말해 줄 수 있다.
///
/// 90일로 잡은 이유: 주요 모델이 대략 분기마다 한 번씩 바뀌어 왔다. 더 짧게
/// 잡으면 멀쩡한 답에 경고가 붙어 잔소리가 되고, 더 길게 잡으면 이미 틀린
/// 답을 조용히 놔두게 된다.
const int kStaleAfterDays = 90;

const int _dayMs = 24 * 60 * 60 * 1000;

/// 이 답이 낡았는가. [pastedAt]이 0이면(붙여넣은 기록이 없으면) 아니다 —
/// 사용자가 직접 쓴 글에 "낡았다"고 말하면 안 된다.
bool isStale({
  required int pastedAt,
  required int nowMs,
  int afterDays = kStaleAfterDays,
}) {
  if (pastedAt <= 0) return false;
  return nowMs - pastedAt >= afterDays * _dayMs;
}

/// 붙여넣은 지 며칠 됐나. 기록이 없으면 -1.
int daysSincePaste({required int pastedAt, required int nowMs}) {
  if (pastedAt <= 0) return -1;
  final d = (nowMs - pastedAt) ~/ _dayMs;
  return d < 0 ? 0 : d;
}
