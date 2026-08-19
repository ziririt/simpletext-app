/// 창고를 바꾸면 '돌아도 되는가'도 같이 바뀌는가.
///
/// 2026-08-20 새벽. 2.0.0 에서 통로 고르는 판단은 useBackend() 한 곳으로
/// 모아 놓고, **돌아도 되는가**를 묻는 자리는 '애플 기기인가'인 채로 뒀다.
/// 그래서 안드로이드에서 구글 드라이브를 골라도 한 번도 안 돌았다 —
/// 아무 말 없이. 그 자리를 못으로 박는다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/icloud_sync.dart';

void main() {
  final sync = ICloudSync.instance;

  test('구글 드라이브를 고르면 어느 기기에서든 돈다', () {
    sync.useBackend('gdrive', driveToken: () async => 'tok');
    expect(sync.active, isTrue);
    expect(sync.paused, isFalse);
  });

  test('아이클라우드를 고르면 애플 기기에서만 돈다', () {
    sync.useBackend('icloud');
    expect(sync.active, ICloudSync.supported);
  });

  test("'동기화 안 함'은 멈춤이지 통로를 없애는 것이 아니다", () {
    sync.useBackend('none');
    expect(sync.paused, isTrue);
    expect(sync.active, ICloudSync.supported);
  });

  test('토큰을 못 구하면 구글을 골랐어도 애플 통로로 떨어진다', () {
    // 토큰 구하는 길이 없는 판(아이디 없이 지은 판, 윈도우 따위).
    // 여기서 구글 통로를 끼우면 조용히 아무 데도 안 오간다.
    sync.useBackend('gdrive');
    expect(sync.active, ICloudSync.supported);
  });
}
