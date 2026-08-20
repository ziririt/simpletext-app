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
}
