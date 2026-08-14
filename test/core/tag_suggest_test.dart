/// 로컬 태그 추출기 테스트.
///
/// fixture는 소유자가 2026-08-14에 실제로 쓰던 메모다(스크린샷으로 받은 것).
/// 정답 한 벌을 통째로 박지 않고 "무엇이 들어가야/빠져야 하는가"로 건다 —
/// 점수 계산을 조금 손봐도 의미가 유지되면 통과해야 하기 때문이다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tag_suggest.dart';

void main() {
  const title = 'AI가 일을 없앤 뒤에도, 인간은 살아갈 수 있을까';
  const body = '''
2~3년 은퇴 연결자금   20%
미국시장 핵심지수     45%
현금창출 AI 플랫폼    15%
반도체·네트워크       10%
전력·그리드·냉각      7%
로봇·물리적 AI 옵션    3%

머스크는 목적지를 보여준다. 그러나 목적지만 믿고 출발하면 다리 중간에서
기름이 떨어질 수 있다.

지금 필요한 것은 2036년에 돈이 사라질 것이라는 믿음이 아니다.
''';

  group('로컬 태그 추출 (2026-08-14)', () {
    test('개수 상한을 지킨다', () {
      expect(suggestTags(title, body).length, lessThanOrEqualTo(5));
      expect(suggestTags(title, body, max: 3).length, lessThanOrEqualTo(3));
    });

    test('제목에 나온 말이 우선 뽑힌다', () {
      final t = suggestTags(title, body);
      expect(t.contains('AI'), true, reason: '제목의 AI가 빠졌다: \$t');
    });

    test('조사를 잘라 낸다', () {
      final t = suggestTags('인간은 무엇인가', '인간은 인간을 인간이 말한다');
      expect(t.contains('인간'), true, reason: '조사가 안 잘렸다: \$t');
      expect(t.any((e) => e == '인간은' || e == '인간을' || e == '인간이'), false);
    });

    test('숫자로 시작하는 토큰은 태그가 되지 않는다', () {
      final t = suggestTags(title, body);
      expect(t.any((e) => RegExp(r'^[0-9]').hasMatch(e)), false, reason: '\$t');
    });

    test('흔한 말은 태그가 되지 않는다', () {
      final t = suggestTags(title, body);
      for (final bad in ['있을까', '그러나', '있다', '것이다']) {
        expect(t.contains(bad), false, reason: '\$bad 가 태그로 나왔다: \$t');
      }
    });

    test('한 글자와 지나치게 긴 말은 버린다', () {
      final t = suggestTags('수 를 가 의', '수 를 가 의');
      expect(t, isEmpty);
    });

    test('빈 입력이면 빈 목록', () {
      expect(suggestTags('', ''), isEmpty);
    });

    test('같은 말이 여러 번 나와도 태그는 하나다', () {
      final t = suggestTags('테슬라', '테슬라 테슬라 테슬라 실적');
      expect(t.where((e) => e == '테슬라').length, 1);
    });
  });
}
