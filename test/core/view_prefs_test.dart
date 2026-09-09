// 보기 설정의 셈. 화면 없이 값만 따진다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/view_prefs.dart';

const base = ViewSpec(
  font: 'system',
  fontSize: 16,
  lineHeight: 1.5,
  bold: false,
  margin: 22,
  align: kAlignStart,
  paraGap: 1.0,
  paper: 'none',
);

void main() {
  group('두 층 섞기', () {
    test('덮어쓸 것이 없으면 전체값 그대로다', () {
      final v = ViewPrefs.none.applyTo(base);
      expect(v.fontSize, 16);
      expect(v.paper, 'none');
      expect(v.align, kAlignStart);
    });

    test('채운 칸만 덮어쓴다 — 나머지는 전체값이 그대로 살아 있다', () {
      const p = ViewPrefs(fontSize: 20, paper: 'sepia');
      final v = p.applyTo(base);
      expect(v.fontSize, 20);
      expect(v.paper, 'sepia');
      // 안 건드린 칸은 전체값이다. 여기가 깨지면 전체 설정을 바꿔도
      // 이 노트만 옛 값에 갇힌다.
      expect(v.lineHeight, 1.5);
      expect(v.margin, 22);
      expect(v.font, 'system');
    });

    test('전체값이 바뀌면 안 건드린 칸은 따라 움직인다', () {
      const p = ViewPrefs(fontSize: 20);
      final v = p.applyTo(base.copyWith(lineHeight: 2.0));
      expect(v.fontSize, 20);
      expect(v.lineHeight, 2.0);
    });
  });

  group('다른 칸만 남기기 (diff)', () {
    test('아무것도 안 바꿨으면 빈 값이다 — 빈 껍데기는 저장하지 않는다', () {
      expect(ViewPrefs.diff(base, base).isEmpty, isTrue);
    });

    test('바꾼 칸만 남는다', () {
      final p = ViewPrefs.diff(base.copyWith(fontSize: 21), base);
      expect(p.fontSize, 21);
      expect(p.lineHeight, isNull);
      expect(p.paper, isNull);
      expect(p.isNotEmpty, isTrue);
    });
  });

  group('저장과 되살리기', () {
    test('채운 칸만 적히고, 그대로 돌아온다', () {
      const p = ViewPrefs(fontSize: 19, bold: true, align: kAlignJustify);
      final j = p.toJson();
      expect(j.containsKey('lh'), isFalse);
      final back = ViewPrefs.fromJson(j);
      expect(back.fontSize, 19);
      expect(back.bold, isTrue);
      expect(back.align, kAlignJustify);
      expect(back.lineHeight, isNull);
    });

    test('망가진 저장본은 조용히 빈 값 — 앱이 안 뜨는 일은 없어야 한다', () {
      expect(ViewPrefs.fromJson(null).isEmpty, isTrue);
      expect(ViewPrefs.fromJson('보기설정').isEmpty, isTrue);
      expect(ViewPrefs.fromJson({'size': '크게'}).fontSize, isNull);
      expect(ViewPrefs.fromJson({'al': '가운데'}).align, kAlignStart);
    });

    test('범위를 벗어난 값은 안으로 끌어들인다', () {
      expect(ViewPrefs.fromJson({'mg': 9999}).margin, kMarginMax);
      expect(ViewPrefs.fromJson({'mg': -5}).margin, kMarginMin);
      expect(ViewPrefs.fromJson({'pg': 99}).paraGap, kParaGapMax);
    });
  });

  group('빈 줄 찾기 (문단 간격)', () {
    test('빈 줄을 끝내는 줄바꿈만 짚는다', () {
      //  0123 4 5678 9
      // 'abc\n\ndef\n'
      expect(blankLineBreaks('abc\n\ndef\n'), [4]);
    });

    test('빈 줄이 잇달아도 다 짚는다', () {
      expect(blankLineBreaks('a\n\n\nb'), [2, 3]);
    });

    test('맨 앞의 빈 줄도 짚는다', () {
      expect(blankLineBreaks('\nabc'), [0]);
    });

    test('맨 끝의 빈 줄은 세지 않는다 — 끝낼 줄바꿈이 없다', () {
      expect(blankLineBreaks('abc\n'), isEmpty);
      expect(blankLineBreaks(''), isEmpty);
      expect(blankLineBreaks('abc'), isEmpty);
    });
  });
}
