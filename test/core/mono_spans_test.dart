/// 어디를 등폭으로 그릴지 고르는 규칙 테스트.
///
/// 2026-08-14 소유자 요청: "표 부분만 등폭 폰트 쓰고 기본 텍스트는 기기의 기본
/// 시스템 폰트 쓸 수 있으면 좋겠다." 그래서 지켜야 할 것이 두 가지다.
///   1) 표·코드는 반드시 등폭으로 잡혀야 한다 (놓치면 칸이 어긋나 보인다)
///   2) 줄글은 절대 등폭으로 잡히면 안 된다 (그러면 요청 자체가 무의미해진다)
/// 아래 테스트는 두 방향을 모두 본다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/mono_spans.dart';
import 'package:simpletext/core/tidy_engine.dart';

/// 구간에 실제로 들어간 줄들을 돌려준다 — 기대값을 눈으로 읽기 쉽게 하려고.
List<String> monoLines(String text) {
  final out = <String>[];
  for (final s in monoSpans(text)) {
    out.addAll(text.substring(s.start, s.end).split('\n'));
  }
  out.removeWhere((l) => l.isEmpty);
  return out;
}

void main() {
  group('등폭으로 그릴 구간 고르기', () {
    test('줄글만 있으면 등폭 구간이 없다', () {
      const t = '오늘 회의 정리\n\n· 예산은 다음 주에 다시 본다.\n· 인원은 그대로 간다.';
      expect(monoSpans(t), isEmpty);
    });

    test('정렬된 표는 머리글부터 마지막 행까지 잡는다', () {
      const t = '앞선 줄글입니다.\n\n'
          '종목    비중\n'
          '────────────\n'
          '애플    12%\n'
          '테슬라  8%\n'
          '\n'
          '뒤에 오는 줄글입니다.';
      expect(monoLines(t), ['종목    비중', '────────────', '애플    12%', '테슬라  8%']);
    });

    test('표 앞뒤 줄글은 등폭이 아니다', () {
      const t = '앞선 줄글입니다.\n\n종목    비중\n────────────\n애플    12%\n\n뒤에 오는 줄글입니다.';
      final picked = monoLines(t).join('\n');
      expect(picked.contains('줄글'), false);
    });

    test('표가 아닌 장식용 가로선은 잡지 않는다', () {
      // 엔진의 표 탐지와 같은 기준: 위가 여러 칸짜리 머리글이어야 표다.
      const t = '제목입니다\n──────────\n본문 한 줄입니다.';
      expect(monoSpans(t), isEmpty);
    });

    test('코드 블록은 통째로 잡는다', () {
      const t = '설명입니다.\n```dart\nvoid main() {}\n```\n다시 설명입니다.';
      expect(monoLines(t), ['```dart', 'void main() {}', '```']);
    });

    test('닫히지 않은 코드 블록은 뒤 전체를 삼키지 않는다', () {
      // 입력하는 도중에는 여는 울타리만 있을 수 있다. 그때 문서 전체가
      // 등폭으로 바뀌어 버리면 글을 쓸 수가 없다.
      const t = '설명입니다.\n```\n아직 입력 중인 줄';
      expect(monoSpans(t), isEmpty);
    });

    test('아직 정리하지 않은 파이프 표도 잡는다', () {
      const t = '아래는 표입니다.\n| 종목 | 비중 |\n|---|---|\n| 애플 | 12% |\n\n끝.';
      expect(monoLines(t), ['| 종목 | 비중 |', '|---|---|', '| 애플 | 12% |']);
    });

    test('탭으로 구분된 표(AI 앱에서 복사한 것)도 잡는다', () {
      const t = '붙여넣은 표\n종목\t비중\n애플\t12%\n테슬라\t8%';
      expect(monoLines(t), ['종목\t비중', '애플\t12%', '테슬라\t8%']);
    });

    test('줄글 한 줄에 세로줄이 하나 있다고 표로 보지 않는다', () {
      const t = '경로는 A | B 형태로 적는다.\n다음 줄은 평범한 줄글이다.';
      expect(monoSpans(t), isEmpty);
    });

    test('풀어쓴 표는 줄글로 둔다', () {
      // 풀어쓰기는 칸을 맞추지 않는 형식이라 등폭이 필요 없다.
      const t = '2021년 4월\n  - 확인된 움직임 : 매수\n  - 해석 : 관망\n\n2021년 5월\n  - 확인된 움직임 : 매도';
      expect(monoSpans(t), isEmpty);
    });

    test('구간은 줄바꿈까지 포함한다 (표 근처 줄 간격이 튀지 않도록)', () {
      const t = '종목    비중\n────────────\n애플    12%\n\n뒷줄글';
      final s = monoSpans(t).single;
      expect(t.substring(s.start, s.end).endsWith('\n'), true);
      expect(t.substring(s.end), '\n뒷줄글');
    });

    test('표 바로 다음 줄에 빈 줄 없이 붙은 글은 표의 행으로 본다', () {
      // 엔진도 똑같이 본다(빈 줄이 나올 때까지가 한 표다). 화면과 엔진이 서로
      // 다르게 판단하면, 정리를 눌렀을 때 방금 본 것과 다른 결과가 나온다.
      const t = '종목    비중\n────────────\n애플    12%\n뒤에 붙은 줄';
      expect(monoLines(t), ['종목    비중', '────────────', '애플    12%', '뒤에 붙은 줄']);
    });
  });

  group('엔진이 만든 표는 반드시 등폭으로 잡힌다', () {
    // 이 프로젝트의 왕복 규칙: 엔진이 만든 형식은 엔진(과 화면)이 되읽을 수 있어야
    // 한다. 표 출력 형식을 바꾸면서 여기를 안 고치면, 정리 직후 표가 줄글 글꼴로
    // 그려져 칸이 어긋나 보인다.
    test('정리한 결과의 표 블록이 그대로 등폭 구간이 된다', () {
      const raw = '| 종목 | 티커 | 수익률 | 비중\n'
          '|------|------|--------|\n'
          '| 애플 | AAPL | +14.2% | 12% |\n'
          '| 마이크로소프트 | MSFT | +21.5%\n'
          '|테슬라|TSLA|-8.3%|8%|';
      final out = tidy(raw, buildPresets().firstWhere((p) => p.id == 'ai').opts).text;
      final tableLines = out.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(monoLines(out), tableLines);
    });

    test('표 + 줄글이 섞인 결과에서 표만 골라낸다', () {
      const raw = '### 요약\n\n- 첫째 줄입니다.\n\n| 기업 | 반응 |\n|---|---|\n| Apple | 혼재 |';
      final out = tidy(raw, buildPresets().firstWhere((p) => p.id == 'ai').opts).text;
      final picked = monoLines(out);
      expect(picked.any((l) => RegExp(r'^─+$').hasMatch(l)), true,
          reason: '표 구분선이 등폭 구간에 없다');
      expect(picked.any((l) => l.contains('첫째 줄')), false,
          reason: '줄글이 등폭 구간에 섞였다');
    });
  });
}
