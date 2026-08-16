/// 실제 원문 다섯 편으로 고정한 출처 감지.
///
/// 2026-08-17 소유자 신고 — "여러 LLM의 답변을 붙여넣기 해 봤더니 출처
/// 분석을 자동으로 하나도 못하네?"
///
/// 그때까지 규칙은 **짐작으로** 짜여 있었다. 각주(`[1]`)를 근거로 삼았는데,
/// 소유자가 보내 준 실제 원문 다섯 편에는 **각주가 하나도 없었다.**
/// 엉뚱한 데를 보고 있었던 것이다. 게다가 별표 글머리만 보고 제미나이로
/// 찍는 규칙 때문에 **퍼플렉시티 원문이 제미나이로 판정됐다** —
/// 못 잡는 것보다 나쁘다.
///
/// 그래서 이 파일이 있다. 규칙을 건드릴 때마다 이 다섯이 제대로 나오는지
/// 자동으로 확인된다. 눈으로 보고 고치는 것과 원문을 놓고 고치는 것의
/// 차이가 아주 큰 자리다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/source_detect.dart';

import 'llm_samples.dart';

void main() {
  group('실제 원문 다섯 편', () {
    test('ChatGPT — 인용 링크의 utm_source가 표식이다', () {
      final g = guessSource(sampleChatgpt);
      expect(g.name, kChatGpt);
      // 우리가 만든 규칙이 아니라 OpenAI가 스스로 찍는 값이다.
      // 그러니 이건 추측이 아니라 사실이고, '(추정)'을 붙이면 안 된다.
      expect(g.certain, isTrue);
    });

    test('Claude — 꾸밈 없이 긴 줄글 문단', () {
      expect(guessSource(sampleClaude).name, kClaude);
    });

    test('Gemini — 소제목·구분선·표·코드·굵게가 전부 있다', () {
      expect(guessSource(sampleGemini).name, kGemini);
    });

    test("Grok — 글머리가 '•' 글자 그 자체", () {
      expect(guessSource(sampleGrok).name, kGrok);
    });

    test('Perplexity — 깊게 겹친 별표 글머리, 꾸밈은 0', () {
      // 2026-08-17 이전에는 이 원문이 Gemini로 판정됐다. 별표 글머리만
      // 보고 찍었기 때문이다. 이 시험이 그 재발을 막는다.
      expect(guessSource(samplePerplexity).name, kPerplexity);
    });

    test('생김새로 찾은 것은 확실이 아니다 — utm 표식이 있는 ChatGPT만 예외', () {
      for (final s in [sampleClaude, sampleGemini, sampleGrok, samplePerplexity]) {
        expect(guessSource(s).certain, isFalse);
      }
    });
  });

  group('다섯 편의 생김새가 실제로 갈리는지', () {
    test('다섯 개 이름이 서로 겹치지 않는다', () {
      final names = <String>{
        guessSource(sampleChatgpt).name,
        guessSource(sampleClaude).name,
        guessSource(sampleGemini).name,
        guessSource(sampleGrok).name,
        guessSource(samplePerplexity).name,
      };
      expect(names.length, 5);
      expect(names.contains(''), isFalse);
    });

    test('다섯 편 모두 각주가 없다 — 옛 규칙이 엉뚱한 데를 보고 있었다', () {
      for (final s in [
        sampleChatgpt,
        sampleClaude,
        sampleGemini,
        sampleGrok,
        samplePerplexity
      ]) {
        expect(citationCount(s), 0);
      }
    });
  });

  group('붙여넣기 덩이만 떼어 내도 그대로 잡힌다', () {
    test('이미 쓰던 메모 뒤에 붙여넣어도 판정이 흔들리지 않는다', () {
      const mine = '내가 쓰던 메모. 여기에 이것저것 적어 두었다. 아직 정리 전.\n\n';
      final after = mine + samplePerplexity;
      final chunk = insertedChunk(mine, after);
      expect(guessSource(chunk).name, kPerplexity);
    });
  });
}
