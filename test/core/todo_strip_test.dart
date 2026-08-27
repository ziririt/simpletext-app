/// 할 일 목록·서식 지우기 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/edit_ops.dart';

void main() {
  group('할 일 목록 — 줄마다 붙는다', () {
    test('여러 줄을 한 번에 (소유자 요청)', () {
      const t = '우유 사기\n청소하기\n전화하기';
      final r = toggleTodo(t, 0, t.length);
      expect(r.text, '- [ ] 우유 사기\n- [ ] 청소하기\n- [ ] 전화하기');
    });

    test('다시 누르면 걷힌다 — 글은 남는다', () {
      const t = '- [ ] 우유 사기\n- [x] 청소하기';
      final r = toggleTodo(t, 0, t.length);
      expect(r.text, '우유 사기\n청소하기');
    });

    test('이미 목록인 줄은 갈아 끼운다 — 두 겹이 되지 않는다', () {
      const t = '- 우유 사기\n1. 청소하기\n· 전화하기';
      final r = toggleTodo(t, 0, t.length);
      expect(r.text, '- [ ] 우유 사기\n- [ ] 청소하기\n- [ ] 전화하기');
    });

    test('들여쓰기를 지킨다', () {
      expect(toggleTodo('  깊은 항목', 0, 0).text, '  - [ ] 깊은 항목');
    });

    test('빈 줄은 안 건드린다', () {
      const t = '하나\n\n둘';
      expect(toggleTodo(t, 0, t.length).text, '- [ ] 하나\n\n- [ ] 둘');
    });

    test('하나만 안 붙어 있으면 붙이는 쪽이다', () {
      const t = '- [ ] 하나\n둘';
      expect(toggleTodo(t, 0, t.length).text, '- [ ] 하나\n- [ ] 둘');
    });

    test('커서만 있어도 그 줄에 붙는다', () {
      const t = '하나\n둘\n셋';
      expect(toggleTodo(t, 4, 4).text, '하나\n- [ ] 둘\n셋');
    });
  });

  group('서식 지우기', () {
    test('굵게를 걷는다', () {
      expect(bareText('**중요한** 말'), '중요한 말');
    });

    test('소제목과 인용을 걷는다', () {
      expect(bareText('## 소제목'), '소제목');
      expect(bareText('> 인용한 말'), '인용한 말');
    });

    test('목록 표시를 걷고 들여쓰기는 남긴다', () {
      expect(bareText('  - 항목'), '  항목');
      expect(bareText('1. 항목'), '항목');
      expect(bareText('- [x] 다 한 일'), '다 한 일');
    });

    test('링크는 이름만 남긴다', () {
      expect(bareText('[구글](https://google.com)에서'), '구글에서');
    });

    test('코드와 취소선과 형광펜', () {
      expect(bareText('`flutter build` 를'), 'flutter build 를');
      expect(bareText('~~지운 말~~'), '지운 말');
      expect(bareText('==밝힌 말=='), '밝힌 말');
    });

    test('홑별표는 안 건드린다 — 곱셈 기호를 지워 버리면 안 된다', () {
      expect(bareText('3 * 4 = 12'), '3 * 4 = 12');
    });

    test('밑줄 문자는 안 건드린다 — snake_case 를 망가뜨리면 안 된다', () {
      expect(bareText('source_detect.dart'), 'source_detect.dart');
    });

    test('고른 것이 없으면 그 줄 하나만 걷는다', () {
      const t = '**첫 줄**\n**둘째 줄**';
      final r = stripFormat(t, 0, 0);
      expect(r.text, '첫 줄\n**둘째 줄**');
    });

    test('고른 곳만 걷는다', () {
      const t = '**앞** 그리고 **뒤**';
      final r = stripFormat(t, 0, 5);
      expect(r.text, '앞 그리고 **뒤**');
    });

    test('걷을 것이 없으면 그대로다', () {
      expect(bareText('그냥 글'), '그냥 글');
    });
  });
}
