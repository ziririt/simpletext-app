/// 폴더 이름 규칙.
///
/// 2026-08-17 — 이름을 다듬는 규칙은 눈으로 보고는 틀린 줄 모른다.
/// 앞뒤 공백, 가운데 두 칸 공백, 경로에 못 쓰는 글자, 너무 긴 이름 —
/// 어느 하나가 어긋나도 화면에서는 그럴듯해 보이고, 나중에 파일로
/// 내보낼 때야 터진다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/folders.dart';

void main() {
  group('이름 다듬기', () {
    test('앞뒤 공백을 뗀다', () {
      expect(normalizeFolder('  투자  '), '투자');
    });

    test('가운데 겹친 공백은 하나로', () {
      expect(normalizeFolder('미국   주식'), '미국 주식');
      expect(normalizeFolder('미국\t주식'), '미국 주식');
    });

    test('파일 이름에 못 쓰는 글자를 뺀다 — 내보낼 때 터진다', () {
      expect(normalizeFolder('2026/08 정리'), '2026 08 정리');
      expect(normalizeFolder('테슬라: 기록'), '테슬라 기록');
      expect(normalizeFolder(r'a\b'), 'a b');
      expect(normalizeFolder('무엇?'), '무엇');
    });

    test('하이픈은 살린다 — 날짜 폴더에 흔하다', () {
      expect(normalizeFolder('2026-08 정리'), '2026-08 정리');
    });

    test('너무 길면 자른다', () {
      final long = '가' * 60;
      expect(normalizeFolder(long).length, kFolderNameMax);
    });

    test('빈 이름은 폴더 없음과 같은 뜻', () {
      expect(normalizeFolder(''), '');
      expect(normalizeFolder('   '), '');
      expect(normalizeFolder('///'), '');
    });

    test("'.'과 '..'은 안 된다 — 파일 시스템에서 다른 뜻이다", () {
      expect(normalizeFolder('.'), '');
      expect(normalizeFolder('..'), '');
      expect(normalizeFolder(' .. '), '');
    });
  });

  group('목록 만들기', () {
    test('쓰이는 이름과 만들어 둔 이름을 합친다', () {
      // 만들어 둔 목록만 보면 다른 기기에서 만든 폴더가 안 보이고,
      // 쓰이는 이름만 보면 방금 만든 빈 폴더가 눈앞에서 사라진다.
      expect(folderNames(['투자'], ['독서']), ['독서', '투자']);
    });

    test('겹치는 것은 하나로', () {
      expect(folderNames(['투자', '투자'], ['투자']), ['투자']);
    });

    test('빈 이름은 목록에 안 넣는다', () {
      expect(folderNames(['', '  ', '투자'], const []), ['투자']);
    });

    test('다듬어서 넣는다', () {
      expect(folderNames(['  투자  '], ['투자']), ['투자']);
    });

    test('대소문자를 무시하고 사전 순', () {
      expect(folderNames(['banana', 'Apple', 'cherry'], const []),
          ['Apple', 'banana', 'cherry']);
    });

    test('순서가 그때그때 달라지지 않는다', () {
      final a = folderNames(['b', 'a', 'c'], const []);
      final b = folderNames(['c', 'b', 'a'], const []);
      expect(a, b);
    });

    test('빈 입력에서 죽지 않는다', () {
      expect(folderNames(const [], const []), isEmpty);
    });
  });

  group('새로 만들 수 있는가', () {
    test('없는 이름이면 된다', () {
      expect(canAddFolder('독서', ['투자']), isTrue);
    });

    test('이미 있으면 안 된다', () {
      expect(canAddFolder('투자', ['투자']), isFalse);
    });

    test('대소문자만 다른 것도 같은 것으로 본다', () {
      expect(canAddFolder('apple', ['Apple']), isFalse);
    });

    test('공백만 다른 것도 같은 것으로 본다', () {
      expect(canAddFolder('  투자 ', ['투자']), isFalse);
    });

    test('빈 이름은 못 만든다', () {
      expect(canAddFolder('', const []), isFalse);
      expect(canAddFolder('   ', const []), isFalse);
      expect(canAddFolder('..', const []), isFalse);
    });
  });
}
