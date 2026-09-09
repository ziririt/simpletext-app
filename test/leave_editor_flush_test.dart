// 편집 화면을 나갈 때 저장이 애니메이션을 밟지 않는가 (2026-09-09 신고).
//
// 소유자 신고 — "편집화면에서 목록으로 나갈 때는 더 버버벅거린다."
// 녹화를 프레임 단위로 재 보니 나가는 쪽 간격이 400 · 298 · 317 · 267ms 였다.
// 1초 가까이 화면이 세 번밖에 안 바뀌었다.
//
// 범인은 dispose 의 store.flush() 였다. 그 한 줄이 모든 메모를 jsonEncode 해서
// 디스크에 쓰고 notifyListeners 로 목록을 통째로 다시 그린다.
//
// 이 검사가 지키는 것은 한 줄이다 — **나가는 동안에는 쓰지 않는다.**
// 그리고 늦게라도 반드시 쓴다. 늦게 쓰는 것과 안 쓰는 것은 아주 다르다.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Store.flushAfter 와 같은 셈. 진짜 Store 는 SharedPreferences 를 물어
/// 위젯 검사 밖에서는 못 세우므로, 규칙만 같은 모양으로 떼어 확인한다.
class _Writer {
  bool dirty = false;
  int writes = 0;
  Timer? _t;

  void touch() {
    dirty = true;
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 700), flush);
  }

  void flush() {
    _t?.cancel();
    if (!dirty) return;
    dirty = false;
    writes++;
  }

  void flushAfter(Duration d) {
    if (!dirty) return;
    _t?.cancel();
    _t = Timer(d, flush);
  }

  void stop() => _t?.cancel();
}

void main() {
  group('나갈 때 저장은 애니메이션 뒤로 (2026-09-09)', () {
    test('나가는 400ms 동안에는 안 쓴다', () {
      fakeAsync((tick) {
        final w = _Writer()..touch();
        w.flushAfter(const Duration(milliseconds: 900));
        tick(const Duration(milliseconds: 400));
        expect(w.writes, 0, reason: '미는 동안 쓰면 프레임이 통째로 빠진다');
        w.stop();
      });
    });

    test('늦게라도 반드시 쓴다', () {
      fakeAsync((tick) {
        final w = _Writer()..touch();
        w.flushAfter(const Duration(milliseconds: 900));
        tick(const Duration(milliseconds: 1000));
        expect(w.writes, 1, reason: '늦게 쓰는 것과 안 쓰는 것은 다르다');
        w.stop();
      });
    });

    test('바뀐 것이 없으면 아무것도 예약하지 않는다', () {
      fakeAsync((tick) {
        final w = _Writer();
        w.flushAfter(const Duration(milliseconds: 900));
        tick(const Duration(milliseconds: 1400));
        expect(w.writes, 0);
        w.stop();
      });
    });

    test('예약을 두 번 걸어도 한 번만 쓴다', () {
      fakeAsync((tick) {
        final w = _Writer()..touch();
        w.flushAfter(const Duration(milliseconds: 900));
        w.flushAfter(const Duration(milliseconds: 900));
        tick(const Duration(milliseconds: 1400));
        expect(w.writes, 1);
        w.stop();
      });
    });
  });
}

/// 시계를 손으로 돌리는 작은 도우미. 진짜로 900ms 를 기다리지 않는다.
void fakeAsync(void Function(void Function(Duration)) body) {
  FakeAsync().run((fa) {
    body(fa.elapse);
  });
}
