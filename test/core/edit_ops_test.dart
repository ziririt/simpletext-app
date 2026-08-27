/// 도구 막대 단추들의 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/edit_ops.dart';

void main() {
  group('제목 돌리기', () {
    test('없음 → # → ## → ### → 없음', () {
      var r = cycleHeading('제목', 0, 0);
      expect(r.text, '# 제목');
      r = cycleHeading(r.text, 0, 0);
      expect(r.text, '## 제목');
      r = cycleHeading(r.text, 0, 0);
      expect(r.text, '### 제목');
      r = cycleHeading(r.text, 0, 0);
      expect(r.text, '제목');
    });

    test('네 번이면 제자리로 — 여섯 번 눌러야 하는 단추는 스위치가 아니라 미로다', () {
      var t = '제목';
      for (var i = 0; i < 4; i++) {
        t = cycleHeading(t, 0, 0).text;
      }
      expect(t, '제목');
    });

    test('빈 줄에는 안 붙인다', () {
      expect(cycleHeading('', 0, 0).text, '');
    });

    test('앞뒤 줄은 안 건드린다', () {
      const t = '첫 줄\n가운데\n끝 줄';
      final r = cycleHeading(t, 6, 6);
      expect(r.text, '첫 줄\n# 가운데\n끝 줄');
    });

    test('들여쓰기를 지킨다', () {
      expect(cycleHeading('  들여쓴 줄', 3, 3).text, '  # 들여쓴 줄');
    });
  });

  group('인용 스위치', () {
    test('붙였다 뗀다', () {
      final on = toggleQuote('한 줄', 0, 0);
      expect(on.text, '> 한 줄');
      expect(toggleQuote(on.text, 0, 0).text, '한 줄');
    });

    test('여러 줄을 한 번에', () {
      const t = '하나\n둘';
      final r = toggleQuote(t, 0, t.length);
      expect(r.text, '> 하나\n> 둘');
      expect(toggleQuote(r.text, 0, r.text.length).text, t);
    });

    test('빈 줄에는 안 붙인다 — 빈 줄에 인용 표시가 붙으면 그건 인용이 아니라 사고다', () {
      const t = '하나\n\n둘';
      expect(toggleQuote(t, 0, t.length).text, '> 하나\n\n> 둘');
    });

    test('하나라도 안 붙어 있으면 붙이는 쪽이다', () {
      const t = '> 하나\n둘';
      expect(toggleQuote(t, 0, t.length).text, '> > 하나\n> 둘');
    });
  });

  group('감싸기 스위치', () {
    test('고른 글을 감싼다', () {
      final r = toggleWrap('굵게 할 말', 0, 2, '**');
      expect(r.text, '**굵게** 할 말');
      expect(r.text.substring(r.start, r.end), '굵게');
    });

    test('밖에 붙은 표시를 벗긴다 — 안쪽만 골라 눌러도 벗겨져야 한다', () {
      const t = '**굵게** 할 말';
      final r = toggleWrap(t, 2, 4, '**');
      expect(r.text, '굵게 할 말');
      expect(r.text.substring(r.start, r.end), '굵게');
    });

    test('통째로 골라도 벗긴다', () {
      const t = '**굵게**';
      final r = toggleWrap(t, 0, t.length, '**');
      expect(r.text, '굵게');
    });

    test('고른 것이 없으면 표시만 놓고 사이에 선다', () {
      final r = toggleWrap('', 0, 0, '**');
      expect(r.text, '****');
      expect(r.start, 2);
      expect(r.collapsed, isTrue);
    });

    test('백틱도 같다', () {
      expect(toggleWrap('코드', 0, 2, '`').text, '`코드`');
      expect(toggleWrap('`코드`', 1, 3, '`').text, '코드');
    });
  });

  group('코드', () {
    test('한 줄이면 백틱', () {
      expect(toggleCode('flutter build', 0, 13).text, '`flutter build`');
    });

    test('줄이 넘어가면 울타리', () {
      const t = 'a\nb';
      final r = toggleCode(t, 0, t.length);
      expect(r.text, '```\na\nb\n```');
    });

    test('울타리를 다시 누르면 걷힌다', () {
      const t = '```\na\nb\n```';
      final r = toggleCode(t, 0, t.length);
      expect(r.text, 'a\nb');
    });
  });

  group('링크', () {
    test('고른 글이 이름이 되고 커서는 주소 자리로', () {
      final r = makeLink('구글 열기', 0, 2);
      expect(r.text, '[구글]() 열기');
      expect(r.start, '[구글]('.length);
    });

    test('고른 것이 없으면 커서는 이름 자리로', () {
      final r = makeLink('', 0, 0);
      expect(r.text, '[]()');
      expect(r.start, 1);
    });
  });

  group('들여쓰기와 내어쓰기', () {
    test('줄머리에 붙는다 — 커서가 줄 한가운데 있어도', () {
      expect(indentLines('한 줄', 2, 2).text, '  한 줄');
    });

    test('내어쓰기가 되돌린다', () {
      final a = indentLines('한 줄', 0, 0);
      expect(outdentLines(a.text, 0, 0).text, '한 줄');
    });

    test('빈 줄은 안 건드린다', () {
      expect(indentLines('', 0, 0).text, '');
    });

    test('탭 하나도 한 칸으로 친다', () {
      expect(outdentLines('\t한 줄', 0, 0).text, '한 줄');
    });

    test('걷을 것이 없으면 그대로다 — 눌러도 글이 안 깎인다', () {
      expect(outdentLines('한 줄', 0, 0).text, '한 줄');
    });

    test('여러 줄을 한 번에', () {
      const t = '하나\n둘';
      final r = indentLines(t, 0, t.length);
      expect(r.text, '  하나\n  둘');
      expect(outdentLines(r.text, 0, r.text.length).text, t);
    });

    test('빈칸이 하나뿐이면 하나만 걷는다', () {
      expect(outdentLines(' 한 줄', 0, 0).text, '한 줄');
    });
  });

  group('줄 범위 셈', () {
    test('커서 하나가 걸친 줄', () {
      const t = '하나\n둘\n셋';
      final s = blockSpan(t, 4, 4);
      expect(t.substring(s.from, s.to), '둘');
    });

    test('여러 줄에 걸친 자리는 양 끝 줄까지 늘린다', () {
      const t = '하나\n둘\n셋';
      final s = blockSpan(t, 1, 4);
      expect(t.substring(s.from, s.to), '하나\n둘');
    });

    test('거꾸로 고른 자리도 같다', () {
      const t = '하나\n둘';
      expect(blockSpan(t, 4, 1), blockSpan(t, 1, 4));
    });
  });
}
