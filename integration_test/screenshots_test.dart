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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletext/main.dart';

import 'shot_demo.dart';

Future<void> back(WidgetTester tester) async {
  final b = find.byType(BackButton);
  if (b.evaluate().isEmpty) return;
  await tester.tap(b.first);
  await tester.pumpAndSettle();
}

/// 메모를 연다.
///
/// 분할 보기에서는 같은 제목이 두 군데 있다 — 왼쪽 목록의 줄, 그리고
/// 오른쪽에 열린 글의 제목칸. 그냥 누르면 '둘 중 어느 것이냐'로 멈춘다.
/// 목록이 먼저 그려지므로 첫 번째가 목록의 줄이다.
Future<void> openNote(WidgetTester tester, String title) async {
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
}

/// 한 장 찍는다.
///
/// 2026-08-17 — 아이폰의 둘째·셋째 장이 **화면이 미끄러지는 도중**에
/// 찍혀 있었다. 왼쪽에 목록이 반쯤, 오른쪽에 글이 반쯤. 스토어에 올리면
/// 앱이 고장 난 것처럼 보인다. 아이패드는 분할 보기라 전환이 없어서 멀쩡했다.
///
/// 원인이 둘 겹쳐 있었다.
///
/// 하나 — `pumpAndSettle(const Duration(seconds: 1))`의 그 1초는 기다리는
/// 시간이 아니다. **몇 초 간격으로 화면을 굴릴 것인가**를 정하는 값이고,
/// 기다리는 한도는 따로 있다(기본 10분). 이름만 보고 '1초 기다린다'로
/// 읽으면 틀린다.
///
/// 둘 — 그리고 이게 진짜다. pumpAndSettle이 보장하는 것은 '위젯이 다
/// 정착했다'까지다. 그런데 **사진을 찍는 일은 플랫폼 쪽에서 따로 일어난다.**
/// 그려진 것이 화면에 실제로 올라오기까지는 진짜 시간이 걸리고, 시험용
/// 시계를 아무리 돌려도 그 시간은 안 지나간다.
///
/// 그래서 진짜 시계로 기다리는 한 박자를 넣었다.
Future<void> shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in shotLocales.entries) {
    final tag = entry.key;
    final demo = shotDemos[tag]!;
    testWidgets('screenshots $tag', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'simpletext.notes.v2': shotDemoNotes(demo)});

      await tester.pumpWidget(SimpleTextApp(locale: entry.value));
      await tester.pumpAndSettle();

      // 1) 목록 화면
      await shoot(tester, binding, '$tag/01_list');

      // 2) 표가 든 메모 (정렬된 좁은 표)
      await openNote(tester, demo.portfolio);
      await shoot(tester, binding, '$tag/02_table');

      // 3) 넓은 표를 풀어쓴 메모
      await back(tester);
      await openNote(tester, demo.timeline);
      await shoot(tester, binding, '$tag/03_records');

      await back(tester);
    });
  }
}
