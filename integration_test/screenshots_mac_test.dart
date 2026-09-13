/// 맥 앱스토어 스크린샷 (11개 로케일) — 화면을 차려 놓고, 찍는 것은 바깥이 한다.
///
/// 2026-09-13 신설. 아이폰 쪽(screenshots_test.dart)은 binding.takeScreenshot
/// 으로 찍지만, 그 다리는 **맥에는 없다**(integration_test 의 macOS 플러그인에
/// 찍는 코드가 없다 — 실측). 그리고 이 앱은 맥에서 샌드박스 안에서 돌아서
/// 제 손으로 screencapture 를 부를 수도 없다.
///
/// 그래서 역할을 나눈다.
///   · 이 시험: 시연 메모를 넣고 화면을 차린 뒤 `want_<이름>` 파일을 놓고 기다린다
///   · tool/screenshots_mac.sh: 그 파일을 보면 창을 찍고 `done_<이름>` 을 놓는다
/// 파일이 오가는 자리는 앱의 샌드박스 컨테이너 안(HOME/shots)이다.
///
/// 동기화는 꺼 둔다 — 설정만으로는 안 된다. 창고 고르기를 열쇠고리가
/// 덮어쓰기 때문에 `--dart-define=SHOT_MODE=true` 로 띄워야 한다
/// (lib/version.dart 의 kShotMode). 안 그러면 이 맥북의 진짜 노트가 시연
/// 목록에 섞여 **스토어 화면에 개인 글이 실리고**, 시연 메모가 거꾸로
/// 아이클라우드로 올라간다. 2026-09-13 에 둘 다 실제로 일어났다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletext/main.dart';

import 'shot_demo.dart';

/// pumpAndSettle 대신 쓴다. 편집 칸이 열리면 깜빡이는 커서 같은 끝나지 않는
/// 움직임이 있어 pumpAndSettle 이 영영 안 돌아온다(2026-09-13, 둘째 장에서
/// 멈췄다). 정해진 만큼만 돌리고 넘어간다.
Future<void> settle(WidgetTester tester, [int ticks = 6]) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Directory _dir() {
  final home = Platform.environment['SKY_SHOT_DIR'] ??
      '${Platform.environment['HOME']}/shots';
  return Directory(home)..createSync(recursive: true);
}

/// 메모를 연다. 목록은 저장소를 다 읽은 뒤에야 차므로, 제목이 보일 때까지
/// 기다린다 — 2026-09-13 첫 실행에서 열한 언어 중 하나만 찍혔다. 나머지는
/// 목록이 아직 비어 있을 때 눌렀다(Bad state: No element).
Future<void> openNote(WidgetTester tester, String title) async {
  final until = DateTime.now().add(const Duration(seconds: 15));
  while (find.text(title).evaluate().isEmpty) {
    if (DateTime.now().isAfter(until)) {
      throw StateError('목록에 "$title" 이 안 보인다');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.tap(find.text(title).first);
  await settle(tester);
}

/// 찍기 전에 목록에 시연 메모만 있는지 본다. 2026-09-13 첫 실행에서
/// 소유자의 진짜 노트가 섞여 찍혔다. 하나라도 섞이면 찍지 않고 멈춘다 —
/// 스토어 그림에 개인 글이 실리는 것보다 33장을 못 찍는 편이 낫다.
void assertDemoOnly() {
  final ids = Store.instance.notes.map((n) => n.id).toList();
  final strangers = ids.where((id) => !id.startsWith('shot-')).toList();
  if (strangers.isNotEmpty) {
    throw StateError('시연 메모가 아닌 것이 목록에 있다(${strangers.length}개). '
        'SHOT_MODE 가 안 켜졌거나 동기화가 살아 있다. 찍지 않는다.');
  }
}

Future<void> shoot(WidgetTester tester, String name) async {
  assertDemoOnly();
  await settle(tester);
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await settle(tester);
  final d = _dir();
  final flat = name.replaceAll('/', '__');
  final done = File('${d.path}/done_$flat');
  if (done.existsSync()) done.deleteSync();
  File('${d.path}/want_$flat').writeAsStringSync(name);
  final until = DateTime.now().add(const Duration(seconds: 90));
  while (!done.existsSync()) {
    if (DateTime.now().isAfter(until)) {
      throw StateError('바깥이 안 찍었다: $name (tool/screenshots_mac.sh 가 돌고 있나)');
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 열한 언어를 **시험 하나**에서 돈다. 언어마다 시험을 따로 두면 시험이
  // 끝날 때 틀을 통째로 걷어 내는데, 나란히 선 두 칸(SplitShell)이 그 순간
  // "visitChildElements() called during build" 로 죽고 그 뒤 시험이 줄줄이
  // 실패했다(2026-09-13, 첫 언어 3장만 찍혔다). 아이폰 시험은 칸이 하나라
  // 그 길을 안 밟는다. 여기서는 틀을 한 번만 세우고, 언어를 바꿀 때는
  // 저장소만 다시 읽힌다 — 같은 자리에 새 언어의 시연 메모가 들어온다.
  testWidgets('mac screenshots', (tester) async {
    var first = true;
    for (final entry in shotLocales.entries) {
      final tag = entry.key;
      final demo = shotDemos[tag]!;
      SharedPreferences.setMockInitialValues({
        'simpletext.notes.v2': shotDemoNotes(demo),
        // 첫 실행 안내와 체험 안내는 이미 본 것으로 둔다 — 그 위에 떠 있으면
        // 목록을 누를 수 없다. 아이폰 시험은 광고 신호를 기다리는 사이에
        // 찍어서 우연히 비켜 갔고, 맥에는 광고가 없어 그 틈이 없다.
        'simpletext.settings.v1': jsonEncode({
          'syncBackend': 'none',
          'onboardShown': true,
          'trialNoticeShown': true,
        }),
      });
      if (!first) {
        // 틀은 그대로 두고 메모만 갈아 끼운다. 같은 id(shot-1..3)라 오른쪽
        // 칸이 열어 둔 메모도 새 언어의 것으로 바뀐다.
        await Store.instance.load();
      }
      // 같은 뿌리 위젯이라 상태는 남고 언어만 바뀐다.
      await tester.pumpWidget(SimpleTextApp(locale: entry.value));
      await settle(tester);
      first = false;

      // 맥은 넓어서 목록과 본문이 나란히 선다. 빈 오른쪽 칸을 첫 장으로
      // 내밀 이유가 없으니 메모를 연 채로 찍는다.
      await openNote(tester, demo.portfolio);
      await shoot(tester, '$tag/01_table');

      await openNote(tester, demo.timeline);
      await shoot(tester, '$tag/02_records');

      await openNote(tester, demo.summary);
      await shoot(tester, '$tag/03_summary');
    }
  });
}
