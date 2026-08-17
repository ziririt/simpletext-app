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
    test('세로줄은 모눈과 원고지 둘뿐이다', () {
      final vertical = [
        for (final p in kPapers)
          if (drawsVertical(p.ruling)) p.id
      ];
      expect(vertical, ['manuscript', 'grid']);
    });

    test('가로줄은 몰스킨·원고지·모눈 셋뿐이다', () {
      final horizontal = [
        for (final p in kPapers)
          if (drawsHorizontal(p.ruling)) p.id
      ];
      expect(horizontal, ['moleskine', 'manuscript', 'grid']);
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
