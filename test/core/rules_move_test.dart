/// 설정이 새로 깐 앱에서 살아남는지.
///
/// 2026-08-18 소유자 신고에서 나온 테스트다 — "설정 값들 유지되게 해준다고
/// 하지 않았니? 방금도 다시 앱이 들어오면서 설정값 초기화되었다."
///
/// 이 고장은 화면을 봐도 안 보였다. 앱을 지우고 다시 깔아야 보이고, 그건
/// 하루에 한 번 할 일이 아니다. 그래서 판단만 떼어 내 여기서 지킨다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_merge.dart';

void main() {
  group('설정 맞추기 — 누가 이기나', () {
    test('새로 깐 앱은 구름 것을 받는다 (이 고침의 핵심)', () {
      // 예전에는 여기서 pushLocal 이 나왔다. 새로 깐 앱의 **기본값**이
      // 구름을 덮어썼고, 그래서 다시 깔 때마다 설정이 사라졌다.
      expect(
        rulesMove(
            firstRun: true, hasRemote: true, remoteStamp: 100, localStamp: 0),
        RulesMove.takeRemote,
      );
    });

    test('구름에도 없으면 이 기기가 기준이 된다', () {
      expect(
        rulesMove(
            firstRun: true, hasRemote: false, remoteStamp: -1, localStamp: 0),
        RulesMove.pushLocal,
      );
    });

    test('구름이 더 새것이면 받는다', () {
      expect(
        rulesMove(
            firstRun: false, hasRemote: true, remoteStamp: 200, localStamp: 100),
        RulesMove.takeRemote,
      );
    });

    test('이 기기가 더 새것이면 올린다', () {
      expect(
        rulesMove(
            firstRun: false, hasRemote: true, remoteStamp: 100, localStamp: 200),
        RulesMove.pushLocal,
      );
    });

    test('같은 시각이면 아무것도 안 한다', () {
      expect(
        rulesMove(
            firstRun: false, hasRemote: true, remoteStamp: 100, localStamp: 100),
        RulesMove.nothing,
      );
    });

    test('쓰던 기기인데 구름이 비었으면 올린다', () {
      expect(
        rulesMove(
            firstRun: false, hasRemote: false, remoteStamp: -1, localStamp: 100),
        RulesMove.pushLocal,
      );
    });
  });
}
