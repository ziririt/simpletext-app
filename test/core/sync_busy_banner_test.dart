/// '동기화 중입니다' 띠의 셈 시험.
///
/// 2026-08-27 소유자 신고 — 로그인 직후 목록이 텅 비어 있으면 사람들이
/// 에러 난 줄 안다. 사람은 침묵을 고장으로 읽는다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';

bool show({
  bool active = true,
  bool paused = false,
  bool everSynced = false,
  bool running = true,
}) =>
    showSyncingBanner(
        active: active,
        paused: paused,
        everSynced: everSynced,
        running: running);

void main() {
  test('첫 동기화가 도는 중이면 보인다 — 이 띠가 있어야 할 유일한 순간', () {
    expect(show(), isTrue);
  });

  test('한 번이라도 끝난 기기에서는 다시 안 나온다', () {
    // 앱을 켤 때마다 몇 초씩 뜨면 그건 안내가 아니라 잔소리다.
    expect(show(everSynced: true), isFalse);
  });

  test('안 도는 중이면 안 보인다 — 멈춘 것을 돈다고 말하지 않는다', () {
    expect(show(running: false), isFalse);
  });

  test('동기화를 안 쓰는 기기에서는 안 보인다', () {
    expect(show(active: false), isFalse);
    expect(show(active: false, running: false), isFalse);
  });

  test("'동기화 안 함'을 고른 사람에게는 안 보인다", () {
    expect(show(paused: true), isFalse);
  });

  test('꺼짐이 이긴다 — 끝난 적 없어도 안 돌면 안 보인다', () {
    expect(show(everSynced: false, running: false), isFalse);
  });
}
