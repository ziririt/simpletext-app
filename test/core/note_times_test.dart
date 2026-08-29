/// 글이 가진 두 시각의 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/note_times.dart';

void main() {
  const t0 = 1700000000000;
  const min = 60 * 1000;

  group('시작 시각', () {
    test('붙여넣은 글이면 붙여넣은 시각이다', () {
      final n = noteTimes(createdAt: t0, pastedAt: t0 + 5000, updatedAt: t0 + 5000);
      expect(n.start, t0 + 5000);
      expect(n.pasted, true);
    });

    test('직접 쓴 글이면 만든 시각이다', () {
      final n = noteTimes(createdAt: t0, pastedAt: 0, updatedAt: t0);
      expect(n.start, t0);
      expect(n.pasted, false);
    });

    test('만든 시각이 없는 옛 저장본은 수정 시각으로 버틴다 — 빈칸을 안 만든다', () {
      final n = noteTimes(createdAt: 0, pastedAt: 0, updatedAt: t0);
      expect(n.start, t0);
    });
  });

  group('고침 시각', () {
    test('손댄 적이 있으면 보여 준다', () {
      final n = noteTimes(createdAt: t0, pastedAt: 0, updatedAt: t0 + 60 * min);
      expect(n.edited, t0 + 60 * min);
    });

    test('방금 만든 글에는 안 붙는다 — 같은 시각을 두 번 적는 것은 소음이다', () {
      expect(noteTimes(createdAt: t0, pastedAt: 0, updatedAt: t0 + 3000).edited,
          null);
    });

    test('붙여넣고 곧바로 정리가 돌아 몇 초 뒤로 찍힌 것도 안 붙는다', () {
      final n =
          noteTimes(createdAt: t0, pastedAt: t0 + 1000, updatedAt: t0 + 9000);
      expect(n.edited, null);
    });

    test('1분을 넘기면 붙는다', () {
      final n = noteTimes(createdAt: t0, pastedAt: 0, updatedAt: t0 + min + 1);
      expect(n.edited, t0 + min + 1);
    });
  });

  group('되돌려도 시작은 안 바뀐다 — 이번 지시의 핵심', () {
    test('원본으로 되돌려 수정 시각이 지금이 되어도 붙여넣은 시각은 그대로다', () {
      const pasted = t0;
      final before = noteTimes(
          createdAt: t0 - 1000, pastedAt: pasted, updatedAt: t0 + 10);
      final after = noteTimes(
          createdAt: t0 - 1000, pastedAt: pasted, updatedAt: t0 + 600 * min);
      expect(before.start, pasted);
      expect(after.start, pasted, reason: '되돌려도 시작은 같다');
      expect(after.edited, t0 + 600 * min);
    });
  });
}
