/// 전·후 와이프 손잡이의 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/wipe.dart';

void main() {
  const w = 400.0;

  group('갈 수 있는 범위', () {
    test('양 끝에 자리를 남긴다 — 한쪽이 통째로 사라지면 두 겹인 줄 모른다', () {
      final (lo, hi) = wipeRange(w);
      expect(lo, 28);
      expect(hi, 372);
    });

    test('너무 좁은 화면에서는 가운데 하나로 무너진다 — 죽지 않는다', () {
      final (lo, hi) = wipeRange(40);
      expect(lo, 20);
      expect(hi, 20);
    });

    test('범위 밖은 끌어당긴다', () {
      expect(wipeClamp(-100, w), 28);
      expect(wipeClamp(9999, w), 372);
      expect(wipeClamp(200, w), 200);
    });
  });

  group('끄는 동안', () {
    test('안쪽에서는 손가락을 1:1로 따라간다', () {
      expect(wipeDrag(200, 37, w), 237);
      expect(wipeDrag(200, -37, w), 163);
    });

    test('왼쪽 끝을 넘기면 덜 따라온다 — 멈추지도, 넘어가지도 않는다', () {
      final x = wipeDrag(30, -100, w);
      expect(x < 28, true, reason: '조금은 넘어간다');
      expect(x > -72, true, reason: '그러나 100만큼은 아니다');
    });

    test('오른쪽 끝도 같다', () {
      final x = wipeDrag(370, 100, w);
      expect(x > 372, true);
      expect(x < 470, true);
    });

    test('더 세게 밀수록 덜 따라온다', () {
      final a = wipeDrag(28, -50, w) - 28;
      final b = wipeDrag(28, -200, w) - 28;
      expect(b.abs() > a.abs(), true, reason: '더 가긴 간다');
      expect(b.abs() / a.abs() < 4, true, reason: '그러나 4배는 아니다');
    });
  });

  group('던졌을 때', () {
    test('놓은 자리가 아니라 갈 자리로 간다', () {
      expect(wipeProject(100, 500) > 100, true);
    });

    test('왼쪽으로 던지면 왼쪽으로', () {
      expect(wipeProject(300, -500) < 300, true);
    });

    test('가만히 놓으면 그 자리다', () {
      expect(wipeProject(200, 0), 200);
    });

    test('두 배로 던지면 두 배로 간다 — 셈이 선형이다', () {
      final a = wipeProject(0, 500);
      final b = wipeProject(0, 1000);
      expect((b - a * 2).abs() < 0.001, true);
    });
  });

  group('자리와 비율', () {
    test('0은 왼쪽 끝, 1은 오른쪽 끝', () {
      expect(wipeAt(0, w), 28);
      expect(wipeAt(1, w), 372);
      expect(wipeAt(0.5, w), 200);
    });

    test('범위를 벗어난 비율도 안 넘어간다', () {
      expect(wipeAt(-3, w), 28);
      expect(wipeAt(9, w), 372);
    });

    test('되돌리면 제자리다', () {
      expect((wipeFrac(wipeAt(0.3, w), w) - 0.3).abs() < 0.0001, true);
    });

    test('범위 밖 자리도 0~1 안에서 답한다', () {
      expect(wipeFrac(-500, w), 0);
      expect(wipeFrac(5000, w), 1);
    });
  });
}
