/// 1단 — 복사한 순간의 증거로 출처 찾기 시험.
///
/// 2026-08-27 소유자 신고 — "디텍팅이 거의 안 된다."
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/source_detect.dart';

void main() {
  group('주소', () {
    test('다섯 서비스 주소를 안다', () {
      expect(sourceFromCapture('https://chatgpt.com/c/abc').name, kChatGpt);
      expect(sourceFromCapture('https://claude.ai/chat/abc').name, kClaude);
      expect(sourceFromCapture('https://gemini.google.com/app/x').name, kGemini);
      expect(sourceFromCapture('https://www.perplexity.ai/search/x').name,
          kPerplexity);
      expect(sourceFromCapture('https://grok.com/chat/x').name, kGrok);
    });

    test('주소로 찾은 것은 추측이 아니다', () {
      expect(sourceFromCapture('https://claude.ai/chat/x').certain, isTrue);
    });

    test('큰 글자로 와도 같다 — 주소는 대소문자를 안 가린다', () {
      expect(sourceFromCapture('HTTPS://ChatGPT.COM/c/1').name, kChatGpt);
    });

    test('링크에 붙어 오는 utm 표식도 잡는다', () {
      expect(
          sourceFromCapture('https://example.com/a?utm_source=chatgpt.com')
              .name,
          kChatGpt);
    });

    test('옛 이름도 그대로 돈다', () {
      expect(sourceFromUrl('https://chat.openai.com/c/1').name, kChatGpt);
    });
  });

  group('HTML 조각의 표식', () {
    test('오픈AI가 제 화면에 박아 둔 이름', () {
      expect(
          sourceFromCapture(
                  '<div data-message-author-role="assistant">안녕</div>')
              .name,
          kChatGpt);
    });

    test('클로드의 글꼴 클래스', () {
      expect(
          sourceFromCapture('<div class="font-claude-message">안녕</div>').name,
          kClaude);
    });

    test('제미나이의 응답 칸', () {
      expect(
          sourceFromCapture('<message-content class="model-response-text">')
              .name,
          kGemini);
    });

    test('표식으로 찾은 것도 확정이다 — 사용자가 어떻게 물어보든 안 바뀌는 것이라', () {
      expect(
          sourceFromCapture('<div class="font-claude-message">').certain,
          isTrue);
    });
  });

  group('안 찍는 자리', () {
    test('빈 증거', () {
      expect(sourceFromCapture(null).isKnown, isFalse);
      expect(sourceFromCapture('').isKnown, isFalse);
    });

    test('아무 사이트나', () {
      expect(sourceFromCapture('https://news.naver.com/a').isKnown, isFalse);
    });

    test('두 서비스가 함께 보이면 아무 말도 안 한다', () {
      // 여러 창에서 긁어모은 글일 수 있다. 하나를 골라 박으면 그건 거짓이다.
      expect(
          sourceFromCapture('https://chatgpt.com/c/1 https://claude.ai/chat/2')
              .isKnown,
          isFalse);
    });

    test('테일윈드 기본 클래스에는 안 걸린다 — prose 는 챗지피티에도 퍼플렉시티에도 있다', () {
      expect(sourceFromCapture('<div class="prose dark:prose-invert">').isKnown,
          isFalse);
    });
  });
}
