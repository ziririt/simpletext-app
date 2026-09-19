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

## 마감에 걸어 둔 것 (`_ops/DEADLINES.md`)

- 2026-10-15 · claude-haiku-4-5 종료 하한 — 폐기 공지 확인
- 2026-12-11 · gpt-5 세대 종료 — 사다리에서 `gpt-5-mini` 보루를 뺀다
