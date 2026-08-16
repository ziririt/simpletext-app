/// 자동 제목 규칙 테스트.
/// 지키려는 것: **사용자가 정한 제목은 절대 덮지 않는다.**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/auto_meta.dart';

void main() {
  group('본문에서 제목 뽑기', () {
    test('첫 줄을 쓴다', () {
      expect(autoTitle('테슬라 정리\n\n본문'), '테슬라 정리');
    });

    test('빈 줄은 건너뛴다', () {
      expect(autoTitle('\n\n   \n진짜 첫 줄'), '진짜 첫 줄');
    });

    test('소제목 표시를 벗긴다', () {
      expect(autoTitle('## 요약\n본문'), '요약');
      expect(autoTitle('###### 깊은 소제목'), '깊은 소제목');
    });

    test('굵게·기울임·코드 표시를 벗긴다', () {
      // 이걸 안 하면 목록이 기호밭이 된다.
      expect(autoTitle('**결론**'), '결론');
      expect(autoTitle('*강조된 첫 줄*'), '강조된 첫 줄');
      expect(autoTitle('`코드처럼 쓴 제목`'), '코드처럼 쓴 제목');
    });

    test('글머리와 번호를 벗긴다', () {
      expect(autoTitle('- 첫 항목'), '첫 항목');
      expect(autoTitle('1. 첫 항목'), '첫 항목');
      expect(autoTitle('• 첫 항목'), '첫 항목');
    });

    test('링크는 글자만 남긴다', () {
      expect(autoTitle('[테슬라 실적](https://example.com/very/long)'), '테슬라 실적');
    });

    test('각주 번호를 지운다', () {
      expect(autoTitle('테슬라 주가 상승[1]'), '테슬라 주가 상승');
    });

    test('끝의 콜론을 뗀다', () {
      expect(autoTitle('오늘 정리한 것:'), '오늘 정리한 것');
    });

    test('가로줄이나 표 구분줄은 제목이 아니다', () {
      expect(autoTitle('---\n진짜 제목'), '진짜 제목');
      expect(autoTitle('| --- | --- |\n진짜 제목'), '진짜 제목');
      expect(autoTitle('===\n진짜 제목'), '진짜 제목');
    });

    test('너무 길면 낱말 사이에서 자른다', () {
      const long = 'This is a fairly long first line that should be trimmed somewhere sensible';
      final t = autoTitle(long);
      expect(t.length, lessThanOrEqualTo(40));
      expect(t.endsWith(' '), isFalse);
      // 낱말 한가운데서 자르지 않았는지
      expect(long.startsWith(t), isTrue);
    });

    test('띄어쓰기가 없으면 그냥 자른다', () {
      // 한국어·중국어에는 자를 자리가 없을 수 있다. 그래도 잘라야 한다.
      final t = autoTitle('가' * 100);
      expect(t.length, 40);
    });

    test('본문이 비면 빈 제목', () {
      expect(autoTitle(''), '');
      expect(autoTitle('\n\n  \n'), '');
      expect(autoTitle('---\n***\n'), '');
    });
  });

  group('언제 손을 떼는가', () {
    test('자동이 꺼져 있으면 다시 짓지 않는다', () {
      // 이 한 줄이 이 기능의 전부라고 해도 된다. 사용자가 정한 제목을
      // 우리가 덮으면 도움이 아니라 고장이다.
      expect(canRetitle(auto: true), isTrue);
      expect(canRetitle(auto: false), isFalse);
    });

    test('제목을 쓰면 자동을 끈다', () {
      expect(stopAutoTitle('내가 정한 제목'), isTrue);
    });

    test('비우기만 한 것은 끄지 않는다', () {
      // 지웠다는 건 "네가 알아서 해"에 가깝지 "이 빈 제목을 지켜라"가 아니다.
      expect(stopAutoTitle(''), isFalse);
      expect(stopAutoTitle('   '), isFalse);
    });
  });
}
