# AI 모델 이름 점검 — 각사가 싼 급을 조용히 끈다

> 2026-09-19 소유자 지시 — "클로드나 제미나이 등 각사 API 버전을 점검해 달라. 하위(저렴이)
> 버전을 중단하고 급을 높이는 일이 수시로 있으니, 한 달에 한 번은 자동으로 체크해 달라."
>
> 앱이 쓰는 이름은 `lib/core/ai_provider.dart` 의 `defaultLadder()` 다. 사람이 고른 모델이
> 없거나 죽었을 때 위에서 아래로 차례로 써 본다. 여기 적힌 이름이 회사에서 사라지면
> AI편집이 "모델을 못 찾았다"로 죽는다 — 사용자는 이유를 모른다.

## 점검하는 법 (매달 1일, 자동 — 클라우드 예약 작업 "AI 모델 점검")

1. 공개 저장소의 `lib/core/ai_provider.dart` 를 읽어 네 사다리를 뽑는다
2. 네 회사의 폐기 안내를 읽는다
   - Anthropic https://platform.claude.com/docs/en/about-claude/model-deprecations
   - Google https://ai.google.dev/gemini-api/docs/deprecations
   - OpenAI https://developers.openai.com/api/docs/deprecations
   - xAI https://docs.x.ai/developers/models (+ migration 문서)
3. 사다리의 이름마다 **살아 있나 · 종료일이 잡혔나 · 대체 이름이 무엇인가** 를 적는다
4. 바꿀 것이 있으면 소유자에게 알린다. 고치는 일은 담당자 세션이 한다(사다리 + `tierRank`)

## 2026-09-19 점검 결과

- **OpenAI — 바꿨다.** `gpt-5`, `gpt-5-mini`, `gpt-5-nano` 가 **2026-12-11 종료**(06-11 공지).
  대체는 mini→`gpt-5.6-terra`, nano→`gpt-5.6-luna`, gpt-5→`gpt-5.6-sol`. 사다리를
  `[gpt-5.6-terra, gpt-5.6-luna, gpt-5.6-sol, gpt-5-mini]` 로 바꿨다(마지막은 12-11 까지 보루).
  `tierRank` 에 terra=mini 급, luna=nano 급을 가르쳤다
- **xAI — 바꿨다.** `grok-4.1-fast`·`grok-4` 계열은 **2026-05-15 에 이미 종료**. 사다리를
  `[grok-4.6, grok-4.3]` 로. 첫째가 살아 있어서 그동안 티가 안 났다
- **Anthropic — 그대로.** `claude-haiku-4-5-20251001` 살아 있음(종료 하한 2026-10-15 —
  그 뒤 언제든 폐기 공지가 올 수 있다. 다음 점검에서 본다). `claude-sonnet-5` 살아 있음.
  haiku 5 는 아직 없다
- **Google — 그대로.** `gemini-2.5-flash-lite/flash/pro` 종료일 없음. 3.5~3.8 세대가 나와
  있으나(3.5-flash-lite 07-21) 서두를 이유가 없다. 종료일이 잡히면 그때 올린다

## 2026-10-01 점검 결과 (자동) → 2026-10-16 고쳤다

- **Google — 바꿨다.** 2.5 세대(`flash-lite`·`flash`·`pro`)는 꺼진 게 아니다. 대신 **09-18 부터
  "예전에 써 본 사용자"에게만 열린다**(changelog 09-18: "limiting access to the 2.5 models to
  users who have actively used them in the past … not deprecated"). 새 프로젝트에는
  3.5 Flash-Lite 또는 3.8 Flash 를 쓰라고 한다. 옛 사다리는 세 칸이 전부 2.5 라서, 새로 키를
  넣은 사람이 목록을 못 받으면 전부 거절될 수 있었다.
  사다리를 `[gemini-3.5-flash-lite, gemini-3.8-flash, gemini-2.5-flash-lite]` 로 바꿨다
  (마지막은 예전부터 쓰던 사람의 보루). 새 사용자의 첫 기본값(`AppSettings.aiModel`)도
  사다리 맨 앞을 따라가게 했다 — 따로 적혀 있던 `'gemini-2.5-flash-lite'` 가 두 번째 자리였다.
  직접 입력 칸의 예시 문구(9개 언어)도 `gemini-3.5-flash-lite` 로.
  - 목록을 받는 평소 길은 원래도 괜찮았다: `pickCheapest` 가 flash-lite 중 숫자가 큰
    3.5 를 고른다(시험으로 못 박았다)
  - `gemini-3.1-flash-lite` 가 값은 더 싸지만($0.25/$1.50 vs 3.5 의 $0.30/$2.50)
    **2027-05-07 종료**가 잡혀 있어 사다리에 넣지 않았다
  - 10-08: `gemini-3.5-flash`·`gemini-3.7-flash` 폐기(각각 3.6·3.8 로 자동 연결). 사다리와 무관
  - 10-13: `gemini-4-argon` 정식. 최고급이라 이 앱과 무관
- **OpenAI — 그대로.** `gpt-5.6-terra/luna/sol` 셋 다 현행. `gpt-5-mini` 는 12-11 종료 그대로라
  그 전에 보루에서 뺀다. GPT-6 세대가 9월에 나왔다(`gpt-6-luna` $0.10/$0.50 — 5.6-luna 의
  절반 이하, `gpt-6.1-sol` $2/$10). 6세대에는 중간 급(terra) 이름이 아직 없고 5.6 폐기 공지도
  없어서 이번에는 손대지 않았다
- **Anthropic — 그대로.** `claude-haiku-4-5-20251001` 현행, 10-16 아침에 다시 봐도 폐기 공지
  없음(하한 "10-15 이후" 그대로 — 이제부터는 언제든 공지가 날 수 있다). 새 haiku 없음.
  `claude-sonnet-5` 현행(하한 2027-06-30). 09-30 에 Sonnet 4.5 가 공지 두 달 뒤 종료로 잡혔다 —
  haiku 도 같은 간격이면 공지 뒤 두 달은 여유가 있다(짐작이다)
- **xAI — 그대로.** `grok-4.6`·`grok-4.3` 현행. `grok-4.7`(09-21)이 나왔지만 값이 4.6 과 같다.
  - 남은 의심 하나: xAI 목록에 `grok-4.20-0309-*` 나 `grok-voice-think-fast-2.0` 이 섞여 오면
    `tierRank` 가 그쪽을 먼저 고를 수 있다(4.20 이 숫자로 4.7 보다 크고, 음성 모델 이름에
    `fast` 가 들어 있다). 실제 목록 응답을 못 봐서 고치지 않았다 — 키로 목록을 한 번 받아 보고 정한다

## 마감에 걸어 둔 것 (`_ops/DEADLINES.md`)

- 2026-10-15 · claude-haiku-4-5 종료 하한 — 폐기 공지 확인
- 2026-12-11 · gpt-5 세대 종료 — 사다리에서 `gpt-5-mini` 보루를 뺀다
