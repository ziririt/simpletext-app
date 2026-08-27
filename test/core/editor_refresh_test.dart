/// 편집 화면이 새 판을 만났을 때의 셈 시험.
///
/// 2026-08-20 저녁 사건: 동기화는 배달을 마쳤는데 열린 편집 화면이
/// 낡은 객체를 물고 낡은 글을 보여줬다(맥·안드로이드·웹 세 곳).
/// 화면 코드는 이 셈을 그대로 따르므로, 갈래는 여기서 못 박는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/sync_plan.dart';

void main() {
  test('같은 객체면 가만히 있는다 — 내 저장이 돌아온 메아리다', () {
    expect(
        editorRefresh(sameObject: true, editing: false, sameContent: true),
        EditorRefresh.keep);
    expect(
        editorRefresh(sameObject: true, editing: true, sameContent: false),
        EditorRefresh.keep);
  });

  test('새 판이 왔고 손대지 않았으면 갈아 그린다', () {
    expect(
        editorRefresh(sameObject: false, editing: false, sameContent: false),
        EditorRefresh.adopt);
  });

  test('치던 중이면 눈앞의 글이 이긴다 — 보면서 만지는 글을 소리 없이 갈아치우지 않는다', () {
    expect(
        editorRefresh(sameObject: false, editing: true, sameContent: false),
        EditorRefresh.assertMine);
  });

  group('2026-08-27 되받아치기 사건', () {
    // 맥앱이 노트 하나를 편집 화면에 열어 둔 채로, 30초마다 제 옛 글을
    // 새 시각으로 창고에 도로 올렸다. 웹앱에서 새로 쓴 줄이 계속 사라졌고,
    // 아이폰은 이미 받았던 글을 도로 잃었다. 옛 글이 새 도장을 받아
    // '가장 새것'이 되었기 때문이다.
    test('알맹이가 같으면 치던 중이어도 다시 쓰지 않는다', () {
      expect(
          editorRefresh(sameObject: false, editing: true, sameContent: true),
          EditorRefresh.rebind);
    });

    test('알맹이가 같으면 손대지 않았어도 갈아 그릴 것이 없다', () {
      expect(
          editorRefresh(sameObject: false, editing: false, sameContent: true),
          EditorRefresh.rebind);
    });

    test('rebind 는 keep 이 아니다 — 객체는 반드시 갈아 끼워야 한다', () {
      // 옛 객체는 이미 store.notes 에서 빠졌다. 그대로 물고 있으면
      // 그 뒤의 편집이 아무 데도 닿지 않는다.
      expect(
          editorRefresh(sameObject: false, editing: true, sameContent: true),
          isNot(EditorRefresh.keep));
    });
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
