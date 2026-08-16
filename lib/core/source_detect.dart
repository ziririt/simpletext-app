/// 붙여넣은 글의 출처 알아내기 — 순수 함수. 화면·클립보드 코드를 넣지 않는다.
///
/// 2026-08-16 소유자 제안: "LLM마다 독특한 개성이 있지? 그걸 감지해서 자동으로
/// 하면 좋겠다. 확신이 안 되는 경우에는 'ChatGPT(추정)'이라고 하면 되겠다."
///
/// ## 두 단으로 간다
///
/// **1단 — 클립보드에 딸려 온 주소.** 브라우저에서 복사하면 글자만 오는 게
/// 아니라 원본 주소가 함께 실려 오는 경우가 많다. 거기 chatgpt.com이 있으면
/// 그건 추측이 아니라 사실이다. 이 파일의 [sourceFromUrl]이 그 일을 한다.
///
/// **2단 — 글의 생김새.** 1단이 비었을 때만 쓴다. 확실하지 않으므로 결과에
/// 반드시 '(추정)'을 붙인다.
///
/// ## 정확도에 대해 정직하게
///
/// 학계·상용 분류기는 90%대를 보고하지만 그건 수십만 건으로 학습한 신경망이다.
/// 우리는 앱 안에서 규칙으로 하므로 그만큼 못 나온다. 인용형(퍼플렉시티
/// 계열)은 거의 확실하고, 나머지 셋은 그보다 훨씬 낮다.
///
/// 그래서 **점수 차이가 벌어질 때만 이름을 말한다.** 애매하면 아무 말도 하지
/// 않는다. 틀린 출처를 조용히 박아 두는 것은 안 하느니만 못하다.
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

  /// 클립보드 주소로 확인됐는가. true면 '(추정)'을 붙이지 않는다.
  final bool certain;

  const SourceGuess(this.name, {this.certain = false});

  static const SourceGuess unknown = SourceGuess('');

  bool get isKnown => name.isNotEmpty;
}

/// 1단 — 클립보드에 딸려 온 주소나 HTML에서 찾기. 찾으면 확실하다.
SourceGuess sourceFromUrl(String? urlOrHtml) {
  if (urlOrHtml == null || urlOrHtml.isEmpty) return SourceGuess.unknown;
  final t = urlOrHtml.toLowerCase();
  if (t.contains('chatgpt.com') || t.contains('chat.openai.com')) {
    return const SourceGuess(kChatGpt, certain: true);
  }
  if (t.contains('claude.ai')) return const SourceGuess(kClaude, certain: true);
  if (t.contains('gemini.google.com') || t.contains('bard.google.com')) {
    return const SourceGuess(kGemini, certain: true);
  }
  if (t.contains('perplexity.ai')) {
    return const SourceGuess(kPerplexity, certain: true);
  }
  if (t.contains('grok.com') || t.contains('x.com/i/grok')) {
    return const SourceGuess(kGrok, certain: true);
  }
  return SourceGuess.unknown;
}

/// 2단 — 글의 생김새로 추측. 애매하면 빈 결과를 준다.
SourceGuess guessSource(String text) {
  if (text.trim().length < 200) {
    // 짧은 글은 어느 모델이 써도 비슷하게 생겼다. 찍으면 틀린다.
    return SourceGuess.unknown;
  }
  final lines = text.split('\n');

  // --- 먼저 특징을 센다. 판정은 그다음이다.
  final cites = RegExp(r'\[\d{1,2}\]').allMatches(text).length;
  final hr = lines.where((l) {
    final t = l.trim();
    return t == '---' || t == '***' || t == '___';
  }).length;
  int bullets(String mark) =>
      lines.where((l) => l.trimLeft().startsWith('$mark ')).length;
  final star = bullets('*');
  final hyphen = bullets('-');
  final bulletLines = star + hyphen;
  final tableRows = lines.where((l) => '|'.allMatches(l).length >= 2).length;
  final bolds = RegExp(r'\*\*[^*\n]{2,}\*\*').allMatches(text).length;
  final headings = RegExp(r'^#{1,6}\s', multiLine: true).allMatches(text).length;

  // --- 문턱: AI 답변처럼 생기지 않았으면 아예 찍지 않는다.
  //
  // 2026-08-16에 이걸 안 두고 만들었다가, 사람이 직접 쓴 평범한 회의 메모가
  // Claude로 판정되는 것을 테스트가 잡아 줬다. 문단이 길고 불릿이 없다는
  // 이유만으로 이름을 붙인 것이다 — 사람이 쓴 글이 원래 그렇다.
  //
  // AI가 채팅창에서 낸 글에는 거의 언제나 마크다운 흔적이 하나는 있다
  // (소제목·굵게·글머리·구분선·각주·표). 그게 하나도 없으면 사람 글로 본다.
  // 놓치는 쪽이 틀리는 쪽보다 낫다.
  final looksFormatted = headings > 0 ||
      bolds > 0 ||
      bulletLines >= 2 ||
      hr > 0 ||
      cites >= 3 ||
      tableRows >= 2;
  if (!looksFormatted) return SourceGuess.unknown;

  final score = <String, int>{
    kChatGpt: 0,
    kClaude: 0,
    kGemini: 0,
    kPerplexity: 0,
  };

  // --- 인용 각주 + 출처 목록: 검색형(퍼플렉시티·코파일럿). 가장 확실한 신호다.
  final hasSourceList = RegExp(
          r'^\s*(출처|참고|참고자료|sources?|references?|citations?)\s*:?\s*$',
          multiLine: true, caseSensitive: false)
      .hasMatch(text);
  if (cites >= 3) score[kPerplexity] = score[kPerplexity]! + 4;
  if (cites >= 3 && hasSourceList) score[kPerplexity] = score[kPerplexity]! + 3;

  // --- 가로 구분선: ChatGPT가 큰 절 사이에 즐겨 넣는다. Claude는 거의 안 쓴다.
  if (hr >= 2) score[kChatGpt] = score[kChatGpt]! + 3;
  if (hr == 0) score[kClaude] = score[kClaude]! + 1;

  // --- 번호 목록의 굵은 머리말: `1. **항목** — 설명`. ChatGPT 특유의 모양이다.
  final boldLead =
      RegExp(r'^\s*\d+\.\s+\*\*', multiLine: true).allMatches(text).length;
  if (boldLead >= 2) score[kChatGpt] = score[kChatGpt]! + 3;

  // --- 글머리 기호: 별표를 쓰면 제미나이 쪽이다. 대부분은 하이픈으로 낸다.
  if (star >= 3 && star > hyphen * 2) score[kGemini] = score[kGemini]! + 4;
  if (hyphen >= 3 && star == 0) score[kChatGpt] = score[kChatGpt]! + 1;

  // --- 표: 제미나이가 유난히 즐겨 만든다.
  if (tableRows >= 3) score[kGemini] = score[kGemini]! + 1;

  // --- 굵게의 밀도: 제미나이가 문장을 통째로 굵게 하는 일이 잦다.
  if (bolds >= 8 && bolds * 100 >= text.length) {
    score[kGemini] = score[kGemini]! + 1;
  }

  // --- 문단 길이: Claude는 불릿을 덜 쓰고 문단을 길게 쓴다.
  final paras = text
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  // 소제목과 한 줄짜리는 '문단 길이'를 재는 데 넣지 않는다. 넣으면 평균이
  // 끌어내려져서 긴 줄글이 짧아 보인다 — 2026-08-16에 테스트가 잡았다.
  final prose =
      paras.where((p) => p.length >= 40 && !p.startsWith('#')).toList();
  if (prose.isNotEmpty) {
    final avg = prose.fold<int>(0, (a, p) => a + p.length) ~/ prose.length;
    final bulletRatio =
        lines.isEmpty ? 0.0 : bulletLines / lines.length;
    if (avg >= 220 && bulletRatio < 0.15) score[kClaude] = score[kClaude]! + 3;
    if (avg >= 140 && bulletRatio < 0.25) score[kClaude] = score[kClaude]! + 1;
  }

  // --- 이모지: Claude는 거의 안 쓴다. 나머지는 소제목에 넣기도 한다.
  final emoji = RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]',
          unicode: true)
      .allMatches(text)
      .length;
  if (emoji >= 3) {
    score[kChatGpt] = score[kChatGpt]! + 1;
    score[kGemini] = score[kGemini]! + 1;
  } else if (emoji == 0) {
    score[kClaude] = score[kClaude]! + 1;
  }

  // --- 맺음말: "원하시면 ~해 드릴까요?" 류는 ChatGPT가 거의 늘 붙인다.
  if (RegExp(
          r'(원하시면|필요하시면|would you like me to|shall i|want me to)',
          caseSensitive: false)
      .hasMatch(text)) {
    score[kChatGpt] = score[kChatGpt]! + 1;
  }

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
