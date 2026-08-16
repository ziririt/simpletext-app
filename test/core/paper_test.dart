import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/paper.dart';

void main() {
  group('종이 고르기 (2026-08-16)', () {
    test('모르는 이름은 기본으로 떨어진다', () {
      expect(paperById('없는종이').id, kPaperNone);
      expect(paperById('').id, kPaperNone);
      expect(paperOn('없는종이'), isFalse);
    });

    test('몰스킨은 가로줄 종이다', () {
      expect(paperById('moleskine').ruling, kRulingLine);
      expect(paperOn('moleskine'), isTrue);
    });

    test('이름이 겹치지 않는다', () {
      final ids = kPapers.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('종이 색은 눈이 아니라 숫자로 정한다 (2026-08-16)', () {
    // 이 테스트가 이 파일의 존재 이유다. 색을 손대는 사람은 반드시 여기를
    // 먼저 통과해야 한다.
    for (final p in kPapers.where((p) => p.id != kPaperNone)) {
      test('${p.id} — 글자가 읽힌다 (4.5:1 이상)', () {
        expect(contrastRatio(p.ink, p.bg), greaterThanOrEqualTo(4.5),
            reason: '${p.id} 라이트');
        expect(contrastRatio(p.inkDark, p.bgDark), greaterThanOrEqualTo(4.5),
            reason: '${p.id} 다크');
      });

      test('${p.id} — 줄이 글자보다 세지 않다 (1.1~3.0)', () {
        // 아래를 막는 이유: 줄이 바탕과 같으면 안 보인다.
        // 위를 막는 이유: 줄이 진하면 글보다 줄이 먼저 읽힌다.
        for (final r in [
          (contrastRatio(p.rule, p.bg), '라이트'),
          (contrastRatio(p.ruleDark, p.bgDark), '다크'),
        ]) {
          expect(r.$1, greaterThan(1.05), reason: '${p.id} ${r.$2} — 안 보인다');
          expect(r.$1, lessThan(3.0), reason: '${p.id} ${r.$2} — 너무 진하다');
        }
      });
    }

    test('명암비 셈이 맞다 — 검정과 흰색은 21:1', () {
      expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21.0, 0.01));
      expect(contrastRatio(0xFF888888, 0xFF888888), closeTo(1.0, 0.001));
    });
  });

  group('줄 위치 (2026-08-16)', () {
    test('글줄 높이만큼 정확히 벌어진다', () {
      final ys = ruleOffsets(
          lineHeight: 27.2, viewHeight: 100, scroll: 0, topPad: 0);
      expect(ys.length, 3);
      expect(ys[0], closeTo(27.2, 0.001));
      expect(ys[1] - ys[0], closeTo(27.2, 0.001));
      expect(ys[2] - ys[1], closeTo(27.2, 0.001));
    });

    test('스크롤해도 줄은 늘 같은 격자 위에 있다', () {
      // 이게 어긋나면 화면 아래로 갈수록 글자가 줄에서 떠오르거나 잠긴다.
      // 종이처럼 안 보이는 가장 흔한 실패다.
      //
      // '같은 자리'가 아니라 '같은 격자'로 재는 것이 중요하다. 한 줄만큼
      // 스크롤하면 위에서 새 줄 하나가 화면 안으로 들어온다 — 목록이
      // 그대로일 수는 없다. 맞아야 하는 것은 간격이지 개수가 아니다.
      // (처음엔 이걸 '목록이 같아야 한다'로 썼다가 테스트가 잡아냈다.)
      const lh = 27.2;
      final base = ruleOffsets(
          lineHeight: lh, viewHeight: 200, scroll: 0, topPad: 12);
      for (final scroll in [lh, lh * 3, lh / 2, 7.0, 123.4]) {
        final ys = ruleOffsets(
            lineHeight: lh, viewHeight: 200, scroll: scroll, topPad: 12);
        expect(ys, isNotEmpty, reason: 'scroll=$scroll 에서 줄이 사라졌다');
        for (final y in ys) {
          // 기준 줄에서 몇 칸 떨어졌는지가 정수여야 한다.
          final n = (y + scroll - base.first) / lh;
          expect((n - n.roundToDouble()).abs(), lessThan(0.0001),
              reason: 'scroll=$scroll, y=$y 가 격자에서 벗어났다');
        }
        // 이웃한 줄 사이는 언제나 정확히 한 줄 높이.
        for (var i = 1; i < ys.length; i++) {
          expect(ys[i] - ys[i - 1], closeTo(lh, 0.0001));
        }
      }
    });

    test('반 줄만큼 스크롤하면 줄도 반 줄만 움직인다', () {
      const lh = 20.0;
      final ys = ruleOffsets(
          lineHeight: lh, viewHeight: 100, scroll: 10, topPad: 0);
      expect(ys.first, closeTo(10.0, 0.001));
    });

    test('화면 위로 올라간 줄은 안 그린다', () {
      final ys = ruleOffsets(
          lineHeight: 20, viewHeight: 100, scroll: 1000, topPad: 0);
      expect(ys.every((y) => y >= 0 && y <= 100), isTrue);
      expect(ys.isNotEmpty, isTrue);
    });

    test('말이 안 되는 값에는 빈 목록 — 무한 반복으로 앱을 세우지 않는다', () {
      expect(ruleOffsets(lineHeight: 0, viewHeight: 100, scroll: 0, topPad: 0),
          isEmpty);
      expect(ruleOffsets(lineHeight: -5, viewHeight: 100, scroll: 0, topPad: 0),
          isEmpty);
      expect(ruleOffsets(lineHeight: 20, viewHeight: 0, scroll: 0, topPad: 0),
          isEmpty);
      expect(
          ruleOffsets(
              lineHeight: double.nan, viewHeight: 100, scroll: 0, topPad: 0),
          isEmpty);
      expect(
          ruleOffsets(
              lineHeight: 20, viewHeight: double.infinity, scroll: 0, topPad: 0),
          isEmpty);
    });

    test('세로줄도 칸 너비만큼 벌어진다', () {
      final xs = columnOffsets(colWidth: 25, viewWidth: 100);
      expect(xs, [25.0, 50.0, 75.0]);
      expect(columnOffsets(colWidth: 0, viewWidth: 100), isEmpty);
      expect(columnOffsets(colWidth: 25, viewWidth: 0), isEmpty);
    });
  });
}
