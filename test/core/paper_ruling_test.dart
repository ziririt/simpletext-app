/// 종이마다 어떤 줄을 긋는지 못 박는다.
///
/// 2026-08-17 소유자 신고에서 나온 테스트다 — "종이/크라프트/월넛/하늘은
/// 모눈종이 배경이 아닌데, 샘플에서는 모눈종이로 나왔다."
///
/// 이런 종류의 고장은 코드를 봐서는 안 보인다. 화면을 봐야 보이고, 화면은
/// 매번 안 본다. 그래서 종이가 늘어날 때마다 여기 한 줄이 늘게 해 둔다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/paper.dart';

void main() {
  group('종이별 줄 모양', () {
    test('세로줄은 모눈 하나뿐이다', () {
      final vertical = [
        for (final p in kPapers)
          if (drawsVertical(p.ruling)) p.id
      ];
      expect(vertical, ['grid']);
    });

    test('가로줄은 몰스킨·모눈 둘뿐이다', () {
      final horizontal = [
        for (final p in kPapers)
          if (drawsHorizontal(p.ruling)) p.id
      ];
      expect(horizontal, ['moleskine', 'grid']);
    });

    // 2026-08-18 소유자 지시로 '원고지'를 뺐다. 목록에서 사라졌다는 것과
    // 이미 그것을 고른 사람이 안전하다는 것은 다른 이야기라 둘 다 못 박는다.
    test("'원고지'는 목록에 없다", () {
      expect(kPapers.any((p) => p.id == 'manuscript'), isFalse);
    });

    test("옛 '원고지' 설정은 모눈으로 간다", () {
      expect(paperById('manuscript').id, 'grid');
    });

    test('보이는 차례', () {
      expect([for (final p in kPapers) p.id], [
        kPaperNone,
        'moleskine',
        'grid',
        'plain',
        'sepia',
        'kraft',
        'walnut',
        'sky',
      ]);
    });

    // 여백은 어느 종이에서든 **본문보다 어둡다.** 방향이 종이에 따라 갈리면
    // 다크에서 책상이 종이보다 밝아진다 — 2026-08-18에 실제로 그렇게
    // 만들었다가 되돌렸다. 그 되돌림을 여기서 못 박는다.
    test('여백은 언제나 본문보다 어둡다', () {
      for (final p in kPapers) {
        if (p.id == kPaperNone) continue;
        for (final dark in [false, true]) {
          final bg = p.bgOf(dark);
          final m = marginTone(bg);
          final reason = '${p.id} dark=$dark';
          expect(relativeLuminance(m) < relativeLuminance(bg), isTrue,
              reason: reason);
          // 살짝. 보이되 제 색을 주장하지는 않는다.
          expect(contrastRatio(bg, m) > 1.03, isTrue, reason: reason);
          expect(contrastRatio(bg, m) < 1.25, isTrue, reason: reason);
          // 알파는 건드리지 않는다.
          expect((m >> 24) & 0xFF, (bg >> 24) & 0xFF, reason: reason);
        }
      }
    });

    // 아주 어두운 종이에서도 한 칸은 움직여야 한다. 곱셈만 쓰면 0x21의
    // 5%는 1.65라 반올림해 두 칸, 사실상 없는 것과 같아진다.
    test('아주 어두운 색에서도 바닥값이 지켜 준다', () {
      expect(marginTone(0xFF101010), 0xFF0A0A0A);
      expect(marginTone(0xFF000000), 0xFF000000);
    });

    test('색 종이 넷과 세피아는 줄이 없다', () {
      for (final id in ['sepia', 'plain', 'kraft', 'walnut', 'sky']) {
        final p = kPapers.firstWhere((x) => x.id == id);
        expect(drawsHorizontal(p.ruling), isFalse, reason: id);
        expect(drawsVertical(p.ruling), isFalse, reason: id);
      }
    });

    test("'기본'도 줄이 없다", () {
      final none = kPapers.firstWhere((x) => x.id == kPaperNone);
      expect(drawsHorizontal(none.ruling), isFalse);
    });
  });
}
