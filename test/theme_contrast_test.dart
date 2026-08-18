/// 화면 색을 눈이 아니라 숫자로 지킨다.
///
/// 2026-08-16 — 주조색을 맑은 하늘색으로 옮기면서 붙였다. 이 앱은 그동안
/// 색을 바꿀 때마다 주석에 명암비를 손으로 적어 왔는데, 손으로 적은 숫자는
/// 색을 바꾸면 같이 안 바뀐다. 실제로 이번에 두 군데가 어긋나 있었다 —
/// 경고 글자가 4.1:1, 삭제 빨강이 4.2:1로 기준(4.5:1)에 못 미쳤다.
///
/// 이제 이 파일이 지킨다. 색을 손대면 여기가 먼저 알려 준다.
///
/// 기준은 WCAG AA다. 글자는 4.5:1, 조작점(손잡이·테두리)은 3:1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/paper.dart' show contrastRatio;
import 'package:simpletext/main.dart'
    show AppC, kAccentFill, kOnAccentFill;

int _v(Color c) => c.toARGB32();

void main() {
  final modes = <String, AppC>{'라이트': AppC.light, '다크': AppC.dark};

  modes.forEach((name, c) {
    group('$name 화면 색 (2026-08-16)', () {
      test('강조색이 바탕과 카드 양쪽에서 읽힌다', () {
        expect(contrastRatio(_v(c.accent), _v(c.bg)),
            greaterThanOrEqualTo(4.5),
            reason: '$name 강조색 on 바탕');
        expect(contrastRatio(_v(c.accent), _v(c.panel)),
            greaterThanOrEqualTo(4.5),
            reason: '$name 강조색 on 카드');
      });

      test('안내문구가 읽힌다', () {
        // 이건 '읽어야 하는 문장'용이라 4.5:1을 지킨다.
        expect(contrastRatio(_v(c.guideInk), _v(c.panel)),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(_v(c.guideInk), _v(c.bg)),
            greaterThanOrEqualTo(4.5));
      });

      test('태그 블럭 글자가 읽힌다', () {
        expect(contrastRatio(_v(c.tagInk), _v(c.tagBg)),
            greaterThanOrEqualTo(4.5));
      });

      test('정보 카드와 경고 카드의 글자가 읽힌다', () {
        expect(contrastRatio(_v(c.accent), _v(c.infoBg)),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(_v(c.warnInk), _v(c.warnBg)),
            greaterThanOrEqualTo(4.5));
      });

      test('삭제 빨강이 읽힌다', () {
        expect(contrastRatio(_v(c.danger), _v(c.panel)),
            greaterThanOrEqualTo(4.5));
      });

      test('보조 글자는 최소한 3:1은 넘는다', () {
        // 날짜·부가정보용이라 본문 기준을 그대로 대지 않는다. 다만
        // 배경에 묻히면 안 되므로 조작점 기준(3:1)은 지킨다.
        expect(contrastRatio(_v(c.sub), _v(c.bg)), greaterThanOrEqualTo(3.0));
        expect(contrastRatio(_v(c.sub), _v(c.panel)), greaterThanOrEqualTo(3.0));
      });

      test('선택 손잡이가 보인다 (조작점 3:1)', () {
        expect(contrastRatio(_v(c.selHandle), _v(c.panel)),
            greaterThanOrEqualTo(3.0));
      });

      test('구분선은 보이되 시끄럽지 않다', () {
        final r = contrastRatio(_v(c.line), _v(c.panel));
        expect(r, greaterThan(1.05), reason: '$name 구분선 — 안 보인다');
        expect(r, lessThan(4.0), reason: '$name 구분선 — 너무 진하다');
      });
    });
  });

  group('채운 버튼의 글자 (2026-08-16)', () {
    // 소유자 신고의 핵심이었다 — 채운 버튼이 칙칙했다. 그 원인은
    // 머티리얼3가 씨앗에서 자동으로 만든 색을 쓰고 있었다는 것이고,
    // 고침은 우리 강조색을 직접 못 박는 것이었다. 그 위의 글자가
    // 읽히는지를 여기서 지킨다.
    // 2026-08-18 — 라이트도 다크와 같은 값으로 맞췄다. 소유자: "아이폰의
    // 버튼 색은 무겁고 답답하고 칙칙한 딥블루 컬러다."
    //
    // 예전에는 라이트가 진한 하늘 + 흰 글자였다. 읽히기는 했지만 '채운
    // 단추는 밝은 바탕에 진한 글자여야 맑다'를 다크에만 적용하고 라이트에는
    // 안 옮긴 상태였다.
    test('라이트·다크 모두 — 밝은 하늘 바탕에 진한 남색 글자', () {
      expect(contrastRatio(_v(kOnAccentFill), _v(kAccentFill)),
          greaterThanOrEqualTo(4.5));
    });

    // 글자용 강조색은 반대 요구를 받는다 — 밝은 바탕 **위에** 놓이므로
    // 진해야 한다. 그래서 채우는 색과 갈라 뒀고, 여기서 그 둘이 다시
    // 하나로 합쳐지지 않게 지킨다.
    test('글자용 강조색은 밝은 바탕에서 읽힌다', () {
      expect(contrastRatio(_v(AppC.light.accent), _v(AppC.light.bg)),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('하늘 기운 (2026-08-16)', () {
    test('바탕의 회색이 실제로 하늘 쪽으로 기울어 있다', () {
      // 소유자 요청: "이런 스카이블루를 가능한 한 좀 더 쓰고 싶다."
      // 진한 색을 여기저기 칠하는 대신 중성 회색을 옅은 하늘색으로
      // 옮겼다. 그 의도가 나중에 회색으로 되돌려지지 않게 못 박는다.
      // 파랑이 빨강보다 크면 하늘 쪽이다.
      for (final e in {'라이트': AppC.light, '다크': AppC.dark}.entries) {
        for (final pair in [
          (e.value.bg, '바탕'),
          (e.value.panel, '카드'),
          (e.value.line, '구분선'),
          (e.value.field, '검색칸'),
        ]) {
          final v = _v(pair.$1);
          final r = (v >> 16) & 0xFF;
          final bl = v & 0xFF;
          // 흰색과 검정은 중립이라 예외로 둔다(다크 바탕은 OLED를 위해
          // 진짜 검정이어야 하고, 라이트 카드는 흰 종이여야 한다).
          if (v == 0xFFFFFFFF || v == 0xFF000000) continue;
          expect(bl, greaterThanOrEqualTo(r),
              reason: '${e.key} ${pair.$2} — 하늘 기운이 없다');
        }
      }
    });
  });
}
