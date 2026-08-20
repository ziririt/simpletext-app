/// 받을 것과 올릴 것을 고르는 셈 시험.
///
/// 2026-08-20. 이 셈이 틀리는 두 방향의 값이 다르다.
///  - 덜 받으면: 남의 고침이 안 온다. 다음 바퀴에 다시 기회가 있다.
///  - 잘못 올리면: 남의 새 글을 이쪽의 옛글로 덮는다. 되돌릴 수 없다.
/// 그래서 올리는 쪽 시험이 더 빡빡하다 — 모르면 안 올린다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';
import 'package:simpletext/core/sync_transport.dart';

void main() {
  group('무엇을 받을까 (pickFetch)', () {
    test('딱지가 없는 옛 파일은 받는다', () {
      expect(
        pickFetch(
            localStamp: const {'a': 5}, metas: const [RemoteMeta('a', null)]),
        ['a'],
      );
    });

    test('이 기기에 없는 노트는 받는다', () {
      expect(
        pickFetch(localStamp: const {}, metas: const [RemoteMeta('a', 3)]),
        ['a'],
      );
    });

    test('딱지가 더 새것이면 받는다', () {
      expect(
        pickFetch(
            localStamp: const {'a': 5}, metas: const [RemoteMeta('a', 9)]),
        ['a'],
      );
    });

    test('딱지가 같으면 안 받는다 — 합치기 결과가 같기 때문', () {
      expect(
        pickFetch(
            localStamp: const {'a': 5}, metas: const [RemoteMeta('a', 5)]),
        isEmpty,
      );
    });

    test('딱지가 옛것이면 안 받는다 — 그건 올릴 자리다', () {
      expect(
        pickFetch(
            localStamp: const {'a': 5}, metas: const [RemoteMeta('a', 2)]),
        isEmpty,
      );
    });
  });

  group('올릴 것인가 (shouldUpload)', () {
    test('저쪽에 없으면 올린다', () {
      expect(
          shouldUpload(
              exists: false, corrupt: false, remoteStamp: null, localStamp: 5),
          isTrue);
    });

    test('깨진 파일은 덮어쓴다', () {
      expect(
          shouldUpload(
              exists: true, corrupt: true, remoteStamp: null, localStamp: 5),
          isTrue);
    });

    test('저쪽이 옛것이면 올린다', () {
      expect(
          shouldUpload(
              exists: true, corrupt: false, remoteStamp: 3, localStamp: 5),
          isTrue);
    });

    test('같으면 안 올린다', () {
      expect(
          shouldUpload(
              exists: true, corrupt: false, remoteStamp: 5, localStamp: 5),
          isFalse);
    });

    test('저쪽이 새것이면 안 올린다', () {
      expect(
          shouldUpload(
              exists: true, corrupt: false, remoteStamp: 9, localStamp: 5),
          isFalse);
    });

    test('있는 건 아는데 얼마나 새것인지 모르면 안 올린다', () {
      // 남이 방금 고친 것을 이쪽의 옛것으로 덮는 길을 여기서 막는다.
      expect(
          shouldUpload(
              exists: true, corrupt: false, remoteStamp: null, localStamp: 5),
          isFalse);
    });
  });
}
