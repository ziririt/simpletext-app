/// 각주 모양이 여러 가지라는 것, 그리고 붙여넣은 덩이만 떼어 내는 것.
///
/// 2026-08-17 소유자 신고 — "여러 LLM의 답변을 붙여넣기 해 봤더니 출처
/// 분석을 자동으로 하나도 못하네? 퍼플렉시티조차도 인식하지 못하는 건
/// 문제가 있지 않니?"
///
/// 열어 보니 각주를 `[1]` 한 가지 모양으로만 세고 있었다. 요즘 복사해 오는
/// 글의 각주는 네댓 가지다. 여기서 그 모양들을 고정해 둔다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/source_detect.dart';

/// 검색형 답변 한 편. 각주 모양만 갈아 끼워 가며 쓴다.
String _searchAnswer(String c1, String c2, String c3) =>
    '테슬라의 최근 인도량은 시장 예상을 웃돌았습니다$c1. '
    '특히 중국 공장의 가동률이 회복된 것이 컸고$c2, '
    '에너지 저장 부문도 분기 기준 최대 실적을 냈습니다$c3. '
    '다만 차량 부문의 총마진은 여전히 압박을 받고 있습니다. '
    '분석가들은 목표 주가를 소폭 올렸지만 의견은 갈립니다.\n\n'
    '출처\n'
    'https://example.com/a\n'
    'https://example.com/b\n'
    'https://example.com/c\n';

void main() {
  group('각주 모양 — 하나만 알면 나머지를 다 놓친다', () {
    test('대괄호 [1]', () {
      expect(guessSource(_searchAnswer('[1]', '[2]', '[3]')).name, kPerplexity);
    });

    test('링크가 붙은 [1](주소)', () {
      final t = _searchAnswer(
          '[1](https://example.com/a)',
          '[2](https://example.com/b)',
          '[3](https://example.com/c)');
      expect(guessSource(t).name, kPerplexity);
    });

    test('각주 표기 [^1]', () {
      expect(
          guessSource(_searchAnswer('[^1]', '[^2]', '[^3]')).name, kPerplexity);
    });

    test('위첨자 ¹²³ — 화면에서 보기 좋으라고 쓰는 것이라 복사하면 따라온다', () {
      expect(
          guessSource(_searchAnswer('¹', '²', '³')).name, kPerplexity);
    });

    test('인라인 각주가 하나도 안 따라와도 끝의 출처 뭉치로 잡는다', () {
      const t = '테슬라의 최근 인도량은 시장 예상을 웃돌았습니다. '
          '특히 중국 공장의 가동률이 회복된 것이 컸고, 에너지 저장 부문도 '
          '분기 기준 최대 실적을 냈습니다. 다만 차량 부문의 총마진은 여전히 '
          '압박을 받고 있습니다. 분석가들은 목표 주가를 소폭 올렸습니다.\n\n'
          '출처:\n'
          '[1] https://example.com/a\n'
          '[2] https://example.com/b\n'
          '[3] https://example.com/c\n'
          '[4] https://example.com/d\n';
      expect(guessSource(t).name, kPerplexity);
    });

    test('세는 함수는 모양을 가리지 않는다', () {
      expect(citationCount('가[1] 나[2] 다[3]'), 3);
      expect(citationCount('가[^1] 나[^2]'), 2);
      expect(citationCount('가¹ 나² 다³'), 3);
      expect(citationCount('가[web:1] 나[post:2]'), 2);
    });
  });

  group('Grok — 점수표에 아예 없었다', () {
    test('[web:n] [post:n] 모양은 Grok이 쓴다', () {
      const t = '최근 X에서 이 주제가 많이 논의되고 있습니다[post:1]. '
          '보도에 따르면 인도량은 예상을 웃돌았고[web:2], 에너지 부문도 '
          '분기 최대 실적을 냈습니다[web:3]. 다만 마진 압박은 이어집니다. '
          '시장의 반응은 아직 엇갈리는 편입니다.\n\n'
          '- 인도량 증가\n- 마진 압박 지속\n';
      expect(guessSource(t).name, kGrok);
    });
  });

  group('문턱을 200자에서 140자로 내렸다', () {
    test('짧게 묻고 짧게 받은 답도 잡힌다', () {
      const t = '요약하면 세 가지입니다[1]. 첫째는 인도량이 예상을 웃돈 것이고[2], '
          '둘째는 차량 부문의 총마진 압박입니다[3]. 셋째는 에너지 저장 부문의 성장입니다. '
          '순서대로 짚어 보겠습니다. 먼저 인도량부터 보겠습니다.\n\n'
          '출처\nhttps://example.com/a\n';
      expect(t.trim().length, greaterThanOrEqualTo(140));
      expect(guessSource(t).name, kPerplexity);
    });

    test('그래도 아주 짧으면 안 찍는다', () {
      expect(guessSource('안녕하세요[1]. 반갑습니다[2].').isKnown, isFalse);
    });
  });

  group('사람이 쓴 글은 여전히 건드리지 않는다', () {
    test('서식도 각주도 없으면 아무 말 안 한다', () {
      final t = '오늘 회의에서 나온 이야기를 적어 둡니다. '
              '다음 주까지 정리하기로 했고, 담당은 아직 안 정해졌습니다. '
              '예산은 다시 확인이 필요합니다. 일정은 다음 회의에서 잡습니다.\n' *
          4;
      expect(guessSource(t).isKnown, isFalse);
    });

    test('주소 몇 개 적어 둔 메모를 검색형으로 보지 않는다', () {
      final t = '참고할 링크를 모아 둡니다. 나중에 다시 봅니다.\n'
              'https://example.com/a\n'
              'https://example.com/b\n' *
          3;
      expect(guessSource(t).isKnown, isFalse);
    });
  });

  group('붙여넣은 덩이만 떼어 내기', () {
    test('가운데에 끼워 넣은 것', () {
      expect(insertedChunk('가나다', '가나XY다'), 'XY');
    });

    test('맨 앞에 붙인 것', () {
      expect(insertedChunk('나다', 'XY나다'), 'XY');
    });

    test('맨 뒤에 붙인 것', () {
      expect(insertedChunk('가나', '가나XY'), 'XY');
    });

    test('빈 글에 붙여넣기', () {
      expect(insertedChunk('', '붙여넣은 글'), '붙여넣은 글');
    });

    test('줄어들었으면 빈 문자열 — 지운 것은 붙여넣기가 아니다', () {
      expect(insertedChunk('가나다', '가다'), '');
      expect(insertedChunk('가나다', '가나다'), '');
    });

    test('앞뒤가 겹쳐도 길이가 어긋나지 않는다', () {
      // 'aaa' 사이에 'aa'를 끼우면 어디를 잘라도 결과 글자 수는 같아야 한다.
      expect(insertedChunk('aaa', 'aaaaa').length, 2);
    });
  });
}
