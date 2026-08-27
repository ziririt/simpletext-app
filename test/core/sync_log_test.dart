import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_log.dart';

void main() {
  group('적을 만한 바퀴', () {
    test('아무것도 안 오간 성공은 안 적는다', () {
      final log = SyncLog();
      expect(log.add(const SyncEvent(atMs: 1, ms: 300)), isFalse);
      expect(log.isEmpty, isTrue);
    });

    test('하나라도 올렸으면 적는다', () {
      final log = SyncLog();
      expect(log.add(const SyncEvent(atMs: 1, up: 1)), isTrue);
      expect(log.events.length, 1);
    });

    test('하나라도 받았으면 적는다', () {
      final log = SyncLog();
      expect(log.add(const SyncEvent(atMs: 1, down: 3)), isTrue);
      expect(log.events.single.down, 3);
    });

    test('실패는 빈 바퀴여도 적는다', () {
      final log = SyncLog();
      expect(log.add(const SyncEvent(atMs: 1, err: '통로 없음')), isTrue);
      expect(log.events.single.ok, isFalse);
    });
  });

  group('고리 버퍼', () {
    test('최신이 앞이다', () {
      final log = SyncLog();
      log.add(const SyncEvent(atMs: 100, up: 1));
      log.add(const SyncEvent(atMs: 200, up: 1));
      expect(log.events.first.atMs, 200);
    });

    test('kMax 를 넘으면 오래된 것부터 버린다', () {
      final log = SyncLog();
      for (var i = 0; i < SyncLog.kMax + 10; i++) {
        log.add(SyncEvent(atMs: i, up: 1));
      }
      expect(log.events.length, SyncLog.kMax);
      expect(log.events.first.atMs, SyncLog.kMax + 9);
      expect(log.events.last.atMs, 10);
    });
  });

  group('마지막 올림·받음', () {
    test('없으면 null', () {
      final log = SyncLog();
      log.add(const SyncEvent(atMs: 5, err: 'x'));
      expect(log.lastUpMs, isNull);
      expect(log.lastDownMs, isNull);
    });

    test('올림과 받음을 따로 센다', () {
      final log = SyncLog();
      log.add(const SyncEvent(atMs: 100, down: 2));
      log.add(const SyncEvent(atMs: 200, up: 1));
      expect(log.lastUpMs, 200);
      expect(log.lastDownMs, 100);
    });
  });

  group('저장과 읽기', () {
    test('한 바퀴 돌아도 그대로다', () {
      final log = SyncLog();
      log.add(const SyncEvent(atMs: 100, up: 1, down: 2, ms: 1500));
      log.add(const SyncEvent(atMs: 200, err: '시간 초과'));
      final back = SyncLog.decode(log.encode());
      expect(back.events.length, 2);
      expect(back.events.first.err, '시간 초과');
      expect(back.events.last.up, 1);
      expect(back.events.last.down, 2);
      expect(back.events.last.ms, 1500);
    });

    test('빈 글자·null 은 빈 기록이 된다', () {
      expect(SyncLog.decode(null).isEmpty, isTrue);
      expect(SyncLog.decode('').isEmpty, isTrue);
    });

    test('깨진 글자에도 던지지 않는다', () {
      expect(SyncLog.decode('{{{').isEmpty, isTrue);
      expect(SyncLog.decode('"그냥 글자"').isEmpty, isTrue);
      expect(SyncLog.decode('[1, 2, null]').isEmpty, isTrue);
    });

    test('at 없는 항목은 버린다 — 시각 없는 기록은 쓸모가 없다', () {
      expect(SyncLog.decode('[{"up":1}]').isEmpty, isTrue);
    });

    test('읽을 때도 kMax 를 넘기지 않는다', () {
      final many = [
        for (var i = 0; i < SyncLog.kMax + 20; i++) '{"at":$i,"up":1}'
      ].join(',');
      expect(SyncLog.decode('[$many]').events.length, SyncLog.kMax);
    });
  });
}
