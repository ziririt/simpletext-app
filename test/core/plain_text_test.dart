// 복사할 때 표시를 벗기는 규칙.
//
// 2026-08-18. 이 앱의 컨셉이 걸린 자리다 — "내 노트에서는 볼드체로 보이되,
// 복사해서 다른 곳에 붙여넣을 땐 기호를 제거한다."
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/plain_text.dart';

void main() {
  group('제목', () {
    test('# 하나부터 여섯까지 벗긴다', () {
      expect(toPlain('# 가'), '가');
      expect(toPlain('###### 가'), '가');
    });
    test('공백이 없으면 제목이 아니다 (해시태그)', () {
      expect(toPlain('#태그'), '#태그');
    });
  });

  group('굵게', () {
    test('짝이 맞으면 벗긴다', () => expect(toPlain('앞 **굵게** 뒤'), '앞 굵게 뒤'));
    test('한 줄에 둘도', () => expect(toPlain('**가** 와 **나**'), '가 와 나'));
    test('짝이 안 맞으면 그대로 — 곱셈이 거짓이 되면 안 된다', () {
      expect(toPlain('2*3=6'), '2*3=6');
      expect(toPlain('**아직'), '**아직');
    });
    test('세 겹도', () => expect(toPlain('***센***'), '센'));
  });

  test('취소선과 홑따옴표 코드', () {
    expect(toPlain('~~지움~~'), '지움');
    expect(toPlain('`코드`'), '코드');
  });

  test('인용', () => expect(toPlain('> 인용문'), '인용문'));

  group('할 일', () {
    test('안 끝낸 것', () => expect(toPlain('- [ ] 사기'), '☐ 사기'));
    test('끝낸 것', () => expect(toPlain('- [x] 샀다'), '☑ 샀다'));
    test('들여쓴 것', () => expect(toPlain('    - [ ] 안쪽'), '    ☐ 안쪽'));
    test('별표 글머리도', () => expect(toPlain('* [X] 했다'), '☑ 했다'));
  });

  group('코드 블록은 안 건드린다', () {
    test('안쪽의 #과 *는 내용이다', () {
      const md = '앞\n```\n# 파이썬 주석\nx = a ** b\n```\n뒤';
      expect(toPlain(md), '앞\n# 파이썬 주석\nx = a ** b\n뒤');
    });
    test('울타리 줄 자체는 사라진다', () {
      expect(toPlain('```\n가\n```'), '가');
    });
  });

  test('여러 줄이 차례를 지킨다', () {
    const md = '# 제목\n\n**굵은** 문장\n\n- [ ] 할 일';
    expect(toPlain(md), '제목\n\n굵은 문장\n\n☐ 할 일');
  });

  test('빈 글은 빈 글', () => expect(toPlain(''), ''));

  test('평범한 글은 하나도 안 바뀐다', () {
    const t = '오늘 날씨가 좋다.\n내일도 좋겠지.';
    expect(toPlain(t), t);
  });
}
