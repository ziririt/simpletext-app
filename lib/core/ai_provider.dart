/// AI 제공사(회사) 판정과 모델 선별 — 순수 로직.
///
/// 2026-08-16 소유자 승인 설계. 배경이 된 신고 두 개:
///   1) "API 키 발급 시 모델을 알려주지 않는데 왜 모델을 골라야 하나?"
///   2) "키를 넣어도 마법사가 안 된다" — OpenAI 키를 넣어도 모델 드롭다운이
///      기본값 Gemini면 구글 서버로 가서 무조건 거절당했다. 모델 이름이
///      회사(엔드포인트) 선택을 겸하고 있던 것이 병의 뿌리다.
///
/// 원칙: 버전 번호는 바뀌지만 등급 이름은 안 바뀐다.
/// gemini 2.0이 2.5가 되어도 'flash-lite'라는 말은 그대로다. haiku도,
/// nano도, fast도 몇 년째 그대로다. 그래서 이 파일은 모델 버전을 외우지
/// 않고 (예비 사다리에만 최소한으로 두고) 등급 이름으로 판정한다.
/// 제일 싼 모델이 폐지되어도 목록을 다시 받으면 그다음 최신이 뽑힌다.
///
/// 화면·네트워크 코드를 넣지 않는다. 그래야 테스트로 고정할 수 있다.
/// 정리 엔진이 아니므로 웹 대칭 규칙(HANDOVER 5절)의 대상이 아니다.
library;

/// 키 앞글자로 회사를 판정한다. 못 알아보면 null — 그때는 화면이
/// "고급에서 직접 지정하라"고 안내한다.
///
/// sk-ant- 를 sk- 보다 먼저 봐야 한다. Claude 키도 sk- 로 시작한다.
String? providerOfKey(String key) {
  final k = key.trim();
  if (k.isEmpty) return null;
  if (k.startsWith('sk-ant-')) return 'anthropic';
  if (k.startsWith('xai-')) return 'xai';
  if (k.startsWith('AIza')) return 'google';
  if (k.startsWith('sk-')) return 'openai';
  return null;
}

/// 모델 이름으로 회사를 역산한다(옛 설정 이관용).
String? providerOfModel(String model) {
  final m = model.trim();
  if (m.isEmpty) return null;
  if (m.startsWith('gemini') || m.startsWith('gemma')) return 'google';
  if (m.startsWith('claude')) return 'anthropic';
  if (m.startsWith('grok')) return 'xai';
  if (m.startsWith('gpt') || RegExp(r'^o\d').hasMatch(m)) return 'openai';
  return null;
}

/// 화면에 보여 줄 회사 이름. 상표라서 언어를 타지 않는다 — l10n 제외.
String providerLabel(String provider) {
  switch (provider) {
    case 'google':
      return 'Gemini';
    case 'anthropic':
      return 'Claude';
    case 'openai':
      return 'ChatGPT';
    case 'xai':
      return 'Grok';
  }
  return provider;
}

/// 예비 사다리 — 목록을 못 받아 왔을 때(오프라인, 방화벽) 위에서부터
/// 시도하는 후보들. 싼 것부터. 여기가 이 파일에서 유일하게 버전 번호를
/// 아는 곳이고, 목록 API가 성공하면 이 사다리는 쓰이지 않는다.
List<String> defaultLadder(String provider) {
  switch (provider) {
    case 'google':
      return const ['gemini-2.5-flash-lite', 'gemini-2.5-flash', 'gemini-2.5-pro'];
    case 'anthropic':
      return const ['claude-haiku-4-5-20251001', 'claude-haiku-4-5', 'claude-sonnet-5'];
    case 'openai':
      // 2026-08-17 — nano에서 mini로 올렸다. 아래 tierRank의 주석 참고.
      return const ['gpt-5-mini', 'gpt-5-nano', 'gpt-5'];
    case 'xai':
      // grok-4.1-fast는 물러났다. 지금 공식 주력은 4.6 하나다.
      return const ['grok-4.6', 'grok-4.1-fast', 'grok-4'];
  }
  return const [];
}

/// 이 모델 이름이 이 회사 것인가. 옛 설정(OpenAI 키 + Gemini 모델)처럼
/// 어긋난 조합을 걸러 내는 데 쓴다.
bool modelMatchesProvider(String model, String provider) =>
    providerOfModel(model) == provider;

/// 목록에서 '글을 다루는 대화 모델'만 남긴다.
/// 회사 목록에는 임베딩·이미지·음성 모델이 잔뜩 섞여 온다.
List<String> filterChatModels(String provider, List<String> ids) {
  const drop = [
    'embedding', 'embed', 'image', 'imagen', 'veo', 'tts', 'audio',
    'realtime', 'transcribe', 'moderation', 'live', 'aqa', 'learnlm',
    'robotics', 'instruct', 'search', 'vision',
  ];
  bool ok(String id) {
    final lo = id.toLowerCase();
    if (drop.any(lo.contains)) return false;
    switch (provider) {
      case 'google':
        return lo.startsWith('gemini-');
      case 'anthropic':
        return lo.startsWith('claude-');
      case 'xai':
        return lo.startsWith('grok-');
      case 'openai':
        return RegExp(r'^(gpt-\d|o\d)').hasMatch(lo);
    }
    return false;
  }

  return [for (final id in ids) if (ok(id)) id];
}

/// 등급 서열. 숫자가 작을수록 먼저 고른다. 등급 이름은 해가 바뀌어도
/// 그대로라서 이 표는 모델이 세대 교체돼도 고칠 일이 없다.
///
/// 2026-08-17 — 기준을 '제일 싼 것'에서 **'값은 낮추되 이 앱이 시키는 일을
/// 해낼 수 있는 것'**으로 바꿨다.
///
/// 이 앱이 AI에게 시키는 일은 분류나 추출이 아니라 **한국어 글을 다시
/// 쓰는 것**이다("더 간결하게 써줘", "날짜 줄을 지워줘"). 이건 제일 작은
/// 모델이 자주 어그러지는 종류의 일이고, 어그러진 결과는 안 나온 것보다
/// 나쁘다 — 사용자가 그 기능을 다시 안 쓰기 때문이다.
///
/// 그래서 OpenAI만 순서를 바꿨다. nano가 mini보다 다섯 배 싸지만, 메모
/// 하나 고치는 데 드는 값은 어차피 몇 원 단위다. 몇 원을 아끼려고 결과를
/// 잃는 거래는 하지 않는다.
///
/// 다른 회사는 그대로다. 구글 flash-lite와 앤트로픽 haiku는 각 회사에서
/// 제일 싸면서 동시에 글을 다룰 만한 등급이라, 값과 품질이 같은 칸에서
/// 만난다.
int tierRank(String provider, String id) {
  final lo = id.toLowerCase();
  switch (provider) {
    case 'google':
      if (lo.contains('flash-lite')) return 0;
      if (lo.contains('flash')) return 1;
      if (lo.contains('pro')) return 2;
      return 3;
    case 'anthropic':
      if (lo.contains('haiku')) return 0;
      if (lo.contains('sonnet')) return 1;
      if (lo.contains('opus')) return 2;
      return 3;
    case 'openai':
      if (lo.contains('mini')) return 0;
      if (lo.contains('nano')) return 1;
      if (lo.contains('pro')) return 3;
      return 2;
    case 'xai':
      if (lo.contains('fast') || lo.contains('mini')) return 0;
      return 1;
  }
  return 9;
}

List<int> _nums(String id) =>
    [for (final m in RegExp(r'\d+').allMatches(id)) int.parse(m.group(0)!)];

int _cmpNums(List<int> a, List<int> b) {
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final x = i < a.length ? a[i] : -1;
    final y = i < b.length ? b[i] : -1;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// 목록에서 '고른 등급의 제일 최신'을 뽑는다. 쓸 만한 게 없으면 null.
///
/// 이름은 pickCheapest지만 하는 일은 tierRank가 정한 차례의 맨 앞을
/// 고르는 것이고, 그 차례는 이제 값만이 아니라 **쓸 만한지**도 본다.
/// (이름을 안 바꾼 이유: 부르는 곳이 여럿이고 뜻이 크게 어긋나지 않는다.
///  값을 낮추는 것이 여전히 이 함수의 첫째 목적이다.)
///
/// 한계를 적어 둔다: 가격표를 주는 목록 API가 거의 없어서 값을 등급
/// 이름으로 대신 판정한다. 등급명과 실제 가격 서열이 어긋나는 날이 오면
/// 여기가 틀린다 — 그래도 '안 됨'이 아니라 '조금 비싼 걸 골랐음'이다.
String? pickCheapest(String provider, List<String> ids) {
  final f = filterChatModels(provider, ids);
  if (f.isEmpty) return null;
  var best = f.first;
  for (final m in f.skip(1)) {
    final rb = tierRank(provider, best), rm = tierRank(provider, m);
    if (rm < rb || (rm == rb && _cmpNums(_nums(m), _nums(best)) > 0)) {
      best = m;
    }
  }
  return best;
}
