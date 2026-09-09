// 선택 핸들 잡기 판정. 화면 없이 좌표만 따진다.
import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/handle_hit.dart';

void main() {
  // 화면 어딘가에 핸들 하나가 있다고 두고, 손가락이 어디까지 와야
  // '잡으려는 것'으로 볼지를 잰다.
  const handle = Offset(200, 400);
  const one = [handle];

  group('선택 핸들 잡기 판정', () {
    test('핸들 위를 정확히 누르면 잡힌다', () {
      expect(nearAnyHandle(handle, one), isTrue);
    });

    test('왼손 엄지가 왼쪽·아래로 치우쳐 닿아도 잡힌다', () {
      // 이것이 2026-09-10 신고의 그 자리다. 예전 상자(가로 36)에서는
      // 여기가 빠져서 잠금이 안 걸렸고, 바깥 스크롤이 손가락을 가져갔다.
      expect(nearAnyHandle(const Offset(155, 440), one), isTrue);
      expect(nearAnyHandle(const Offset(145, 455), one), isTrue);
    });

    test('오른손 엄지가 오른쪽으로 치우쳐 닿아도 잡힌다', () {
      expect(nearAnyHandle(const Offset(250, 430), one), isTrue);
    });

    test('멀면 안 잡힌다 — 아무 데나 눌러도 걸리면 스크롤을 뺏는다', () {
      expect(nearAnyHandle(const Offset(200, 500), one), isFalse);
      expect(nearAnyHandle(const Offset(280, 400), one), isFalse);
    });

    test('두 핸들 중 하나만 가까워도 잡힌다', () {
      const two = [Offset(80, 200), handle];
      expect(nearAnyHandle(const Offset(90, 210), two), isTrue);
      expect(nearAnyHandle(const Offset(190, 410), two), isTrue);
      expect(nearAnyHandle(const Offset(600, 700), two), isFalse);
    });

    test('핸들이 없으면 아무 데도 안 잡힌다 — 블록이 없을 때다', () {
      expect(nearAnyHandle(handle, const <Offset>[]), isFalse);
    });

    test('경계는 포함한다. 딱 걸친 손가락을 떨어뜨리지 않는다', () {
      expect(
        nearAnyHandle(
          Offset(handle.dx - kHandleGrabX, handle.dy + kHandleGrabY),
          one,
        ),
        isTrue,
      );
      expect(
        nearAnyHandle(Offset(handle.dx - kHandleGrabX - 0.5, handle.dy), one),
        isFalse,
      );
    });
  });
}
