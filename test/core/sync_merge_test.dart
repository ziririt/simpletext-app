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
  String Function(_N)? bodyOf,
  int syncedBeforeMs = 0,
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
      bodyOf: bodyOf,
      syncedBeforeMs: syncedBeforeMs,
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

  /// 2026-08-18 소유자 신고에서 나온 묶음이다.
  ///
  ///     "기본 샘플 메모가 계속 빌드 회수만큼 생긴다."
  ///
  /// 시드 메모의 번호가 만들 때마다 달라서, 새로 깔 때마다 아이클라우드에
  /// 있던 예전 시드와 방금 만든 시드가 다른 메모가 되어 둘 다 남았다.
  ///
  /// 번호를 붙박이(seed-1)로 바꾸고 시각을 아주 옛날로 못 박아 고쳤다.
  /// 아래는 그 고침이 지켜야 하는 성질이다. 하나라도 깨지면 시드가 다시
  /// 늘거나, 지운 것이 되살아나거나, 사람이 고친 글이 덮인다.
  group('시드 메모 (붙박이 번호 + 옛 시각)', () {
    // 시드는 언제나 지는 쪽에 서야 하므로 시각을 작게 준다.
    const seedAt = 100;

    test('두 기기가 각각 시드를 만들어도 하나가 된다', () {
      final r = run(
        local: const [_N('seed-1', seedAt, '시드')],
        remote: const [_N('seed-1', seedAt, '시드')],
      );
      expect(r.notes.length, 1);
      expect(r.notes.first.id, 'seed-1');
    });

    test('시드를 지웠으면 새로 깐 기기의 시드가 되살아나지 않는다', () {
      // 새로 깐 기기(local)가 방금 시드를 만들었다. 다른 기기는 그것을
      // 지운 적이 있다.
      final r = run(
        local: const [_N('seed-1', seedAt, '시드')],
        remoteTombs: const [
          {'id': 'seed-1', 'deletedAt': 500}
        ],
      );
      expect(r.notes, isEmpty);
      expect(r.removed, 1);
    });

    test('사람이 고친 시드를 새로 깐 기기의 시드가 덮지 않는다', () {
      final r = run(
        local: const [_N('seed-1', seedAt, '시드')],
        remote: const [_N('seed-1', 900, '내가 고친 시드')],
      );
      expect(r.notes.length, 1);
      expect(r.notes.first.text, '내가 고친 시드');
    });

    test('옛 번호는 붙박이 번호와 다른 메모로 본다 (앱이 이사시켜야 한다)', () {
      // 고장이 아니라 확인이다. 번호가 다르면 다른 메모라는 것이 합치기의
      // 규칙이고, 그래서 옛 번호는 앱 쪽에서 옮겨야 한다(Store.foldOldSeeds).
      // 여기서 접어 주기를 기대하면 안 된다.
      final r = run(
        local: const [_N('seed-1', seedAt, '시드')],
        remote: const [_N('seed-1755400000000', 700, '시드')],
      );
      expect(r.notes.length, 2);
    });
  });

  group('지는 판 백업 (2026-08-21 자정 사건)', () {
    test('구름에 못 올라간 수정이 지면 백업 목록에 담긴다', () {
      final r = run(
        local: [const _N('a', 900, '여섯 줄')],
        remote: [const _N('a', 950, '다섯 줄')],
        bodyOf: (n) => n.text,
        syncedBeforeMs: 800,
      );
      expect(r.notes.single.text, '다섯 줄');
      expect(r.backups.single.text, '여섯 줄');
    });

    test('이미 맞춘 적 있는 옛 판이 지는 것은 정상 배달 — 백업하지 않는다', () {
      final r = run(
        local: [const _N('a', 700, '옛것')],
        remote: [const _N('a', 950, '새것')],
        bodyOf: (n) => n.text,
        syncedBeforeMs: 800,
      );
      expect(r.backups, isEmpty);
    });

    test('알맹이가 같으면 도장만 진 것 — 백업하지 않는다', () {
      final r = run(
        local: [const _N('a', 900, '같다')],
        remote: [const _N('a', 950, '같다')],
        bodyOf: (n) => n.text,
        syncedBeforeMs: 800,
      );
      expect(r.backups, isEmpty);
    });

    test('남의 툼스톤에 밀려 지워질 때도 못 올라간 수정은 백업한다', () {
      final r = run(
        local: [const _N('a', 900, '쓰던 글')],
        remoteTombs: [
          {'id': 'a', 'deletedAt': 950}
        ],
        syncedBeforeMs: 800,
      );
      expect(r.notes, isEmpty);
      expect(r.backups.single.text, '쓰던 글');
    });
  });

  group('AI 키 옮기기 — 빈 키는 값이 아니다', () {
    test('키가 없는 기기는 도장이 더 새것이어도 받는 쪽이다', () {
      // 2026-08-30 맥에서 난 사고 그대로다. 맥의 도장이 더 새것이지만
      // 맥에는 키가 없었다. 그래도 받아야 한다.
      expect(
        keyMove(
          firstRun: false,
          hasRemote: true,
          remoteStamp: 1000,
          localStamp: 9999,
          localEmpty: true,
        ),
        RulesMove.takeRemote,
      );
    });

    test('키가 없고 구름에도 없으면 아무 일도 안 한다', () {
      expect(
        keyMove(
          firstRun: false,
          hasRemote: false,
          remoteStamp: -1,
          localStamp: 9999,
          localEmpty: true,
        ),
        RulesMove.nothing,
      );
    });

    test('키가 있으면 예전 규칙 그대로 — 새 도장이 이긴다', () {
      expect(
        keyMove(
          firstRun: false,
          hasRemote: true,
          remoteStamp: 1000,
          localStamp: 9999,
          localEmpty: false,
        ),
        RulesMove.pushLocal,
      );
      expect(
        keyMove(
          firstRun: false,
          hasRemote: true,
          remoteStamp: 9999,
          localStamp: 1000,
          localEmpty: false,
        ),
        RulesMove.takeRemote,
      );
    });
  });
}
