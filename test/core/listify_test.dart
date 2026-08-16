/// 목록 만들기 규칙.
///
/// 2026-08-17 — 자판 위 막대를 목록 셋으로 갈아 끼우면서 붙였다.
/// 이 규칙은 눈으로 보고는 틀린 줄 모른다. 빈 줄, 들여쓰기, 이미 붙어
/// 있던 표시 — 어느 하나가 어긋나도 화면에서는 그럴듯해 보인다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/listify.dart';

void main() {
  group('붙이기', () {
    test('구분점을 줄마다 붙인다', () {
      expect(listify('사과\n배\n감', kind: kListBullet),
          '· 사과\n· 배\n· 감');
    });

    test('대시', () {
      expect(listify('사과\n배', kind: kListDash), '- 사과\n- 배');
    });

    test('번호는 1부터 센다', () {
      expect(listify('사과\n배\n감', kind: kListNumber),
          '1. 사과\n2. 배\n3. 감');
    });

    test('설정한 글머리 기호를 쓴다', () {
      expect(listify('사과', kind: kListBullet, bullet: '•'), '• 사과');
    });

    test('빈 글머리 기호가 오면 기본값으로 물러선다', () {
      expect(listify('사과', kind: kListBullet, bullet: '   '), '· 사과');
    });
  });

  group('빈 줄', () {
    test('빈 줄에는 아무것도 안 붙인다', () {
      expect(listify('사과\n\n배', kind: kListBullet), '· 사과\n\n· 배');
    });

    test('빈 줄은 번호를 먹지 않는다 — 빈 줄에 3.이 붙으면 사고다', () {
      expect(listify('사과\n\n배', kind: kListNumber), '1. 사과\n\n2. 배');
    });

    test('공백만 있는 줄도 빈 줄이다', () {
      expect(listify('사과\n   \n배', kind: kListNumber), '1. 사과\n   \n2. 배');
    });
  });

  group('들여쓰기', () {
    test('들여쓰기는 살린다', () {
      expect(listify('  사과\n    배', kind: kListDash),
          '  - 사과\n    - 배');
    });

    test('탭도 살린다', () {
      expect(listify('\t사과', kind: kListDash), '\t- 사과');
    });
  });

  group('이미 붙어 있는 표시', () {
    test('다른 종류는 떼고 새로 붙인다 — 안 그러면 두 겹이 된다', () {
      expect(listify('- 사과\n- 배', kind: kListBullet), '· 사과\n· 배');
      expect(listify('· 사과', kind: kListNumber), '1. 사과');
      expect(listify('1. 사과\n2. 배', kind: kListDash), '- 사과\n- 배');
    });

    test('별표와 엔대시·엠대시도 표시로 본다', () {
      expect(listify('* 사과\n– 배\n— 감', kind: kListDash),
          '- 사과\n- 배\n- 감');
    });

    test("'1)' 꼴도 번호로 본다", () {
      expect(listify('1) 사과', kind: kListDash), '- 사과');
    });
  });

  group('스위치처럼 다시 누르면 뗀다', () {
    test('같은 종류를 다시 누르면 표시가 사라진다', () {
      const src = '사과\n배';
      final on = listify(src, kind: kListBullet);
      expect(listify(on, kind: kListBullet), src);
    });

    test('번호도 마찬가지', () {
      const src = '사과\n배\n감';
      final on = listify(src, kind: kListNumber);
      expect(on, '1. 사과\n2. 배\n3. 감');
      expect(listify(on, kind: kListNumber), src);
    });

    test('하나라도 표시가 없으면 떼지 않고 마저 붙인다', () {
      expect(listify('- 사과\n배', kind: kListDash), '- 사과\n- 배');
    });

    test('뗄 때 들여쓰기는 남는다', () {
      expect(listify('  - 사과', kind: kListDash), '  사과');
    });
  });

  group('줄 단위로 넓히기', () {
    test('줄 가운데를 골라도 그 줄 전체가 대상이다', () {
      const t = '첫째 줄\n둘째 줄\n셋째 줄';
      final (a, b) = lineSpan(t, 6, 7); // '둘째 줄' 안쪽
      expect(t.substring(a, b), '둘째 줄');
    });

    test('여러 줄에 걸치면 걸친 줄 전부', () {
      const t = '가\n나\n다';
      final (a, b) = lineSpan(t, 1, 3); // '가' 끝 ~ '나' 뒤
      expect(t.substring(a, b), '가\n나');
    });

    test('맨 앞과 맨 끝', () {
      const t = '가\n나';
      final (a, b) = lineSpan(t, 0, 0);
      expect(t.substring(a, b), '가');
      final (c, d) = lineSpan(t, t.length, t.length);
      expect(t.substring(c, d), '나');
    });

    test('빈 글에서도 죽지 않는다', () {
      final (a, b) = lineSpan('', 0, 0);
      expect(a, 0);
      expect(b, 0);
    });
  });

  test('한 줄짜리 글에 그냥 커서만 있어도 된다', () {
    expect(listify('안녕', kind: kListBullet), '· 안녕');
  });
}
