/// 자동 태그가 '이름'만 뽑는지 못 박는다.
///
/// 2026-08-17 소유자 신고에서 나온 테스트다.
///
///     "자동 태그. 제목만 분석하냐? 안된다. 그리고 과연 이게 무슨 핵심
///      태그냐. 동사는 특히 안된다."
///
/// 화면에 붙어 있던 것: 소비 · 해야하는데 · 국채금리 · AI · 꺾인
/// 다섯 중 둘이 문장 조각이었다. 저런 것이 하나만 섞여도 나머지까지
/// 못 미더워진다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tag_suggest.dart';

void main() {
  group('동사·형용사 활용형은 태그가 아니다', () {
    test('신고에 나온 그 글에서 문장 조각이 안 나온다', () {
      final tags = suggestTags(
        '기록 뒤의 청구서 — 소비의 균열',
        '''
소비가 꺾인 신호가 여럿이다. 국채금리는 계속 올랐고, 소비 지표는
석 달째 내려가고 있다. 지금 해야하는데 미루면 늦는다. AI 투자에
들어간 돈이 실적으로 돌아오는지를 봐야 한다. 소비와 국채금리,
그리고 AI 이 셋이 이번 분기의 축이다.
''',
      );
      expect(tags, isNot(contains('해야하는데')));
      expect(tags, isNot(contains('꺾인')));
      expect(tags, contains('소비'));
      expect(tags, contains('국채금리'));
    });

    test('어미로 끝나는 말은 버린다', () {
      final tags = suggestTags('', '''
검토해야 하는데 시간이 없다. 확인하려고 했지만 못 했다.
진행하면서 정리하도록 하겠습니다. 올랐다 내렸다 반복한다.
''');
      for (final bad in [
        '해야하는데',
        '하는데',
        '확인하려고',
        '했지만',
        '진행하면서',
        '정리하도록',
        '하겠습니다',
        '반복한다',
      ]) {
        expect(tags, isNot(contains(bad)), reason: bad);
      }
    });

    test('한자어 이름은 살아남는다 — 확인·원인·요인은 동사가 아니다', () {
      final tags = suggestTags('', '''
확인 확인 확인. 원인 원인 원인. 요인 요인 요인.
보고 보고 보고. 문서 문서 문서. 수요 수요 수요.
''', max: 6);
      for (final good in ['확인', '원인', '요인', '보고', '문서', '수요']) {
        expect(tags, contains(good), reason: good);
      }
    });
  });

  group('제목만 보지 않는다', () {
    test('본문에서 되풀이되는 말이 제목 낱말보다 앞선다', () {
      final tags = suggestTags('잡담', '''
반도체 이야기다. 반도체 수요가 늘고 반도체 가격이 올랐다.
반도체 재고는 줄었다. 반도체 업황이 좋다.
''', max: 2);
      expect(tags.first, '반도체');
    });

    test('제목에만 있는 말도 후보다', () {
      final tags = suggestTags('테슬라 실적', '자동차 판매가 늘었다.', max: 4);
      expect(tags, contains('테슬라'));
    });
  });

  group('예전 규칙은 그대로', () {
    test('숫자로 시작하면 버린다', () {
      final tags = suggestTags('', '2036년에는 45퍼센트 정도가 될 것이다.');
      expect(tags.any((t) => t.startsWith('2')), isFalse);
      expect(tags.any((t) => t.startsWith('4')), isFalse);
    });

    test('영문 대소문자 표기를 지킨다', () {
      final tags = suggestTags('AI 정리', 'ChatGPT와 AI 이야기. AI ChatGPT.', max: 3);
      expect(tags, contains('AI'));
      expect(tags, contains('ChatGPT'));
    });

    test('빈 글에서는 아무것도 안 뽑는다', () {
      expect(suggestTags('', ''), isEmpty);
    });
  });
}
