/// 굵은 강조(**)를 어떻게 처리하는지 고정하는 테스트.
///
/// 2026-08-14 소유자 신고: "**굵게**"가 "'굵게'"로 바뀌어 나온다.
/// 따옴표가 필요 없는 자리에까지 따옴표가 붙어 붙여넣기 뒤에 손이 갔다.
/// 지시: ** 는 모두 지운다. 따옴표로 바꾸지 않는다. 기본 규칙으로 넣는다.
///
/// 여기서 두 가지를 지킨다.
///   1) 기본값이 '마커 제거'라는 것 (앱 설정 쪽 기본값 + 옛 기기 1회 이관)
///   2) 짝이 깨진 ** 도 지운다는 것. 단 *** (구분선)은 건드리지 않는다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tidy_engine.dart';
import 'package:simpletext/main.dart';

void main() {
  group('앱 설정 기본값', () {
    // 2026-08-18 — 기본값이 'remove'에서 'keep'으로 바뀌었다.
    //
    // 08-14에 지우기로 한 진짜 까닭은 '**굵게**'가 "'굵게'"로 바뀌어
    // 나오는 것이 보기 싫어서였고, 그때는 굵게 보여 줄 방법이 없어서
    // 지우는 것이 최선이었다. 이제 편집기가 굵게 그려 주고, 복사할 때
    // core/plain_text.dart 가 벗긴다. 지울 이유가 사라졌다.
    test('새로 깔면 강조는 따옴표도 제거도 아니고 그대로 둔다', () {
      expect(AppSettings().emphStyle, 'keep');
    });

    test('판(rev)이 없던 옛 설정의 quoteSingle은 한 번 갈아엎는다', () {
      // 기본값만 바꾸면 이미 쓰던 기기는 저장된 값을 그대로 읽어 와서
      // 아무것도 안 바뀐다. 소유자 기기가 그 상태였다.
      //
      // 갈아엎기가 둘 겹친다. rev<1 이 quoteSingle → remove 로 옮기고,
      // rev<3 이 remove → keep 으로 옮긴다. 옛 기기는 두 번을 한 번에
      // 지나 keep 에 닿는다.
      final s = AppSettings.fromJson({'emphStyle': 'quoteSingle'});
      expect(s.emphStyle, 'keep');
    });

    test('remove 로 두고 쓰던 기기는 한 번만 keep 으로 옮긴다', () {
      expect(AppSettings.fromJson({'emphStyle': 'remove'}).emphStyle, 'keep');
    });

    test('옮긴 뒤 사용자가 다시 remove 로 돌려놓으면 그대로 둔다', () {
      // 이걸 안 지키면 고치는 게 아니라 설정을 뺏는 것이 된다.
      final s = AppSettings.fromJson(
          {'rev': AppSettings.settingsRev, 'emphStyle': 'remove'});
      expect(s.emphStyle, 'remove');
    });

    test('갈아엎은 뒤 사용자가 따옴표로 되돌려 놓으면 그대로 둔다', () {
      // 이걸 안 지키면 고치는 게 아니라 설정을 뺏는 것이 된다.
      final s = AppSettings.fromJson(
          {'rev': AppSettings.settingsRev, 'emphStyle': 'quoteSingle'});
      expect(s.emphStyle, 'quoteSingle');
    });

    test('판이 없어도 quoteSingle이 아니면 손대지 않는다', () {
      final s = AppSettings.fromJson({'emphStyle': 'keep'});
      expect(s.emphStyle, 'keep');
    });
  });

  group('굵은 강조 처리', () {
    TidyOptions o({String emph = 'remove'}) =>
        TidyOptions(stripEmphasis: true, emphStyle: emph);

    test('기본값에서는 마커만 지우고 따옴표를 붙이지 않는다', () {
      expect(tidy('이번 분기는 **역대 최고**였다.', o()).text,
          '이번 분기는 역대 최고였다.');
    });

    test('따옴표를 고른 사람에게는 그대로 따옴표를 준다', () {
      expect(tidy('이번 분기는 **역대 최고**였다.', o(emph: 'quoteSingle')).text,
          "이번 분기는 '역대 최고'였다.");
    });

    test('한쪽만 찍혀 온 **도 지운다', () {
      // AI 답변에서 흔하다. 지금까지는 본문에 그대로 박혀 나왔다.
      expect(tidy('비용이 지속적으로 증가**함에 따라', o()).text,
          '비용이 지속적으로 증가함에 따라');
    });

    test('줄이 바뀌어 짝이 깨진 **도 지운다', () {
      // 문단을 통째로 강조하면 줄바꿈이 사이에 끼어 짝 규칙이 안 먹는다.
      final out = tidy('**앞줄이 있고\n뒷줄이 있다**', o()).text;
      expect(out.contains('*'), isFalse, reason: out);
    });

    test('마침표 뒤에 홀로 남은 **도 지운다', () {
      expect(tidy('준비해주시기 바랍니다.**', o()).text, '준비해주시기 바랍니다.');
    });

    test('***는 구분선이므로 건드리지 않는다', () {
      // 앞의 두 개만 떼면 *가 하나 남아 구분선 판정이 통째로 깨진다.
      expect(tidy('앞\n\n***\n\n뒤', o()).text.contains('***'), isTrue);
    });

    test('그대로 유지를 고르면 **도 남는다', () {
      expect(tidy('**굵게**', o(emph: 'keep')).text, '**굵게**');
    });

    test('마커를 지운 개수를 보고서에 센다', () {
      final r = tidy('**하나** 그리고 **둘**', o());
      expect(r.text, '하나 그리고 둘');
      expect(r.report.markers, greaterThanOrEqualTo(2));
    });
  });
}
