import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/capture_sig.dart';

void main() {
  group('붙여넣기 지문', () {
    test('빈 것은 빈 것이다', () {
      expect(captureSignature(null), '');
      expect(captureSignature(''), '');
    });

    test('맨 글자면 길이만 남긴다 — 표식이 없다는 것도 정보다', () {
      expect(captureSignature('## 장점\n**1. 실시간**'), 'plain:16');
    });

    test('클래스 이름을 낱개로 쪼갠다', () {
      final s = captureSignature('<div class="markdown prose dark">글</div>');
      expect(s.contains('markdown'), true);
      expect(s.contains('prose'), true);
      expect(s.contains('dark'), true);
    });

    test('글자는 한 자도 안 담는다', () {
      final s = captureSignature('<p class="x">비밀번호는 1234입니다</p>');
      expect(s.contains('비밀'), false);
      expect(s.contains('1234'), false);
      expect(s.contains('x'), true);
    });

    test('id 와 data-* 이름과 호스트를 담는다', () {
      final s = captureSignature(
          '<div id="root" data-message-author-role="assistant">'
          '<a href="https://gemini.google.com/app">ㄱ</a></div>');
      expect(s.contains('#root'), true);
      expect(s.contains('data-message-author-role'), true);
      expect(s.contains('@gemini.google.com'), true);
    });

    test('같은 이름이 여러 번 나와도 한 번만', () {
      final s = captureSignature('<p class="a">1</p><p class="a">2</p>');
      expect(s.split(' ').where((e) => e == 'a').length, 1);
    });

    test('너무 긴 이름은 버린다 — 본문이 클래스에 끼어든 경우다', () {
      final long = 'z' * 80;
      expect(captureSignature('<p class="$long">x</p>').contains(long), false);
    });

    test('길이를 넘기면 자른다', () {
      final many = List.generate(200, (i) => '<p class="c$i">x</p>').join();
      expect(captureSignature(many).length <= 400, true);
    });
  });
}
