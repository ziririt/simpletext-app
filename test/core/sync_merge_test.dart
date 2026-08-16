/// 동기화 병합 규칙을 못 박는 테스트.
///
/// 여기서 지키려는 것은 한 가지다 — **두 기기를 쓴다고 해서 사용자가 쓴 글이
/// 사라지거나, 지운 글이 되살아나면 안 된다.** 아래 케이스는 전부 실제로
/// 일어나는 상황이고, 하나라도 깨지면 사용자는 앱을 지운다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_merge.dart';

/// 테스트용 최소 메모. 진짜 Note를 안 쓰는 이유는 sync_merge가 Note를
/// 몰라야 하기 때문이다(모르면 화면 코드가 섞여 들어올 수 없다).
class _N {
  final String id;
  final int at;
  final String text;
  const _N(this.id, this.at, [this.text = '']);
  @override
  String toString() => '$id@$at($text)';
}

MergeResult<_N> run({
  List<_N> local = const [],
  List<Map<String, dynamic>> localTombs = const [],
  List<_N> remote = const [],
  List<Map<String, dynamic>> remoteTombs = const [],
  int nowMs = 2000000,
  int keepDays = 180,
}) =>
    mergeNotes<_N>(
      local: local,
      localTombs: localTombs,
      remote: remote,
      remoteTombs: remoteTombs,
      idOf: (n) => n.id,
      stampOf: (n) => n.at,
      nowMs: nowMs,
      keepDays: keepDays,
    );

Map<String, _N> byId(List<_N> ns) => {for (final n in ns) n.id: n};

void main() {
  group('기본 합치기', () {
    test('한쪽에만 있는 메모는 양쪽 모두에 남는다', () {
      final r = run(local: [const _N('a', 10)], remote: [const _N('b', 20)]);
      expect(byId(r.notes).keys.toSet(), {'a', 'b'});
      expect(r.pulled, 1); // b를 받아 왔다
      expect(r.pushed, 1); // a는 올려야 한다
      expect(r.removed, 0);
    });

    test('양쪽에 같은 메모 — 늦게 고친 쪽이 이긴다', () {
      final r = run(
        local: [const _N('a', 10, '로컬')],
        remote: [const _N('a', 20, '원격')],
      );
      expect(r.notes.single.text, '원격');
      expect(r.pulled, 1);
      expect(r.pushed, 0);
    });

    test('반대 방향도 같다', () {
      final r = run(
        local: [const _N('a', 30, '로컬')],
        remote: [const _N('a', 20, '원격')],
      );
      expect(r.notes.single.text, '로컬');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
    });

    test('시각이 같으면 눈앞의 것(로컬)을 남기고 아무것도 안 센다', () {
      // 시계가 어긋난 기기에서 나온다. 방금 친 글자를 지우지 않는 쪽을 고른다.
      final r = run(
        local: [const _N('a', 20, '로컬')],
        remote: [const _N('a', 20, '원격')],
      );
      expect(r.notes.single.text, '로컬');
      expect(r.pulled, 0);
      expect(r.pushed, 0);
      expect(r.localUnchanged, isTrue);
    });
  });

  group('지운 메모는 되살아나지 않는다', () {
    test('폰에서 지웠으면 맥에 남아 있어도 지워진다', () {
      // 가장 흔한 사고. 툼스톤이 없으면 맥의 메모가 '새 메모'로 보여 부활한다.
      final r = run(
        local: [const _N('a', 10)],
        remote: const [],
        remoteTombs: [
          {'id': 'a', 'deletedAt': 50}
        ],
      );
      expect(r.notes, isEmpty);
      expect(r.removed, 1);
      expect(r.tombstones.single['id'], 'a');
    });

    test('원격에 아직 살아 있어도 삭제 기록이 더 늦으면 삭제가 이긴다', () {
      final r = run(
        local: const [],
        localTombs: [
          {'id': 'a', 'deletedAt': 50}
        ],
        remote: [const _N('a', 10)],
      );
      expect(r.notes, isEmpty);
      expect(r.removed, 0); // 로컬에는 이미 없었다
    });

    test('지운 뒤에 다른 기기에서 다시 고쳤으면 그 수정이 이긴다', () {
      // 되살리기는 이 한 경우에만 허용한다. 사용자가 실제로 손을 댔기 때문이다.
      final r = run(
        local: const [],
        localTombs: [
          {'id': 'a', 'deletedAt': 50}
        ],
        remote: [const _N('a', 80, '다시 씀')],
      );
      expect(r.notes.single.text, '다시 씀');
      expect(r.pulled, 1);
    });

    test('삭제와 수정이 같은 시각이면 삭제가 이긴다', () {
      final r = run(
        local: [const _N('a', 50)],
        remoteTombs: [
          {'id': 'a', 'deletedAt': 50}
        ],
      );
      expect(r.notes, isEmpty);
      expect(r.removed, 1);
    });

    test('삭제 기록은 양쪽을 합치고 늦은 쪽만 남긴다', () {
      final r = run(
        localTombs: [
          {'id': 'a', 'deletedAt': 10}
        ],
        remoteTombs: [
          {'id': 'a', 'deletedAt': 90}
        ],
      );
      expect(r.tombstones.length, 1);
      expect(r.tombstones.single['deletedAt'], 90);
    });
  });

  group('삭제 기록 청소', () {
    const day = 24 * 60 * 60 * 1000;

    test('오래된 기록은 버린다 — 안 버리면 이 목록만 영원히 자란다', () {
      final now = 400 * day;
      final r = run(
        nowMs: now,
        localTombs: [
          {'id': 'old', 'deletedAt': now - 200 * day},
          {'id': 'new', 'deletedAt': now - 3 * day},
        ],
      );
      expect(r.tombstones.map((t) => t['id']), ['new']);
    });

    test('180일은 넉넉히 잡은 값이다 — 179일 된 기록은 살아 있다', () {
      // 여행·방학으로 한 기기를 몇 주씩 안 켜는 일이 실제로 있다. 그 기기가
      // 돌아오기 전에 툼스톤을 지우면 위의 부활 사고가 그대로 일어난다.
      final now = 400 * day;
      final r = run(nowMs: now, localTombs: [
        {'id': 'x', 'deletedAt': now - 179 * day}
      ]);
      expect(r.tombstones.length, 1);
    });
  });

  group('망가진 자료가 들어와도 안 죽는다', () {
    test('id가 없거나 이상한 삭제 기록은 조용히 버린다', () {
      // 다른 버전의 앱이 올린 파일, 또는 반쯤 쓰다 만 파일에서 나온다.
      final r = run(localTombs: [
        {'deletedAt': 10},
        {'id': '', 'deletedAt': 10},
        {'id': 'ok'},
      ]);
      expect(r.tombstones.length, 1);
      expect(r.tombstones.single['id'], 'ok');
      expect(r.tombstones.single['deletedAt'], 0);
    });

    test('양쪽 다 비어 있으면 빈 결과 — 예외를 던지지 않는다', () {
      final r = run();
      expect(r.notes, isEmpty);
      expect(r.tombstones, isEmpty);
      expect(r.localUnchanged, isTrue);
    });
  });

  group('실제로 벌어지는 하루', () {
    test('폰에서 새 메모, 맥에서 수정, 아이패드에서 삭제가 한 번에 들어와도 맞는다', () {
      final r = run(
        local: [
          const _N('phone', 100, '폰에서 새로 씀'),
          const _N('shared', 50, '맥에서 고친 옛 버전'),
          const _N('gone', 30),
        ],
        remote: [
          const _N('shared', 120, '아이패드가 더 늦게 고침'),
          const _N('ipad', 110, '아이패드에서 새로 씀'),
        ],
        remoteTombs: [
          {'id': 'gone', 'deletedAt': 90}
        ],
      );
      final m = byId(r.notes);
      expect(m.keys.toSet(), {'phone', 'shared', 'ipad'});
      expect(m['shared']!.text, '아이패드가 더 늦게 고침');
      expect(r.pulled, 2); // shared(원격 승) + ipad
      expect(r.pushed, 1); // phone
      expect(r.removed, 1); // gone
      expect(r.localUnchanged, isFalse);
    });

    test('아무것도 안 바뀐 날에는 화면을 흔들지 않는다', () {
      final r = run(
        local: [const _N('a', 10), const _N('b', 20)],
        remote: [const _N('a', 10), const _N('b', 20)],
      );
      expect(r.localUnchanged, isTrue);
      expect(r.notes.length, 2);
    });
  });
}
