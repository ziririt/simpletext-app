/// 스토어 스크린샷 자동 촬영 (11개 로케일).
///
/// 왜 이게 있는가 — 노하우 문서 6절:
///   "현지화된 스크린샷이 없으면 기본 언어의 스크린샷이 그대로 나간다.
///    경고도 없고 오류도 없다. 비한국어 사용자 전원이 한국어 스크린샷을 보고 있었다."
/// 손으로 11개 언어 × 여러 기기를 찍으면 반드시 빠지는 언어가 생긴다. 그래서 자동화한다.
///
/// 실행 (맥에서):
///   tool/screenshots.sh
///
/// 촬영 결과는 store/screenshots/<기기>/<로케일>/NN_이름.png 로 떨어진다.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletext/main.dart';

/// 스크린샷에 쓸 시연용 메모. 언어와 무관한 데이터(티커·수치)를 쓴다 —
/// 번역 품질과 상관없이 표 정렬이 똑같이 보여야 하기 때문이다.
String _demoNotes() {
  const wide = '''2021년 4월
  - 확인된 움직임 : 세계 책의 날에 작가 일러스트 기반 디지털 굿즈를 배포
  - 해석 : 굿즈를 독서 경험에 연결한 초기 사례

2023년 3~4월
  - 확인된 움직임 : 사명을 리디북스에서 리디로 변경, IP 영상화 추진
  - 해석 : IP 사업 확장 전략을 공개한 단계''';

  const narrow = '''종목            티커  수익률  비중
──────────────────────────────────
애플            AAPL  +14.2%  12%
마이크로소프트  MSFT  +21.5%  18%
엔비디아        NVDA  +48.9%  22%
테슬라          TSLA  -8.3%   8%''';

  const t = 1786000000000;
  final notes = [
    {
      'id': 'shot-1', 'title': 'Portfolio', 'body': narrow, 'originalBody': narrow,
      'pinned': true, 'source': 'ChatGPT', 'tags': <String>[],
      'createdAt': t, 'updatedAt': t, 'history': <String>[], 'lastReport': '',
    },
    {
      'id': 'shot-2', 'title': 'Timeline', 'body': wide, 'originalBody': wide,
      'pinned': false, 'source': 'Claude', 'tags': <String>[],
      'createdAt': t - 86400000, 'updatedAt': t - 86400000,
      'history': <String>[], 'lastReport': '',
    },
    {
      'id': 'shot-3', 'title': 'Research summary', 'body': 'Paste an answer and it becomes clean text.',
      'originalBody': '', 'pinned': false, 'source': 'Gemini', 'tags': <String>[],
      'createdAt': t - 172800000, 'updatedAt': t - 172800000,
      'history': <String>[], 'lastReport': '',
    },
  ];
  return jsonEncode({'v': 2, 'notes': notes, 'tombstones': <dynamic>[]});
}

/// 앱이 지원하는 9개 언어 → 스토어 로케일 11개.
/// 스페인어·포르투갈어는 지역별로 스토어 항목이 갈리므로 화면도 따로 찍는다
/// (문구 자체는 각각 es/pt 하나를 쓰지만, 스토어에 올릴 파일은 분리되어야 한다).
const _locales = <String, Locale>{
  'ko': Locale('ko'),
  'en-US': Locale('en'),
  'ja': Locale('ja'),
  'zh-Hans': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  'zh-Hant': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  'de-DE': Locale('de'),
  'fr-FR': Locale('fr'),
  'es-ES': Locale('es'),
  'es-MX': Locale('es'),
  'pt-BR': Locale('pt'),
  'pt-PT': Locale('pt'),
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _locales.entries) {
    final tag = entry.key;
    testWidgets('screenshots $tag', (tester) async {
      SharedPreferences.setMockInitialValues({'simpletext.notes.v2': _demoNotes()});

      await tester.pumpWidget(SimpleTextApp(locale: entry.value));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 1) 목록 화면
      await binding.takeScreenshot('$tag/01_list');

      // 2) 표가 든 메모 (정렬된 좁은 표)
      await tester.tap(find.text('Portfolio'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await binding.takeScreenshot('$tag/02_table');

      // 3) 넓은 표를 풀어쓴 메모
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await binding.takeScreenshot('$tag/03_records');

      await tester.pageBack();
      await tester.pumpAndSettle();
    });
  }
}
