// 종이로 나갈 때 글이 어떤 덩어리로 읽히는지 — 눈으로는 확인하기 어려운 값들.
//
// PDF 자체는 바이트 덩어리라 시험으로 보기 어렵다. 그래서 **판정만** 떼어
// 두고 여기서 지킨다. 종이 위 모양이 이상하면 열에 아홉은 여기가 틀린 것이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/print_blocks.dart';

void main() {
  group('printBlocks', () {
    test('제목은 표시를 걷어내고 뜻만 남긴다', () {
      final b = printBlocks('# 큰제목\n## 중간\n#### 넷째');
      expect(b.map((e) => e.kind).toList(),
          [PKind.h1, PKind.h2, PKind.h3]);
      expect(b[0].plain, '큰제목');
      expect(b[2].plain, '넷째'); // 넷 이상은 셋과 같이
    });

    test('코드 울타리 안은 아무 규칙도 보지 않는다', () {
      final b = printBlocks('```\n# 이건 제목이 아니다\n- 이것도\n```');
      expect(b.length, 1);
      expect(b.first.kind, PKind.code);
      expect(b.first.text, '# 이건 제목이 아니다\n- 이것도');
    });

    test('할 일의 네모와 들여쓰기', () {
      final b = printBlocks('- [ ] 안 함\n  - [x] 끝냄');
      expect(b[0].kind, PKind.task);
      expect(b[0].checked, isFalse);
      expect(b[0].indent, 0);
      expect(b[1].checked, isTrue);
      expect(b[1].indent, 1);
      expect(b[1].plain, '끝냄');
    });

    test('글머리표와 번호는 갈라 본다', () {
      final b = printBlocks('- 하나\n1. 둘\n2) 셋');
      expect(b[0].kind, PKind.bullet);
      expect(b[1].kind, PKind.numbered);
      expect(b[1].marker, '1.');
      expect(b[2].marker, '2)');
    });

    test('구분줄이 있어야 표로 본다', () {
      final t = printBlocks('| 종목 | 등락 |\n|---|---|\n| TSLA | -8.3% |');
      expect(t.first.kind, PKind.table);
      expect(t.first.rows, [
        ['종목', '등락'],
        ['TSLA', '-8.3%'],
      ]);

      // 구분줄이 없으면 그냥 글이다 — 세로줄 든 문장을 표로 만들지 않는다.
      final n = printBlocks('| 그냥 | 글 |');
      expect(n.first.kind, PKind.para);
    });

    test('표의 칸 수가 줄마다 다르면 넓은 쪽에 맞춰 채운다', () {
      final t = printBlocks('| a | b | c |\n|---|---|---|\n| 1 | 2 |');
      expect(t.first.rows[1], ['1', '2', '']);
    });

    test('가로선', () {
      expect(printBlocks('---').first.kind, PKind.hr);
      expect(printBlocks('***').first.kind, PKind.hr);
      expect(printBlocks('--').first.kind, PKind.para); // 둘은 아니다
    });

    test('앞뒤 빈 줄은 떨어내고 가운데 빈 줄은 남긴다', () {
      final b = printBlocks('\n\n가\n\n나\n\n');
      expect(b.map((e) => e.kind).toList(),
          [PKind.para, PKind.blank, PKind.para]);
    });
  });

  group('inlineSpans', () {
    test('굵게·기울임·코드', () {
      expect(inlineSpans('보통 **굵게** 끝'), [
        const PSpan('보통 '),
        const PSpan('굵게', bold: true),
        const PSpan(' 끝'),
      ]);
      expect(inlineSpans('`코드`'), [const PSpan('코드', code: true)]);
      expect(inlineSpans('~~지움~~'), [const PSpan('지움', strike: true)]);
    });

    test('짝이 없는 표시는 표시가 아니다', () {
      // 이걸 안 보면 곱셈 하나 때문에 그 뒤가 통째로 기울어진다.
      expect(inlineSpans('2 * 3 = 6'), [const PSpan('2 * 3 = 6')]);
    });

    test('낱말 안의 밑줄은 표시가 아니다', () {
      expect(inlineSpans('snake_case_name'), [const PSpan('snake_case_name')]);
    });

    test('연결은 사람이 읽는 모양으로 편다', () {
      expect(inlineSpans('[테슬라](https://x.com/tesla)').first.text,
          '테슬라 (https://x.com/tesla)');
      expect(inlineSpans('[https://a.b](https://a.b)').first.text,
          'https://a.b');
    });
  });
}
