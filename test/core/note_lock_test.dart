// 잠긴 메모에서 본문이 새는 구멍 넷 — 눈으로는 절대 못 지키는 자리.
//
// 잠금은 뚫리는 순간 기능이 아니라 거짓말이 된다. 그래서 판정을 순수
// 함수로 떼어 두고 여기서 지킨다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/note_lock.dart';

void main() {
  const body = '테슬라 실적은 어쩌고\n둘째 줄\n\n셋째 줄';

  group('검색', () {
    test('안 잠근 메모는 본문까지 뒤진다', () {
      final h = searchHaystack(
          locked: false,
          title: '제목',
          body: body,
          tags: ['투자'],
          source: 'ChatGPT');
      expect(h.contains('실적'), isTrue);
    });

    test('잠근 메모는 본문을 안 내준다', () {
      // 글자를 안 보여 주고도, 본문에만 있는 낱말로 그 메모를 찾아낼 수
      // 있으면 내용이 샌 것이다.
      final h = searchHaystack(
          locked: true,
          title: '제목',
          body: body,
          tags: ['투자'],
          source: 'ChatGPT');
      expect(h.contains('실적'), isFalse);
      expect(h.contains('제목'), isTrue);
      expect(h.contains('투자'), isTrue);
      expect(h.contains('ChatGPT'), isTrue);
    });
  });

  group('목록 미리보기', () {
    test('안 잠근 메모는 빈 줄을 걸러 한 문단으로', () {
      expect(listPreview(locked: false, body: body),
          '테슬라 실적은 어쩌고  둘째 줄  셋째 줄');
    });

    test('잠근 메모는 빈 문자열', () {
      expect(listPreview(locked: true, body: body), '');
    });
  });

  group('길게 눌러 뜨는 미리보기', () {
    test('잠근 메모는 빈 문자열', () {
      expect(peekBody(locked: true, body: body), '');
      expect(peekBody(locked: false, body: body), body.trim());
    });
  });

  group('제목 줄', () {
    test('제목이 있으면 잠금과 상관없이 제목', () {
      expect(listTitle(locked: true, title: '  제목  ', body: body), '제목');
    });

    test('제목이 없으면 본문 첫 줄 하나만 올린다 — 안 잠근 경우', () {
      // 이은 문단이 아니라 첫 줄이다. 미리보기 카드의 제목이 본문 두 줄로
      // 부풀어 오르던 것을 여기서 막는다.
      expect(listTitle(locked: false, title: '', body: body),
          '테슬라 실적은 어쩌고');
    });

    test('제목이 없고 잠갔으면 아무것도 안 올린다', () {
      // 가장 놓치기 쉬운 구멍. 제목 줄로 본문 첫 줄이 그대로 샌다.
      expect(listTitle(locked: true, title: '', body: body), '');
    });
  });
}
