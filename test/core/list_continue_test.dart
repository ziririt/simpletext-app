/// 목록 이어 주기 시험.
///
/// 2026-08-27 소유자 신고 — 목록 마지막 줄에서 엔터를 쳐도 다음 번호나
/// 블릿이 안 붙는다.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/list_continue.dart';

/// 글 끝에서 엔터를 친 셈. 편하려고 만든 손잡이다.
ListStep? at(String text) => listStep(text, text.length);

void main() {
  group('번호 목록', () {
    test('다음 번호가 붙는다', () {
      expect(at('1. 첫째')?.head, '2. ');
      expect(at('9. 아홉째')?.head, '10. ');
      expect(at('99. 아흔아홉')?.head, '100. ');
    });

    test('닫는 괄호 꼴도 그대로 이어 간다', () {
      expect(at('3) 셋째')?.head, '4) ');
    });

    test('들여쓰기를 물려받는다', () {
      expect(at('  2. 둘째')?.head, '  2. '.replaceFirst('2', '3'));
      expect(at('\t1. 하나')?.head, '\t2. ');
    });

    test('빈 항목에서는 표시를 걷고 목록을 끝낸다', () {
      final s = at('1. 첫째\n2. ');
      expect(s?.ends, isTrue);
      expect(s?.strip, '2. '.length);
    });

    test('빈 항목이 들여쓰기까지 걷힌다 — 들여쓴 자리에 커서만 남으면 그것도 찌꺼기다', () {
      final s = at('  1. ');
      expect(s?.strip, '  1. '.length);
    });
  });

  group('구분점·대시 목록', () {
    test('같은 표시가 이어진다', () {
      expect(at('· 하나')?.head, '· ');
      expect(at('- 하나')?.head, '- ');
      expect(at('• 하나')?.head, '• ');
      expect(at('* 하나')?.head, '* ');
    });

    test('빈 항목에서는 끝낸다', () {
      expect(at('· 하나\n· ')?.ends, isTrue);
      expect(at('- ')?.strip, 2);
    });
  });

  group('할 일 목록', () {
    test('이어지는 항목은 늘 빈 네모다 — 앞 줄이 끝났다고 다음 줄도 끝났을 리 없다', () {
      expect(at('- [ ] 살 것')?.head, '- [ ] ');
      expect(at('- [x] 산 것')?.head, '- [ ] ');
      expect(at('* [X] 산 것')?.head, '* [ ] ');
    });

    test('빈 항목에서는 끝낸다', () {
      expect(at('- [ ] ')?.ends, isTrue);
      expect(at('- [ ] ')?.strip, '- [ ] '.length);
    });

    test('할 일이 대시 목록보다 먼저 잡힌다 — 안 그러면 네모가 두 겹이 된다', () {
      expect(at('- [ ] 할 일')?.head, isNot('- '));
    });
  });

  group('목록이 아닌 줄', () {
    test('그냥 글에는 아무 일도 없다', () {
      expect(at('그냥 한 줄'), isNull);
      expect(at(''), isNull);
      expect(at('안녕하세요.\n두 번째 줄'), isNull);
    });

    test('표시 뒤에 빈칸이 없으면 목록이 아니다', () {
      // '1.5초'가 목록이 되면 곤란하다.
      expect(at('1.5초 걸렸다'), isNull);
      expect(at('-3도'), isNull);
    });

    test('줄 한가운데서 갈라도 이어 준다 — 그때 표시가 없으면 더 놀랍다', () {
      const t = '1. 하나와 둘';
      expect(listStep(t, 6)?.head, '2. ');
    });
  });

  group('글 칸에 물린 자', () {
    const f = ListContinueFormatter();

    TextEditingValue typeEnter(String text, int caret) {
      final before = TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: caret));
      final after = TextEditingValue(
        text: text.substring(0, caret) + '\n' + text.substring(caret),
        selection: TextSelection.collapsed(offset: caret + 1),
      );
      return f.formatEditUpdate(before, after);
    }

    test('엔터 한 번에 다음 번호가 따라온다', () {
      final v = typeEnter('1. 첫째', 5);
      expect(v.text, '1. 첫째\n2. ');
      expect(v.selection.baseOffset, v.text.length);
    });

    test('빈 항목에서 치면 표시가 걷히고 줄도 안 바뀐다', () {
      final v = typeEnter('1. 첫째\n2. ', 9);
      expect(v.text, '1. 첫째\n');
      // 줄바꿈 바로 뒤 — 표시가 있던 자리다.
      expect(v.selection.baseOffset, 6);
    });

    test('붙여넣기에는 안 끼어든다 — 글자가 여럿 늘면 그건 타자가 아니다', () {
      const before = TextEditingValue(
          text: '1. 첫째', selection: TextSelection.collapsed(offset: 5));
      const after = TextEditingValue(
          text: '1. 첫째\n붙여넣은 글',
          selection: TextSelection.collapsed(offset: 12));
      expect(f.formatEditUpdate(before, after).text, '1. 첫째\n붙여넣은 글');
    });

    test('글자를 지울 때는 안 끼어든다', () {
      const before = TextEditingValue(
          text: '1. 첫째', selection: TextSelection.collapsed(offset: 5));
      const after = TextEditingValue(
          text: '1. 첫', selection: TextSelection.collapsed(offset: 4));
      expect(f.formatEditUpdate(before, after).text, '1. 첫');
    });

    test('목록이 아니면 그냥 줄만 바뀐다', () {
      final v = typeEnter('그냥 글', 4);
      expect(v.text, '그냥 글\n');
    });
  });
}
