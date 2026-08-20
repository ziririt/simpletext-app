/// 편집 화면이 새 판을 만났을 때의 셈 시험.
///
/// 2026-08-20 저녁 사건: 동기화는 배달을 마쳤는데 열린 편집 화면이
/// 낡은 객체를 물고 낡은 글을 보여줬다(맥·안드로이드·웹 세 곳).
/// 화면 코드는 이 셈을 그대로 따르므로, 갈래는 여기서 못 박는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';

void main() {
  test('같은 객체면 가만히 있는다 — 내 저장이 돌아온 메아리다', () {
    expect(editorRefresh(sameObject: true, editing: false),
        EditorRefresh.keep);
    expect(editorRefresh(sameObject: true, editing: true),
        EditorRefresh.keep);
  });

  test('새 판이 왔고 손대지 않았으면 갈아 그린다', () {
    expect(editorRefresh(sameObject: false, editing: false),
        EditorRefresh.adopt);
  });

  test('치던 중이면 눈앞의 글이 이긴다 — 보면서 만지는 글을 소리 없이 갈아치우지 않는다', () {
    expect(editorRefresh(sameObject: false, editing: true),
        EditorRefresh.assertMine);
  });

  group('잠든 동기화 안내 띠', () {
    test('정상이면 띠 없음 — 멀쩡한 날에 띠가 누워 있으면 그게 고장이다', () {
      expect(
          syncBanner(
              gdrive: true,
              healthy: true,
              signedIn: true,
              authExpired: false),
          SyncBanner.none);
    });

    test('구글 창고가 아니면 어떤 상태여도 띠 없음', () {
      expect(
          syncBanner(
              gdrive: false,
              healthy: false,
              signedIn: false,
              authExpired: true),
          SyncBanner.none);
    });

    test('계정은 붙어 있는데 허락만 만료 — 누르면 바로 켜는 띠', () {
      expect(
          syncBanner(
              gdrive: true,
              healthy: false,
              signedIn: true,
              authExpired: true),
          SyncBanner.wake);
    });

    test('로그인이 풀림 — 시트로 안내하는 띠', () {
      expect(
          syncBanner(
              gdrive: true,
              healthy: false,
              signedIn: false,
              authExpired: false),
          SyncBanner.signIn);
    });

    test('붙어 있고 허락도 멀쩡한데 아직 안 맞춘 판 — 띠 없음(곧 돈다)', () {
      expect(
          syncBanner(
              gdrive: true,
              healthy: false,
              signedIn: true,
              authExpired: false),
          SyncBanner.none);
    });
  });
}
