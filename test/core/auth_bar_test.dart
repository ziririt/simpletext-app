/// 로그인 때문에 멈춘 것을 언제 말하나.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';

void main() {
  bool bar({
    bool gdrive = true,
    bool active = true,
    bool paused = false,
    String why = 'no-account',
  }) =>
      showAuthBar(gdrive: gdrive, active: active, paused: paused, why: why);

  group('로그인 때문에 멈췄다는 한 줄', () {
    test('계정이 떨어졌으면 말한다', () {
      expect(bar(why: 'no-account'), true);
    });

    test('허락만 끊겼어도 말한다 — 계정은 멀쩡해도 동기화는 죽어 있다', () {
      expect(bar(why: 'no-scope'), true);
    });

    test('알 수 없는 오류도 말한다 — 조용한 실패가 제일 나쁘다', () {
      expect(bar(why: 'err-TimeoutException'), true);
    });

    test('멀쩡하면 아무 말 안 한다', () {
      expect(bar(why: ''), false);
    });

    test('이 기기에서 구글을 못 쓰는 판은 말할 일이 아니다', () {
      expect(bar(why: 'unsupported'), false);
    });

    test('아이클라우드를 쓰는 사람에게는 안 뜬다', () {
      expect(bar(gdrive: false), false);
    });

    test("'동기화 안 함'을 고른 사람에게는 안 뜬다", () {
      expect(bar(paused: true), false);
    });

    test('돌 수 없는 기기에서는 안 뜬다', () {
      expect(bar(active: false), false);
    });
  });
}
