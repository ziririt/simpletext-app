/// 키→회사 판정과 모델 선별 규칙을 고정하는 테스트.
///
/// 2026-08-16 배경: "키를 넣어도 마법사가 안 된다" — OpenAI 키를 넣어도
/// 모델 드롭다운이 Gemini면 구글로 가서 거절당했다. 회사는 키가 정한다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/ai_provider.dart';

void main() {
  group('키 앞글자로 회사 판정', () {
    test('sk-ant- 는 Claude', () => expect(providerOfKey('sk-ant-api03-xx'), 'anthropic'));
    test('sk- 는 ChatGPT (sk-ant- 를 먼저 봐야 한다)',
        () => expect(providerOfKey('sk-proj-xxxx'), 'openai'));
    test('AIza 는 Gemini', () => expect(providerOfKey('AIzaSyXXXX'), 'google'));
    test('xai- 는 Grok', () => expect(providerOfKey('xai-xxxx'), 'xai'));
    test('모르는 형식은 null — 화면이 직접 지정을 안내한다',
        () => expect(providerOfKey('hello-world'), isNull));
    test('빈 키는 null', () => expect(providerOfKey('  '), isNull));
  });

  group('옛 설정 이관 — 모델 이름으로 회사 역산', () {
    test('gemini → google', () => expect(providerOfModel('gemini-2.5-flash-lite'), 'google'));
    test('claude → anthropic', () => expect(providerOfModel('claude-sonnet-5'), 'anthropic'));
    test('gpt → openai', () => expect(providerOfModel('gpt-5-mini'), 'openai'));
    test('grok → xai', () => expect(providerOfModel('grok-4.1-fast'), 'xai'));
    test('어긋난 조합을 걸러 낸다 — OpenAI 회사에 gemini 모델은 아니다',
        () => expect(modelMatchesProvider('gemini-2.5-flash-lite', 'openai'), isFalse));
  });

  group('예비 사다리', () {
    for (final p in const ['google', 'anthropic', 'openai', 'xai']) {
      test('$p 사다리는 비어 있지 않고 전부 제 회사 것이다', () {
        final l = defaultLadder(p);
        expect(l, isNotEmpty);
        for (final m in l) {
          expect(modelMatchesProvider(m, p), isTrue, reason: m);
        }
      });
    }
  });

  group('목록에서 제일 싼 등급의 최신을 고른다', () {
    test('구글 — 임베딩·이미지·음성은 걸러 내고 flash-lite 최신을 집는다', () {
      final pick = pickCheapest('google', [
        'gemini-2.5-pro',
        'gemini-2.0-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'text-embedding-004',
        'gemini-2.5-flash-image',
        'gemini-2.5-flash-preview-tts',
        'imagen-4.0-generate-001',
      ]);
      expect(pick, 'gemini-2.5-flash-lite');
    });

    test('구글 — flash-lite가 전부 폐지되면 flash로 내려간다 (자가 회복)', () {
      final pick = pickCheapest('google', ['gemini-3.0-flash', 'gemini-3.0-pro']);
      expect(pick, 'gemini-3.0-flash');
    });

    test('앤스로픽 — sonnet보다 haiku, haiku끼리는 최신', () {
      final pick = pickCheapest('anthropic', [
        'claude-sonnet-5',
        'claude-haiku-4-5-20251001',
        'claude-haiku-3-5-20241022',
        'claude-opus-4-1',
      ]);
      expect(pick, 'claude-haiku-4-5-20251001');
    });

    // 2026-08-17 — nano에서 mini로 바꿨다.
    //
    // 이 앱이 AI에게 시키는 일은 한국어 글을 다시 쓰는 것이라, 제일 작은
    // 모델이 자주 어그러진다. 어그러진 결과는 안 나온 것보다 나쁘다.
    // 메모 하나 고치는 값은 어차피 몇 원이라 아낄 자리가 아니다.
    test('OpenAI — mini 우선, 세대는 최신 (gpt-4.1-mini보다 gpt-5-mini)', () {
      final pick = pickCheapest('openai', [
        'gpt-5-nano',
        'gpt-4.1-mini',
        'gpt-5-mini',
        'gpt-4o-audio-preview',
        'text-embedding-3-small',
        'o3',
      ]);
      expect(pick, 'gpt-5-mini');
    });

    // 2026-08-17 — 소유자가 구글 AI 스튜디오 키를 넣었을 때 실제로 오는
    // 목록에 가깝게 적었다. 정식판과 시험판이 섞여 있고, 시험판 이름에
    // 붙은 날짜가 '더 최신'으로 읽히는 것이 함정이다.
    test('구글 — 시험판이 아니라 정식 flash-lite 를 고른다', () {
      final pick = pickCheapest('google', [
        'gemini-2.5-pro',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'gemini-2.5-flash-lite-preview-09-2025',
        'gemini-2.0-flash-lite',
        'gemini-embedding-001',
        'gemma-3-27b-it',
      ]);
      expect(pick, 'gemini-2.5-flash-lite');
    });

    test('정식판이 없으면 시험판이라도 고른다', () {
      expect(
          pickCheapest('google', [
            'gemini-3.0-flash-lite-preview-11-2026',
            'gemini-3.0-pro',
          ]),
          'gemini-3.0-flash-lite-preview-11-2026');
    });

    test('시험판 판별', () {
      expect(isPreviewModel('gemini-2.5-flash-lite-preview-09-2025'), isTrue);
      expect(isPreviewModel('gemini-2.0-flash-exp'), isTrue);
      expect(isPreviewModel('gemini-2.5-flash-lite'), isFalse);
      expect(isPreviewModel('claude-haiku-4-5-20251001'), isFalse);
      expect(isPreviewModel('gpt-5-mini-2025-08-07'), isFalse);
    });

    test('nano밖에 없으면 nano라도 고른다', () {
      expect(pickCheapest('openai', ['gpt-5-nano', 'gpt-5']), 'gpt-5-nano');
    });

    test('쓸 만한 게 하나도 없으면 null', () {
      expect(pickCheapest('google', ['text-embedding-004', 'imagen-4.0']), isNull);
    });
  });
}
