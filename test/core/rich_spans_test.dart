// 마크다운을 어디에 어떻게 그릴지 — 규칙을 못 박는다.
//
// 2026-08-18. 눈으로 보면 늘 그럴듯해 보인다. 틀린 줄 아는 순간은 커서가
// 엉뚱한 데로 뛸 때고, 그때는 어느 셈이 하나 어긋난 것인지 못 찾는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/rich_spans.dart';

void main() {
  group('제목', () {
    test('## 표시는 옅게, 뒤는 h2', () {
      final r = richSpans('## 안녕');
      expect(r, [
        const RichSpan(0, 3, RichKind.marker),
        const RichSpan(3, 5, RichKind.h2),
      ]);
    });

    test('#은 h1, ###은 h3', () {
      expect(richSpans('# 가').last.kind, RichKind.h1);
      expect(richSpans('### 가').last.kind, RichKind.h3);
    });

    test('####는 제목이 아니다 — 우리는 셋까지만 그린다', () {
      expect(richSpans('#### 가'), isEmpty);
    });

    test('#만 있고 공백이 없으면 제목이 아니다 (해시태그일 수 있다)', () {
      expect(richSpans('#태그'), isEmpty);
    });

    test('둘째 줄의 자리도 맞는다', () {
      final r = richSpans('가나다\n## 라');
      expect(r.first.start, 4);
    });
  });

  group('굵게', () {
    test('표시 두 쌍은 옅게, 사이는 굵게', () {
      final r = richSpans('앞 **굵게** 뒤');
      expect(r, [
        const RichSpan(2, 4, RichKind.marker),
        const RichSpan(4, 6, RichKind.bold),
        const RichSpan(6, 8, RichKind.marker),
      ]);
    });

    test('짝이 안 맞으면 그리지 않는다 (치는 중일 수 있다)', () {
      expect(richSpans('**아직'), isEmpty);
    });

    test('빈 ****는 굵게가 아니다', () {
      expect(richSpans('****'), isEmpty);
    });

    test('한 줄에 둘도 찾는다', () {
      final r = richSpans('**가** 사이 **나**');
      expect(r.where((e) => e.kind == RichKind.bold).length, 2);
    });

    test('제목 안의 굵게도 찾는다', () {
      final r = richSpans('## **가**');
      expect(r.any((e) => e.kind == RichKind.h2), isTrue);
      expect(r.any((e) => e.kind == RichKind.bold), isTrue);
    });
  });

  group('할 일', () {
    test('안 끝낸 것 — 네모만 물들고 글은 그대로', () {
      final r = richSpans('- [ ] 할 일');
      expect(r, [
        const RichSpan(0, 2, RichKind.marker),
        const RichSpan(2, 5, RichKind.box),
      ]);
    });

    test('끝낸 것 — 뒤의 글에 줄이 그어진다', () {
      final r = richSpans('- [x] 했다');
      expect(r.any((e) => e.kind == RichKind.done), isTrue);
    });

    test('대문자 X도 끝낸 것이다', () {
      expect(richSpans('- [X] 했다').any((e) => e.kind == RichKind.done), isTrue);
    });

    test('들여쓴 것도 찾는다', () {
      final r = richSpans('    - [ ] 안쪽');
      expect(r.first.start, 4);
    });

    test('- [y] 는 할 일이 아니다', () {
      expect(richSpans('- [y] 뭐지'), isEmpty);
    });
  });

  test('인용', () {
    final r = richSpans('> 인용문');
    expect(r, [
      const RichSpan(0, 2, RichKind.marker),
      const RichSpan(2, 5, RichKind.quote),
    ]);
  });

  group('네모 자리 찾기 (눌러서 켜고 끄기)', () {
    test('줄 첫머리에서 찾는다', () {
      final t = '- [ ] 가';
      final f = todoAt(t, 0)!;
      expect(f.boxAt, 3);
      expect(f.done, isFalse);
      expect(t[f.boxAt], ' ');
    });

    test('끝낸 것', () {
      expect(todoAt('- [x] 가', 0)!.done, isTrue);
    });

    test('둘째 줄', () {
      const t = '첫 줄\n- [ ] 가';
      final f = todoAt(t, 4)!;
      expect(t[f.boxAt], ' ');
    });

    test('할 일이 아니면 null', () {
      expect(todoAt('그냥 글', 0), isNull);
      expect(todoAt('- 목록', 0), isNull);
    });

    test('그리는 쪽과 누르는 쪽의 셈이 같다', () {
      // 이게 어긋나면 보이는 네모와 눌리는 자리가 다른 데 있게 된다.
      const t = '  * [x] 가';
      final drawn = richSpans(t).firstWhere((e) => e.kind == RichKind.box);
      final tapped = todoAt(t, 0)!;
      expect(drawn.start, tapped.markStart + 2);
      expect(tapped.boxAt, drawn.start + 1);
    });
  });
}
