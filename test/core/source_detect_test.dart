/// 출처 감지 규칙 테스트.
///
/// 여기서 지키려는 것은 정확도가 아니라 **정직함**이다. 애매하면 아무 말도
/// 하지 않아야 한다. 틀린 출처를 조용히 박아 두는 것은 안 하느니만 못하다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/source_detect.dart';

const int _day = 24 * 60 * 60 * 1000;

void main() {
  group('1단 — 클립보드 주소로 확실히 알아내기', () {
    test('주요 서비스 주소를 알아본다', () {
      expect(sourceFromUrl('https://chatgpt.com/c/abc').name, kChatGpt);
      expect(sourceFromUrl('https://chat.openai.com/c/abc').name, kChatGpt);
      expect(sourceFromUrl('https://claude.ai/chat/x').name, kClaude);
      expect(sourceFromUrl('https://gemini.google.com/app').name, kGemini);
      expect(sourceFromUrl('https://www.perplexity.ai/search/x').name, kPerplexity);
      expect(sourceFromUrl('https://grok.com/chat').name, kGrok);
    });

    test('주소로 찾으면 추측이 아니라 확실이다', () {
      expect(sourceFromUrl('https://claude.ai/x').certain, isTrue);
    });

    test('HTML 안에 섞여 있어도 찾는다', () {
      const html = '<meta content="https://chatgpt.com/share/xyz">';
      expect(sourceFromUrl(html).name, kChatGpt);
    });

    test('모르는 주소면 빈 결과', () {
      expect(sourceFromUrl('https://naver.com').isKnown, isFalse);
      expect(sourceFromUrl('').isKnown, isFalse);
      expect(sourceFromUrl(null).isKnown, isFalse);
    });
  });

  group('2단 — 생김새로 추측', () {
    test('짧은 글은 아예 찍지 않는다', () {
      // 짧으면 어느 모델이 써도 비슷하게 생겼다.
      expect(guessSource('안녕하세요. 반갑습니다.').isKnown, isFalse);
    });

    test('각주와 출처 목록이 있으면 검색형', () {
      final t = '테슬라 주가는 최근 상승했습니다[1]. 인도량이 예상을 넘었고[2], '
              '에너지 부문도 성장했습니다[3]. 다만 마진 압박은 계속되고 있습니다. '
              '분석가들은 목표가를 상향했습니다. 시장은 이를 긍정적으로 봤습니다.\n\n'
              '출처\n'
              'https://example.com/a\nhttps://example.com/b\n' *
          2;
      final g = guessSource(t);
      expect(g.name, kPerplexity);
      expect(g.certain, isFalse); // 생김새로 찾은 것은 언제나 추측이다
    });

    test('구분선과 굵은 번호 머리말이 있으면 ChatGPT 쪽', () {
      final t = '좋습니다. 정리해 드리겠습니다.\n\n'
          '1. **첫째 항목** — 이것에 대한 설명입니다. 충분히 길게 씁니다.\n'
          '2. **둘째 항목** — 이것도 설명입니다. 충분히 길게 씁니다.\n'
          '3. **셋째 항목** — 마찬가지로 설명입니다.\n\n'
          '---\n\n'
          '## 다음 단계\n\n'
          '- 하나\n- 둘\n- 셋\n\n'
          '---\n\n'
          '원하시면 더 자세히 풀어 드릴까요?\n' * 2;
      expect(guessSource(t).name, kChatGpt);
    });

    test('별표 글머리에 표 하나로는 아무 말도 안 한다', () {
      // 2026-08-17에 뒤집힌 시험이다. 전에는 여기서 kGemini를 기대했다.
      //
      // 그런데 소유자가 보내 준 **실제 퍼플렉시티 원문도 별표 글머리를
      // 쓴다.** 그 가정 위에 세운 규칙 때문에 퍼플렉시티 원문이 제미나이로
      // 판정되고 있었다 — 못 잡는 것보다 나쁘다.
      //
      // 별표 글머리에 표가 하나 붙은 글은 정말로 애매하다. 그러면 아무
      // 말도 안 하는 것이 맞다. 실제 제미나이는 소제목·구분선·표·코드·
      // 굵게가 한꺼번에 들어 있고, 그건 test/core/llm_samples.dart의
      // 원문으로 확인한다.
      final t = '물론입니다! 아래에 정리했습니다.\n\n'
          '* 첫 번째 항목에 대한 설명입니다. 조금 길게 적습니다.\n'
          '* 두 번째 항목에 대한 설명입니다. 조금 길게 적습니다.\n'
          '* 세 번째 항목에 대한 설명입니다. 조금 길게 적습니다.\n'
          '* 네 번째 항목에 대한 설명입니다.\n\n'
          '| 항목 | 값 |\n| --- | --- |\n| 하나 | 1 |\n| 둘 | 2 |\n' * 2;
      expect(guessSource(t).isKnown, isFalse);
    });

    test('긴 문단에 불릿이 적으면 Claude 쪽', () {
      final para = '이 문제를 이해하려면 먼저 배경을 봐야 합니다. '
          '지난 몇 년 동안 시장은 크게 바뀌었고, 그 변화의 원인은 하나가 아니라 '
          '여럿이 겹친 결과였습니다. 그래서 어느 한 가지만 짚어서는 전체 그림이 '
          '보이지 않습니다. 순서대로 짚어 보겠습니다. 먼저 수요 쪽입니다. '
          '수요는 지난 분기까지 꾸준히 늘었지만 증가 속도는 눈에 띄게 느려졌고, '
          '그 원인으로는 금리와 보조금 축소가 함께 꼽힙니다. 다음은 공급입니다.';
      final t = '## 배경\n\n$para\n\n$para\n\n$para\n\n$para';
      expect(guessSource(t).name, kClaude);
    });

    test('사람이 쓴 평범한 글에는 이름을 붙이지 않는다', () {
      // 이게 이 파일에서 가장 중요한 테스트다. 처음 만들 때 이 문턱이 없어서
      // 회의 메모가 Claude로 판정됐다 — 문단이 길고 불릿이 없다는 이유만으로.
      // 사람이 쓴 글이 원래 그렇게 생겼다.
      final t = '오늘 회의에서 나온 이야기를 적어 둡니다. '
              '다음 주까지 정리하기로 했고, 담당은 아직 안 정해졌습니다. '
              '예산은 다시 확인이 필요합니다. 일정은 다음 회의에서 잡습니다.\n' *
          4;
      expect(guessSource(t).isKnown, isFalse);
    });

    test('서식은 있는데 특징이 섞이면 아무 말도 안 한다', () {
      final t = '## 회의 메모\n\n'
              '- 담당 미정\n- 예산 재확인\n\n'
              '이번 주에 결정할 것은 두 가지입니다. 하나는 일정이고 다른 하나는 '
              '범위입니다. 둘 다 다음 회의에서 정합니다.\n\n' *
          3;
      expect(guessSource(t).isKnown, isFalse);
    });

    test('빈 글에서 죽지 않는다', () {
      expect(guessSource('').isKnown, isFalse);
      expect(guessSource('\n\n\n').isKnown, isFalse);
    });
  });

  group('화면에 쓸 이름', () {
    test('확실하면 그대로, 추측이면 꼬리표를 붙인다', () {
      expect(sourceLabel(const SourceGuess(kChatGpt, certain: true), '(추정)'),
          'ChatGPT');
      expect(sourceLabel(const SourceGuess(kChatGpt), '(추정)'), 'ChatGPT(추정)');
    });

    test('모르면 빈 문자열', () {
      expect(sourceLabel(SourceGuess.unknown, '(추정)'), '');
    });
  });

  group('신선도 — AI 답변은 썩는다', () {
    const now = 1000 * _day;

    test('90일이 기준이다', () {
      expect(kStaleAfterDays, 90);
      expect(isStale(pastedAt: now - 89 * _day, nowMs: now), isFalse);
      expect(isStale(pastedAt: now - 90 * _day, nowMs: now), isTrue);
    });

    test('직접 쓴 글에는 낡았다고 말하지 않는다', () {
      // 붙여넣은 기록이 없으면 AI 답변이 아니다. 경고하면 잔소리가 된다.
      expect(isStale(pastedAt: 0, nowMs: now), isFalse);
      expect(isStale(pastedAt: -1, nowMs: now), isFalse);
    });

    test('며칠 됐는지 센다', () {
      expect(daysSincePaste(pastedAt: now - 5 * _day, nowMs: now), 5);
      expect(daysSincePaste(pastedAt: now, nowMs: now), 0);
      expect(daysSincePaste(pastedAt: 0, nowMs: now), -1);
    });
  });
}
