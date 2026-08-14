/// 최근 목록(MRU) 순서 규칙 테스트.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/mru.dart';

void main() {
  group('자주 쓰는 지시문 순서 (2026-08-14)', () {
    test('새로 넣은 것이 맨 위로 온다', () {
      final l = <String>['가', '나'];
      mruInsert(l, '다');
      expect(l.first, '다');
      expect(l, ['다', '가', '나']);
    });

    test('이미 있던 것을 다시 쓰면 올라오기만 하고 늘어나지 않는다', () {
      final l = <String>['가', '나', '다'];
      mruInsert(l, '다');
      expect(l, ['다', '가', '나']);
      expect(l.length, 3);
    });

    test('앞뒤 공백만 다른 것은 같은 것으로 본다', () {
      final l = <String>['글머리를 점으로 바꿔'];
      mruInsert(l, '  글머리를 점으로 바꿔  ');
      expect(l.length, 1);
      expect(l.first, '글머리를 점으로 바꿔');
    });

    test('빈 문자열은 넣지 않는다', () {
      final l = <String>['가'];
      mruInsert(l, '   ');
      expect(l, ['가']);
    });

    test('상한을 넘으면 오래된 것부터 버린다', () {
      final l = <String>[];
      for (var i = 0; i < 35; i++) {
        mruInsert(l, '지시 $i', max: 30);
      }
      expect(l.length, 30);
      expect(l.first, '지시 34');
      expect(l.contains('지시 4'), false, reason: '오래된 것이 안 밀려났다');
    });
  });
}
