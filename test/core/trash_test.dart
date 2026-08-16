/// 휴지통 규칙을 못 박는 테스트.
/// 여기서 지키려는 것은 하나다 — **지운 메모가 30일 안에는 반드시 돌아온다.**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/trash.dart';

const int _day = 24 * 60 * 60 * 1000;

void main() {
  const now = 1000 * _day; // 아무 기준점

  test('보관 기간은 30일이다', () {
    expect(kTrashKeepDays, 30);
  });

  test('방금 지운 것은 만료가 아니다', () {
    expect(trashExpired(deletedAt: now, nowMs: now), isFalse);
  });

  test('29일까지는 살아 있고 30일에 만료된다', () {
    expect(trashExpired(deletedAt: now - 29 * _day, nowMs: now), isFalse);
    expect(trashExpired(deletedAt: now - 30 * _day, nowMs: now), isTrue);
    expect(trashExpired(deletedAt: now - 100 * _day, nowMs: now), isTrue);
  });

  test('남은 날짜는 사람이 읽을 수 있게 나온다', () {
    expect(trashDaysLeft(deletedAt: now, nowMs: now), 30);
    expect(trashDaysLeft(deletedAt: now - 1 * _day, nowMs: now), 29);
    expect(trashDaysLeft(deletedAt: now - 29 * _day, nowMs: now), 1);
  });

  test('마지막 날에도 0일이 아니라 1일이라고 말한다', () {
    // "0일 뒤 삭제"는 사람이 읽을 문장이 아니다. 아직 안 지워졌으니 1이 맞다.
    final almost = now - (30 * _day - 1);
    expect(trashExpired(deletedAt: almost, nowMs: now), isFalse);
    expect(trashDaysLeft(deletedAt: almost, nowMs: now), 1);
  });

  test('만료된 것은 0일', () {
    expect(trashDaysLeft(deletedAt: now - 40 * _day, nowMs: now), 0);
  });

  test('기한 지난 것만 걸러 낸다', () {
    final items = [
      {'id': 'a', 'at': now - 1 * _day},
      {'id': 'b', 'at': now - 29 * _day},
      {'id': 'c', 'at': now - 31 * _day},
      {'id': 'd', 'at': now - 365 * _day},
    ];
    final kept = pruneTrash<Map<String, dynamic>>(
      items,
      deletedAtOf: (e) => e['at'] as int,
      nowMs: now,
    );
    expect(kept.map((e) => e['id']), ['a', 'b']);
  });

  test('빈 목록은 빈 목록', () {
    expect(
      pruneTrash<Map<String, dynamic>>(const [],
          deletedAtOf: (e) => 0, nowMs: now),
      isEmpty,
    );
  });

  test('보관 일수를 바꿔도 규칙은 같다', () {
    expect(
        trashExpired(deletedAt: now - 8 * _day, nowMs: now, keepDays: 7),
        isTrue);
    expect(
        trashExpired(deletedAt: now - 6 * _day, nowMs: now, keepDays: 7),
        isFalse);
  });
}
