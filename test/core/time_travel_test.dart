/// 시간 여행 정거장 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/time_travel.dart';

void main() {
  List<Stop> mk({
    List<String> h = const [],
    List<int> at = const [],
    List<String> why = const [],
    String body = '지금',
    int updated = 1000,
  }) =>
      travelStops(
          history: h,
          historyAt: at,
          historyWhy: why,
          body: body,
          updatedAt: updated);

  group('정거장 세우기', () {
    test('기록이 없으면 정거장은 하나 — 지금뿐이다', () {
      final s = mk();
      expect(s.length, 1);
      expect(s.first.now, true);
      expect(s.first.text, '지금');
    });

    test('오래된 것부터, 마지막이 지금', () {
      final s = mk(h: ['가', '나'], body: '다');
      expect(s.map((e) => e.text).toList(), ['가', '나', '다']);
      expect(s.last.now, true);
      expect(s.first.now, false);
    });

    test('시각과 까닭이 제 판에 붙는다', () {
      final s = mk(h: ['가', '나'], at: [11, 22], why: ['tidy', 'ai']);
      expect(s[0].at, 11);
      expect(s[0].why, 'tidy');
      expect(s[1].at, 22);
      expect(s[1].why, 'ai');
    });

    test('곁줄이 짧으면 **끝에서부터** 맞춘다 — 오늘 시각이 옛 판에 붙으면 안 된다', () {
      final s = mk(h: ['옛것', '옛것2', '새것'], at: [99], why: ['ai']);
      expect(s[0].at, 0, reason: '짝이 없다');
      expect(s[1].at, 0);
      expect(s[2].at, 99, reason: '하나뿐인 곁줄은 마지막 것의 짝이다');
      expect(s[2].why, 'ai');
    });

    test('지금 판에는 까닭이 없다', () {
      expect(mk(h: ['가'], why: ['tidy']).last.why, '');
    });

    test('지금 판의 시각은 수정일이다', () {
      expect(mk(updated: 777).last.at, 777);
    });
  });

  group('손잡이와 정거장', () {
    test('0은 가장 오래된 것, 1은 지금', () {
      expect(stopAt(0, 4), 0);
      expect(stopAt(1, 4), 3);
    });

    test('가운데는 가운데', () {
      expect(stopAt(0.5, 3), 1);
    });

    test('범위를 벗어나도 안 넘어간다', () {
      expect(stopAt(-9, 3), 0);
      expect(stopAt(9, 3), 2);
    });

    test('정거장이 하나면 늘 그것이다', () {
      expect(stopAt(0.3, 1), 0);
      expect(fracOf(0, 1), 1);
    });

    test('되돌리면 제자리다', () {
      for (var n = 2; n < 8; n++) {
        for (var i = 0; i < n; i++) {
          expect(stopAt(fracOf(i, n), n), i, reason: 'n=$n i=$i');
        }
      }
    });
  });

  group('얼마나 늘고 줄었나', () {
    test('줄면 음수', () {
      final s = mk(h: ['가나다라'], body: '가나');
      expect(growth(s, 1), -2);
    });

    test('늘면 양수', () {
      final s = mk(h: ['가'], body: '가나다');
      expect(growth(s, 1), 2);
    });

    test('첫 정거장은 견줄 앞이 없다', () {
      expect(growth(mk(h: ['가']), 0), 0);
    });

    test('범위 밖은 0', () {
      expect(growth(mk(h: ['가']), 99), 0);
    });
  });
}
