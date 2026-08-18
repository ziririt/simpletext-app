// 폴더 차례 — 2026-08-18 소유자 지시로 사전 순에서 사람이 정한 순으로.
//
// 이 파일이 하는 일: **눈으로는 못 보는 규칙**을 못 박는다. 폴더 차례는
// 화면을 열어 보면 늘 그럴듯해 보인다. 틀린 줄 아는 순간은 폴더가 열
// 개를 넘긴 다음이고, 그때는 이미 고칠 자리를 잊었다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/folders.dart';

void main() {
  group('폴더 차례는 사람이 정한다', () {
    test('만들어 둔 차례를 사전 순으로 다시 세우지 않는다', () {
      expect(folderNames(const [], ['하늘', '가방', '나무']),
          ['하늘', '가방', '나무']);
    });

    test('차례에 없는데 메모가 쓰는 이름은 사전 순으로 뒤에 붙는다', () {
      expect(folderNames(['zoo', 'apple'], ['하늘']),
          ['하늘', 'apple', 'zoo']);
    });

    test('대소문자만 다른 것은 하나로 본다 — 먼저 정해 둔 쪽이 이긴다', () {
      expect(folderNames(['WORK'], ['work']), ['work']);
    });
  });

  group('끌어 놓기', () {
    test('아래로 내리면 자리를 하나 당겨야 맞는다', () {
      // ReorderableListView 는 뽑기 전 자리를 준다. 0을 2로 보내면
      // 실제로는 1번 자리다.
      expect(reorderFolders(['a', 'b', 'c'], 0, 2), ['b', 'a', 'c']);
    });

    test('위로 올릴 때는 그대로다', () {
      expect(reorderFolders(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
    });

    test('맨 끝으로 보내기', () {
      expect(reorderFolders(['a', 'b', 'c'], 0, 3), ['b', 'c', 'a']);
    });

    test('제자리에 놓으면 안 바뀐다', () {
      expect(reorderFolders(['a', 'b', 'c'], 1, 1), ['a', 'b', 'c']);
      expect(reorderFolders(['a', 'b', 'c'], 1, 2), ['a', 'b', 'c']);
    });

    test('말이 안 되는 자리가 들어와도 안 죽는다', () {
      expect(reorderFolders(['a', 'b'], 5, 0), ['a', 'b']);
      expect(reorderFolders(const [], 0, 0), isEmpty);
    });
  });
}
