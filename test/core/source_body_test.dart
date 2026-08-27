/// 본문에 박힌 링크로 출처 찾기 시험.
///
/// 2026-08-27 저녁 실측에서 알게 된 것 — 요즘 AI 앱의 '복사' 단추는
/// 마크다운 글자만 넣는다. 클립보드에 HTML 이 아예 안 실린다. 그때 남는
/// 유일한 증거가 본문에 박힌 링크다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/source_detect.dart';

void main() {
  group('본문 링크', () {
    test('출처 목록에 주소가 있으면 잡는다', () {
      const t = '테슬라가 하락했습니다.\n\n출처\n1. https://www.perplexity.ai/search/abc';
      expect(sourceFromBody(t).name, kPerplexity);
    });

    test('링크에 붙어 온 utm 표식', () {
      const t = '자세한 것은 [여기](https://example.com/a?utm_source=chatgpt.com)를 보세요.';
      expect(sourceFromBody(t).name, kChatGpt);
    });

    test('클로드 공유 링크', () {
      expect(sourceFromBody('원문: https://claude.ai/chat/abc').name, kClaude);
    });
  });

  group('안 찍는 자리 — 여기가 이 함수의 전부다', () {
    test('낱말로만 나오면 안 센다', () {
      // '퍼플렉시티가 좋다'고 쓴 글이 퍼플렉시티 답변일 리 없다.
      expect(sourceFromBody('perplexity 가 요즘 좋다고 하네요').isKnown, isFalse);
      expect(sourceFromBody('claude.ai 라는 사이트').isKnown, isFalse);
    });

    test('여러 서비스가 함께 나오면 아무 말도 안 한다', () {
      // 오늘 이 앱을 만들며 쓴 설계 문서가 정확히 이 경우다.
      const t = '''
비교 대상
- https://chatgpt.com
- https://claude.ai
- https://www.perplexity.ai
''';
      expect(sourceFromBody(t).isKnown, isFalse);
    });

    test('빈 글', () {
      expect(sourceFromBody('').isKnown, isFalse);
    });

    test('아무 링크나', () {
      expect(sourceFromBody('https://news.naver.com/a').isKnown, isFalse);
    });

    test('x.com 링크 하나로는 그록이라고 안 한다', () {
      // 어느 AI 든 X 를 인용할 수 있다.
      expect(sourceFromBody('https://x.com/elonmusk/status/1').isKnown, isFalse);
    });
  });

  test('본문으로 찾은 것도 증거다 — 추정이 아니다', () {
    expect(sourceFromBody('https://www.perplexity.ai/search/x').certain, isTrue);
  });
}
