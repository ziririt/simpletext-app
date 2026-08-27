/// 심플텍스트 (SimpleText) — Flutter MVP
/// AI 답변을 붙여넣으면, 바로 쓸 수 있는 글이 됩니다.
///
/// 2026-08-12 i18n: UI 문자열은 전부 lib/l10n/으로 분리했다 (한/영/일/중간·번체/스/포/독/프).
/// 엔진(tidy_engine)·마법사(wizard)가 만드는 리포트 문구는 JS 엔진과의 대칭 규칙 때문에
/// 이번 범위에서 제외 — 로드맵의 후속 항목이다. 프리셋 이름은 Preset.id를 UI 층에서 매핑한다.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart'
    show CupertinoAlertDialog, CupertinoDialogAction, CupertinoIcons;
// material.dart는 defaultTargetPlatform을 내보내지 않는다(TargetPlatform은 내보낸다).
// 2026-08-14에 이걸 몰라서 analyze가 undefined_identifier로 잡았다.
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart' show openFiles, XFile;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;
import 'core/store_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_service.dart';
import 'clipboard_source.dart';
import 'core/ai_provider.dart';
import 'attach_store.dart';
import 'core/attach_meta.dart';
import 'core/auto_meta.dart';
import 'core/folders.dart';
import 'core/hangul.dart';
import 'core/history_align.dart';
import 'core/key_vault.dart';
import 'core/edit_ops.dart';
import 'core/list_continue.dart';
import 'core/listify.dart';
import 'core/lock.dart';
import 'core/mono_controller.dart';
import 'core/auto_tag_gate.dart';
import 'core/rich_spans.dart' show todoAt;
import 'core/sync_plan.dart'
    show
        EditorRefresh,
        editorRefresh,
        SyncBanner,
        syncBanner,
        showSyncingBanner;
import 'core/sync_log.dart';
import 'core/mru.dart';
import 'core/note_lock.dart';
import 'core/paper.dart';
import 'core/plain_text.dart';
import 'core/purchase_gate.dart';
import 'purchase_service.dart';
import 'core/body_font.dart';
import 'core/capture_sig.dart';
import 'core/source_detect.dart';
import 'core/tidy_engine.dart';
import 'core/trash.dart';
import 'core/usage_gate.dart';
import 'core/wizard.dart';
import 'export_service.dart';
import 'pdf_service.dart';
import 'widget_bridge.dart';
import 'import_service.dart';
import 'lock_service.dart';
import 'mac_menu.dart';
import 'share_intake.dart';
import 'sync/drive_auth.dart';
import 'sync/google_button.dart';
import 'web_font.dart';
import 'icloud_sync.dart';
import 'l10n/l10n.dart';
import 'version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 앱이 뒤로 갈 때 모아 둔 저장을 즉시 비운다.
  //
  // 사용자가 앱을 스와이프로 닫으면 그 뒤에는 우리 코드가 돌지 않는다.
  // 여기가 마지막 기회다. 화면 하나에 매달아 두지 않는 이유는 그 화면이
  // 사라질 때 같이 사라지기 때문이다.
  //
  // 돌려받은 값을 변수에 담지 않는다. 생성자가 스스로를 프레임워크의 관찰자
  // 목록에 넣으므로 그것만으로 살아 있고, 우리는 앱이 끝날 때까지 떼지
  // 않는다. 변수에 담아 두면 읽는 곳이 없어 analyze가 잡는다(실제로 잡혔다).
  AppLifecycleListener(
    onInactive: () => unawaited(Store.instance.flush()),
    onPause: () => unawaited(Store.instance.flush()),
    onDetach: () => unawaited(Store.instance.flush()),
  );
  // 날짜·시각을 사용자 언어로 찍기 위한 자료(intl). 이걸 안 깔면 영어(en_US)
  // 형식만 나온다 — 9개 언어로 파는 앱에서 이건 버그다. 자료는 앱에 함께
  // 들어 있어 네트워크를 타지 않는다.
  initializeDateFormatting();
  // 아래 물리키 줄을 검게(2026-08-18 소유자 지시).
  //
  // AppBar 가 있는 화면은 테마의 systemOverlayStyle 이 맡는다. 여기서 한 번
  // 더 부르는 것은 **AppBar 가 없는 순간**을 위한 것이다 — 앱이 막 떠서
  // 첫 화면이 그려지기 전, 그리고 전체 화면으로 뜨는 판들.
  //
  // 그 짧은 순간에 밝은 회색이 번쩍했다 사라지는 것은 고장으로 보인다.
  // 아직 테마가 없는 순간이라 기기 설정을 그대로 따른다. 첫 프레임이
  // 그려지면 AppBarTheme 이 같은 함수로 다시 정한다.
  SystemChrome.setSystemUIOverlayStyle(systemBars(
      WidgetsBinding.instance.platformDispatcher.platformBrightness));
  // 홈 화면 위젯 자리 잡기(아이폰·안드로이드에서만). 목록을 실제로 보내는
  // 것은 화면이 말을 알려 준 뒤다 — 위젯에 쓸 글자를 다트가 담아 보내므로.
  // 웹에서만 한글 글꼴을 심는다. 다른 판에서는 곧바로 돌아온다.
  // 앱이 뜨기 전에 기다리는 까닭: 뜬 뒤에 바뀌면 글자가 한 번 출렁인다.
  await loadWebFont();
  unawaited(WidgetBridge.init());
  // 광고 시동(모바일에서만 동작 — 맥·윈도우에서는 아무것도 안 한다).
  // 웹에서 붙여넣기 사건을 엿듣기 시작한다. 다른 판에서는 아무 일도
  // 안 한다(clipboard_source.dart).
  ClipboardSource.boot();
  AdsService.instance.boot();
  // 결제 시동. 상품 목록을 받아 오고, 스토어에 "권한이 아직 살아 있나"를
  // 묻는다. 웹·윈도우에서는 아무것도 안 한다.
  unawaited(PurchaseService.instance.boot());
  runApp(const SimpleTextApp());
}

// 2026-08-16 — 주조색을 브랜드(Cloudfall) 팔레트로 전환했다(소유자 지시:
// "컬러 주조색은 모두 skyblue 기조로", "밝고 맑고 경쾌하게, 다크는
// 눈부시지 않게").
// 브랜드 팔레트: 글로우 #9BEDFF · 하늘 #3FB2F0 · 바탕/텍스트 #1A5FCB
// · 딥 #08205A.
//
// 2026-08-16 저녁, 소유자 재신고 — "버튼 등 주조색을 스카이블루로 해 줘.
// 칙칙한 색 말고 맑고 깨끗한 색으로."
//
// 두 가지가 겹쳐 있었다.
//
// 하나. 라이트의 강조색 #1A5FCB는 색상각이 217도다. 하늘색이라기보다
// 남색 쪽이다. 205도 근처로 옮기면 눈에 띄게 맑아진다. 다만 그냥 밝히면
// 글자가 안 읽히므로, 흰 배경과 카드 배경 **양쪽에서** 4.5:1을 넘는
// 가장 맑은 자리를 계산으로 찾았다 — #0070BE(색상각 205도)다.
//   #0070BE on 흰 배경 5.2:1 · on 앱 배경 4.7:1
//
// 둘. **이게 진짜 원인이었다.** 채운 버튼과 떠 있는 버튼은 우리가 정한
// 색을 안 쓰고 있었다. 머티리얼3가 씨앗 색 하나로 자동으로 만들어 낸
// 색표(ColorScheme.fromSeed)를 쓰는데, 그 변환은 채도를 크게 깎는다.
// 씨앗이 아무리 맑은 하늘색이어도 버튼에 나오는 것은 가라앉은 남색이다.
// 그래서 주요 자리는 자동에 맡기지 않고 직접 못 박는다(_theme 참고).
//
// 명암비는 전부 계산으로 검증했다(값을 바꾸면 반드시 재계산). 이제
// test/theme_contrast_test.dart가 이걸 자동으로 지킨다 — 색을 손대면
// 테스트가 먼저 알려 준다.
/// 시스템 막대(위 상태 막대·아래 소프트키)를 어떻게 그릴지 — **한 곳에서.**
///
/// 2026-08-20 소유자 신고 — "안드로이드 소프트 물리키 찾기가 어려울 정도다."
///
/// 이 값이 두 군데에 적혀 있었다. main() 과 AppBarTheme. 아침에 AppBar 쪽만
/// 고쳤고 main() 쪽은 아이콘 밝기가 Brightness.light 로 박힌 채였다.
/// 같은 판단을 두 군데 적으면 반드시 한 군데를 빠뜨린다.
///
/// contrastEnforced 를 다시 켠다. 이게 켜져 있으면 안드로이드가 소프트키
/// 뒤에 옅은 판을 깔아 어떤 배경 위에서도 키가 보이게 해 준다. 2026-08-18에
/// 껐던 까닭은 '우리가 칠한 검정을 시스템이 덮어쓴다'였는데, 안드로이드 15
/// 부터는 그 검정 자체가 무시된다. **지키려던 것은 이미 없고 대가만 남아
/// 있었다.**
///
/// 막대 색은 투명이다. 검정으로 칠하는 길은 15에서 사라졌고, 14 이하에서는
/// 검정 막대 위에 라이트 테마의 검은 아이콘이 얹혀 같은 사고가 난다.
/// 투명 + 시스템 판이 어느 판에서나 성립하는 하나의 답이다.
/// 안드로이드 소프트키 자리를 우리 색으로 덮는다.
///
/// 2026-08-20 소유자 신고 **네 번째** — "소프트키랑 설정 및 노트
/// 리스트페이지 하단이 겹쳐서 여전히 자세히 봐야만 보인다."
///
/// 앞의 세 번은 전부 **시스템에게 부탁하는 방식**이었다. 아래 여백을
/// 늘리고(scrollPad), 아이콘 밝기를 맞추고, 시스템의 대비 판을 다시 켰다.
/// 그 부탁이 먹히는지는 안드로이드 판·제조사 껍데기·손짓 방식에 따라
/// 달라지고, 우리는 그중 어느 것도 기기 없이 확인할 수 없다.
///
/// 그래서 부탁을 그만둔다. 키가 놓이는 딱 그 높이만큼 **불투명한 띠**를
/// 깐다. 그러면 그 자리에 우리 글이 지나갈 수 없고, 키는 언제나 한 가지
/// 색 위에 놓인다. 판이 무엇을 하든 결과가 안 달라진다.
///
/// **여백과 띠는 다르다.** 여백은 '글이 거기까지 안 가도록' 부탁하는
/// 것이라 굴리는 동안에는 소용이 없다 — 소유자가 "스크롤하면서도
/// 마찬가지"라고 한 것이 그 지점이다. 띠는 굴리든 말든 늘 거기 있다.
///
/// 안드로이드에서만. 아이폰의 홈 인디케이터 자리는 글이 비쳐 지나가는
/// 편이 낫고(애플 메모도 그렇다) 신고도 없었다.
///
/// IgnorePointer 를 두는 까닭: 이 띠는 보이기만 할 뿐 아무것도 안 받는다.
/// 안 그러면 그 자리에서 시작한 굴리기가 막힌다.
Widget navBarPlate(BuildContext ctx, Widget child) {
  if (defaultTargetPlatform != TargetPlatform.android) return child;
  final h = MediaQuery.paddingOf(ctx).bottom;
  if (h <= 0) return child;
  final c = Theme.of(ctx).extension<AppC>();
  final color = c?.bg ?? Theme.of(ctx).scaffoldBackgroundColor;
  return Stack(
    children: [
      child,
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: h,
        child: IgnorePointer(child: ColoredBox(color: color)),
      ),
    ],
  );
}

SystemUiOverlayStyle systemBars(Brightness b) {
  final dark = b == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: true,
  );
}

const _accent = Color(0xFF0070BE);

/// 하늘색 위에 얹는 글자·아이콘 색(다크). 브랜드 '딥'이다.
///
/// 다크에서 채운 버튼은 **밝은 하늘 바탕에 진한 글자**여야 맑아 보인다.
/// 어두운 바탕에 밝은 글자로 만들면 아무리 색을 골라도 가라앉는다 —
/// 소유자가 신고한 그림이 정확히 그것이었다.
/// 명암비 #08205A on #4FC3F7 = 7.7:1
const _onAccentDark = Color(0xFF08205A);

/// 채운 단추의 바탕과 그 위의 글자. **라이트·다크가 같다.**
///
/// 2026-08-18 소유자 신고 — "맥앱과 안드로이드앱의 이 버튼 색은 하늘색에
/// 가까운데, 아이폰의 버튼 색은 무겁고 답답하고 칙칙한 딥블루 컬러다."
///
/// 기기 차이가 아니었다. 맥과 안드로이드는 다크였고 그 아이폰은 라이트였다.
///
/// 2026-08-16에 다크에서 이미 배운 것을 라이트에는 안 옮겼던 것이다 —
/// "채운 버튼은 밝은 하늘 바탕에 진한 글자여야 맑아 보인다." 라이트에서
/// 우리는 진한 하늘(#0070BE)에 흰 글자를 얹고 있었고, 그게 정확히 '가라앉은'
/// 쪽이다. 한쪽에서 배운 것을 다른 쪽에 안 옮기면 배운 게 아니다.
///
/// 그래서 **채우는 색과 글자로 쓰는 색을 가른다.**
///   _accent(#0070BE)  밝은 바탕 위의 글자·아이콘. 진해야 읽힌다.
///   kAccentFill       채운 단추의 바탕. 밝아야 산뜻하다.
/// 하나로 쓰려니 한쪽이 반드시 손해를 봤다. 두 자리의 요구가 반대다.
///
/// 글자 명암비는 오히려 좋아졌다 — 흰 글자 5.2:1 에서 진한 남색 7.7:1 로.
/// 대신 단추 테두리와 바탕의 대비는 낮다(#4FC3F7 대 #EFF6FB = 1.8:1).
/// 채운 단추는 그림자와 글자로 이미 또렷하고, 이건 소유자가 눈으로 고른
/// 값이다 — 읽히는 쪽을 지켰으면 나머지는 취향의 자리다.
const Color kAccentFill = Color(0xFF4FC3F7);
const Color kOnAccentFill = _onAccentDark;

/// 보조로 떠 있는 단추의 바탕. 주된 단추보다 한 계단 옅은 하늘.
///
/// 2026-08-18 소유자 신고 — "'글쓰기' 버튼 아이콘은 별로 눈에 안 띄어서
/// 못 찾을 정도임. ... 정리는 하늘색, 글쓰기는 더 연한 연하늘색으로."
///
/// 종이색(panel)으로 두었던 것이 화근이었다. 종이 위의 종이는 안 보인다.
/// 서열은 **색을 빼서**가 아니라 **같은 색을 옅게 해서** 매긴다 — 그래야
/// 둘 다 단추로 보이면서 어느 쪽이 주된 길인지도 보인다.
///
/// kAccentFill 과 마찬가지로 라이트·다크가 같은 값이다. 떠 있는 단추는
/// 배경 위가 아니라 그림자 위에 있어서, 모드를 따라갈 이유가 없다.
const Color kAccentSoft = Color(0xFFBFE6FA);
const Color kOnAccentSoft = Color(0xFF0B3B63);
// 밝은 하늘색은 큰 글자엔 흐려서 시드(파생 색 뿌리)로만 쓴다.
const _sky = Color(0xFF3FB2F0);

/// 애플 기기인가 — 아이클라우드가 있는 자리인지를 가르는 기준.
///
/// 2026-08-20 — **웹을 먼저 묻는다.** defaultTargetPlatform 은 웹에서
/// 브라우저를 돌리는 컴퓨터의 운영체제를 답한다. 맥에서 크롬을 열면
/// macOS 라고 하는데, 그 자리에 아이클라우드는 없다. 그래서 웹 설정의
/// iCloud 칸이 고를 수 있게 열려 있었다.
///
/// core/key_vault.dart 에서 같은 함정을 이미 밟고 주석까지 적어 뒀는데
/// 이 함수는 안 고쳤다. 같은 판단이 두 군데 있으면 한 군데를 빠뜨린다.
bool get isApplePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// 아이폰·아이패드에서 "밖에서 가져온 API 키로 기능을 여는 장치"를
/// 보여도 되는가.
///
/// 2026-08-21 앱스토어 거절(지침 3.1.1) — 키 입력칸·키 안내문·AI 단추가
/// 그 '장치'다. 애플 판에서는 인앱 구매로 살 수 없는 열쇠를 앱 안에서
/// 받으면 안 된다. 그래서 아이폰·아이패드에서는 키가 이미 있을 때만
/// (다른 기기에서 넣어 동기화로 들어온 경우) AI 자리를 보인다.
/// 맥 앱스토어에 낼 때도 같은 지침이 적용되므로 iOS만 따로 보지 않고
/// 애플 모바일 판 전체(iOS = 아이폰·아이패드)를 본다.
/// 2026-08-25 소유자 결정 — 1.2 승인 후 재도전: 아이폰에서도 키 입력칸을
/// 다시 보인다. BYO 키 앱이 널리 통과되는 회색지대이므로 한 번 부딪혀
/// 본다. **1.3이 3.1.1로 거절되면 절충안으로 물러선다**(입력칸 대신
/// '다른 기기나 웹에서 키를 넣으면 여기서도 쓸 수 있다' 안내문만).
/// 함수는 남겨 둔다 — 물러설 때 이 한 곳만 되돌리면 되게.
bool aiUiVisible() => true;

/// 이 기기가 자기 잠금을 부르는 이름 — 'apple' · 'android' · 'windows'.
///
/// 2026-08-19 소유자 신고(안드로이드 폰) — "안드로이드폰에서는 터치아이디
/// 페이스아이디 용어 나오면 좀 어색한."
///
/// 맞는 말이다. 잠금 자체는 local_auth 가 기기에 맞춰 알아서 띄우는데,
/// 우리가 화면에 적어 둔 **이름만** 애플이었다. 안드로이드에 Face ID 는
/// 없고 윈도우에 Touch ID 는 없다. 없는 물건 이름을 대면, 쓰는 사람은
/// 자기 기기가 모자란 줄 안다.
String get lockVendor => defaultTargetPlatform == TargetPlatform.android
    ? 'android'
    : defaultTargetPlatform == TargetPlatform.windows
        ? 'windows'
        : 'apple';

/// 데스크톱(맥·윈도우·리눅스)인가 — 글자 크기와 밀도를 가르는 기준.
bool get isDesktopPlatform =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// ---------------- 색 (라이트/다크) ----------------
/// 2026-08-12 — 다크 모드 미지원이 애플 기기에서 가장 크게 어색한 지점이었다.
/// 애플 메모장은 시스템 설정을 따라가는데 이 앱은 밤에도 흰 화면이었다.
/// 화면 코드에 색을 직접 박지 말고 반드시 여기(context.c)를 거칠 것 —
/// 한 곳이라도 직접 박으면 다크 모드에서 그 부분만 눈이 부신다.
/// 값은 iOS 시스템 색(systemGroupedBackground, separator, label 등)에 맞췄다.
@immutable
class AppC extends ThemeExtension<AppC> {
  final Color bg; // 화면 배경
  final Color panel; // 카드·행 배경
  final Color line; // 구분선
  final Color sub; // 보조 글자
  final Color accent; // 강조
  final Color field; // 검색창 배경
  final Color toolbar; // 키보드 액세서리 바
  final Color toolbarLine;
  final Color infoBg; // 요약 카드
  final Color warnBg; // 경고 카드
  final Color warnInk; // 경고 글자
  final Color codeBg; // 본문 미리보기 상자
  final Color codeLine;
  final Color pin; // 고정 표시
  final Color danger; // 삭제
  // 2026-08-14 소유자 요청: 태그 블럭은 '밝고 경쾌한 하늘색'.
  // 다만 밝기만 좇으면 라이트에서 글자가 안 읽히고 다크에서는 눈이 부시다.
  // 그래서 눈으로 고르지 않고 명암비를 계산해서 정했다(WCAG 기준 4.5:1).
  //   라이트 #0A66AA on #DFF1FF = 5.2:1   다크 #7ACBFF on #10344F = 7.3:1
  // 값을 바꿀 일이 생기면 반드시 명암비를 다시 계산하고 바꿀 것.
  // 2026-08-14 소유자 요청: 설정의 안내문구가 너무 작고 흐리다.
  // 크기는 본문과 같게 하고 색은 '아주 진한 회색', 다크에서는 반대로
  // '흰색에 가까운 회색'으로. sub(#8E8E93)보다 훨씬 진하다 — sub는
  // 날짜·부가정보용이고 이건 읽어야 하는 문장용이다. 둘을 섞지 말 것.
  //   라이트 #3A3A3C on #FFFFFF = 11.6:1   다크 #E5E5EA on #1C1C1E = 13.9:1
  final Color guideInk; // 설정 안내문구
  // 2026-08-14 소유자 신고 둘: (1) 글자를 선택했을 때 씌워지는 블럭 색이
  // 밝고 경쾌한 하늘색이 아니다 (2) 전체 선택 뒤 범위를 줄이려는데
  // 드래그할 손잡이가 안 보인다.
  //
  // 원인은 하나였다 — 이 앱에는 선택 관련 색 설정이 **아예 없었다**.
  // 그래서 머티리얼3 기본값이 그대로 나왔다. 기본 선택색은 seed에서
  // 만들어진 흐린 보라빛이고, 손잡이도 같은 계열이라 배경에 묻힌다.
  // 색을 안 정한 것이지 손잡이가 없는 게 아니었다.
  //
  // 값은 눈이 아니라 계산으로 정했다(반투명이라 배경과 섞인 뒤를 봐야 한다).
  //   라이트: #4FC3F7 40% + 흰 배경 = #B9E7FC → 검정 글자 15.9:1
  //   다크  : #4FC3F7 48% + 검정 배경 = #265E77 → 흰 글자 8.0:1
  //   손잡이 라이트 #0288D1(흰 배경 3.9:1) / 다크 #4FC3F7(검정 10.5:1)
  // 손잡이는 글자가 아니라 조작점이라 기준이 3:1이다 — 둘 다 넘는다.
  // 선택색을 불투명하게 만들면 글자가 묻힌다. 반드시 알파를 남길 것.
  final Color selBg; // 글자 선택 블럭
  final Color selHandle; // 선택 손잡이·커서
  // 2026-08-16 리퀴드 글래스 채택(소유자: "적극, 세련되게"). 유리는
  // 반투명 틴트 + 뒤 배경 블러다. 밝은 유리 위 검정 잉크, 어두운 유리 위
  // 흰 잉크 — 틴트가 흐릿해도 잉크 대비는 바탕색 기준으로 유지된다.
  final Color glass; // 유리 틴트
  final Color glassLine; // 유리 가장자리 실선
  final Color tagBg; // 태그 블럭 배경
  final Color tagInk; // 태그 글자
  final Color tagLine; // 태그 테두리

  const AppC({
    required this.bg,
    required this.panel,
    required this.line,
    required this.sub,
    required this.accent,
    required this.field,
    required this.toolbar,
    required this.toolbarLine,
    required this.infoBg,
    required this.warnBg,
    required this.warnInk,
    required this.codeBg,
    required this.codeLine,
    required this.pin,
    required this.danger,
    required this.guideInk,
    required this.selBg,
    required this.selHandle,
    required this.glass,
    required this.glassLine,
    required this.tagBg,
    required this.tagInk,
    required this.tagLine,
  });

  // 2026-08-16 소유자 요청 — "이런 스카이블루를 가능한 한 좀 더 쓰고 싶다.
  // 자연스럽게 컬러감을 많이 발휘할 수 있을까?"
  //
  // 색을 더 쓰는 방법에는 두 가지가 있다. 진한 색을 여기저기 칠하거나,
  // **회색을 전부 아주 옅은 하늘색으로 바꾸거나.** 뒤엣것을 골랐다.
  // 앞엣것은 서너 군데만 넘어가도 금세 시끄러워지고, 시끄러운 화면은
  // 글 쓰는 앱에서 가장 나쁜 것이다.
  //
  // 그래서 바탕·구분선·검색칸·도구막대의 중성 회색을 하늘 기운이 도는
  // 값으로 바꿨다. 하나하나는 회색인지 하늘색인지 헷갈릴 만큼 옅지만,
  // 화면을 통째로 보면 전체가 하늘빛을 띤다. 애플 메모의 노란 기운,
  // 베어의 따뜻한 회색이 같은 수법이다.
  static const light = AppC(
    bg: Color(0xFFEFF6FB), // 옛 #F2F2F7 — 같은 밝기에 하늘 기운만 얹었다
    panel: Colors.white,
    line: Color(0xFFE2EDF5),
    // 2026-08-20 소유자 지시 — "에디터 본문 제외하고 회색 폰트 컬러를 모두
    // 진회색 또는 블랙으로. 폰트 가독성 문제."
    //
    // 옛 #7C8A96은 흰 바탕에서 **3.2:1**이었다. 본문 크기 글자에 요구되는
    // 4.5:1에 못 미친다. '하늘 기운을 얹는다'는 뜻은 좋았는데, 색을 옅게
    // 만드는 방향으로 갔던 것이 문제였다 — **틴트는 밝기로 내는 게 아니라
    // 색조로 내는 것이다.** 밝기는 그대로 두고 하늘 쪽 색조만 남긴다.
    //
    // #4B5762 — 흰 바탕 7.4:1, 앱 바탕(#EFF6FB) 6.8:1. 파랑 기운은 그대로다.
    // 이 색은 부제·설명·시각·구역 제목에 쓴다. 본문(guideInk 11.4:1)과는
    // 여전히 층이 갈리므로 화면이 납작해지지 않는다.
    // 2026-08-20 두 번째 지시 — 7.4:1로 올린 것을 보고도 "너무 연하다.
    // 대비가 낮아서 저시력자 문제"라고 하셨다. 맞는 말이다. 대비 수치는
    // 이미 AAA(7:1)를 넘었는데도 연해 보이는 까닭은 **이 글자가 14~15px
    // 이기 때문**이다. WCAG의 4.5:1과 7:1은 '본문 크기'를 전제로 한 값이고,
    // 애플이 아이폰 본문으로 쓰는 크기는 17pt다. 작은 글자에 문턱만 겨우
    // 맞추는 것은 숫자를 만족시키는 것이지 읽히게 하는 것이 아니다.
    //
    // #37434E — 흰 바탕 10.1:1, 앱 바탕 9.3:1. 본문 잉크(11.4:1)와 거의
    // 같은 무게다. 층은 색이 아니라 크기와 굵기로 낸다 — 원래 그렇게
    // 하는 것이 맞고, 색으로 층을 내려다 읽히지 않게 된 것이 이 사고다.
    // 2026-08-20 세 번째 지시 — "블랙에 가깝게 해줘. 난 연회색은 싫다."
    //
    // 3.2:1 → 7.4:1 → 10.1:1 로 두 번 올렸는데도 연해 보이신다고 했다.
    // 숫자를 더 대지 않고 눈을 따른다. **읽는 사람이 연하다고 하면 연한
    // 것이다** — 대비 값은 그 말을 확인해 주는 도구지 반박하는 도구가 아니다.
    //
    // #26313A — 흰 바탕 13.3:1. 검정(21:1)에 가깝고, 하늘 쪽 색조만 남는다.
    sub: Color(0xFF26313A),
    accent: _accent,
    field: Color(0xFFDEEAF3),
    toolbar: Color(0xFFEEF5FA),
    toolbarLine: Color(0xFFDCE7F0),
    infoBg: Color(0xFFE3F3FE), // 하늘빛 정보 카드 (#0070BE 글자 4.6:1 — 테스트가 지킨다)
    warnBg: Color(0xFFFDF3E7),
    // 옛 #9A6A1F는 이 카드 위에서 4.1:1이었다 — 4.5에 못 미쳤다.
    // 이번에 테스트를 붙이면서 드러났다. #8A5A12는 5.2:1.
    warnInk: Color(0xFF8A5A12),
    codeBg: Color(0xFFF1F7FB),
    codeLine: Color(0xFFDDE9F2),
    pin: Color(0xFFF2B705),
    // 옛 #E53935는 흰 배경에서 4.2:1이었다(테스트가 잡았다). #D32F2F는 5.0:1.
    danger: Color(0xFFD32F2F),
    // 본문 잉크. 보조 글자를 13.3:1로 올리면서 같이 내렸다 — 안 그러면
    // 본문이 보조보다 옅어져 층이 뒤집힌다. 층은 크기와 굵기로 낸다.
    // #1A2229 on 흰 배경 16.1:1
    guideInk: Color(0xFF1A2229),
    // 2026-08-16 브랜드 하늘색으로 통일. 계산값:
    //   선택 블럭 #3FB2F0 40%+흰 배경 = #B2E0F9 → 검정 글자 14.9:1
    //   손잡이 #0070BE on 흰 배경 5.2:1 (조작점 기준 3:1)
    //   태그 글자 #0070BE on #E1F4FF 4.7:1
    selBg: Color(0x663FB2F0),
    selHandle: _accent,
    // 2026-08-18 소유자 지시 — "상단 고정바의 투명도를 살짝 줘서
    // 스크롤되면서 메모가 위로 올라갈 때 고정바 밑으로 살짝 비춰지게."
    // 0xCC(80%)에서 0xA6(65%)으로. 흐림을 24로 올려 그만큼을 메운다 —
    // 투명도만 올리면 밑의 글자가 그대로 읽혀서 머리 위의 글자와 겹친다.
    // 2026-08-18 소유자 지시 — "메인페이지 상단 고정바의 컬러는 흰색이네.
    // 바탕색의 연하늘색과 동일하게 해줘. 확 뚫린 느낌이 나서."
    //
    // 흰색 틴트는 유리 밑에 흰 종이를 한 장 더 깐 것과 같다. 밑의 바탕이
    // 하늘 쪽으로 기울어 있는데(#EFF6FB) 그 위에 중성 흰색을 얹으니,
    // 비쳐 보이는 것이 아니라 색이 하나 더 생겼다. 틴트를 바탕과 같은
    // 색으로 두면 유리는 '밝기만 더한 층'이 되고, 그때부터 밑의 것이
    // 색이 아니라 형태로 비친다.
    glass: Color(0x33EFF6FB),
    glassLine: Color(0x1F000000),
    tagBg: Color(0xFFE1F4FF),
    tagInk: _accent,
    tagLine: Color(0xFFB8E2FA),
  );

  // 다크도 같은 수법이다. 바탕은 검정 그대로 두고(OLED에서 진짜 꺼진다),
  // 그 위에 얹히는 회색 판들만 아주 옅은 남빛으로 옮겼다.
  static const dark = AppC(
    bg: Color(0xFF000000),
    panel: Color(0xFF15191D), // 옛 #1C1C1E — 같은 어둡기에 하늘 기운
    line: Color(0xFF2E3740),
    // 어두운 쪽은 '진하게'가 아니라 '밝게'가 같은 뜻이다. 옛 #919CA6은
    // 패널(#15191D) 위에서 6.3:1로 이미 읽혔지만, 밝은 쪽을 7.4:1로
    // 올린 김에 여기도 맞춘다 — 두 모드가 다른 세기로 말하면 안 된다.
    // #9FAAB4 on #15191D 7.5:1
    // 어두운 쪽도 같은 세기로. #C3CCD4 on #15191D 10.9:1
    // 어두운 쪽에서 '검정에 가깝게'는 '흰색에 가깝게'와 같은 뜻이다.
    // #DDE4EA on #15191D 14.1:1
    sub: Color(0xFFDDE4EA),
    // 다크 강조는 하늘색을 밝힌 톤 — 어두운 바탕에 쨍한 원색은 눈을
    // 찌른다(소유자: 밤에 눈부시지 않게). 다만 옛 #6FC4F4는 채도가
    // 모자라 흐릿했다. #4FC3F7은 같은 밝기에 채도만 올린 값이라 밤에
    // 눈부시지 않으면서 훨씬 맑다.  on #15191D 8.8:1, on 검정 10.5:1
    accent: Color(0xFF4FC3F7),
    field: Color(0xFF15191D),
    toolbar: Color(0xFF15191D),
    toolbarLine: Color(0xFF2E3740),
    infoBg: Color(0xFF0B2740), // 딥 네이비(#08205A 계열) 정보 카드
    warnBg: Color(0xFF2A2318),
    warnInk: Color(0xFFE0B96A),
    codeBg: Color(0xFF101418),
    codeLine: Color(0xFF242C34),
    pin: Color(0xFFF2B705),
    danger: Color(0xFFFF453A),
    guideInk: Color(0xFFE5E5EA),
    // 선택 블럭 #3FB2F0 48%+검정 = #1E5573 → 흰 글자 8.1:1
    // 손잡이는 기존 검증값 유지(#4FC3F7 on 검정 10.5:1)
    selBg: Color(0x7A3FB2F0),
    selHandle: Color(0xFF4FC3F7),
    glass: Color(0x3315191D),
    glassLine: Color(0x26FFFFFF),
    tagBg: Color(0xFF10344F),
    tagInk: Color(0xFF7ACBFF),
    tagLine: Color(0xFF1D5578),
  );

  @override
  AppC copyWith({
    Color? bg,
    Color? panel,
    Color? line,
    Color? sub,
    Color? accent,
    Color? field,
    Color? toolbar,
    Color? toolbarLine,
    Color? infoBg,
    Color? warnBg,
    Color? warnInk,
    Color? codeBg,
    Color? codeLine,
    Color? pin,
    Color? danger,
    Color? guideInk,
    Color? selBg,
    Color? selHandle,
    Color? glass,
    Color? glassLine,
    Color? tagBg,
    Color? tagInk,
    Color? tagLine,
  }) =>
      AppC(
        bg: bg ?? this.bg,
        panel: panel ?? this.panel,
        line: line ?? this.line,
        sub: sub ?? this.sub,
        accent: accent ?? this.accent,
        field: field ?? this.field,
        toolbar: toolbar ?? this.toolbar,
        toolbarLine: toolbarLine ?? this.toolbarLine,
        infoBg: infoBg ?? this.infoBg,
        warnBg: warnBg ?? this.warnBg,
        warnInk: warnInk ?? this.warnInk,
        codeBg: codeBg ?? this.codeBg,
        codeLine: codeLine ?? this.codeLine,
        pin: pin ?? this.pin,
        danger: danger ?? this.danger,
        guideInk: guideInk ?? this.guideInk,
        selBg: selBg ?? this.selBg,
        selHandle: selHandle ?? this.selHandle,
        glass: glass ?? this.glass,
        glassLine: glassLine ?? this.glassLine,
        tagBg: tagBg ?? this.tagBg,
        tagInk: tagInk ?? this.tagInk,
        tagLine: tagLine ?? this.tagLine,
      );

  @override
  AppC lerp(ThemeExtension<AppC>? other, double t) {
    if (other is! AppC) return this;
    return AppC(
      bg: Color.lerp(bg, other.bg, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      line: Color.lerp(line, other.line, t)!,
      sub: Color.lerp(sub, other.sub, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      field: Color.lerp(field, other.field, t)!,
      toolbar: Color.lerp(toolbar, other.toolbar, t)!,
      toolbarLine: Color.lerp(toolbarLine, other.toolbarLine, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      warnBg: Color.lerp(warnBg, other.warnBg, t)!,
      warnInk: Color.lerp(warnInk, other.warnInk, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      codeLine: Color.lerp(codeLine, other.codeLine, t)!,
      pin: Color.lerp(pin, other.pin, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      guideInk: Color.lerp(guideInk, other.guideInk, t)!,
      selBg: Color.lerp(selBg, other.selBg, t)!,
      selHandle: Color.lerp(selHandle, other.selHandle, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassLine: Color.lerp(glassLine, other.glassLine, t)!,
      tagBg: Color.lerp(tagBg, other.tagBg, t)!,
      tagInk: Color.lerp(tagInk, other.tagInk, t)!,
      tagLine: Color.lerp(tagLine, other.tagLine, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppC get c => Theme.of(this).extension<AppC>() ?? AppC.light;
}

/// 잠금 문지기.
///
/// 2026-08-16 로드맵 B단계 — 잠금(Face ID). 남이 내 폰을 집어 들었을 때 제일
/// 먼저 열어 보는 것이 메모다. 우리 앱은 특히 그렇다 — 여기 쌓이는 것은
/// 남에게 물어본 것들이다.
///
/// MaterialApp의 builder 자리에 둔다. 화면 하나에 매달면 다른 화면(설정,
/// 휴지통, 미리보기)이 그대로 열려 있는 채로 남는다. 여기라면 앱 안의 모든
/// 화면 위를 한 장이 덮는다.
///
/// 덮개가 둘이라는 점이 중요하다.
///
///  - **잠김**: 확인을 받아야 열린다. 되돌아왔을 때 규칙(core/lock.dart)이
///    잠그라고 하면 켜진다.
///  - **가림막**: 확인을 받을 필요는 없고 그냥 안 보이게만 한다. 앱이
///    잠깐 뒤로 갈 때(inactive) 켠다. iOS가 앱 전환기에 쓸 그림을 그때
///    찍기 때문이다. 이걸 안 하면 잠금을 켜 놓고도 전환기 썸네일에 메모
///    본문이 그대로 보인다 — 잠금이 있으나 마나가 된다.
///
/// 얼굴 확인 창이 뜨는 동안에도 앱은 inactive가 된다. 그래서 확인 중에는
/// 생명주기 신호를 통째로 무시한다(_asking). 안 그러면 확인 창이 뜨는
/// 순간 스스로 다시 잠그는 무한 반복에 빠진다.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final store = Store.instance;
  bool _locked = false;
  bool _shield = false;
  bool _asking = false;
  int _leftAt = 0;

  /// **정말** 나갔다 왔는가.
  ///
  /// 2026-08-17 — 이게 없어서 맥에서 확인 창이 무한 반복됐다. 맥은 확인
  /// 창이 뜨거나 다른 창을 클릭해도 inactive까지만 오고 paused는 안 온다.
  /// inactive를 '나갔다'로 치면 확인 창이 뜨는 순간 스스로 다시 잠근다.
  bool _away = false;

  /// 확인에 성공한 시각. 이 직후에 오는 신호는 무시한다 — 확인 창이
  /// 닫히면서 오는 resumed가 우리 손을 떠난 뒤에 도착할 수 있다.
  int _unlockedAt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱을 방금 켰다. leftAt이 0이라 규칙이 무조건 잠그라고 한다.
    if (store.settings.lockOn) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_asking) return;
    final on = store.settings.lockOn;
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (state) {
      case AppLifecycleState.inactive:
        // **나간 게 아니다.** 잠깐 흐려진 것이다. 확인 창이 뜨거나, 다른
        // 창을 클릭하거나, 알림 센터를 열어도 여기로 온다. 이걸 '나갔다'로
        // 치면 확인 창이 뜨는 순간 스스로 다시 잠그는 무한 반복이 된다
        // (2026-08-17 맥에서 실제로 그랬다). 가림막만 켜고 만다.
        if (on && !_shield) setState(() => _shield = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _away = true;
        _leftAt = now;
        // 물러나기 전에 부치고, 3초 시계를 끈다(2026-08-27).
        ICloudSync.instance.onPause();
        if (on && !_shield) setState(() => _shield = true);
      case AppLifecycleState.resumed:
        // 나간 적이 없으면 돌아온 것도 아니다.
        // 그리고 방금 확인을 통과했다면 그 창이 닫히며 오는 신호다.
        final justUnlocked = now - _unlockedAt < 1500;
        final lock = _away &&
            !justUnlocked &&
            shouldLock(
              enabled: on,
              leftAtMs: _leftAt,
              nowMs: now,
              graceSec: store.settings.lockGraceSec,
            );
        _away = false;
        setState(() {
          _shield = false;
          if (lock) _locked = true;
        });
        if (lock) _unlock();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    final ok = await LockService.instance.ask(L10n.of(context).lockReasonOpen);
    _asking = false;
    if (!mounted) return;
    if (!ok) return;
    // 나간 시각을 지금으로 적는다. 0으로 두면 규칙이 다음 신호에서 또
    // "앱을 새로 켠 것"으로 읽고 잠근다(2026-08-17 무한 반복의 한 축).
    final now = DateTime.now().millisecondsSinceEpoch;
    _leftAt = now;
    _unlockedAt = now;
    _away = false;
    setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    // 잠긴 화면 위에 가림막을 또 얹을 필요는 없다.
    final cover = _locked || _shield;
    return Stack(children: [
      widget.child,
      if (cover)
        Positioned.fill(
          // 2026-08-17 소유자 스크린샷 — 글자에 빨간 글씨와 노란 밑줄이
          // 그어져 있었다. 우리가 그은 게 아니다. 이 화면은 앱의 맨 바깥에
          // 얹히는 층이라 위에 Material이 없고, 그러면 프레임워크가 "이
          // 글자가 어디에 얹힌 건지 모르겠다"는 표시를 한다.
          //
          // 마법 가루 판에서 겪은 것과 똑같은 문제다. 그때 고치면서 여기도
          // 같은 처지라는 걸 알아챘어야 했다.
          child: Material(
            color: c.bg,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 46, color: c.accent),
                    const SizedBox(height: 14),
                    Text(l.appTitle,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(l.lockLocked,
                        style: TextStyle(fontSize: 14, color: c.sub)),
                    const SizedBox(height: 22),
                    // 가림막일 때는 버튼을 안 낸다. 누를 일이 없고,
                    // 앱 전환기 그림에 버튼이 찍히는 것도 이상하다.
                    if (_locked)
                      FilledButton.icon(
                        onPressed: _unlock,
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: Text(l.lockUnlock),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class SimpleTextApp extends StatelessWidget {
  /// 스토어 스크린샷 촬영용 강제 로케일. 평상시엔 null이라 기기 설정을 따른다.
  /// (integration_test/screenshots_test.dart에서 언어별로 지정한다 —
  ///  노하우 6절: 현지화 스크린샷이 없으면 기본 언어 것이 그대로 나간다)
  final Locale? locale;
  const SimpleTextApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    // 설정(화면 모드)이 바뀌면 앱 전체가 다시 그려져야 한다 — Store를 듣는다.
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final tm = Store.instance.settings.themeMode;
        return MaterialApp(
      locale: locale,
      onGenerateTitle: (ctx) => L10n.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const GlideScrollBehavior(),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      theme: buildTheme(Brightness.light, AppC.light),
      darkTheme: buildTheme(Brightness.dark, AppC.dark),
      // 2026-08-16 소유자 신고 — 맥 앱 글자가 애플 메모장보다 훨씬 크다.
      // 모바일 크기(본문 17 등)를 그대로 데스크톱에 내보내고 있었다.
      // 애플 메모장 맥판 본문은 13~14 상당 — 데스크톱 전체를 0.8배로 줄이면
      // 17이 13.6으로 정확히 그 자리에 떨어진다. 화면마다 값을 따로 두면
      // 반드시 한 군데를 빠뜨리므로 한 곳에서 전역으로 줄인다.
      builder: (ctx, child) {
        // 2026-08-18 — Cmd+C(맥·윈도)도 표시를 벗겨 복사한다.
        //
        // 여기 두는 까닭: 단축키는 **초점에서 위로** 찾아 올라가는데,
        // 플러터의 기본 글자 단축키는 WidgetsApp 에 있다. 그보다 아래
        // 아무 데나 두면 우리 것이 먼저 걸린다. 그리고 여기 한 곳에
        // 두면 화면이 늘어나도 빠뜨릴 자리가 없다.
        //
        // 제목·태그 칸에서 눌러도 해가 없다. 거기에는 벗길 표시가 없어서
        // 벗기기가 아무 일도 안 한다.
        Widget w = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                PlainCopyIntent(),
            SingleActivator(LogicalKeyboardKey.keyC, control: true):
                PlainCopyIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              PlainCopyIntent: PlainCopyAction(),
            },
            child: child!,
          ),
        );
        if (isDesktopPlatform) {
          final mq = MediaQuery.of(ctx);
          w = MediaQuery(
            data: mq.copyWith(textScaler: const TextScaler.linear(0.8)),
            child: w,
          );
        }
        w = navBarPlate(ctx, w);
        // 잠금은 제일 바깥이다. 앱 안의 어느 화면이 열려 있든 한 장이 덮는다.
        return LockGate(child: w);
      },
      // 2026-08-16 소유자 요청 — 설정에서 시스템/라이트/다크를 고른다.
      themeMode: tm == 'light'
          ? ThemeMode.light
          : tm == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const SplitShell(),
    );
      },
    );
  }

  /// 한글을 그릴 때 쓸 글꼴을 못 박는다.
  ///
  /// 2026-08-14 소유자 신고: 본문 글꼴이 아이폰 기본 글꼴과 달라 보인다.
  /// 코드에는 글꼴 지정이 없어 기기 기본값을 쓰고 있었는데, 문제는 "기기 기본값"이
  /// 한 가지가 아니라는 점이다. Flutter는 영문 글꼴(SF)만 지정하고 한글은 시스템의
  /// 대체 글꼴 목록에 맡기는데, 그 목록은 기기 언어 설정에 따라 일본어·중국어
  /// 글꼴이 먼저 걸릴 수 있다. 한글 글자 모양이 미묘하게 달라 보이는 전형적인 원인이다.
  ///
  /// 그래서 한글 대체 글꼴을 애플·안드로이드·윈도우의 '진짜' 시스템 글꼴로 못 박는다.
  /// 영문은 여전히 각 기기의 기본 글꼴(SF/Roboto/Segoe)이 그린다 — 순서상 먼저다.
  /// 없는 이름은 그냥 무시되므로 어느 기기에서도 안전하다.
  static const List<String> _hangulFallback = [
    'Apple SD Gothic Neo', // iOS·macOS
    'Noto Sans KR', // Android
    'Malgun Gothic', // Windows
  ];

  /// 화면 색표를 만든다.
  ///
  /// 2026-08-20 — 밖으로 연 이유는 시험 때문이다. 우리가 **안 적어 준**
  /// 자리에 머티리얼이 무슨 색을 꺼내 쓰는지는 완성된 색표를 봐야
  /// 알 수 있다. AppC 만 봐서는 안 보인다 — 연회색이 네 번이나 살아
  /// 남은 까닭이 그것이었다(test/scheme_ink_test.dart).
  static ThemeData buildTheme(Brightness b, AppC c) {
    // 채운 단추는 라이트든 다크든 **밝은 하늘 바탕에 진한 남색 글자**다
    // (kAccentFill / kOnAccentFill). 2026-08-18에 라이트도 그쪽으로 맞췄다.

    // **여기가 소유자 신고의 진짜 원인이었다.**
    //
    // fromSeed는 씨앗 색 하나에서 색표를 자동으로 만드는데, 그 변환이
    // 채도를 크게 깎는다. 씨앗이 맑은 하늘색(#3FB2F0)이어도 버튼에 나오는
    // primary/primaryContainer는 가라앉은 남색이 된다. 우리가 AppC에 맑은
    // 색을 정해 놨어도 버튼은 그걸 안 보고 있었다.
    //
    // 그래서 눈에 보이는 자리는 자동에 맡기지 않고 우리 값으로 덮는다.
    // fromSeed를 아예 안 쓰지는 않는다 — 여기서 안 덮은 자리(비활성 색,
    // 그림자 톤 등)를 채워 주는 값은 여전히 쓸모가 있다.
    final scheme = ColorScheme.fromSeed(seedColor: _sky, brightness: b).copyWith(
      primary: kAccentFill,
      onPrimary: kOnAccentFill,
      primaryContainer: c.tagBg,
      onPrimaryContainer: c.tagInk,
      secondary: kAccentFill,
      onSecondary: kOnAccentFill,
      secondaryContainer: c.tagBg,
      onSecondaryContainer: c.tagInk,
      // 떠 있는 판에 머티리얼이 섞어 넣는 물빛. 이걸 하늘색으로 두면
      // 카드가 미묘하게 하늘 기운을 띤다 — 색을 더 쓰되 시끄럽지 않게.
      surfaceTint: c.accent,
      error: c.danger,
      // 2026-08-20 소유자 지시(**네 번째**) — "제발 좀 연회색 폰트
      // 사용 금지. 진회색이나 연블랙, 또는 블랙 폰트로."
      //
      // 우리 색은 이미 다 내려놨는데도 화면에 연회색이 남아 있었다.
      // 세 번을 고치고도 또 나왔으면 고치는 자리가 틀린 것이다.
      // 짐작을 그만두고 머티리얼 기본 색표를 **실제로 재 봤다**:
      //   onSurfaceVariant  #41484D   흰 판에서  9.30:1
      //   outline           #71787E   흰 판에서  4.48:1
      //   (다크) onSurfaceVariant #C1C7CE, outline #8B9198
      //
      // 우리 보조 글자는 #26313A(13.3:1)다. 숫자로만 보면 9.3:1도
      // AAA를 넘지만, **같은 화면에서 나란히 놓이면 눈에 띄게 연하다.**
      // 대비는 배경과의 관계지, 옆 글자와의 관계가 아니다. 사람 눈은
      // 옆을 본다.
      //
      // 그리고 저 색이 나오는 자리는 전부 **우리가 색을 안 적어 준**
      // 자리다 — ListTile 부제, 드롭다운 글자, 입력칸 이름표, 메뉴,
      // 슬라이더 눈금. 화면을 하나하나 찾아다니며 색을 적는 것은 또
      // 같은 판단을 여러 군데에 적는 짓이고, 그러면 다음에 만드는
      // 화면에서 다시 연회색이 나온다.
      //
      // **연회색을 색표에서 지운다.** 꺼낼 자리가 없으면 안 나온다.
      onSurface: c.guideInk,
      onSurfaceVariant: c.sub,
      outline: c.sub,
      // 선은 글자가 아니다. 여기까지 잉크색으로 만들면 화면이 격자가
      // 된다. 우리가 쓰던 선 색을 그대로 준다.
      outlineVariant: c.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        // 2026-08-19 — 앱바의 아이콘과 제목을 잉크색으로 내렸다.
        //
        // 여기가 하늘색이었기 때문에 뒤로가기·태그·핀·메뉴가 전부 하늘색이
        // 됐다. 그러면 하늘색이 '눈여겨볼 것'이 아니라 '이 앱의 글자색'이
        // 된다. 아끼지 않은 색은 신호가 아니라 배경이다.
        //
        // 강조색은 이제 세 자리에만 쓴다.
        //   떠 있는 단추 — 지금 할 일
        //   지금 고른 것 — 어디에 있는지
        //   누를 수 있는 글자 — 여기서 뭔가 열린다
        foregroundColor: c.guideInk,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        // 위·아래 시스템 막대는 systemBars() 한 곳에서 정한다.
        systemOverlayStyle: systemBars(b),
      ),
      // 떠 있는 둥근 버튼. 기본값은 primaryContainer(연한 판)라서
      // 다크에서 '칙칙한 남색 판에 옅은 글자'가 됐다 — 신고된 그림이다.
      // 채운 하늘색으로 못 박는다.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kAccentFill,
        foregroundColor: kOnAccentFill,
        elevation: 3,
      ),
      // 돌아가는 표시, 스위치, 슬라이더가 전부 primary를 따라간다.
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      // 체크 표시도 하늘색으로. 기본값은 자동 색표라 또 가라앉는다.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? kAccentFill : null),
        checkColor: WidgetStateProperty.all(kOnAccentFill),
      ),
      // 글자만 있는 버튼과 테두리 버튼도 같은 하늘색으로.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
      // 선택 블럭·손잡이·커서 색. 이걸 안 주면 머티리얼 기본값이 나오고,
      // 손잡이가 배경에 묻혀 "드래그할 점이 안 보인다"는 신고가 된다.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.selHandle,
        selectionColor: c.selBg,
        selectionHandleColor: c.selHandle,
      ),
      extensions: [c],
    );
    return base.copyWith(
      // 웹에서는 우리가 심은 글꼴을 **주 글꼴로** 세운다.
      //
      // fontFamilyFallback 만으로는 안 된다. 그건 '주 글꼴에 없는 글자를
      // 어디서 찾을까'이고, 웹의 주 글꼴은 CanvasKit 의 로보토다. 로보토에
      // 라틴이 다 있으니 라틴은 끝까지 로보토로 그려지고, 한글만 넘어간다.
      // **섞이는 것 자체가 문제**였으므로 주 글꼴을 갈아야 한다.
      //
      // 폰·맥·안드로이드에서는 null 이다. 그 기기들의 시스템 글꼴이
      // 이미 그 자리에 맞는 답이고, 우리가 고른 글꼴로 덮으면 오히려
      // 그 기기에서 낯설어진다.
      textTheme: base.textTheme.apply(
        fontFamily: kIsWeb ? kWebFontFamily : null,
        fontFamilyFallback: _hangulFallback,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: kIsWeb ? kWebFontFamily : null,
        fontFamilyFallback: _hangulFallback,
      ),
    );
  }
}

/// ---------------- 데이터 모델 ----------------
class Note {
  String id;
  String title;
  String body;
  String originalBody;
  bool pinned;
  String source;
  List<String> tags;
  int createdAt;
  int updatedAt;
  List<String> history;

  /// 이 메모에 붙은 파일들. **메타데이터만** 여기 있다.
  ///
  /// 2026-08-19 소유자 확정(HANDOVER 8-2절). 알맹이는 붙인 그 기기 안에만
  /// 있고 클라우드로 안 나간다. 오가는 것은 이름·크기·붙인 시각·어느
  /// 기기였는가 넷뿐이다. 규칙과 까닭은 core/attach_meta.dart 머리말.
  List<Attach> attachments;

  /// 이 노트에만 적용되는 자동 바꾸기 규칙 (2026-08-24 소유자 지시 —
  /// "문서 편집 시에도 규칙 추가, 이 문서만/전체 옵션").
  /// 전체 규칙은 설정(customRules)에, 이 노트 전용은 여기에 산다.
  /// 노트 JSON에 실려 동기화를 따라가고, 옛 판 앱에서는 extra가 보존한다.
  List<CustomRule> rules;

  /// 이 메모 하나만 잠갔는가. 2026-08-19 소유자 확정.
  ///
  /// **잠금은 화면만 가린다.** 본문은 지금처럼 그대로 저장되고
  /// 동기화되고 백업에 실린다. 남이 내 기기를 집었을 때 못 보게
  /// 하는 자물쇠이지, 디스크 위의 글자를 암호로 바꾸는 일이 아니다.
  /// 무엇이 가려지고 무엇이 안 가려지는지는 core/note_lock.dart.
  bool locked;

  /// 각 이전 판을 남긴 시각. history와 같은 자리끼리 짝이다.
  ///
  /// 2026-08-16 — 예전 저장본에는 이 칸이 없다. 없으면 빈 목록이고, 그때는
  /// 화면에 시각 대신 '이전 판 n'이라고 쓴다. 짝이 안 맞아도 죽지 않는다.
  List<int> historyAt;

  /// 각 이전 판이 **왜** 남았는가. history와 끝에서부터 짝이다.
  ///
  /// 2026-08-19 소유자 지시 — "원복하기 직전의 히스토리를 잘 따라갈 수
  /// 있으면 좋겠다. 정교하게." 시각만으로는 못 따라간다. 오후 두 시에
  /// 남은 판이 셋이면 어느 것이 원본 복귀 직전인지 알 길이 없다.
  ///
  /// 옮겨 적을 말이 아니라 **부호**를 넣는다('tidy', 'ai', 'replace',
  /// 'revert', 'restore'). 화면에 쓸 말은 그때의 언어로 고른다 — 말을
  /// 그대로 저장하면 언어를 바꾼 뒤 옛 기록만 옛 언어로 남는다.
  List<String> historyWhy;

  String lastReport;

  /// 이 글을 붙여넣은 시각. 0이면 붙여넣은 게 아니라 직접 쓴 글이다.
  ///
  /// 2026-08-16 소유자 제안 — 수정일과 따로 둔다. AI 답변에서 진짜 중요한
  /// 시각은 '그 답을 받은 때'다. 그게 그 대화를 한 날이고, 그 모델 버전이
  /// 살아 있던 때다. 수정일은 내가 마지막으로 손댄 날일 뿐이다.
  int pastedAt;

  /// 출처를 우리가 추측한 것인가. true면 화면에 '(추정)'을 붙인다.
  /// 사용자가 직접 고르면 false가 된다.
  bool sourceAuto;

  /// 제목을 우리가 관리하고 있는가.
  ///
  /// 2026-08-16 소유자 제안 — 저장될 때마다 본문 기준으로 제목을 다시 짓되,
  /// **사용자가 한 번이라도 제목을 쓰면 그 뒤로는 손을 뗀다.** 이게 이
  /// 기능의 전부라고 해도 된다. 사용자가 정한 제목을 우리가 덮으면 그건
  /// 도움이 아니라 고장이다.
  bool titleAuto;

  /// 태그를 우리가 관리하고 있는가. 규칙은 제목과 같다.
  bool tagsAuto;

  /// 이 메모가 든 폴더. 빈 문자열이면 어디에도 안 들어 있다.
  ///
  /// 2026-08-17 — 태그와 따로 두는 이유: 태그는 "무엇에 관한 것인가"이고
  /// 폴더는 "어디에 두었나"다. 태그는 여럿, 폴더는 하나.
  String folder;

  /// 마지막으로 태그를 뽑았을 때의 본문 길이. -1이면 한 번도 안 뽑았다.
  ///
  /// 2026-08-18. 기기마다 따로 세면 아이폰에서 뽑고 맥에서 또 뽑는다.
  /// 노트에 붙여 두면 동기화를 타고 같이 다닌다.
  int taggedLen;

  /// 우리가 모르는 칸.
  ///
  /// 2026-08-18. 새 판 앱이 넣은 칸을 옛 판 앱이 지우지 않게, 읽을 때
  /// 주워 담아 두었다가 쓸 때 도로 뿌린다. **형식이 바뀌는 동안 두 판이
  /// 같은 폴더를 나눠 쓰는 며칠**을 무사히 건너기 위한 것이다.
  final Map<String, dynamic> extra;

  Note({
    required this.id,
    this.title = '',
    this.body = '',
    this.originalBody = '',
    this.pinned = false,
    this.source = '',
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
    List<String>? history,
    List<int>? historyAt,
    List<String>? historyWhy,
    this.lastReport = '',
    this.pastedAt = 0,
    this.sourceAuto = false,
    this.titleAuto = true,
    this.tagsAuto = true,
    this.folder = '',
    this.taggedLen = -1,
    this.locked = false,
    List<Attach>? attachments,
    List<CustomRule>? rules,
    Map<String, dynamic>? extra,
  })  : extra = extra ?? const <String, dynamic>{},
        tags = tags ?? [],
        history = history ?? [],
        historyAt = historyAt ?? [],
        historyWhy = historyWhy ?? [],
        attachments = attachments ?? [],
        rules = rules ?? [];

  factory Note.fresh({String body = ''}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Note(
      id: 'n$now${now % 997}',
      body: body,
      originalBody: body,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 노트 자료의 판. 형식이 바뀌면 이 숫자로 가른다.
  static const int schema = 1;

  /// 우리가 아는 칸. 이 밖의 것은 [extra] 로 들어간다.
  static const Set<String> knownKeys = {
    'v', 'id', 'title', 'body', 'originalBody', 'pinned', 'source', 'tags',
    'createdAt', 'updatedAt', 'history', 'historyAt', 'lastReport',
    'pastedAt', 'sourceAuto', 'titleAuto', 'tagsAuto', 'folder', 'taggedLen',
    'locked', 'historyWhy', 'attach', 'rules',
  };

  /// 기록에 남길 수 있는 최대 판 수.
  static const int historyMax = 30;

  /// 이전 판 하나를 기록에 넣는다.
  ///
  /// 이 일을 하는 자리가 앱 안에 **다섯**이었다 — 정리, AI 편집, 바꾸기,
  /// 원본 복귀, 그리고 버전 기록에서 되살리기. 다섯 곳이 전부 같은 여섯
  /// 줄을 베껴 쓰고 있었다. '왜 남았나'를 붙이려고 다섯 곳을 다 찾아
  /// 다니다가, 이게 바로 이 저장소가 오늘만 세 번 겪은 그 자리라는 걸
  /// 알았다 — 한쪽을 고치고 반대쪽을 안 보는 자리. 그래서 먼저 하나로
  /// 모았다.
  ///
  /// [why]는 옮겨 적을 말이 아니라 부호다. historyWhy 주석을 볼 것.
  void pushHistory(String before, {required String why}) {
    history.add(before);
    historyAt.add(DateTime.now().millisecondsSinceEpoch);
    historyWhy.add(why);
    while (history.length > historyMax) {
      history.removeAt(0);
      if (historyAt.isNotEmpty) historyAt.removeAt(0);
      if (historyWhy.isNotEmpty) historyWhy.removeAt(0);
    }
  }

  /// 방금 넣은 기록을 도로 뺀다 — 되돌리기를 되돌릴 때만 쓴다.
  ///
  /// 자국을 남기지 않는 것이 중요하다. 잘못 눌러 놓고 바로 취소한 일까지
  /// 목록에 쌓이면, 다음에 그 목록을 볼 때 무엇이 진짜였는지 흐려진다.
  bool popHistoryIf(String expected) {
    if (history.isEmpty || history.last != expected) return false;
    history.removeLast();
    if (historyAt.isNotEmpty) historyAt.removeLast();
    if (historyWhy.isNotEmpty) historyWhy.removeLast();
    return true;
  }

  /// [i]번째 이전 판이 남은 시각. 없으면 0.
  int historyTimeOf(int i) => sideValue(historyAt, history.length, i) ?? 0;

  /// [i]번째 이전 판이 남은 까닭의 부호. 없으면 빈 글자.
  String historyWhyOf(int i) => sideValue(historyWhy, history.length, i) ?? '';

  Map<String, dynamic> toJson() => {
        // 모르는 칸을 먼저 깔고 아는 칸으로 덮는다. 차례가 반대면 옛
        // 자료가 새 값을 이긴다.
        ...extra,
        'v': schema,
        'id': id,
        'title': title,
        'body': body,
        'originalBody': originalBody,
        'pinned': pinned,
        'source': source,
        'tags': tags,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'history': history,
        'historyAt': historyAt,
        'historyWhy': historyWhy,
        'lastReport': lastReport,
        'pastedAt': pastedAt,
        'sourceAuto': sourceAuto,
        'titleAuto': titleAuto,
        'tagsAuto': tagsAuto,
        'folder': folder,
        'taggedLen': taggedLen,
        'locked': locked,
        'attach': attachments.map((e) => e.toJson()).toList(),
        'rules': rules
            .map((r) => {'find': r.find, 'replace': r.replace, 'regex': r.regex})
            .toList(),
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        originalBody: (j['originalBody'] ?? '') as String,
        pinned: (j['pinned'] ?? false) as bool,
        source: (j['source'] ?? '') as String,
        historyAt: ((j['historyAt'] ?? const []) as List)
            .map((e) => e is int ? e : 0)
            .toList(),
        historyWhy: ((j['historyWhy'] ?? const []) as List)
            .map((e) => e is String ? e : '')
            .toList(),
        pastedAt: (j['pastedAt'] ?? 0) as int,
        sourceAuto: (j['sourceAuto'] ?? false) as bool,
        // 예전 저장본에는 이 칸이 없다. 없으면 그냥 true로 두면 안 된다 —
        // 사용자가 손으로 지은 제목이 다음 저장에서 통째로 덮인다. 그래서
        // 지금 제목이 본문에서 뽑은 것과 같을 때만 '우리 것'으로 본다.
        titleAuto: (j['titleAuto'] ??
            (((j['title'] ?? '') as String).trim().isEmpty ||
                ((j['title'] ?? '') as String) ==
                    autoTitle((j['body'] ?? '') as String))) as bool,
        tagsAuto: (j['tagsAuto'] ??
            (((j['tags'] ?? const []) as List).isEmpty)) as bool,
        folder: normalizeFolder((j['folder'] ?? '') as String),
        taggedLen: (j['taggedLen'] ?? -1) as int,
        locked: (j['locked'] ?? false) as bool,
        attachments: ((j['attach'] ?? const []) as List)
            .map(Attach.fromJson)
            .whereType<Attach>()
            .toList(),
        rules: ((j['rules'] ?? const []) as List)
            .map((e) => CustomRule(
                  find: (e['find'] ?? '') as String,
                  replace: (e['replace'] ?? '') as String,
                  regex: (e['regex'] ?? false) as bool,
                ))
            .toList(),
        extra: {
          for (final e in j.entries)
            if (!knownKeys.contains(e.key)) e.key: e.value,
        },
        tags: ((j['tags'] ?? []) as List).map((e) => e.toString()).toList(),
        createdAt: (j['createdAt'] ?? 0) as int,
        updatedAt: (j['updatedAt'] ?? 0) as int,
        history: ((j['history'] ?? []) as List).map((e) => e.toString()).toList(),
        lastReport: (j['lastReport'] ?? '') as String,
      );
}

/// 사용자 정리 규칙 설정 (웹 프로토타입과 동일 기본값)
class AppSettings {
  /// 저장된 설정의 판(版). 기본값을 바꿀 때 '한 번만' 갈아엎기 위해 쓴다.
  static const int settingsRev = 5;

  // 2026-08-14 소유자 신고 — **굵게**가 '굵게'로 바뀌어 나온다.
  // 따옴표가 필요 없는 자리에까지 따옴표가 붙어서 붙여넣기 뒤에 손이 간다.
  // 소유자 지시: "**를 모두 삭제처리해줘. 외따옴표 처리하지 말고.
  // 기본 정리 규칙에도 넣어줘."
  //
  // 엔진(TidyOptions)의 기본값은 원래부터 'remove'였다. 따옴표는 여기,
  // 앱 설정의 기본값이 'quoteSingle'이라서 붙던 것이다(effOpts가 엔진
  // 기본값을 덮어쓴다). 그래서 고칠 자리는 엔진이 아니라 여기다.
  String emphStyle = 'keep';
  String hrMode = 'keep';
  /// 2026-08-18 — 'strip'에서 'keep'으로.
  ///
  /// 소유자 신고: "너 # 이나 ##를 볼드체로 안 하는 거 아니니?" 화면은
  /// 제대로 그리고 있었다. **정리가 '#'을 먼저 깎아 버려서** 그릴 것이
  /// 남지 않았던 것이다. 강조(**)와 똑같은 자리다 — 08-18에 강조만 고치고
  /// 제목을 안 옮겼다. 오늘만 다섯 번째로 같은 실수다.
  ///
  /// 이제 화면에서 크게 그리고, 복사할 때 core/plain_text.dart 가 벗긴다.
  String headingMode = 'keep';

  /// 인용문('> ')을 정리가 어떻게 다루나. 'keep' 또는 'strip'.
  ///
  /// 2026-08-18. 제목·강조와 같은 가족인데 마지막까지 남아 있었다. 셋을
  /// 같은 규칙으로 두는 것이 이 앱의 개념이다 — **글에는 표시를 담아 두고,
  /// 화면에서 뜻으로 보여 주고, 복사할 때 벗긴다.**
  ///
  /// 새로 생긴 칸이라 갈아엎기가 필요 없다. 저장된 값이 없으면 이 기본값을
  /// 쓴다(쓰던 기기도 자동으로 '그대로 두기'가 된다).
  String quoteMode = 'keep';
  String headingSymbol = '■';
  String bulletChar = '-';
  bool smartDashList = true;
  bool smartFillerHeading = true;
  bool headingPad = true;
  int headingPadAbove = 2;
  int headingPadBelow = 1;
  int bulletIndent = 2;
  bool removeCitations = true;
  // 기본 켬 — 비례 글꼴에서는 공백 정렬이 원리적으로 맞을 수 없다.
  // 이 앱의 핵심이 표라서 기본값을 켜는 쪽이 맞다(CotEditor도 등폭이 기본).
  bool monoEditor = true;

  /// AI 키를 기기끼리 옮길지. 기본은 끔.
  ///
  /// 2026-08-20 소유자 지시로 길을 냈다. 기본값을 꺼 두는 까닭은
  /// 소유자를 못 믿어서가 아니라, 이 앱을 쓸 **다른 사람의 키까지**
  /// 우리가 대신 정해서 남의 서버에 올릴 수는 없기 때문이다.
  /// 켜는 데는 기기마다 한 번이면 된다.
  bool aiKeySync = false;
  int aiKeyStamp = 0;
  String aiKeySig = '';

  /// 정리 결과를 먼저 보여 줄지.
  ///
  /// 2026-08-17 소유자 지적 — "정리하기 하면 왜 미리보기를 거치나? 이유가
  /// 있나? 가능하면 안 거치면 좋겠다." 기본값을 껐다.
  ///
  /// 원래 켜 뒀던 까닭은 정리가 본문을 통째로 갈아 치우기 때문이었다.
  /// 그 사이에 안전망이 셋으로 늘었다 — 판마다 쌓이는 이전 판(30개),
  /// 버전 기록 화면, 붙여넣은 원본 보관. **안전망이 갖춰지면 확인 절차는
  /// 안전이 아니라 마찰이다.** 열에 아홉은 그냥 '네'를 누른다.
  ///
  /// 대신 정리 뒤 알림에 '되돌리기' 버튼을 붙였다. 먼저 하고, 무엇을
  /// 했는지 보여 주고, 한 번에 물릴 수 있게 한다.
  ///
  /// 미리보기를 좋아하는 사람을 위해 설정은 남긴다.
  bool previewBeforeApply = false;

  /// 붙여넣기 물음 안내를 이미 보여 줬는가.
  ///
  /// 2026-08-17 소유자 신고 — "매번 붙여넣기할 때마다 물어보니 귀찮다.
  /// 사람들이 몰라서 못하니까, 쉽게 알려줘."
  ///
  /// 한 번만 보여 준다. 두 번째부터는 잔소리다. 다시 보고 싶으면
  /// 설정에 늘 있다.
  bool pasteTipDone = false;

  /// 본문 글자 크기. 쓰던 메모앱과 눈으로 맞출 수 있게 설정에서 고른다
  /// (2026-08-14 — 고정값을 바꿔 가며 맞추려니 매번 설치 왕복이 생겼다).
  double bodyFontSize = MonoTextController.defaultBodyFontSize;
  double bodyLineHeight = MonoTextController.bodyHeight;

  /// 본문 글꼴. 값과 까닭은 core/body_font.dart 에 있다.
  /// 2026-08-27 밤 소유자 지시 — 크기는 있는데 글꼴이 없었다.
  String bodyFont = kBodyFontSystem;
  String aiKey = '';
  // 2026-08-16 소유자 승인 — 모델은 키에서 자동으로 정한다.
  // 키 앞글자로 회사를 판정하고, 그 회사의 모델 목록을 받아 와서 제일 싼
  // 등급의 최신을 고른다. 버전 번호를 코드에 박으면 그 모델이 폐지되는
  // 날 앱이 죽는다. 등급 이름(flash-lite·haiku·nano·fast)은 안 바뀐다.
  // 판정·선별 규칙과 예비 사다리는 core/ai_provider.dart (테스트로 고정).
  String aiProvider = ''; // google | anthropic | openai | xai | ''(미판정)
  String aiModel = 'gemini-2.5-flash-lite';
  List<String> aiModels = []; // '키 확인' 때 받아 온 실제 모델 목록

  /// 지금 프리미엄인가 — **읽기 전용으로 여겨라.** 아래 두 칸에서 계산해
  /// 채운다(core/purchase_gate.dart의 premiumNow). 화면·광고·한도 코드는
  /// 이 값만 보면 된다.
  bool premium = false;

  /// 결제로 얻은 것. 네 칸이며 규칙은 core/purchase_gate.dart에 있다.
  ///
  /// 스토어마다 울타리를 따로 두는 까닭: 기본 등급은 **산 스토어의 기기군**
  /// 에서만 열린다. 한 사람이 애플에서도 구글에서도 살 수 있으므로 등급
  /// 하나로는 표현이 안 된다.
  Entitlement ent = const Entitlement();

  /// 유료 체계가 생기기 전(1.0~1.3)부터 쓰던 사람인가.
  ///
  /// 2026-08-26 소유자 결정 — 하루 한도는 **새로 깐 사람부터**다. 그 사람들은
  /// '완전 무료'라는 말을 보고 앱을 깔았다. 나중에 문을 달아 잠그는 것은
  /// 약속을 깨는 일이고, 돌아오는 것은 결제가 아니라 별 하나짜리 리뷰다.
  ///
  /// 판정은 딱 한 번, 설정을 불러올 때 한다. 저장본에 이 열쇠가 없으면
  /// 옛 판에서 올라온 것이므로 유예다. 저장본 자체가 없으면 새 설치다.
  bool legacyFree = false;

  /// 무료 한도 계수기(정리·마법사). 규칙은 core/usage_gate.dart.
  String tidyDate = '';
  int tidyCount = 0;
  String wizDate = '';
  int wizCount = 0;

  // 2026-08-16 소유자 제안 — 설치 직후 2주는 제한 없이 쓰게 해서 손에
  // 익히자. 규칙은 core/usage_gate.dart에 있고 여기는 저장만 한다.
  //
  // trialDays는 '앱을 연 날'의 수다(달력 날짜가 아니다). trialLastDate가
  // 오늘과 다를 때만 하루 오른다 — 하루에 몇 번을 켜도 한 번만 센다.
  //
  // trialTidyTotal/trialWizTotal은 체험이 끝날 때 "그동안 이만큼 쓰셨다"고
  // 숫자로 보여 주기 위한 누적값이다. 하루치를 세는 tidyCount와 다르다.
  int trialDays = 0;
  String trialLastDate = '';
  int trialTidyTotal = 0;
  int trialWizTotal = 0;
  bool trialNoticeShown = false;

  // 2026-08-16 소유자 지적 — "정리 규칙과 자동 바꾸기 규칙은 모든 기기에서
  // 동기화되어야 한다. 매번 기기마다 설정하는 것은 아이클라우드 쓰는 앱으로서
  // 부적절하다." 맞는 말이라 규칙도 동기화 대상에 넣었다(AI 키는 제외).
  //
  // rulesStamp는 규칙을 마지막으로 바꾼 시각, rulesSig는 그때 내용의 지문이다.
  // 시각을 규칙 바꾸는 자리마다 찍게 하지 않은 이유: 그 자리가 설정 화면
  // 곳곳에 흩어져 있어서 하나는 반드시 빠뜨린다. 지문을 견주면 어디서 바뀌든
  // 알아챈다.
  int rulesStamp = 0;
  String rulesSig = '';

  /// 글을 고친 뒤 조용히 태그를 다시 뽑을 것인가 (2026-08-18).
  ///
  /// 켜져 있어도 AI 키가 없으면 아무 일도 안 한다. 끄는 스위치를 두는
  /// 까닭은 이것이 **남의 API 요금을 쓰는 일**이기 때문이다. 돈이 나가는
  /// 일에는 반드시 끄는 길이 있어야 한다.
  bool autoTagAi = true;

  /// 넓은 화면에서 왼쪽 목록 칸의 폭 (2026-08-18 소유자 지시).
  ///
  /// 동기화하지 않는다. 창 크기는 기기마다 다르고, 27인치에서 정한 폭이
  /// 13인치 노트북으로 건너오면 목록이 화면 절반을 먹는다. 이 값은 이
  /// 기기의 사정이지 사람의 취향이 아니다.
  /// 노트를 어디에 둘까 — 'none' · 'icloud' · 'gdrive'.
  ///
  /// 2026-08-19 소유자 지시로 들어왔다. 기기마다 따로 고른다(구름에 안
  /// 올린다). 아이폰은 아이클라우드로, 안드로이드는 구글 드라이브로
  /// 가는 것이 자연스러운데, 이 값을 구름에 올리면 한쪽이 다른 쪽의
  /// 선택을 덮어써 **자기 창고를 스스로 끄는** 일이 생긴다.
  ///
  /// 기본값을 'icloud'로 두는 데는 까닭이 있다. 이 값이 없던 저장본을
  /// 읽을 때 'none'이 되어 버리면, 잘 쓰던 사람의 동기화가 앱 한 번
  /// 올리는 것으로 조용히 꺼진다. 동기화에서 조용한 변화가 제일 나쁘다.
  String syncBackend = 'icloud';

  double listWidth = 320;

  /// 모양 값(글자 크기·줄 간격·종이·화면 모드·정렬)을 위한 같은 짝.
  ///
  /// 2026-08-18 — 규칙과 따로 센다. 규칙은 모든 기기가 한 파일을 나눠 쓰고,
  /// 모양은 기기마다 제 파일을 쓴다. 시각을 한 쌍으로 같이 쓰면 남의 기기가
  /// 규칙을 고친 것만으로 내 글자 크기가 '바뀐 것'으로 세어진다.
  int prefsStamp = 0;
  String prefsSig = '';

  // 2026-08-16 — 정렬과 필터. 조사해 보니 "정렬 옵션이 없다"는 것이 앱을
  // 미완성으로 느끼게 만드는 대표 원인 중 하나였다. 있으면 아무도 눈치
  // 못 채고, 없으면 리뷰에 남는 종류다.
  //
  // 2026-08-18 — 정렬 기준은 동기화한다. 예전에 "맥에서는 제목순, 폰에서는
  // 최근순으로 보고 싶을 수 있다"고 적어 뒀는데 그건 내 짐작이었다.
  // 소유자는 반대로 말했다 — 설정은 남아 있어야 한다.
  //
  // 필터는 여전히 안 올린다. 그건 설정이 아니라 '지금 보고 있는 화면'이라,
  // 다른 기기에서 걸어 둔 필터가 넘어오면 메모가 사라진 것처럼 보인다.
  String sortMode = 'updated'; // updated | created | title
  String filterSource = ''; // 빈 문자열 = 전체
  String filterTag = '';
  String filterFolder = '';

  /// 사용자가 만들어 둔 폴더 이름. 메모가 하나도 없는 폴더도 여기 남는다.
  ///
  /// 2026-08-17 — 이것만 보면 안 되고, 이것 없이도 안 된다. 메모가 쓰는
  /// 이름만 보면 방금 만든 빈 폴더가 눈앞에서 사라지고, 이 목록만 보면
  /// 다른 기기에서 만든 폴더가 안 보인다(설정은 늦게 고친 쪽이 통째로
  /// 이긴다). 화면에서는 둘을 합쳐 쓴다 — core/folders.dart의 folderNames.
  List<String> folders = [];

  /// 화면 모드: system(기기 따름) | light | dark. 2026-08-16 소유자 요청.
  String themeMode = 'system';

  /// 편집 화면 종이. 2026-08-16 소유자 요청 — "원고지 등 백그라운드 설정은?
  /// 굿노트처럼", 그리고 "몰스킨 스타일 프리셋은 필요하다."
  ///
  /// 값의 뜻과 색은 core/paper.dart에 있다. 여기는 고른 이름만 담는다.
  ///
  /// 2026-08-18 — 동기화한다. 예전에 "맥은 모눈, 폰은 몰스킨처럼 기기마다
  /// 다른 게 자연스럽다"고 적어 뒀는데, 사용자가 그렇게 말한 적은 없다.
  /// 종이를 고르는 데 든 수고를 기기마다 다시 하게 만들 이유가 없다.
  String paperMode = kPaperNone;

  /// 앱 잠금. 2026-08-16 로드맵 B단계.
  ///
  /// 기기마다 다르다 — 집에 두는 맥은 안 잠그고 들고 다니는 폰만 잠그는
  /// 것이 자연스럽다. 그래서 동기화하지 않는다. 애초에 동기화해서도 안
  /// 된다: 잠금을 못 쓰는 기기에 켜진 값이 넘어오면 그 기기는 영영 안 열린다.
  bool lockOn = false;

  /// 뒤로 갔다가 돌아왔을 때 다시 잠그기까지 봐주는 시간(초).
  /// 값과 규칙은 core/lock.dart.
  int lockGraceSec = kLockNow;

  /// 전면 광고를 본 날(YYYY-MM-DD). 이 날짜가 오늘이면 그날은 배너까지
  /// 광고가 전부 사라진다(소유자 확정 규칙). 판정은 core/ad_gate.dart.
  String adFreeDate = '';
  /// 마법사에서 등록해 둔 지시문. 최근에 쓴 것이 앞이다(core/mru.dart).
  List<String> favPrompts = [];
  List<CustomRule> customRules = [];

  Map<String, dynamic> toJson() => {
        'rev': settingsRev,
        'emphStyle': emphStyle,
        'hrMode': hrMode,
        'headingMode': headingMode,
        'quoteMode': quoteMode,
        'headingSymbol': headingSymbol,
        'bulletChar': bulletChar,
        'smartDashList': smartDashList,
        'smartFillerHeading': smartFillerHeading,
        'headingPad': headingPad,
        'headingPadAbove': headingPadAbove,
        'headingPadBelow': headingPadBelow,
        'bulletIndent': bulletIndent,
        'removeCitations': removeCitations,
        'monoEditor': monoEditor,
        'previewBeforeApply': previewBeforeApply,
        'pasteTipDone': pasteTipDone,
        'bodyFontSize': bodyFontSize,
        'bodyFont': bodyFont,
        'bodyLineHeight': bodyLineHeight,
        'prefsStamp': prefsStamp,
        'prefsSig': prefsSig,
        'aiKey': aiKey,
        'aiKeySync': aiKeySync,
        'aiKeyStamp': aiKeyStamp,
        'aiKeySig': aiKeySig,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'aiModels': aiModels,
        'adFreeDate': adFreeDate,
        'themeMode': themeMode,
        'paperMode': paperMode,
        'lockOn': lockOn,
        'lockGraceSec': lockGraceSec,
        'premium': premium,
        'ent': ent.toJson(),
        'legacyFree': legacyFree,
        'tidyDate': tidyDate,
        'tidyCount': tidyCount,
        'wizDate': wizDate,
        'wizCount': wizCount,
        'trialDays': trialDays,
        'trialLastDate': trialLastDate,
        'trialTidyTotal': trialTidyTotal,
        'trialWizTotal': trialWizTotal,
        'trialNoticeShown': trialNoticeShown,
        'rulesStamp': rulesStamp,
        'rulesSig': rulesSig,
        'syncBackend': syncBackend,
        'listWidth': listWidth,
        'autoTagAi': autoTagAi,
        'sortMode': sortMode,
        'filterSource': filterSource,
        'filterTag': filterTag,
        'filterFolder': filterFolder,
        'folders': folders,
        'favPrompts': favPrompts,
        'customRules': customRules
            .map((r) => {'find': r.find, 'replace': r.replace, 'regex': r.regex})
            .toList(),
      };

  static AppSettings fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    s.emphStyle = (j['emphStyle'] ?? s.emphStyle) as String;
    // 2026-08-14 — 기본값만 바꾸면 이미 쓰던 기기는 아무것도 안 바뀐다.
    // 저장된 'quoteSingle'을 그대로 읽어 오기 때문이다. 소유자 기기가
    // 그 상태였다 — 코드를 고쳐도 따옴표가 계속 붙는다.
    // 그래서 판(rev)이 없던 옛 설정에 한해 한 번만 갈아엎는다.
    // rev를 안 남기면, 사용자가 일부러 따옴표로 되돌려 놔도 다음 실행에서
    // 또 지워 버린다. 그건 고치는 게 아니라 설정을 뺏는 것이다.
    // 2026-08-17 — 여기 settingsRev를 쓰고 있었다. 판을 올리는 순간 이
    // 갈아엎기가 **다시 돈다**(따옴표로 되돌려 놓은 사람의 뜻을 두 번째로
    // 뺏는다). 갈아엎기는 언제나 '내가 도입된 판'을 적어야 한다.
    if (((j['rev'] ?? 0) as int) < 1 && s.emphStyle == 'quoteSingle') {
      s.emphStyle = 'remove';
    }
    // 2026-08-18 — 강조 표시를 지우던 것을 '유지'로 바꾼다.
    //
    // 08-14에 지우기로 한 진짜 까닭은 '**굵게**'가 "'굵게'"로 바뀌어
    // 나오는 것이 보기 싫어서였고, **그때는 굵게 보여 줄 방법이 없어서**
    // 지우는 것이 최선이었다. 이제는 화면에서 굵게 보여 주고 복사할 때
    // 벗긴다. 지울 이유가 사라졌다.
    //
    // 갈아엎기는 언제나 '내가 도입된 판'을 적는다(위 주석 참고).
    if (((j['rev'] ?? 0) as int) < 3 && s.emphStyle == 'remove') {
      s.emphStyle = 'keep';
    }
    s.hrMode = (j['hrMode'] ?? s.hrMode) as String;
    s.headingMode = (j['headingMode'] ?? s.headingMode) as String;
    // 2026-08-18 — 제목도 같은 길로 옮긴다. 까닭은 headingMode 선언에 적었다.
    //
    // 처음 쓴 자리가 틀렸다. 갈아엎기를 **저장본을 읽기 전에** 놓았다.
    // 그 자리에서 s.headingMode 는 아직 갓 만든 기본값 'keep'이라
    // 'strip'과 견주는 조건이 참이 될 수 없고, 바로 아래 줄이 저장된
    // 'strip'을 덮어썼다. 갈아엎기가 통째로 헛돌았다 — 소유자 기기에서
    // 제목의 '#'이 계속 지워지고 있었던 까닭이 이것이다.
    //
    // 강조(emphStyle)는 읽기가 맨 위에 있어서 멀쩡히 돌았다. 같은 함수
    // 안에서 하나는 맞고 하나는 틀렸다. 갈아엎기는 **읽은 뒤에** 둔다.
    //
    // 판을 5로 적는 것은 4가 이미 저장돼 나갔기 때문이다(갈아엎기는
    // 언제나 '내가 도입된 판'을 적는다).
    if (((j['rev'] ?? 0) as int) < 5 && s.headingMode == 'strip') {
      s.headingMode = 'keep';
    }
    s.quoteMode = (j['quoteMode'] ?? s.quoteMode) as String;
    s.headingSymbol = (j['headingSymbol'] ?? s.headingSymbol) as String;
    s.bulletChar = (j['bulletChar'] ?? s.bulletChar) as String;
    s.smartDashList = (j['smartDashList'] ?? s.smartDashList) as bool;
    s.smartFillerHeading = (j['smartFillerHeading'] ?? s.smartFillerHeading) as bool;
    s.headingPad = (j['headingPad'] ?? s.headingPad) as bool;
    s.headingPadAbove = (j['headingPadAbove'] ?? s.headingPadAbove) as int;
    s.headingPadBelow = (j['headingPadBelow'] ?? s.headingPadBelow) as int;
    s.bulletIndent = (j['bulletIndent'] ?? s.bulletIndent) as int;
    s.removeCitations = (j['removeCitations'] ?? s.removeCitations) as bool;
    s.monoEditor = (j['monoEditor'] ?? s.monoEditor) as bool;
    s.previewBeforeApply = (j['previewBeforeApply'] ?? s.previewBeforeApply) as bool;
    s.pasteTipDone = (j['pasteTipDone'] ?? s.pasteTipDone) as bool;
    // 2026-08-17 — 기본값을 껐다. 기본값만 바꾸면 이미 쓰던 기기는 저장된
    // true를 그대로 읽어 와서 아무것도 안 바뀐다(2026-08-14에 따옴표
    // 규칙에서 똑같은 일을 겪었다). 그래서 판(rev)이 2보다 낮은 저장본에
    // 한해 한 번만 끈다.
    //
    // 일부러 켜 놓은 사람의 뜻을 뺏는 셈이 될 수 있다. 그럴 수 있는 것은
    // 이 값이 지금까지 '켜짐'이 기본이라 대부분 손대지 않은 채였기
    // 때문이다. 그래도 뺏는 것은 뺏는 것이라, rev를 남겨서 **두 번은
    // 안 하게** 한다. 다시 켜면 그 뒤로는 지켜진다.
    if (((j['rev'] ?? 0) as int) < 2 && s.previewBeforeApply) {
      s.previewBeforeApply = false;
    }
    s.bodyFontSize = ((j['bodyFontSize'] ?? s.bodyFontSize) as num).toDouble();
    s.bodyFont = safeBodyFont(j['bodyFont'] as String?);
    s.bodyLineHeight =
        ((j['bodyLineHeight'] ?? s.bodyLineHeight) as num).toDouble();
    // 2026-08-24 — 기본값을 클로드 앱 실측(16 / 1.5)에 맞추면서, 옛 기본값
    // (17 / 1.6)을 손대지 않고 쓰던 기기는 새 기본값으로 옮긴다. 두 값이
    // 동시에 옛 기본값일 때만 건드리므로, 직접 고른 크기·줄간은 그대로다.
    if (s.bodyFontSize == 17 && s.bodyLineHeight == 1.6) {
      s.bodyFontSize = MonoTextController.defaultBodyFontSize;
      s.bodyLineHeight = MonoTextController.bodyHeight;
    }
    s.prefsStamp = (j['prefsStamp'] ?? s.prefsStamp) as int;
    s.prefsSig = (j['prefsSig'] ?? s.prefsSig) as String;
    s.aiKey = (j['aiKey'] ?? s.aiKey) as String;
    s.aiKeySync = (j['aiKeySync'] ?? s.aiKeySync) as bool;
    s.aiKeyStamp = (j['aiKeyStamp'] ?? s.aiKeyStamp) as int;
    s.aiKeySig = (j['aiKeySig'] ?? s.aiKeySig) as String;
    s.aiProvider = (j['aiProvider'] ?? s.aiProvider) as String;
    s.aiModel = (j['aiModel'] ?? s.aiModel) as String;
    s.aiModels = List<String>.from((j['aiModels'] ?? const []) as List);
    s.adFreeDate = (j['adFreeDate'] ?? s.adFreeDate) as String;
    s.themeMode = (j['themeMode'] ?? s.themeMode) as String;
    s.ent = Entitlement.fromJson(j['ent'] as Map<String, dynamic>?);
    // 이 열쇠가 없는 저장본 = 유료 체계 이전(1.0~1.3)에 만들어진 것이다.
    // 그 사람은 한도를 면제받는다. 새 설치는 저장본 자체가 없으므로 이
    // 갈래를 아예 지나지 않고 기본값 false로 남는다.
    s.legacyFree = (j['legacyFree'] ?? true) as bool;
    // premium은 저장값을 믿지 않고 매번 다시 센다 — 구독은 시간이 지나면
    // 끝나는데 저장된 참은 스스로 거짓이 되지 못한다. 그리고 **이 기기**
    // 에서의 답이므로 기기 갈래를 함께 본다.
    s.premium = premiumHere(
      e: s.ent,
      family: deviceFamily(),
      now: DateTime.now(),
    );
    s.tidyDate = (j['tidyDate'] ?? s.tidyDate) as String;
    s.tidyCount = (j['tidyCount'] ?? s.tidyCount) as int;
    s.wizDate = (j['wizDate'] ?? s.wizDate) as String;
    s.wizCount = (j['wizCount'] ?? s.wizCount) as int;
    // 예전 판에서 올라온 저장본에는 이 칸들이 없다 — 없으면 0/''이고,
    // 그러면 다음 실행 때 체험 1일째로 시작한다. 기존 사용자도 2주를 받는다.
    s.trialDays = (j['trialDays'] ?? s.trialDays) as int;
    s.trialLastDate = (j['trialLastDate'] ?? s.trialLastDate) as String;
    s.trialTidyTotal = (j['trialTidyTotal'] ?? s.trialTidyTotal) as int;
    s.trialWizTotal = (j['trialWizTotal'] ?? s.trialWizTotal) as int;
    s.trialNoticeShown = (j['trialNoticeShown'] ?? s.trialNoticeShown) as bool;
    s.rulesStamp = (j['rulesStamp'] ?? s.rulesStamp) as int;
    s.rulesSig = (j['rulesSig'] ?? s.rulesSig) as String;
    s.syncBackend = (j['syncBackend'] ?? s.syncBackend) as String;
    s.listWidth = ((j['listWidth'] ?? s.listWidth) as num).toDouble();
    s.autoTagAi = (j['autoTagAi'] ?? s.autoTagAi) as bool;
    s.sortMode = (j['sortMode'] ?? s.sortMode) as String;
    s.filterSource = (j['filterSource'] ?? s.filterSource) as String;
    s.filterTag = (j['filterTag'] ?? s.filterTag) as String;
    s.filterFolder = (j['filterFolder'] ?? s.filterFolder) as String;
    s.folders = ((j['folders'] ?? const []) as List)
        .map((e) => normalizeFolder(e.toString()))
        .where((e) => e.isNotEmpty)
        .toList();
    // 모르는 이름이 들어와도 paperById가 '기본'으로 떨어뜨린다.
    s.paperMode = (j['paperMode'] ?? s.paperMode) as String;
    s.lockOn = (j['lockOn'] ?? s.lockOn) as bool;
    s.lockGraceSec = normalizeLockDelay((j['lockGraceSec'] ?? s.lockGraceSec) as int);
    s.favPrompts =
        ((j['favPrompts'] ?? []) as List).map((e) => e.toString()).toList();
    s.customRules = ((j['customRules'] ?? []) as List)
        .map((e) => CustomRule(
              find: (e['find'] ?? '') as String,
              replace: (e['replace'] ?? '') as String,
              regex: (e['regex'] ?? false) as bool,
            ))
        .toList();
    return s;
  }
}

/// ---------------- 저장소 ----------------
class Store extends ChangeNotifier {
  static final Store instance = Store._();
  Store._();

  static const _notesKey = 'simpletext.notes.v2';
  static const _settingsKey = 'simpletext.settings.v1';

  List<Note> notes = [];
  List<Map<String, dynamic>> tombstones = [];

  /// 지운 메모를 30일 동안 담아 두는 곳. `{'note': {...}, 'deletedAt': int}`.
  ///
  /// 툼스톤과 다르다. 툼스톤은 "이 id는 지워졌다"는 기록일 뿐 내용이 없어서
  /// 되돌릴 수 없다. 기기끼리 맞추기 위한 내부 장치다. 휴지통은 사용자를
  /// 위한 것이고 내용을 통째로 들고 있는다.
  ///
  /// 동기화하지 않는다. 지운 사실은 툼스톤이 이미 옮겨 주고, 휴지통까지
  /// 옮기면 "폰에서 지운 걸 맥 휴지통에서 되살리는" 헷갈리는 상황이 생긴다.
  List<Map<String, dynamic>> trash = [];
  AppSettings settings = AppSettings();
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_notesKey);
      if (raw != null) {
        final p = jsonDecode(raw) as Map<String, dynamic>;
        notes = ((p['notes'] ?? []) as List)
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList();
        tombstones = ((p['tombstones'] ?? []) as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        // 기한이 지난 것은 여기서 조용히 버린다. 따로 청소 절차를 두면
        // 그 절차가 안 돌았을 때 휴지통이 영원히 자란다.
        trash = pruneTrash<Map<String, dynamic>>(
          ((p['trash'] ?? []) as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList(),
          deletedAtOf: (e) => (e['deletedAt'] ?? 0) as int,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        );
        // 옛 판이 쌓아 둔 시드들을 여기서 한 번 접는다. 아이클라우드가
        // 켜지기 전이어야 한다 — 접기 전에 올라가면 옛 번호가 그대로 다시
        // 퍼진다.
        if (foldOldSeeds(notes, tombstones)) {
          await persist();
        }
      } else {
        notes = [_seedNote()];
      }
    } catch (_) {
      notes = [_seedNote()];
    }
    try {
      final raw = prefs.getString(_settingsKey);
      if (raw != null) settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}

    // AI 키는 설정 JSON이 아니라 키체인에 있다(core/key_vault.dart).
    //
    // 옛 판이 JSON에 넣어 둔 키가 있으면 여기서 한 번 옮기고, 옛 자리의
    // 사본은 지운다. 두 군데 있으면 어느 쪽이 참인지 알 수 없게 되고,
    // 그런 물건은 반드시 어긋난 뒤에야 발견된다.
    // 창고 고르기는 **키체인이 참이다.** 자료 그릇이 새로 파여도 여기만은
    // 남는다. 그릇이 멀쩡하면 두 값이 같으므로 덮어써도 달라지는 것이 없다.
    final keptBackend = (await KeyVault.readBackend()).trim();
    if (keptBackend.isNotEmpty) settings.syncBackend = keptBackend;
    // 창고 이름을 이 기기에서 말이 되게 고친다. 한 곳에서만 한다 —
    // 화면마다 고치면 다음에 만드는 화면에서 또 빠진다.
    settings.syncBackend = fitBackend(settings.syncBackend);

    final fromPrefs = settings.aiKey.trim();
    final fromVault = (await KeyVault.read()).trim();
    if (fromVault.isNotEmpty) {
      settings.aiKey = fromVault;
    } else if (fromPrefs.isNotEmpty) {
      await KeyVault.write(fromPrefs, roam: settings.aiKeySync);
    }
    if (fromPrefs.isNotEmpty) {
      await persistSettingsLocalOnly(); // 옛 사본 지우기
    }
    // 체험 날짜 세기. 여기서 하는 이유는 이 지점이 '앱이 실제로 열렸다'를
    // 가장 확실히 아는 자리이기 때문이다. 하루에 몇 번 열든 bumpTrialDays가
    // 한 번만 올린다.
    final tnow = DateTime.now();
    final td = bumpTrialDays(
        now: tnow, lastDate: settings.trialLastDate, trialDays: settings.trialDays);
    if (td != settings.trialDays) {
      settings.trialDays = td;
      settings.trialLastDate = usageDateKey(tnow);
      await persistSettings();
    }

    loaded = true;
    notifyListeners();
  }

  /// 기기에만 쓴다. 아이클라우드에는 올리지 않는다.
  ///
  /// 동기화 코드가 '합친 결과'를 되쓸 때 이걸 쓴다. 그때 persist()를 부르면
  /// 다시 올리기가 예약되고, 그 올리기가 또 합치기를 부르는 고리가 생긴다.
  Future<void> persistLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _notesKey,
        jsonEncode({
          'v': 3,
          'notes': notes.map((n) => n.toJson()).toList(),
          'tombstones': tombstones,
          'trash': trash,
        }));
    notifyListeners();
  }

  Future<void> persistSettingsLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    // AI 키만 다른 자리에 쓴다. 나머지 설정과 달리 이건 비밀이고,
    // 앱을 지웠다 깔아도 남아야 한다.
    final m = settings.toJson()..remove('aiKey');
    await prefs.setString(_settingsKey, jsonEncode(m));
    // 어느 칸에 둘지는 여기 한 곳에서만 정한다. 설정을 저장하는 길이
    // 여럿이어도 이 줄을 지나므로 빠뜨릴 자리가 없다.
    await KeyVault.write(settings.aiKey, roam: settings.aiKeySync);
    // 창고 고르기도 같이 남긴다. 여기 한 자리에서 쓰므로, 설정을 저장하는
    // 길이 여럿이어도 빠뜨릴 자리가 없다.
    await KeyVault.writeBackend(settings.syncBackend);
    notifyListeners();
  }

  /// 화면만 다시 그리게 한다(동기화가 남의 기기 것을 받아 왔을 때).
  void bump() => notifyListeners();

  Timer? _writeTimer;
  bool _dirty = false;

  /// 메모가 바뀌었다고 알린다. **디스크 쓰기는 잠시 모았다가 한 번에 한다.**
  ///
  /// 2026-08-16 — 이걸 넣기 전에는 글자 하나 칠 때마다 persist()가 돌았다.
  /// persist()는 **모든 메모를 통째로 JSON으로 바꿔서** 저장소에 쓰고,
  /// 끝나면 notifyListeners()로 목록 화면까지 다시 그린다. 메모가 수백 개면
  /// 타자 한 번에 그 일이 전부 일어난다 — 손이 무겁게 느껴지는 진짜 원인이다.
  ///
  /// 메모리에는 즉시 반영되므로 화면은 늘 최신이고, 잃어버릴 것도 없다.
  /// 디스크에 늦게 닿을 뿐이다. 그 사이에 앱이 죽는 경우는 flush()로 막는다
  /// (편집 화면을 나갈 때, 앱이 뒤로 갈 때).
  void touch() {
    _dirty = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 700), () => unawaited(flush()));
  }

  /// 모아 둔 것을 지금 쓴다. 안 바뀌었으면 아무것도 안 한다.
  Future<void> flush() async {
    _writeTimer?.cancel();
    if (!_dirty) return;
    _dirty = false;
    await persist();
  }

  Future<void> persist() async {
    await persistLocalOnly();
    // 홈 화면 위젯도 같이 따라간다. 저장은 글자를 칠 때마다 일어나므로
    // 안에서 2초를 모았다가 한 번만 보낸다 — 바로 아래 scheduleUp 과 같다.
    WidgetBridge.schedule();
    // 저장은 글자를 칠 때마다 일어난다. scheduleUp이 3초 모았다가 한 번만
    // 올린다 — 여기서 곧바로 올리면 파일을 초당 몇 번씩 쓴다.
    ICloudSync.instance.scheduleUp();
  }

  Future<void> persistSettings() async {
    await persistSettingsLocalOnly();
    ICloudSync.instance.scheduleUp();
  }

  /// 지우기 — 곧바로 없애지 않고 휴지통으로 보낸다(2026-08-16).
  ///
  /// 조사에서 확인한 것: 메모가 사라지는 사건은 앱을 버리게 만든다. 다른
  /// 노트앱 포럼에는 "휴지통에도 없고 이력도 없이 사라졌다"는 글이 반복해서
  /// 올라오고, 그 스레드마다 사람들이 떠난다. 휴지통은 편의가 아니라 신뢰다.
  void deleteNote(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final i = notes.indexWhere((n) => n.id == id);
    if (i >= 0) {
      trash.insert(0, {'note': notes[i].toJson(), 'deletedAt': now});
      notes.removeAt(i);
    }
    tombstones.add({'id': id, 'deletedAt': now});
    persist();
  }

  /// 여러 개를 한 번에 지운다.
  ///
  /// deleteNote를 스무 번 부르지 않는 이유가 셋 있다.
  ///
  ///   1. 그 함수는 한 건마다 persist()를 부른다. 스무 개면 디스크에 스무
  ///      번 쓴다. 느린 것보다 나쁜 것은, 쓰는 도중에 앱이 죽으면 **절반만
  ///      지워진 상태**가 남는다는 것이다.
  ///   2. 한 건마다 목록이 다시 그려진다. 화면이 스무 번 덜컥거린다.
  ///   3. 되살릴 때 순서가 무너진다. 한 건씩 맨 앞에 꽂으면 마지막에 지운
  ///      것이 휴지통 맨 위로 온다 — 사용자가 고른 차례와 거꾸로다.
  ///
  /// 그래서 모아서 한 번에 옮기고, 한 번만 쓴다.
  void deleteNotes(Iterable<String> ids) {
    final set = ids.toSet();
    if (set.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 목록에 보이던 차례 그대로 휴지통 맨 위에 얹는다.
    final batch = notes
        .where((n) => set.contains(n.id))
        .map((n) => {'note': n.toJson(), 'deletedAt': now})
        .toList();
    if (batch.isEmpty) return;
    trash.insertAll(0, batch);
    notes.removeWhere((n) => set.contains(n.id));
    for (final id in set) {
      tombstones.add({'id': id, 'deletedAt': now});
    }
    persist();
  }

  /// 휴지통에서 되살린다.
  ///
  /// updatedAt을 '지금'으로 올리고 이 기기의 툼스톤을 지우는 게 핵심이다.
  /// 안 그러면 다음 동기화에서 "지운 시각이 고친 시각보다 늦다"로 읽혀서
  /// **되살린 메모가 곧바로 다시 사라진다.** 다른 기기의 툼스톤은 그대로
  /// 남아 있으므로 시각으로 이겨야 한다(규칙은 core/sync_merge.dart).
  void restoreNote(String id) {
    final i = trash.indexWhere((e) => (e['note'] as Map)['id'] == id);
    if (i < 0) return;
    final j = Map<String, dynamic>.from(trash[i]['note'] as Map);
    j['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    notes.insert(0, Note.fromJson(j));
    trash.removeAt(i);
    tombstones.removeWhere((t) => t['id'] == id);
    persist();
  }

  /// 휴지통에서 완전히 지운다. 툼스톤은 남긴다 — 그게 없으면 다른 기기가
  /// 아직 들고 있는 그 메모가 '새 메모'로 보여 되살아난다.
  void purgeFromTrash(String id) {
    trash.removeWhere((e) => (e['note'] as Map)['id'] == id);
    // 붙어 있던 파일도 같이 태운다. 휴지통을 비웠는데 디스크는 그대로면
    // 사용자는 지운 줄 알고, 용량만 조용히 남는다.
    //
    // 휴지통으로 **보낼 때는** 안 태운다 — 되살릴 수 있는 메모의 첨부를
    // 미리 태우면 되살려도 반쪽이다.
    unawaited(AttachStore.purge(id));
    persist();
  }

  void emptyTrash() {
    for (final e in trash) {
      final id = ((e['note'] as Map)['id'] ?? '') as String;
      if (id.isNotEmpty) unawaited(AttachStore.purge(id));
    }
    trash.clear();
    persist();
  }

  /// 프리셋 + 사용자 설정 병합 (웹의 effOpts와 동일 규칙)
  TidyOptions effOpts(Preset p, {List<CustomRule> noteRules = const []}) {
    final s = settings;
    final o = p.opts.copyWith();
    // 자동 바꾸기 규칙은 사람이 자기 글을 두고 적어 둔 것이라 어느 방식을
    // 골라도 따라간다. 합치는 순서와 까닭은 core/tidy_engine.dart의
    // mergeRules에 있다.
    if (o.stripEmphasis) {
      o.customRules = mergeRules(s.customRules, noteRules);
    }
    // 2026-08-18 — 여기서부터는 '기본 정리'에만 씌운다. 까닭은
    // core/tidy_engine.dart 의 Preset.userMarks 에 적었다.
    if (!p.userMarks) return o;
    if (o.stripEmphasis) o.emphStyle = s.emphStyle;
    if (o.removeHr) o.hrMode = s.hrMode;
    if (o.stripHeadings) {
      o.headingMode = s.headingMode;
      o.headingSymbol = s.headingSymbol;
    }
    // 2026-08-18 — 인용문도 사람이 고른다. 제목·강조와 같은 자리다.
    if (o.stripQuotes) o.stripQuotes = s.quoteMode == 'strip';
    if (o.bulletsToDot) o.bulletChar = s.bulletChar;
    if (o.smartDashList) o.smartDashList = s.smartDashList;
    if (o.smartFillerHeading) o.smartFillerHeading = s.smartFillerHeading;
    if (o.stripHeadings || o.smartFillerHeading) {
      o.headingPad = s.headingPad;
      o.headingPadAbove = s.headingPadAbove;
      o.headingPadBelow = s.headingPadBelow;
    }
    if (o.bulletsToDot) o.bulletIndent = s.bulletIndent;
    if (o.removeCitations) o.removeCitations = s.removeCitations;
    return o;
  }

  /// 시드 메모의 붙박이 번호.
  ///
  /// 2026-08-18 소유자 신고 — "기본 샘플 메모가 계속 빌드 회수만큼 생긴다."
  ///
  /// 예전에는 'seed-<지금시각>'이었다. 그러니 새로 깔 때마다 번호가 달라졌고,
  /// 합치는 규칙은 번호로 같은 메모인지 보므로 아이클라우드에 있던 예전
  /// 시드와 방금 만든 시드가 **다른 메모**가 되어 둘 다 남았다.
  ///
  /// 개발자만 겪는 일이 아니다. 아이폰에서 쓰던 사람이 아이패드에 깔면
  /// 똑같이 둘이 된다. 하필 첫인상 자리다.
  static const String kSeedId = 'seed-1';

  /// 시드 메모의 붙박이 시각.
  ///
  /// 번호만 고정하면 새 함정이 생긴다.
  ///
  ///   · 아이폰에서 시드를 고쳐 뒀는데 아이패드에 새로 깔면, 아이패드가
  ///     방금 만든 시드가 더 최신이라 **사람이 고친 내용을 덮는다.**
  ///   · 시드를 지웠는데 새로 깔면, 방금 만든 시드가 툼스톤보다 최신이라
  ///     **지운 것이 되살아난다.**
  ///
  /// 시각을 아주 옛날로 박으면 둘 다 막힌다. 합치는 규칙은 '늦게 고친 쪽이
  /// 이긴다'와 '지운 시각이 고친 시각보다 늦으면 삭제가 이긴다'이므로,
  /// 시드는 언제나 지는 쪽에 선다. 사람이 손댄 것과 지운 것이 항상 이긴다.
  ///
  /// 날짜 줄에 2026년 1월 1일이 보이는 것은 감수한다. 시드는 앱과 함께 온
  /// 것이지 사용자가 그날 쓴 글이 아니므로 오히려 정직한 표기다.
  static final int kSeedStamp = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

  /// 시드 메모 — 위젯 트리 밖이라 L10n.system()으로 시스템 로케일을 따른다
  static Note _seedNote() {
    final l = L10n.system();
    return Note(
      id: kSeedId,
      title: l.seedTitle,
      body: l.seedBody,
      originalBody: l.seedBody,
      pinned: true,
      tags: [l.seedTag],
      createdAt: kSeedStamp,
      updatedAt: kSeedStamp,
    );
  }

  /// 옛 판이 만들어 둔 'seed-<시각>'들을 seed-1 하나로 접는다.
  ///
  /// 이미 여러 개 쌓인 기기가 있다. 번호만 고쳐 놓고 두면 그 기기들은
  /// 영원히 그대로다 — 고쳤다고 말할 수 없다.
  ///
  /// 가장 최근에 손댄 것 하나를 골라 seed-1 로 옮기고, 나머지 번호는
  /// 툼스톤으로 남긴다. 툼스톤이라 다른 기기에서도 같이 사라진다.
  ///
  /// **손댄 것을 고르는 이유**: 사용자가 시드 위에 뭔가 적어 뒀을 수 있다.
  /// 그걸 버리고 깨끗한 쪽을 남기면 조용한 데이터 손실이 된다.
  static bool foldOldSeeds(
      List<Note> notes, List<Map<String, dynamic>> tombstones) {
    final olds = notes.where((n) => n.id.startsWith('seed-') && n.id != kSeedId)
        .toList();
    if (olds.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hasNew = notes.any((n) => n.id == kSeedId);

    // 이미 seed-1 이 있으면 옛것들은 전부 접는다. 없으면 그중 하나를
    // 승격시킨다 — 가장 최근에 손댄 것.
    olds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final keep = hasNew ? null : olds.first;
    final drop = hasNew ? olds : olds.skip(1).toList();

    if (keep != null) {
      final moved = keep.toJson();
      moved['id'] = kSeedId;
      final at = notes.indexOf(keep);
      notes[at] = Note.fromJson(moved);
    }
    for (final n in olds) {
      // 옛 번호는 전부 지운 것으로 남긴다. 승격시킨 것의 옛 번호도
      // 포함이다 — 다른 기기에 그 번호로 남아 있기 때문이다.
      tombstones.add({'id': n.id, 'deletedAt': now});
    }
    for (final n in drop) {
      notes.remove(n);
    }
    return true;
  }
}

/// 메모 하나를 잠그고 푼다. 목록과 편집 화면 둘 다 여기를 부른다.
///
/// 켤 때도 끌 때도 얼굴·지문을 묻는다. 끌 때 안 물으면, 잠긴 화면을 못 여는
/// 사람도 자물쇠는 떼어 낼 수 있다 — 그러면 자물쇠가 아니다.
Future<bool> toggleNoteLock(BuildContext context, Note n) async {
  final l = L10n.of(context);
  if (!n.locked) {
    if (!await LockService.instance.available()) {
      if (context.mounted) _toast(context, l.lockUnavailable(lockVendor));
      return false;
    }
    if (!await LockService.instance.ask(l.lockReasonOn)) return false;
    n.locked = true;
  } else {
    if (!await LockService.instance.ask(l.lockReasonOff)) return false;
    n.locked = false;
  }
  // 시각을 올린다. 안 올리면 다음 동기화에서 구름의 옛 판이 이겨서
  // 자물쇠가 조용히 풀린다(_setPinned에서 같은 자리를 겪었다).
  n.updatedAt = DateTime.now().millisecondsSinceEpoch;
  await Store.instance.persist();
  ICloudSync.instance.scheduleUp();
  if (context.mounted) {
    _toast(context, n.locked ? l.noteLockDone : l.noteUnlockDone);
  }
  return true;
}

/// 되돌릴 수 있는 일을 한 뒤의 알림 — 오른쪽에 '실행 취소'가 붙는다.
///
/// 보통 알림보다 오래 띄운다(6초). 단추가 달린 알림이 2초 만에 사라지면
/// 그건 단추가 아니라 놀리는 것이다.
void _toastUndo(BuildContext context, String msg, VoidCallback onUndo) {
  final l = L10n.of(context);
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  final bar = m.showSnackBar(SnackBar(
    content: Text(msg),
    duration: _kToastUndo,
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(label: l.undoTip, onPressed: onUndo),
  ));

  // 시계를 우리가 직접 건다.
  //
  // 2026-08-19 소유자 신고 — "원본 복귀하고 나면 뜨는 하단의 토스트가 5초
  // 정도 후에 자동으로 사라지게 해줘. 지금은 계속 남아있어서 거슬린다."
  //
  // duration 을 줬는데도 안 사라진다. 플러터는 **손잡이가 달린 알림**에는
  // 조건에 따라 시계를 아예 안 건다 — 읽고 누를 시간을 뺏지 않으려는
  // 배려다. 배려가 이번에도 원인이었다(아이패드 위젯과 같은 모양의 일).
  //
  // 이미 닫힌 알림을 또 닫으면 **다음 알림**을 닫아 버린다. 그래서 닫혔는지
  // 먼저 보고 건다.
  var gone = false;
  bar.closed.then((_) => gone = true);
  Timer(_kToastUndo, () {
    if (!gone) bar.close();
  });
}

/// 되돌릴 수 있는 알림이 화면에 머무는 시간.
///
/// 다섯. 여섯은 이미 읽고 판단이 끝난 사람에게 길고, 넷은 '실행 취소'라는
/// 글자를 읽고 손을 올리기에 짧다.
const Duration _kToastUndo = Duration(seconds: 5);

/// 고른 창고에 맞는 통로를 끼운다.
///
/// 2026-08-20. 이 일을 하는 자리를 **하나로 못 박는다.** 설정에서 고를 때와
/// 앱을 켤 때, 두 군데서 같은 판단을 하게 두면 한쪽만 고치는 날이 온다 —
/// 그날의 증상은 '설정에서는 구글이라는데 실제로는 아이클라우드로 오간다'이고,
/// 그건 아무도 못 알아챈다.
/// 설정에 '동기화' 칸을 보여 줄 것인가.
///
/// 2026-08-20 — 예전엔 ICloudSync.supported 하나로 가렸다. 창고가 둘이
/// 된 뒤로 그 말은 '애플 기기인가'라는 뜻밖에 안 된다. 안드로이드에서
/// 구글 드라이브를 붙여 놓고 **그걸 고를 화면을 가려 놨었다.**
///
/// 창고가 하나라도 있으면 보여 준다. 여기 한 곳만 본다.
/// 이 기기에서 말이 되는 창고로 고쳐 준다.
///
/// 2026-08-20 소유자 지적(웹) — "아이클라우드가 아니라 구글 로그인만
/// 가능한 거 아닌가?" 맞다. 그런데 웹 설정에는 "기기 설정에서 iCloud
/// Drive를 켜 주세요"가 떠 있었다. 브라우저에 그런 설정은 없다.
///
/// 처음 값이 'icloud' 인데 그 창고는 애플 기기에만 있다. 아무것도 안
/// 고른 사람은 **못 쓰는 창고를 고른 상태**로 앱을 켜고, 화면은 그
/// 창고를 켜라고 한다. 안드로이드도 소유자가 손으로 구글 드라이브를
/// 고르기 전까지 같은 그림이었다 — 아무도 그 화면을 안 봤을 뿐이다.
///
/// 구글로 대신 바꿔 주지 않는다. 못 고르는 것을 대신 골라 주는 것보다,
/// **안 고른 채로 두고 사람이 고르게** 하는 편이 정직하다. 화면은
/// '동기화 안 함'이라고 말하고, 고르는 자리는 한 번 누르면 나온다.
String fitBackend(String b) =>
    (b == 'icloud' && !ICloudSync.supported) ? 'none' : b;

bool get syncVisible => ICloudSync.supported || DriveAuth.supported;

/// 이 기기에서 앱 잠금을 걸 수 있는가.
///
/// 2026-08-20 소유자 지시 — "웹앱 앱 잠금 : 되는 척 하지말고 설정에서
/// 빼라."
///
/// local_auth 는 안드로이드·애플·윈도우만 받는다(pubspec.lock 에
/// local_auth_android · local_auth_darwin · local_auth_windows 만
/// 있다). 브라우저에는 얼굴이나 지문을 물을 자리가 아예 없다.
///
/// 그런데 설정 화면에는 스위치가 그대로 떠 있었다. 누르면 "이 기기
/// 에서는 쓸 수 없습니다" 알림만 떴다. **못 하는 일을 할 수 있는
/// 것처럼 보여 준 것**이다. 동기화 칸은 syncVisible 로 가려 놓고
/// 잠금 칸은 안 가렸다 — 같은 판단을 한 군데만 적은 자리다.
bool get lockVisible =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows);

/// 동기화 상태를 사람 말로 옮기는 자리 — **한 곳뿐이다.**
///
/// 2026-08-20 아침. 사장님이 아이폰에서 구글 드라이브로 바꾸고 로그인에
/// 성공했는데, 바로 아래 줄이 "iCloud 연동 중…"이라고 했다. 창고는 옮겨
/// 갔는데 말이 안 따라갔다.
///
/// 게다가 그 판단이 **두 군데**에 똑같이 적혀 있었다(설정 → 동기화,
/// 설정 첫 화면). 한쪽만 고쳤으면 두 화면이 서로 다른 말을 했을 것이다.
/// 오늘만 아홉 번째다. 그래서 문구를 고치는 김에 여기로 모은다.
class SyncSay {
  const SyncSay(this.title, this.sub);
  final String title;
  final String? sub;

  /// [everSynced] — 한 번이라도 맞춘 적이 있는가.
  ///
  /// 2026-08-20 소유자 지적 — "'마지막 맞춘 때' 시각은 1분 전인데 아직
  /// 맞추고 있다고 나오는 건 모순." 맞다. 그리고 둘 다 사실이었다 —
  /// 한 바퀴가 끝났고 30초 뒤 다음 바퀴가 시작됐을 뿐이다.
  /// **둘 다 사실인데 나란히 놓으니 거짓이 됐다.**
  factory SyncSay.of(L10n l, SyncState st,
      {bool paused = false, bool everSynced = false}) {
    final gdrive = Store.instance.settings.syncBackend == 'gdrive';
    final where = gdrive ? l.syncBackendGdrive : l.syncBackendIcloud;
    if (paused) return SyncSay(l.syncBackendNone, l.syncBackendNoneSub);
    switch (st) {
      case SyncState.ok:
        return SyncSay(l.syncOnTitle, l.syncStateOn(where));
      case SyncState.running:
        // 한 번이라도 맞춘 뒤라면 도는 것은 30초마다 일어나는 정상이지
        // 사건이 아니다. 큰 글씨는 '켜짐'으로 두고, 지금 도는 중이라는
        // 것은 아래 짧은 줄이 말한다.
        return everSynced
            ? SyncSay(l.syncOnTitle, l.syncStateOn(where))
            : SyncSay(l.syncStateSyncing(where), null);
      case SyncState.signedOut:
        return SyncSay(l.syncSignedOutTitle, l.syncStateSignedOut);
      case SyncState.off:
      case SyncState.unsupported:
        // 계정은 붙어 있는데 허락만 끊긴 판을 따로 말한다. 예전에는
        // 이 자리에서도 "다시 로그인"이라고 해서, 멀쩡한 계정을 두고
        // 로그인이 풀렸다고 읽히게 만들었다.
        if (gdrive &&
            DriveAuth.instance.signedIn &&
            DriveAuth.instance.authExpired) {
          return SyncSay(l.syncOffTitle, l.syncStateExpiredGdrive);
        }
        return SyncSay(l.syncOffTitle,
            gdrive ? l.syncStateOffGdrive : l.syncStateOff);
    }
  }
}

Future<void> applySyncBackend() async {
  ICloudSync.instance.useBackend(
    Store.instance.settings.syncBackend,
    driveToken: DriveAuth.supported ? DriveAuth.instance.token : null,
  );
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(msg),
        // 2026-08-18 소유자 요청 — "'깔끔하게 정리했습니다'가 1초 정도
        // 줄어들면 좋겠어." 2초는 이미 읽은 글을 한 번 더 보는 시간이다.
        duration: const Duration(milliseconds: 1100)));
}

/// 아이폰이 붙여넣을 때마다 묻는 것을 없애는 길 안내.
///
/// 2026-08-17 소유자 신고 — "매번 붙여넣기할 때마다 물어보니 귀찮다.
/// 이거 한번 같이 안내해주면 좋겠다. 사람들이 몰라서 못하니까, 쉽게
/// 알려줘."
///
/// iOS 16부터 앱이 클립보드를 읽을 때마다 시스템이 허락을 묻는다. 대부분의
/// 앱은 붙여넣기가 가끔 하는 일이라 견딜 만한데, **이 앱은 붙여넣기에서
/// 시작한다.** 그러니 그 물음이 이 앱에서는 유난히 자주 뜨고, 자주 뜨는
/// 만큼 자주 거슬린다.
///
/// 그런데 이 물음을 없애는 스위치는 아이폰 설정 안쪽에 있고, 그런 것이
/// 있다는 사실 자체를 아는 사람이 드물다. **몰라서 못 하는 것은 우리
/// 잘못이다** — 우리가 만든 앱 때문에 뜨는 물음이니 길도 우리가 안내한다.
///
/// 앱이 대신 눌러 줄 수는 없다. 애플이 그 값을 앱에서 읽지도 쓰지도 못하게
/// 막아 뒀고, 그건 옳다 — 클립보드에는 남의 비밀번호가 들어 있을 수 있다.
/// 우리가 할 수 있는 일은 설정 앱의 우리 자리까지 데려다 놓고, 무엇을
/// 누르면 되는지 세 줄로 적어 두는 것뿐이다.
Future<void> showPasteTip(BuildContext context) async {
  final l = L10n.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: sheet.c.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.content_paste_go, size: 22, color: sheet.c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.pasteTipTitle,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(l.pasteTipBody,
                  style: TextStyle(
                      fontSize: 15, height: 1.55, color: sheet.c.guideInk)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  final ok = await ICloudSync.instance.openSettings();
                  if (!sheet.mounted) return;
                  Navigator.pop(sheet);
                  // 열리지 않았으면 아무 일도 안 일어난 것처럼 보인다.
                  // 그 침묵이 제일 나쁘다(2026-08-16에 같은 자리를 겪었다).
                  if (!ok) _toast(context, L10n.of(context).syncOpenManual);
                },
                child: Text(l.syncOpenSettings,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: Text(l.pasteTipLater),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 처음 붙여넣은 그 자리에서 딱 한 번 안내한다.
///
/// 때를 여기로 잡은 이유: 방금 시스템 물음을 겪은 직후다. '아까 그것'이
/// 무엇이었는지 설명할 필요가 없다. 하루 뒤 설정에서 만나면 무슨 소린지
/// 모른다.
Future<void> maybeShowPasteTip(BuildContext context) async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return;
  final s = Store.instance.settings;
  if (s.pasteTipDone) return;
  s.pasteTipDone = true;
  await Store.instance.persistSettings();
  if (!context.mounted) return;
  await showPasteTip(context);
}

/// 예/아니오를 묻는 확인 창 — 앱 전체가 이 한 벌을 쓴다.
///
/// 2026-08-17 소유자 신고: "확인 팝업창들의 하단 우측 버튼이 좀 어색하다.
/// 불균형."
///
/// 원인은 크기가 아니라 **섞임**이었다. AlertDialog.adaptive는 애플 기기에서
/// 애플식 창을 만든다 — 가는 실선으로 반씩 나뉜 평평한 두 칸이다. 그런데
/// 우리는 그 칸에 머티리얼의 FilledButton(파란 알약)을 넣고 있었다. 애플
/// 틀에 안드로이드 단추를 끼운 셈이라 오른쪽 칸만 알약이 되어 도드라졌고,
/// 알약의 둥근 모서리가 창의 모서리와 어긋나 보였다.
///
/// 이제 틀에 맞는 단추를 쓴다.
///   애플  — CupertinoDialogAction. 두 칸이 정확히 반씩이라 저절로 균형이 맞는다.
///   그 밖 — TextButton / FilledButton (머티리얼의 제자리다)
///
/// 지우는 일에는 어느 판에서든 빨강을 쓴다. 되돌릴 수 있는 일과 없는 일이
/// 같은 색이면 손이 눈보다 먼저 움직인다.
/// 알림 창 하나 — 고를 것이 없고 읽고 닫기만 한다.
///
/// 2026-08-19 소유자 지시. confirmDialog 와 갈라 둔 까닭이 있다. 취소가
/// 있는 창은 "할까 말까"를 묻는 것이고, 이건 이미 끝난 일을 **알려 주는**
/// 것이다. 같은 창에 취소를 남겨 두면 누른 사람이 "취소하면 방금 일이
/// 없던 게 되나" 하고 한 번 더 헷갈린다.
Future<void> infoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final apple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  await showAdaptiveDialog<void>(
    context: context,
    builder: (ctx) {
      final ok = L10n.of(ctx).okAction;
      if (apple) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
              padding: const EdgeInsets.only(top: 8), child: Text(body)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text(ok),
            ),
          ],
        );
      }
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: Text(ok)),
        ],
      );
    },
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String okLabel,
  bool destructive = false,
}) async {
  final apple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  final ok = await showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) {
      final cancel = L10n.of(ctx).cancel;
      if (apple) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: body == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(body)),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: !destructive,
              isDestructiveAction: destructive,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(okLabel),
            ),
          ],
        );
      }
      return AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: ctx.c.danger, foregroundColor: Colors.white)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel),
          ),
        ],
      );
    },
  );
  return ok == true;
}

/// 한 일을 잠깐 보여 주고 사라지는 판.
///
/// 2026-08-17 소유자 요청 — "'적용 완료'라는 피드백을 마법의 가루를 뿌리며
/// 신비하게 잠깐 보여 주고 사라져 줘. 밑에 저렇게 나오지 말고."
///
/// 아래에서 올라오는 막대(SnackBar)는 시스템이 주는 그릇이라 어디에 쓰든
/// 똑같이 생겼다. 무엇을 알리든 '알림'으로 보인다. 정리는 이 앱에서 사람이
/// 가장 자주 누르는 버튼이고, 그 순간에만 일어나는 일이라면 그 순간만의
/// 모습이어야 한다.
///
/// 되돌리기 버튼은 여기에 안 붙인다. 사라지는 알림에 버튼을 달면 누르려는
/// 순간 사라지는 일이 생긴다 — 그건 없느니만 못하다. 되돌리기는 아래 도구
/// 막대에 늘 있고, 무엇이 바뀌었는지는 편집 화면 밑줄에 계속 남는다.
Future<void> showMagic(BuildContext context, String title, String detail) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final entry = OverlayEntry(
    builder: (_) => _MagicPuff(title: title, detail: detail, c: context.c),
  );
  overlay.insert(entry);
  await Future<void>.delayed(_MagicPuff.life);
  entry.remove();
}

class _MagicPuff extends StatefulWidget {
  final String title;
  final String detail;
  final AppC c;
  const _MagicPuff({required this.title, required this.detail, required this.c});

  /// 2026-08-17 소유자 지적 — "너무 속전속결이라 뭐라는지 모르겠다."
  ///
  /// 1.7초는 '알림'의 길이지 '연출'의 길이가 아니다. 3.4초로 늘리고
  /// 안에서 셋으로 나눴다.
  ///   0.00~0.22 (0.75초)  판이 천천히 떠오른다
  ///   0.22~0.80 (2.0초)   머문다. 읽을 시간이다
  ///   0.80~1.00 (0.7초)   스러진다
  /// 빛알은 앞 62%(2.1초)에 걸쳐 아주 천천히 퍼진다.
  static const Duration life = Duration(milliseconds: 3400);

  @override
  State<_MagicPuff> createState() => _MagicPuffState();
}

class _MagicPuffState extends State<_MagicPuff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: _MagicPuff.life)..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    // 움직임을 줄이도록 설정한 사람에게는 빛알을 안 뿌린다. 그 설정은
    // 취향이 아니라 어지럼증 대응인 경우가 많다.
    final calm = MediaQuery.of(context).disableAnimations;
    return Positioned.fill(
      // 떠 있는 동안에도 글을 만질 수 있어야 한다.
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _a,
          builder: (_, __) {
            final t = _a.value;

            final inT = (t / 0.22).clamp(0.0, 1.0);
            final outT = ((t - 0.80) / 0.20).clamp(0.0, 1.0);
            final opacity = (calm ? inT : Curves.easeOutSine.transform(inT)) *
                (1 - Curves.easeInSine.transform(outT));
            // 튀어 오르는 곡선(easeOutBack)을 뺐다. 통통 튀는 것은
            // 경쾌하지 우아하지 않다. 아주 조금만 커지며 조용히 자리를
            // 잡는 쪽이 '마법'에 가깝다.
            final scale = calm
                ? 1.0
                : 0.94 + 0.06 * Curves.easeOutCubic.transform(inT);
            // 들어올 때 살짝 내려앉고, 나갈 때 살짝 떠오른다. 숨 쉬듯이.
            final lift = 6.0 * (1 - Curves.easeOutCubic.transform(inT)) -
                14.0 * Curves.easeInSine.transform(outT);

            return Stack(
              alignment: Alignment.center,
              children: [
                if (!calm)
                  Positioned.fill(
                    child: CustomPaint(painter: _DustPainter(t: t, c: c)),
                  ),
                Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: _card(c),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 2026-08-17 소유자 지적 — "피드백 메시지에 밑줄은 치지 마라."
  ///
  /// 우리가 그은 밑줄이 아니다. 오버레이는 Material 위가 아니라 화면
  /// 꼭대기에 얹히는 층이라 조상에 Material이 없고, 그러면 프레임워크가
  /// 글자에 노란 이중 밑줄을 긋는다 — "이 글자가 어디에 얹힌 건지 모르겠다"는
  /// 표시다. 투명한 Material 한 겹을 두면 사라진다.
  Widget _card(AppC c) => Material(
        type: MaterialType.transparency,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
          boxShadow: [
            // 그림자를 강조색으로 준다. 검정 그림자는 무겁고, 이건
            // 빛이 나는 것처럼 보여야 한다.
            BoxShadow(
              color: c.accent.withValues(alpha: 0.28),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 30, color: c.accent),
            const SizedBox(height: 10),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.accent)),
            // 2026-08-17 소유자 지적 — "'마커 51개 제거'라는 말은 보여 줄
            // 필요도 없다." 맞다. 몇 개를 지웠는지는 우리가 열심히 했다는
            // 자랑이지 사용자가 알고 싶은 것이 아니다. 사용자가 알고 싶은
            // 것은 '됐나?' 하나뿐이다.
            //
            // 자세한 셈은 편집 화면 밑줄에 그대로 남아 있다. 궁금한 사람은
            // 거기서 본다.
            if (widget.detail.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(widget.detail,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, height: 1.35, color: c.sub)),
            ],
          ],
        ),
        ),
      );
}

/// 판에서 퍼져 나가는 빛알.
///
/// 무작위를 쓰지 않는다. 같은 자리에 같은 모양이 나와야 손에 익고,
/// 무작위는 매번 조금씩 다른 것을 '흔들린다'고 느끼게 한다.
///
/// 각도를 황금각(137.5도)씩 돌린다. 해바라기 씨앗이 그렇게 앉는데,
/// 어떤 개수를 뿌려도 뭉치지 않고 고르게 퍼지는 유일한 각이다.
class _DustPainter extends CustomPainter {
  final double t;
  final AppC c;
  const _DustPainter({required this.t, required this.c});

  static const int count = 18;
  static const double golden = 2.399963; // 라디안 137.5도

  @override
  void paint(Canvas canvas, Size size) {
    // 빛알은 앞의 62%(약 2.1초)에 걸쳐 아주 천천히 퍼진다. 판이 스러지기
    // 전에 먼저 사그라들어야 '가루가 뿌려지고 글이 정리됐다'는 차례로
    // 읽힌다.
    final u = (t / 0.62).clamp(0.0, 1.0);
    if (u >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final reach = size.shortestSide * 0.46;
    // easeOutCubic은 앞이 너무 빠르다 — '터진다'로 보인다.
    // easeOutSine은 처음부터 끝까지 고르게 흘러서 '떠간다'로 보인다.
    final ease = Curves.easeOutSine.transform(u);
    // 처음엔 없다가 차오르고, 끝에서 사그라든다. 확 켜졌다 꺼지는 것보다
    // 훨씬 조용하다.
    final fade = math.sin(math.pi * u);

    final p = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final ang = i * golden;
      // 안쪽과 바깥쪽을 섞어 뿌린다. 다 같은 거리면 고리처럼 보인다.
      final far = 0.55 + 0.45 * ((i % 5) / 4);
      final d = reach * far * ease;
      final at = center + Offset(math.cos(ang), math.sin(ang)) * d;
      final r = (2.2 + 1.8 * ((i % 3) / 2)) * (1 - 0.45 * u);

      p.color = (i.isEven ? c.accent : c.tagInk).withValues(alpha: fade);
      _star(canvas, at, r, p);
    }
  }

  /// 네 갈래 별. 동그라미보다 '반짝'으로 읽힌다.
  void _star(Canvas canvas, Offset at, double r, Paint p) {
    final path = Path();
    // 뾰족한 끝과 잘록한 허리. 허리를 0.3으로 두면 십자보다 별처럼 보인다.
    const waist = 0.30;
    path.moveTo(at.dx, at.dy - r);
    path.quadraticBezierTo(at.dx + r * waist, at.dy - r * waist, at.dx + r, at.dy);
    path.quadraticBezierTo(at.dx + r * waist, at.dy + r * waist, at.dx, at.dy + r);
    path.quadraticBezierTo(at.dx - r * waist, at.dy + r * waist, at.dx - r, at.dy);
    path.quadraticBezierTo(at.dx - r * waist, at.dy - r * waist, at.dx, at.dy - r);
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.t != t || old.c != c;
}

/// 스크롤 화면의 아래 여백 — 시스템 막대(안드로이드 물리키 자리)만큼 더.
///
/// 2026-08-20 소유자 신고 — 설정 화면 맨 아래 글자가 물리키와 겹쳐 안 읽힌다.
///
/// 안드로이드 15부터는 앱이 화면 가장자리까지 그리는 것이 강제라, 우리가
/// 정한 막대 색이 무시된다. **색으로 가리려던 길이 막혔으면 남은 길은
/// 하나뿐이다 — 그 자리에 글자를 안 두는 것.**
///
/// SafeArea 안이면 이미 깎여 있어 0이 더해진다. 밖이면 실제 값이 더해진다.
/// 어느 쪽이든 맞으므로 부르는 자리마다 따지지 않아도 된다.
EdgeInsets scrollPad(BuildContext c, {double top = 0, double bottom = 40}) =>
    EdgeInsets.only(top: top, bottom: bottom + sysBottom(c));

/// 시스템 막대(안드로이드 물리키 자리)의 높이.
///
/// 2026-08-20 소유자 추가 신고 — "편집 화면은 물리키와 확실히 구분되어
/// 있는데, 목록과 설정은 그 영역 구분이 없어서 겹친다."
///
/// 편집 화면은 SafeArea 안에 있어서 프레임워크가 알아서 깎아 준다. 목록은
/// 유리 머리 밑으로 흘러 들어가야 해서 SafeArea 를 안 쓰고, 그래서 이 값을
/// 손으로 챙겨야 한다. **한 화면이 예외라는 것은 그 화면만 다르게 짰다는
/// 뜻이고, 다르게 짠 화면은 반드시 한 번 잊힌다.**
double sysBottom(BuildContext c) => MediaQuery.paddingOf(c).bottom;

/// ---------------- 홈 화면 ----------------
/// 목록 행의 "카드 안쪽 왼쪽 여백".
///
/// 2026-08-14 — 애플 메모와 나란히 놓고 눈으로 맞추지 않고, 아이폰 16(3x)
/// 스크린샷을 픽셀로 재서 정한 값이다(노하우 3절: 추정하지 말고 숫자를 쥔다).
///   애플 메모: 카드 좌여백 48px(16pt), 글자 좌측 133px(44.3pt) → 안쪽 여백 28pt
///   구분선도 글자 왼쪽 끝(44pt)에서 시작한다. 그래서 같은 값을 쓴다.
/// 한쪽만 바꾸면 글자와 줄이 어긋난다.
const double kListRowInset = 28;

/// 홈의 떠 있는 유리 머리(검색 줄) 높이. 목록 첫 칸을 이만큼 비워서
/// 목록이 유리 밑으로 흘러 들어가게 한다.
const double kHomeHeaderH = 60;

/// 리퀴드 글래스 재질 — 2026-08-16 소유자 채택("적극, 세련되게").
///
/// 플러터는 화면을 직접 그리므로 iOS 27이 유리를 공짜로 입혀 주지 않는다.
/// 대신 이 위젯 하나로 네 판(아이폰·안드로이드·맥·윈도우) 모두에 같은
/// 유리를 입힌다. 애플 디자인 원칙에서 가져온 규칙:
///   - 반투명 틴트 + 뒤 배경 블러(18). 콘텐츠가 밑으로 비쳐 흐른다
///   - 경계는 1px 실선 대신 아주 옅은 헤어라인
///   - 밝은 유리 위에 밝은 유리를 겹치지 말 것 (가독성이 무너진다)
/// Cmd+C / Ctrl+C — 표시를 벗겨 복사한다.
class PlainCopyIntent extends Intent {
  const PlainCopyIntent();
}

class PlainCopyAction extends Action<PlainCopyIntent> {
  @override
  Object? invoke(PlainCopyIntent intent) {
    // 지금 글자를 치고 있는 칸을 찾는다.
    final st = FocusManager.instance.primaryFocus?.context
        ?.findAncestorStateOfType<EditableTextState>();
    if (st == null) return null;
    final v = st.textEditingValue;
    if (!v.selection.isValid || v.selection.isCollapsed) return null;
    Clipboard.setData(
        ClipboardData(text: toPlain(v.selection.textInside(v.text))));
    // 손끝에 한 번. 아무 일도 안 일어난 것처럼 보이면 두 번 누른다.
    HapticFeedback.selectionClick();
    return null;
  }
}


/// 무엇이 오가고 무엇이 안 오가나 — 두 화면이 같은 글을 쓴다.
///
/// 설정 화면 안에 있던 _syncScopeBlock 과 같은 내용이다. 같은 말을 두
/// 군데에 손으로 적어 두면 한쪽만 고치는 날이 반드시 온다.
Widget _syncScopeBody(BuildContext context, L10n l) {
  Widget line(String text) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('· ', style: TextStyle(fontSize: 14, color: context.c.sub)),
          Expanded(
            child: Text(text,
                // 2026-08-20 — 읽으라고 쓴 안내문이 14px이었다. 대비만
                // 올리고 크기를 그대로 두면 절반만 고친 것이다.
                style: TextStyle(
                    fontSize: 15, height: 1.5, color: context.c.sub)),
          ),
        ]),
      );
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line(l.syncScopeShared),
      line(l.syncScopeDevice),
      line(l.syncScopeNever),
      // 닿는 범위는 창고마다 다르다. 애플 것을 그대로 두면 구글을 골라
      // 놓고도 "안드로이드는 백업 내보내기를 쓰세요"라고 말하게 된다.
      line(Store.instance.settings.syncBackend == 'gdrive'
          ? l.syncScopePlatformGdrive
          : l.syncScopePlatform),
    ]),
  );
}

/// 동기화 — 두 뎁스.
///
/// 2026-08-19 소유자 지시로 만들었다. 네 토막이다.
///
///   ① 어디에 둘까   — 창고 고르기
///   ② 지금 상태     — 켜짐/꺼짐, 마지막으로 맞춘 때, 지금 맞추기
///   ③ 무엇이 오가나 — 설정 화면에 있던 것을 그대로 옮겨 왔다
///   ④ 문제가 생기면 — 동기화는 백업이 아니라는 말
///
/// ④를 넣은 까닭을 적어 둔다. 사람은 동기화를 백업으로 믿는다. 그런데
/// 동기화는 정반대다 — 한쪽에서 지우면 **모든 곳에서** 지워진다.
/// 그 말을 안 해 주면, 잘못 지운 날 우리가 노트를 먹은 것이 된다.
///
/// 여기에 '내보내기' 단추를 달지 않은 것은 일부러다. 2026-08-17에 그
/// 셋(가져오기·내보내기·백업)을 설정에서 빼서 목록의 메뉴로 옮겼다.
/// 같은 일로 가는 문이 둘이면 사람은 둘이 다른 일인가 의심한다. 그래서
/// 여기서는 **어디에 있는지만** 말한다.
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen>
    with SettingsRows {
  /// 라디오 한 줄. 미닫이(_dropRow)를 안 쓰는 까닭은, 창고 고르기는
  /// **셋을 한눈에 견주는** 일이기 때문이다. 미닫이는 고른 하나만
  /// 보여 주므로 "다른 데 두면 뭐가 달라지나"에 답하지 못한다.
  Widget _radioRow(String group, String value, String title, String? sub,
      {bool enabled = true, String? badge}) {
    final c = context.c;
    final on = value == group;
    return InkWell(
      onTap: enabled ? () => _pick(value) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(on ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 21, color: on ? c.accent : c.sub),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w600,
                              color: on ? c.accent : c.guideInk)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: c.tagBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: c.tagLine)),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.tagInk)),
                      ),
                    ],
                  ]),
                  if (sub != null) ...[
                    const SizedBox(height: 3),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.35, color: c.sub)),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pick(String v) async {
    final s = store.settings;
    // 2026-08-20 소유자 신고 — "동기화 자동으로 해제 문제. 왜 이렇지?"
    //
    // 이 줄이 맨 앞에 있었다: `if (s.syncBackend == v) return;`
    // 뜻은 '같은 걸 또 고르면 헛일'이었는데, **고른 것과 붙은 것은
    // 다른 일**이라는 걸 빠뜨렸다. 구글이 이미 골라져 있고 로그인만
    // 풀린 판에서 'Google Drive' 를 누르면 아무 일도 안 일어난다 —
    // 로그인도 안 하고 말도 안 한다. 되돌아갈 문이 없었다.
    //
    // 그래서 '붙었는가'를 '골랐는가'보다 먼저 본다.
    if (v == 'gdrive' && !DriveAuth.instance.signedIn) {
      // 웹은 여기서 붙일 수 없다 — 구글이 그린 단추를 사람이 눌러야만
      // 창이 열린다. 고르기만 하고, 붙는 일은 상태 줄의 안내 창이 맡는다.
      // 화면은 '꺼짐 · 로그인 필요'라고 정직하게 말한다.
      if (kIsWeb) {
        setState(() => s.syncBackend = v);
        await applySyncBackend();
        await store.persistSettings();
        unawaited(ICloudSync.instance.rebind());
        return;
      }
      final ok = await DriveAuth.instance.signIn();
      if (!mounted) return;
      if (!ok) {
        _toast(context, L10n.of(context).driveSignInFailed);
        return;
      }
      setState(() => s.syncBackend = v);
      await applySyncBackend();
      await store.persistSettings();
      unawaited(ICloudSync.instance.rebind());
      return;
    }
    if (s.syncBackend == v) return;
    setState(() => s.syncBackend = v);
    await applySyncBackend();
    await store.persistSettings();
    if (v != 'none') unawaited(ICloudSync.instance.rebind());
  }

  String _when(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${DateFormat.yMd().format(d)} ${DateFormat.Hm().format(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    final sync = ICloudSync.instance;
    final paused = s.syncBackend == 'none';
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: context.c.bg,
        title: Text(l.syncTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: narrowBody(
        context,
        ListView(
          padding: scrollPad(context, top: 6),
          children: [
            // ① 어디에 둘까
            _secHeader(l.syncWhereTitle),
            _card([
              _radioRow(s.syncBackend, 'none', l.syncBackendNone,
                  l.syncBackendNoneSub),
              _sep(),
              _radioRow(s.syncBackend, 'icloud', l.syncBackendIcloud,
                  l.syncBackendIcloudSub,
                  enabled: isApplePlatform,
                  badge: isApplePlatform ? null : l.syncAppleOnly),
              _sep(),
              // 2026-08-20 — 문을 열었다. 다만 **아무 데서나 열지는
              // 않는다.** 구글 로그인 플러그인이 안 받는 자리(윈도우·리눅스)와
              // 클라이언트 아이디를 안 넣고 빌드한 판에서는 눌러도 아무 일이
              // 안 일어나는 단추가 된다. DriveAuth.supported 가 그 둘을 다 본다.
              _radioRow(s.syncBackend, 'gdrive', l.syncBackendGdrive,
                  DriveAuth.instance.signedIn && s.syncBackend == 'gdrive'
                      ? '${l.syncBackendGdriveSub} · ${l.driveSignedInAs} ${DriveAuth.instance.email}'
                      : l.syncBackendGdriveSub,
                  enabled: DriveAuth.supported,
                  badge: DriveAuth.supported ? null : l.syncSoon),
            ]),

            // ② 지금 상태
            if (!paused) ...[
              _secHeader(l.syncSectionState),
              _card([
                ValueListenableBuilder<SyncState>(
                  valueListenable: sync.state,
                  builder: (_, st, __) {
                    final ok = st == SyncState.ok;
                    final busy = st == SyncState.running;
                    final say = SyncSay.of(l, st,
                        everSynced: sync.lastSyncMs.value > 0);
                    final title = say.title;
                    final sub = say.sub;
                    final row = Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                      child: Row(children: [
                        Icon(
                            ok
                                ? Icons.cloud_done_outlined
                                : busy
                                    ? Icons.cloud_sync_outlined
                                    : Icons.cloud_off_outlined,
                            size: 22,
                            color: ok ? context.c.accent : context.c.sub),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: ok
                                          ? context.c.accent
                                          : context.c.guideInk)),
                              if (sub != null) ...[
                                const SizedBox(height: 2),
                                Text(sub,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: context.c.sub)),
                              ],
                            ],
                          ),
                        ),
                        if (!ok && !busy)
                          Icon(Icons.chevron_right, color: context.c.sub),
                      ]),
                    );
                    if (ok || busy) return row;
                    return InkWell(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SyncHelpSheet(),
                      ),
                      child: row,
                    );
                  },
                ),
                _sep(),
                // 마지막으로 맞춘 때. 이것 하나가 '되고 있나?'라는 물음에
                // 상태 문구보다 정확히 답한다 — 켜짐이라고 써 있어도 두
                // 시간 전이 마지막이면 뭔가 잘못된 것이다.
                // 2026-08-20 소유자 지적 — "동기화하고 있는데 '지금 맞추기'
                // 단추는 없어야 하지 않니?" 맞다. 맞추는 중에 눌러도
                // syncNow() 가 _busy 에서 그대로 되돌아간다. **아무 일도 안
                // 하는 단추는 없는 것보다 나쁘다** — 눌러 본 사람은 앱이
                // 고장 났다고 읽는다.
                //
                // 그래서 시각(lastSyncMs)만 듣던 것을 상태(state)도 함께
                // 듣게 바꾼다. 예전에는 이 줄이 시각만 알아서, 맞추는 중인지
                // 아닌지를 몰랐다.
                ListenableBuilder(
                  listenable: Listenable.merge([sync.lastSyncMs, sync.state]),
                  builder: (_, __) {
                    final ms = sync.lastSyncMs.value;
                    final busy = sync.state.value == SyncState.running;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, busy ? 16 : 8, 12),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                              // 도는 중이면 시각 대신 '지금 어떤가'를 말한다.
                              // 시각과 '맞추는 중'을 함께 놓으면 두 줄이 서로
                              // 다른 순간을 가리켜 모순으로 읽힌다.
                              busy
                                  ? l.syncNowBusy
                                  : ms == 0
                                      ? l.syncLastNever
                                      : l.syncLastAt(_when(ms)),
                              style: TextStyle(
                                  fontSize: 13.5, color: context.c.sub)),
                        ),
                        if (!busy)
                          TextButton(
                            onPressed: () => unawaited(sync.syncNow()),
                            child: Text(l.syncNowAction,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                    );
                  },
                ),
                _sep(),
                // 동기화 기록(2026-08-27). '되고 있나'에 상태 문구보다
                // 정확히 답하는 자리다 — 무엇이 언제 몇 개 오갔는지.
                ListTile(
                  title: Text(l.syncLogTitle,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  trailing:
                      Icon(Icons.chevron_right, color: context.c.sub),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SyncLogScreen()),
                  ),
                ),
              ]),
            ],

            // ③ 무엇이 오가나
            _secHeader(l.syncScopeTitle),
            _card([_syncScopeBody(context, l)]),

            // ④ 문제가 생기면
            _secHeader(l.syncTroubleTitle),
            _card([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                child: Text(l.syncTroubleNote,
                    style: TextStyle(
                        fontSize: 14, height: 1.5, color: context.c.guideInk)),
              ),
              _sep(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Text('${l.exportBackup} — ${l.exportBackupSub}',
                    style:
                        TextStyle(fontSize: 13.5, height: 1.45, color: context.c.sub)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// 조금 더 미끄러지는 굴림.
///
/// 2026-08-18 소유자 — "위/아래 스크롤을 할 때, 조금만 더 스르르륵
/// 미끄러지는 듯한 유연한 느낌이 필요해."
///
/// 머티리얼 기본(ClampingScrollPhysics)은 손을 떼면 금세 선다. 애플 계열
/// 굴림(BouncingScrollPhysics)은 마찰이 작아 한참 더 미끄러지고, 끝에
/// 닿으면 고무줄처럼 되튄다. 한 앱이 기기마다 다른 속도로 구르면 그건 두
/// 앱이므로 전부 뒤쪽으로 맞춘다.
///
/// RangeMaintainingScrollPhysics 를 부모로 두는 것은 머티리얼 기본과 같다 —
/// 목록의 길이가 바뀌어도 보고 있던 자리를 지켜 준다. 이걸 빼면 동기화가
/// 들어와 메모가 하나 늘어난 순간 화면이 튄다.
class GlideScrollBehavior extends MaterialScrollBehavior {
  const GlideScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());
}

/// 편집 화면 맨 위의 유리 띠.
///
/// 흐림 세기와 짙기는 눈으로 맞췄다(2026-08-27). 기준은 하나 — **밑을
/// 지나는 글이 글자로 읽히면 안 되고, 그렇다고 밑이 비어 보여도 안 된다.**
/// 색과 움직임은 남기고 글자만 죽인다.
class _HeadGlass extends StatelessWidget {
  const _HeadGlass();

  /// 아래 몇 할부터 사라지기 시작하나.
  static const double _fadeFrom = 0.74;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, _fadeFrom, 1],
        ).createShader(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          // 흐림만으로는 큰 글자가 아직 형태로 읽힌다. 종이색을 옅게
          // 한 겹 얹어 대비를 마저 죽인다. 다 덮지는 않는다 — 다 덮으면
          // 유리가 아니라 벽이다.
          child: Container(color: c.bg.withValues(alpha: 0.72)),
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final bool hairlineTop;
  final bool hairlineBottom;
  final BorderRadius? radius;

  /// 아래로 갈수록 옅어지는가.
  ///
  /// 화면 맨 위에 떠 있는 머리에만 켠다. 자판 위 도구 막대처럼 **아래에
  /// 붙는** 것에 켜면 결이 거꾸로라 위쪽이 뚫려 보인다.
  final bool fade;

  const Glass({
    super.key,
    required this.child,
    this.hairlineTop = false,
    this.hairlineBottom = false,
    this.radius,
    this.fade = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: fade ? null : c.glass,
          // 위는 옅은 막, 아래는 아무것도 없음. 선을 긋지 않고 경계를
          // 알리는 방법이다.
          gradient: fade
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.glass,
                    c.glass.withValues(alpha: 0),
                  ],
                )
              : null,
          borderRadius: radius,
          // 둥근 유리에는 비균일 테두리를 못 쓴다(프레임워크 제약).
          border: radius != null
              ? null
              : Border(
                  top: hairlineTop
                      ? BorderSide(color: c.glassLine)
                      : BorderSide.none,
                  bottom: hairlineBottom
                      ? BorderSide(color: c.glassLine)
                      : BorderSide.none,
                ),
        ),
        child: child,
      ),
    );
  }
}

/// 메모를 연다 — 화면이 넓으면 오른쪽 칸에, 좁으면 새 화면으로 민다.
///
/// 메모를 여는 자리가 앱 안에 네 군데 있다. 규칙을 이 함수 하나에 모으지
/// 않았다면 넓은 화면을 지원하면서 그중 하나는 반드시 빠뜨렸을 것이다.
Future<void> openNote(BuildContext context, String id,
    {bool autoTidy = false, bool showMeta = false}) async {
  // 잠긴 메모는 여기서 막는다. 바로 위 주석이 말한 그 까닭 그대로다 —
  // 여는 자리가 넷인데 그중 하나라도 빠뜨리면 이건 잠금이 아니라
  // **잠금처럼 보이는 것**이 된다.
  final reason = L10n.of(context).lockReasonNote;
  final i = Store.instance.notes.indexWhere((x) => x.id == id);
  if (i >= 0 && Store.instance.notes[i].locked) {
    final ok = await LockService.instance.ask(reason);
    if (!ok || !context.mounted) return;
  }
  final shell = SplitShell.of(context);
  if (shell != null && shell.isWide) {
    shell.open(id, autoTidy: autoTidy, showMeta: showMeta);
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => EditorScreen(
            noteId: id, autoTidy: autoTidy, showMeta: showMeta)),
  );
}

/// 넓은 화면에서 왼쪽에 목록, 오른쪽에 본문을 함께 보여 주는 껍데기.
///
/// 2026-08-16 소유자 요청 — "맥이나 윈도의 경우 왼쪽에 리스트를 보여주면
/// 어떨까?" 지금까지 맥 앱은 휴대폰 화면을 크게 늘린 모양이었다. 넓은
/// 화면에서 한 번에 하나만 보이는 것은 자리 낭비이고, 목록과 글을 오갈
/// 때마다 화면이 통째로 바뀌어 지금 어디에 있는지 감각이 끊긴다.
///
/// 갈림목을 900으로 잡았다. 아이패드 세로(834)는 한 칸, 가로(1194)는 두
/// 칸이 된다. 애플 자체 앱들이 쓰는 값과 같다 — 독자 설계를 하지 않는다.
class SplitShell extends StatefulWidget {
  const SplitShell({super.key});

  /// 이 폭부터 두 칸으로 나눈다.
  static const double kWideAt = 900;

  /// 목록 칸의 처음 폭. 애플 메모·메일과 비슷한 값이다.
  static const double kListWidth = 320;

  /// 손으로 끌 수 있는 범위.
  ///
  /// 아래는 240 — 이보다 좁으면 제목 한 줄이 두 줄로 접혀서 목록이
  /// 목록으로 안 보인다. 위는 480 — 이보다 넓으면 오른쪽 글 칸이
  /// 읽기 좋은 폭 아래로 내려간다. 늘릴 수 있게 해 놓고 늘리면
  /// 망가지게 두는 것은 늘릴 수 있게 한 것이 아니다.
  static const double kListMin = 240;
  static const double kListMax = 480;

  /// 글 칸이 넘지 않을 폭의 아래 한계.
  ///
  /// 2026-08-17 소유자 지시 — "가로 모드에서는 편집 화면이 너무 풀사이즈로
  /// 넓어지지 않게 세로 보기 해상도 만큼의 width를 할 수 있을까? 가운데
  /// 정렬로."
  ///
  /// 기준을 화면의 **짧은 변**으로 잡았다. 그 값이 곧 그 기기를 세로로
  /// 들었을 때의 폭이라, 기기마다 숫자를 외울 필요가 없다. 아이패드
  /// 12.9는 1024, 11인치는 834다. 가로로 눕히든 목록을 접든 글이 읽던
  /// 폭 그대로 남는다.
  ///
  /// 다만 맥에서는 창을 납작하게 만들면 짧은 변이 창 높이가 되어 글 칸이
  /// 지나치게 좁아진다. 그래서 아래 한계를 둔다.
  static const double kMinReadWidth = 720;

  static SplitShellState? of(BuildContext c) =>
      c.findAncestorStateOfType<SplitShellState>();

  /// 한 화면에서 눈이 편하게 훑을 수 있는 폭.
  ///
  /// 2026-08-17에 글 칸에 쓰려고 만든 셈인데, 2026-08-18 소유자 지시로
  /// 설정 화면도 같은 폭을 쓴다 — "맥앱과 아이패드 앱(가로모드)에서
  /// 설정도 너무 넙대대하다."
  ///
  /// 같은 셈을 두 자리에 베껴 쓰지 않고 여기 하나로 둔다. 한쪽만 고치면
  /// 글과 설정의 폭이 달라지고, 그건 화면이 두 개인 것처럼 보인다.
  ///
  /// 폰에서는 이 값이 화면보다 커서 아무 일도 일어나지 않는다 — 자리에
  /// 따라 켜고 끄는 조건문이 필요 없다.
  static double readWidth(BuildContext c) {
    final s = MediaQuery.sizeOf(c).shortestSide;
    return s < kMinReadWidth ? kMinReadWidth : s;
  }

  @override
  State<SplitShell> createState() => SplitShellState();
}

class SplitShellState extends State<SplitShell> {
  /// 왼쪽 칸의 폭. 손으로 끌어 바꾼다(2026-08-18 소유자 지시).
  ///
  /// 값을 State 가 들고 있고 설정에는 **손을 뗄 때만** 적는다. 끄는 동안
  /// 매 프레임 저장하면 초당 예순 번 파일을 쓴다.
  double? _drag;
  double get _listW =>
      (_drag ?? Store.instance.settings.listWidth)
          .clamp(SplitShell.kListMin, SplitShell.kListMax);

  String? _openId;
  bool _autoTidy = false;
  bool _showMeta = false;

  /// 왼쪽 목록을 펴 두었는가.
  ///
  /// 2026-08-17 소유자 지시 — "메모 리스트가 좌측에 계속 보이게 되어있는데,
  /// 이걸 안보이게 접을 수 있게 해줘. 토글."
  ///
  /// 기본은 펴 둔 상태다. 넓은 화면에서 두 칸으로 나눈 까닭이 그것이기
  /// 때문이다. 접는 것은 '글에만 집중하겠다'는 뜻이라 사용자가 그때그때
  /// 정한다. 앱을 껐다 켜면 다시 펴진다 — 접힌 채로 다시 열면 목록이
  /// 사라진 것처럼 보이고, 그건 고장으로 읽힌다.
  bool _listOpen = true;

  bool get listOpen => _listOpen;

  void toggleList() => setState(() => _listOpen = !_listOpen);

  /// 글 칸 양옆 여백에 깔 색.
  ///
  /// 종이마다 다르다 — 종이가 바뀌면 여백도 같이 바뀐다. 셈은
  /// paper.dart 의 marginTone 하나뿐이라, 여백이 종이에서 떨어져 나가
  /// 따로 노는 일이 생기지 않는다.
  Color _marginColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = paperById(Store.instance.settings.paperMode);
    if (p.id == kPaperNone) {
      // '기본'은 종이 색이 없다. 그때 글 칸 바탕은 앱 바탕색이므로,
      // 같은 잣대를 앱 바탕색에 댄다.
      return Color(marginTone(context.c.bg.toARGB32()));
    }
    return Color(marginTone(p.bgOf(dark)));
  }

  /// 지금 오른쪽 칸에 열려 있는 메모. 목록이 그것을 표시하려고 본다.
  String? get openId => _openId;

  bool get isWide => MediaQuery.sizeOf(context).width >= SplitShell.kWideAt;

  void open(String id, {bool autoTidy = false, bool showMeta = false}) {
    setState(() {
      _openId = id;
      _autoTidy = autoTidy;
      _showMeta = showMeta;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < SplitShell.kWideAt) {
      // 좁으면 예전 그대로다. 오른쪽 칸이 없으니 목록만 보여 준다.
      return const HomeScreen();
    }
    final c = context.c;
    final store = Store.instance;

    // 열어 둔 메모가 지워졌을 수 있다(휴지통으로 보냈거나 다른 기기에서
    // 지웠거나). 그때 "메모를 찾을 수 없습니다"를 띄우는 것보다 빈 칸으로
    // 돌아가는 편이 낫다 — 사용자가 한 일의 결과로는 그게 자연스럽다.
    final id = _openId;
    final alive = id != null && store.notes.any((n) => n.id == id);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // 배너는 두 칸 위를 가로지른다. 왼쪽 칸 안에만 두면 320pt짜리
          // 광고 자리가 되어 채울 소재가 거의 없다.
          const TopBannerBar(),
          Expanded(
            child: Row(children: [
              // 접을 때 폭만 0으로 줄인다. 목록을 트리에서 빼 버리면 스크롤
              // 위치와 고른 상태가 사라져서, 다시 펴면 맨 위로 돌아가 있다.
              // 잠깐 감춘 것과 지운 것은 다르다.
              //
              // 안쪽은 OverflowBox로 320을 그대로 물려 준다. 폭이 줄어드는
              // 동안 목록까지 같이 찌그러지면 글자가 겹쳐 보인다 — 접히는
              // 것이 아니라 망가지는 것으로 읽힌다.
              ClipRect(
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: _listOpen ? _listW : 0,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: _listW,
                    maxWidth: _listW,
                    child: const HomeScreen(embedded: true),
                  ),
                ),
              ),
              // 끄는 손잡이. 보이는 것은 선 하나지만 손이 닿는 자리는
              // 열 배 넓다 — 1픽셀짜리 선을 정확히 집으라고 요구하는 것은
              // 마우스에게도 무리다. 맥 앱들이 다 이렇게 한다.
              if (_listOpen)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) => setState(() {
                      _drag = (_drag ?? Store.instance.settings.listWidth) +
                          d.delta.dx;
                    }),
                    onHorizontalDragEnd: (_) {
                      // 손을 뗄 때 한 번만 적는다.
                      final w = _listW;
                      Store.instance.settings.listWidth = w;
                      unawaited(Store.instance.persistSettings());
                      setState(() => _drag = w);
                    },
                    child: SizedBox(
                      width: 10,
                      child: Center(
                        child: Container(width: 1, color: c.line),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: _marginColor(context),
                  child: !alive
                    ? Stack(children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              L10n.of(context).splitEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, height: 1.5, color: c.sub),
                            ),
                          ),
                        ),
                        // 편집 화면이 있을 때와 **같은 자리**에 둔다.
                        // 열려 있든 비어 있든 새 노트 단추는 늘 오른쪽
                        // 아래다 — 자리가 바뀌면 손이 매번 찾아야 한다.
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton(
                            heroTag: 'split-new',
                            tooltip: L10n.of(context).newNoteTooltip,
                            backgroundColor: kAccentSoft,
                            foregroundColor: kOnAccentSoft,
                            onPressed: () async {
                              final note = Note.fresh();
                              store.notes.insert(0, note);
                              await store.persist();
                              if (!mounted) return;
                              open(note.id);
                            },
                            child: const Icon(CupertinoIcons.square_pencil,
                                size: 24),
                          ),
                        ),
                      ])
                    : Center(
                        // 글 칸을 화면 폭만큼 늘리지 않는다. 한 줄이 길어질수록
                        // 눈이 다음 줄 첫머리를 찾기 어려워진다 — 읽기가 힘든
                        // 것은 글자 크기가 아니라 줄 길이인 경우가 많다.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: SplitShell.readWidth(context)),
                          child: AnimatedSwitcher(
                        // 오른쪽 칸이 바뀔 때 뚝 끊기지 않게 아주 짧게 겹친다.
                        // 180ms는 '봤다'와 '기다렸다' 사이의 값이다 — 더 길면
                        // 목록을 훑을 때 답답해진다.
                        //
                        // 움직임을 줄이도록 설정한 사용자에게는 아예 끈다.
                        // 그 설정은 취향이 아니라 어지럼증 대응인 경우가 많다.
                        duration: MediaQuery.of(context).disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                          child: EditorScreen(
                            key: ValueKey(id),
                            noteId: id,
                            autoTidy: _autoTidy,
                            showMeta: _showMeta,
                            embedded: true,
                          ),
                        ),
                        ),
                      ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.embedded = false});

  /// 두 칸 화면의 왼쪽에 들어가 있는가. 그렇다면 배너는 껍데기가 그린다.
  final bool embedded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 아이폰·아이패드에서 맨 위 시계 자리를 한 번 두드리면 맨 위로 올린다.
///
/// 2026-08-17 소유자 지시 — "맨 위의 기기 시계 부분을 원터치를 하면 맨 위로
/// 스크롤이 올라가게 해줘."
///
/// 이건 우리가 손가락을 받는 것이 아니다. 상태막대는 앱이 아니라 iOS의
/// 것이라 터치가 우리에게 오지 않는다. 대신 iOS가 "누가 상태막대를
/// 두드렸다"고 알려 주고(flutter/system 채널), 플러터가 그것을 등록된
/// 감시자들에게 handleStatusBarTap 으로 나눠 준다. 우리는 그 소식을 받아
/// 스크롤만 올리면 된다.
///
/// 그래서 **안드로이드에는 이 소식이 오지 않는다.** 안드로이드의 상태
/// 표시줄은 내려서 알림을 보는 곳이지 두드리는 곳이 아니라서, 운영체제가
/// 아예 그런 사건을 만들지 않는다. 없는 사건을 흉내 내려면 화면 맨 위에
/// 투명한 판을 덮어야 하는데, 그러면 알림 내리기를 우리가 가로채게 된다.
/// 남의 동작을 뺏는 편의는 편의가 아니다.
mixin _ScrollTopOnStatusBarTap<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  /// 맨 위로 올릴 스크롤. 아직 붙지 않았으면 null 을 돌려주면 된다.
  ScrollController? get topScroller;

  void _bindStatusBarTap() => WidgetsBinding.instance.addObserver(this);
  void _unbindStatusBarTap() => WidgetsBinding.instance.removeObserver(this);

  @override
  void handleStatusBarTap() {
    final c = topScroller;
    if (c == null || !c.hasClients || c.offset <= 0) return;
    c.animateTo(0,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, _ScrollTopOnStatusBarTap {
  /// 목록은 컨트롤러를 따로 두지 않고 기본 스크롤을 쓴다. 그 임자를 여기서
  /// 빌려 온다.
  @override
  ScrollController? get topScroller => PrimaryScrollController.maybeOf(context);

  final store = Store.instance;
  String query = '';

  /// 검색칸이 펼쳐져 있는가.
  ///
  /// 2026-08-18 소유자 지시 — "검색을 많이 할 것도 아니니. 그냥 검색
  /// 버튼(돋보기)만 하나 두고 시원하게 하자."
  ///
  /// 검색칸을 늘 띄워 두면 머리 60px 중 절반을 '오늘 한 번도 안 쓸 칸'이
  /// 먹는다. 그 칸이 사라지면 그 자리에 목록의 첫 줄이 올라온다 — 앱을
  /// 열었을 때 맨 먼저 보이는 것이 도구가 아니라 내 글이 된다.
  bool _searching = false;
  final _searchCtl = TextEditingController();

  /// 여러 개를 골라 한 번에 지우는 중인가.
  ///
  /// 2026-08-17 소유자 지시 — "'정렬과 필터'에서 '선택 메모 한번에 삭제'
  /// 버튼을 누르면 메모 좌측에 체크박스가 생겨서 한번에 멀티로 선택할 수
  /// 있어. 고정 메모까지 포함해서."
  ///
  /// 왜 목록에 상시로 체크박스를 두지 않는가: 평소에 이 앱에서 하는 일은
  /// 고르는 것이 아니라 **읽고 여는 것**이다. 체크박스를 늘 띄워 두면 매번
  /// 안 쓰는 칸이 글자를 오른쪽으로 밀어낸다. 정리하는 순간에만 나타났다
  /// 사라지는 것이 맞다.
  bool _picking = false;

  /// 고른 메모의 id. 화면에서 사라진 것(필터가 바뀐 것)은 지울 때 셈에서
  /// 뺀다 — **안 보이는 것이 지워지는 일**만은 없어야 한다.
  final Set<String> _picked = <String>{};

  /// 앱이 다시 앞으로 나올 때 아이클라우드를 한 번 훑기 위한 것.
  /// 다른 기기에서 고친 메모는 대개 이 순간에 들어온다.
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _bindStatusBarTap();
    store.addListener(_onChange);
    // 돌아올 때는 받아 오고(onResume), 물러날 때는 부친다(flushUp).
    // inactive는 확인 창만 떠도 오는 신호라(LockGate 주석 참고) 여기서
    // 하는 일은 '남은 모으기 흘려보내기'뿐이다 — 보낼 게 없으면 무해하다.
    if (kDebugMode && kShowPaywallOnStart) {
      // 첫 프레임이 그려진 뒤에 연다 — 그 전에는 Navigator 가 아직 없다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const PremiumScreen(),
        )));
      });
    }
    _life = AppLifecycleListener(
      onResume: () {
        ICloudSync.instance.onResume();
        // 스토어에도 다시 묻는다. 뒤에 있는 동안 구독이 끊겼을 수도,
        // 다른 기기에서 샀을 수도 있다.
        unawaited(PurchaseService.instance.refresh());
      },
      onInactive: ICloudSync.instance.flushUp,
      onHide: ICloudSync.instance.flushUp,
    );
    // 아이클라우드는 메모를 다 읽은 **뒤에** 켠다. 먼저 켜면 아직 비어 있는
    // 목록을 "이 기기에는 메모가 없다"로 읽고, 그 상태로 남의 기기 것과
    // 합친 결과를 기기에 되쓴다 — 메모가 통째로 날아가는 길이다.
    store.load().then((_) {
      // 저장된 창고 고르기를 켜자마자 스위치에 옮긴다. 이걸 빠뜨리면
      // '동기화 안 함'으로 두고 앱을 껐다 켠 사람의 노트가 다시 오간다.
      // 구글을 고른 사람은 조용히 다시 붙어 본다. 실패해도 아무 말 안 한다 —
      // 앱을 켤 때마다 로그인 창이 뜨는 것은 동기화가 아니라 검문이다.
      // 붙든 못 붙든 통로는 끼운다. 못 붙었으면 토큰이 null 이라 이번
      // 차례를 거르고, 설정 화면이 '로그인 필요'로 알려 준다.
      final wantDrive = store.settings.syncBackend == 'gdrive';
      (wantDrive ? DriveAuth.instance.resume() : Future<bool>.value(false))
          .then((_) async {
        await applySyncBackend();
        ICloudSync.instance.boot();
      });
    });
    // 다른 앱에서 보낸 글 받기(2026-08-17). 목록 화면이 살아 있는 동안
    // 계속 듣는다.
    _wireShare();
    _wireWidget();
    // 맥 상단의 '파일' 메뉴. 첫 프레임 뒤에 단다 — 그때라야 L10n이 있다.
    if (MacMenu.supported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _installMacMenu());
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _unbindStatusBarTap();
    _life.dispose();
    ICloudSync.instance.dispose();
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// 목록 화면의 '...' 메뉴.
  ///
  /// 2026-08-16 소유자 지적 — "목록에서 메뉴를 신설하기로 한 거 아니니?
  /// 불러오기 등등 여러 가지 신 기능들을 넣을 수 있어야지."
  ///
  /// 불러오기·내보내기·휴지통이 전부 설정 화면 깊숙이 있었다. 설정은
  /// 한 번 정해 놓고 안 여는 곳이고 불러오기는 자주 하는 일인데, 둘을
  /// 같은 서랍에 넣으면 자주 하는 일이 안 보인다. 설정 화면에서 빼지는
  /// 않았다 — 거기서 찾던 사람이 못 찾게 되면 그건 다른 종류의 잘못이다.
  ///
  /// 편집 화면의 '...'과 같은 모양으로 만든다. 위쪽은 이 화면에서 하는 일,
  /// 맨 아래는 앱 설정, 그 사이에 구분선. 두 화면의 메뉴가 다르게 생기면
  /// 사용자는 매번 새로 배운다.
  Widget _listMenu(L10n l) => PopupMenuButton<String>(
        // 2026-08-17 소유자 요청 — 삼선. '...'은 애플이 '더 있음'을 뜻할 때
        // 쓰는 표시고, 삼선은 '메뉴'를 뜻한다. 이 자리는 이제 불러오기·
        // 내보내기·휴지통·설정이 들어 있는 진짜 메뉴다.
        icon: const Icon(Icons.menu),
        tooltip: l.moreTooltip,
        // 메뉴가 '...' 버튼을 덮으면 같은 자리를 다시 눌러 닫을 수 없다
        // (2026-08-16에 편집 화면에서 겪고 고친 것과 같은 문제다).
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        onSelected: (v) async {
          switch (v) {
            case 'import':
              final n = await ImportService.importFiles();
              if (!mounted) return;
              setState(() {});
              _toast(context, n > 0 ? l.importDone(n) : l.importNone);
            case 'exportMd':
              final ok = await ExportService.shareAllMarkdown();
              if (!mounted) return;
              if (!ok) _toast(context, l.exportEmpty);
            case 'backup':
              final ok = await ExportService.shareBackup();
              if (!mounted) return;
              if (!ok) _toast(context, l.exportFailed);
            case 'folders':
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const FolderManageScreen()));
              if (mounted) setState(() {});
            case 'trash':
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()));
              if (mounted) setState(() {});
          }
        },
        itemBuilder: (ctx) {
          // 편집 화면 메뉴와 같은 치수로 맞춘다(2026-08-27). 같은 일을
          // 하는 두 서랍이 서로 다른 줄 높이를 쓰면 그게 눈에 걸린다.
          PopupMenuItem<String> row(String v, IconData ic, String label) =>
              PopupMenuItem<String>(
                value: v,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(ic, size: 18, color: ctx.c.sub),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontSize: 15)),
                ]),
              );
          return [
            // --- 이 화면에서 하는 일 (앞으로 여기에 더 붙는다) ---
            row('import', Icons.file_open_outlined, l.importFiles),
            row('exportMd', Icons.folder_zip_outlined, l.exportAllMd),
            row('backup', Icons.settings_backup_restore, l.exportBackup),
            const PopupMenuDivider(height: 6),
            // 2026-08-17 소유자 지시 — '앱 설정'을 메뉴에서 뺐다.
            //
            // 설정은 메뉴 안에 있을 이유가 없다. 메뉴 안의 것들은 가끔 하는
            // 일이고 설정은 자주 여는 곳이다. 한 번 더 눌러야 열리는 것은
            // 그만한 이유가 있을 때만 그렇게 둔다. 이제 위 줄 오른쪽 끝에
            // 톱니바퀴로 나와 있다.
            // 2026-08-18 소유자 지시 — '폴더 설정'은 여기.
            row('folders', Icons.folder_outlined, l.folderManage),
            row('trash', Icons.delete_outline, l.trashTitle),
          ];
        },
      );

  /// 맥 상단 '파일' 메뉴를 달고, 눌렀을 때 할 일을 잇는다.
  ///
  /// 글자를 여기서 넘기는 이유는 mac_menu.dart 머리말에 적어 뒀다 —
  /// 짧게는, 아홉 언어 문구를 스위프트에 또 한 벌 두면 어긋나기 때문이다.
  Future<void> _installMacMenu() async {
    if (!mounted) return;
    final l = L10n.of(context);
    await MacMenu.install({
      'file': l.menuFile,
      'new': l.newNoteTooltip,
      'import': l.importFiles,
      'exportMd': l.exportAllMd,
      'backup': l.exportBackup,
      'close': l.menuClose,
      'settings': l.menuPrefs,
    }, onPick: (id) async {
      if (!mounted) return;
      switch (id) {
        case 'new':
          final fresh = Note.fresh(body: '');
          store.notes.insert(0, fresh);
          await store.persist();
          if (!mounted) return;
          await openNote(context, fresh.id);
        case 'import':
          final n = await ImportService.importFiles();
          if (!mounted) return;
          setState(() {});
          _toast(context, n > 0 ? l.importDone(n) : l.importNone);
        case 'exportMd':
          final ok = await ExportService.shareAllMarkdown();
          if (!mounted) return;
          if (!ok) _toast(context, l.exportEmpty);
        case 'backup':
          final ok = await ExportService.shareBackup();
          if (!mounted) return;
          if (!ok) _toast(context, l.exportFailed);
        case 'settings':
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
          if (mounted) setState(() {});
      }
    });
  }

  Future<void> _pasteAndTidy() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (mounted) _toast(context, L10n.of(context).clipboardEmpty);
      return;
    }
    // 시스템 물음을 방금 겪은 자리다. 여기서 딱 한 번 길을 알려 준다.
    if (mounted) await maybeShowPasteTip(context);
    // 1단은 클립보드에 딸려 온 주소다. 거기 chatgpt.com이 있으면 추측이
    // 아니라 사실이라 '(추정)'을 안 붙인다.
    final fromUrl = sourceFromCapture(await ClipboardSource.read());
    await _intake(text, tidy: true, known: fromUrl);
  }

  /// 밖에서 들어온 글로 메모를 하나 만든다.
  ///
  /// 2026-08-17 — 붙여넣기와 공유가 같은 자리를 쓰게 묶었다. 전에는
  /// 붙여넣기 쪽에만 출처 감지가 붙어 있었고, 그래서 다른 길로 들어온
  /// 글은 검사조차 안 됐다. **같은 일을 하는 자리가 둘이면 반드시
  /// 어긋난다.**
  Future<void> _intake(String text, {
    required bool tidy,
    SourceGuess known = SourceGuess.unknown,
  }) async {
    if (text.trim().isEmpty) return;
    final note = Note.fresh(body: text);
    note.pastedAt = DateTime.now().millisecondsSinceEpoch;

    // 2단은 글의 생김새로 찍는 것이라 반드시 '(추정)'이 붙는다. 둘 다
    // 안 되면 아무 말도 하지 않는다 — 틀린 출처를 조용히 박아 두는 건
    // 안 하느니만 못하다.
    // 생김새로 찍는 길은 닫았다(core/source_detect.dart 의 guessSource
    // 머리말 참고). 증거가 없으면 아무 말도 안 한다.
    final guess = known.isKnown ? known : sourceFromBody(text);
    if (guess.isKnown) {
      note.source = guess.name;
      note.sourceAuto = !guess.certain;
    }

    store.notes.insert(0, note);
    await store.persist();
    if (!mounted) return;
    await openNote(context, note.id, autoTidy: tidy);
  }

  /// 다른 앱에서 보낸 글을 받는다.
  ///
  /// 2026-08-17 — 정리를 자동으로 걸지 않는다. 붙여넣기는 사용자가 '붙여넣고
  /// 정리'라고 적힌 버튼을 눌러서 온 것이라 정리를 기대하지만, 공유는 다른
  /// 앱에서 그냥 보낸 것이다. 남이 보낸 글을 묻지도 않고 고쳐 놓으면
  /// 사용자는 무슨 일이 일어났는지 모른다. 글은 열어 두고, 정리 버튼은
  /// 바로 아래에 있다.
  /// 홈 화면 위젯에서 눌러 들어온 것.
  ///
  /// 공유 받기와 똑같이 **두 길**을 다 받는다. 앱이 켜져 있으면 흐름으로
  /// 오고, 꺼져 있었으면 켜지면서 한 번 온다.
  /// 목록을 아래로 당겼을 때. 지금 맞춘다.
  ///
  /// 창고가 없거나 꺼져 있으면 맞출 것도 없다. 그때는 빙글이만 잠깐 돌고
  /// 만다 — 여기서 '동기화가 꺼져 있습니다' 같은 것을 띄우면 당길 때마다
  /// 잔소리를 듣는 셈이 된다. **물어본 것에 대답만 하고 훈수는 안 둔다.**
  /// 목록에 눈에 띄는 변화가 있었는지 값 하나로 요약한다 — 당김 손맛의
  /// '진짜 받았다' 판정용. 가장 늦은 도장과 개수를 섞는다.
  int _notesMark() {
    var m = 0;
    for (final n in store.notes) {
      if (n.updatedAt > m) m = n.updatedAt;
    }
    return m ^ store.notes.length;
  }

  Future<void> _pullSync() async {
    // 손맛 (2026-08-25 소유자 지시 "햅틱 피드백이 같이 있으면 좋겠다.
    // 손맛."). 당기는 순간 가볍게 '톡' — 손짓을 받았다는 답이다.
    // 데스크톱·웹에서는 진동이 없으므로 조용히 지나간다.
    unawaited(HapticFeedback.lightImpact());
    final sync = ICloudSync.instance;
    if (!sync.active || sync.paused) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      return;
    }
    // 동그라미는 **손짓을 받았다**는 표시지 일이 끝났다는 표시가 아니다.
    //
    // 2026-08-20 소유자 신고 — "2분이 넘도록 계속 돌고 있다. 몇 초만
    // 돌다가 사라져야 하는 거 아닌가?" 맞는 말이다. 손짓에 대한 답은
    // 즉시 와야 하고, 오래 걸리는 일을 보고하는 자리는 따로 있다 —
    // 설정의 동기화 줄이 '맞추는 중'으로 계속 알린다.
    //
    // 8초가 지나면 동그라미만 걷는다. 동기화는 그대로 돈다.
    final before = _notesMark();
    await sync
        .recheck()
        .timeout(const Duration(seconds: 8), onTimeout: () {});
    // 새 것이 실제로 들어왔을 때만 한 번 더, 조금 무겁게 — '진짜 됐다'.
    // 아무 일도 없었으면 조용히 끝난다. 과한 피드백은 신호를 소음으로
    // 만든다.
    if (mounted && _notesMark() != before) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }
  void _wireWidget() {
    if (!WidgetBridge.supported) return;
    WidgetBridge.clicks.listen(_openFromWidget);
    WidgetBridge.initialClick().then((u) {
      if (u != null) _openFromWidget(u);
    });
  }

  Future<void> _openFromWidget(Uri? uri) async {
    final id = WidgetBridge.noteIdFrom(uri);
    if (id == null || !mounted) return;
    if (id.isEmpty) {
      // 위젯의 연필 — 새 메모.
      final note = Note.fresh();
      store.notes.insert(0, note);
      await store.persist();
      if (!mounted) return;
      await openNote(context, note.id);
      return;
    }
    // 그 사이에 지워졌을 수 있다. 없는 메모를 열면 빈 편집 화면이 뜨는데,
    // 그건 '없어졌다'가 아니라 '새로 썼다'로 보여서 더 나쁘다.
    if (!store.notes.any((n) => n.id == id)) return;
    if (mounted) await openNote(context, id);
  }

  void _wireShare() {
    ShareIntake.listen((t) {
      if (mounted) _intake(t, tidy: false);
    });
    ShareIntake.take().then((t) {
      if (t != null && mounted) _intake(t, tidy: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    // 위젯에 쓸 말을 알려 준다. 아홉 언어짜리 말 뭉치를 코틀린·스위프트에
    // 또 두지 않기 위해서다(widget_bridge.dart 머리말). 바뀐 게 없으면
    // 아무 일도 안 하므로 여기서 매번 불러도 된다.
    WidgetBridge.words(WidgetWords(
      title: l.appTitle,
      untitled: l.untitled,
      empty: l.widgetEmpty,
      allLocked: l.widgetAllLocked,
    ));
    final s = store.settings;
    final q = query.trim();
    final filtered = store.notes.where((n) {
      if (s.filterSource.isNotEmpty && n.source != s.filterSource) return false;
      if (s.filterTag.isNotEmpty && !n.tags.contains(s.filterTag)) return false;
      if (s.filterFolder.isNotEmpty && n.folder != s.filterFolder) return false;
      if (q.isEmpty) return true;
      // 2026-08-16 — contains에서 hangulContains로 바꿨다. "ㅌㅅㄹ"을 치면
      // "테슬라"가 나와야 한다. 한국 사용자에게 초성 검색은 있으면 좋은
      // 기능이 아니라 기본 기대치다(규칙은 core/hangul.dart, 테스트로 고정).
      // 잠긴 메모는 본문을 안 내준다. 안 그러면 본문에만 있는 낱말을 쳐서
      // "그 낱말이 거기 있다"를 알아낼 수 있다 — 글자를 안 보여 주고도
      // 내용이 새는 길이다(core/note_lock.dart).
      return hangulContains(
          searchHaystack(
              locked: n.locked,
              title: n.title,
              body: n.body,
              tags: n.tags,
              source: n.source),
          q);
    }).toList();

    int order(Note a, Note b) {
      switch (s.sortMode) {
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        case 'title':
          String key(Note n) =>
              (n.title.trim().isNotEmpty ? n.title : n.body).trim().toLowerCase();
          final r = key(a).compareTo(key(b));
          // 제목이 같으면 최근 것이 위로. 안 그러면 순서가 그때그때 달라져
          // 목록이 흔들리는 것처럼 보인다.
          return r != 0 ? r : b.updatedAt.compareTo(a.updatedAt);
        default:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    }

    // 고정된 메모는 정렬 방식과 무관하게 늘 위다. '고정'의 뜻이 그거다.
    final pinned = filtered.where((n) => n.pinned).toList()..sort(order);
    final rest = filtered.where((n) => !n.pinned).toList()..sort(order);

    // 지금 화면에 보이는 전부. '전체 선택'과 '선택 삭제'가 다루는 범위가
    // 이것이고, 고정된 메모도 여기 들어간다(소유자 지시).
    //
    // 검색어나 필터가 걸려 있으면 걸러진 뒤의 것만이다. 화면에 안 보이는
    // 메모가 '전체 선택'에 딸려 들어가면 그건 전체 선택이 아니라 함정이다.
    final visible = <Note>[...pinned, ...rest];

    return Scaffold(
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          // 2026-08-16 소유자 요청: 큰 '메모' 타이틀을 없애고 검색을 설정
          // 톱니 왼쪽으로. 그 위 최상단은 배너 자리다(광고 없는 날은 0px).
          : SafeArea(
              bottom: false,
              child: Column(children: [
                if (!widget.embedded) const TopBannerBar(),
                const SyncNapBanner(),
                const SyncBusyBanner(),
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      // 2026-08-20 소유자 요청 — "노트 목록 페이지에서 위에서
                      // 아래로 잡아당기면 업데이트(동기화)되게 하면 좋겠다."
                      //
                      // 목록은 사람이 '지금 맞았나?'를 묻는 자리다. 그런데
                      // 그 물음에 답하려면 설정 → 동기화까지 두 번 들어가야
                      // 했다. 당기는 손짓은 그 물음의 가장 짧은 모양이다.
                      //
                      // edgeOffset 에 유리 머리 높이를 준다. 안 주면 빙글이가
                      // 머리 뒤에 숨어서, 당겼는데 아무 일도 안 일어난 것처럼
                      // 보인다.
                      child: RefreshIndicator(
                        onRefresh: _pullSync,
                        edgeOffset: kHomeHeaderH,
                        displacement: 28,
                        color: context.c.accent,
                        backgroundColor: context.c.panel,
                        child: CustomScrollView(
              // 내용이 짧아도 당길 수 있어야 한다. 이게 없으면 메모가 몇 개
              // 없는 사람은 이 손짓을 아예 못 만난다.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 유리 머리 높이만큼 비워서 목록이 그 밑으로 흘러 들어간다.
                const SliverToBoxAdapter(child: SizedBox(height: kHomeHeaderH)),
                // 폴더 줄. 폴더가 하나도 없으면 아예 안 보인다 —
                // 쓰지도 않는 줄이 자리를 먹으면 그게 더 나쁘다.
                if (folderNames(store.notes.map((n) => n.folder), s.folders)
                    .isNotEmpty)
                  _folderBar(l, s),
                // 고르는 중에는 빈 화면 안내를 띄우지 않는다. 그 안내가
                // 남은 자리를 다 먹어서 '삭제완료'가 화면 밖으로 밀려나면
                // 빠져나올 길이 없어진다.
                if (pinned.isEmpty && rest.isEmpty && !_picking)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l.emptyList, textAlign: TextAlign.center)),
                  ),
                // 2026-08-18 소유자 지시로 '고정됨' 소제목을 뗐다 —
                // "핀 아이콘이 보이니, 그게 고정이라고 알아볼거야."
                // 같은 말을 두 번 하는 화면은 그만큼 좁아진다.
                // 고정 목록도 같은 규칙이다(2026-08-17 소유자 지시).
                // 고정을 스무 개씩 해 두는 사람에게는 고정 목록이 곧
                // '그 사람의 목록'이라, 거기를 안 지나면 아무 데도 안 지난다.
                if (pinned.length >= 10) ...[
                  _groupCard(pinned.take(5).toList()),
                  const SliverToBoxAdapter(
                      child: InlineAdBlock(gapAbove: 20, wide: true)),
                  _groupCard(pinned.skip(5).toList()),
                ] else if (pinned.isNotEmpty)
                  _groupCard(pinned),
                // 고르는 중이면 메모가 하나도 안 남아도 이 줄은 남긴다.
                // 여기에 '삭제완료'가 달려 있어서, 이 줄이 사라지면 고르기
                // 상태에 갇힌다.
                if (rest.isNotEmpty || _picking)
                  _groupLabel(l.notesLabel,
                      // 고르는 중에는 안 붙인다 — 그때 이 줄은 '몇 개
                      // 골랐나'를 말하는 자리이지 동기화 자리가 아니다.
                      badge: _picking
                          ? null
                          : const SyncFreshLabel(size: 12.5),
                      leading: _picking ? _pickAllBtn(l, visible) : null,
                      trailing: _picking
                          ? _pickActions(l, visible)
                          : _sortFilterBtn(l, s)),
                // 광고를 어디에 놓는가 — 목록 길이에 따라 갈린다.
                //
                // 2026-08-17 소유자 지시: "목록이 긴 경우에 누가 맨 아래까지
                // 스크롤을 하겠어? 그럼 한 번도 목록에 배너를 보여주기
                // 힘들겠지."
                //
                // 맞는 말이고, 이건 광고 수익의 문제만이 아니다. **아무도
                // 안 보는 자리에 놓는 것은 광고를 안 놓은 것과 같으면서
                // 코드만 늘어난다.** 놓을 거면 보이는 자리에 놓아야 한다.
                //
                //   메모가 열 개 미만 — 맨 아래. 한 화면에서 몇 번만
                //     굴리면 끝까지 닿는다.
                //   메모가 열 개 이상 — 다섯째와 여섯째 사이. 목록을
                //     훑는 사람은 반드시 그 자리를 지난다.
                //
                // 고정된 메모는 셈에 안 넣는다. 그건 늘 맨 위에 붙어 있는
                // 몇 개라 '목록이 길다'의 근거가 못 된다.
                if (rest.length >= 10) ...[
                  _groupCard(rest.take(5).toList()),
                  // 카드와 카드 사이. 광고 판이 스스로 자르는 선과 다른
                  // 바탕색을 갖고 있어 여백은 조금이면 된다.
                  const SliverToBoxAdapter(
                      child: InlineAdBlock(gapAbove: 20, wide: true)),
                  _groupCard(rest.skip(5).toList()),
                ] else ...[
                  if (rest.isNotEmpty) _groupCard(rest),
                  // 맨 아래 광고는 **중간에 하나도 안 넣었을 때만** 놓는다.
                  // 한 화면에 큰 광고 둘은 앱이 아니라 광고판이다.
                  // 목록에서 두 줄쯤 떨어뜨린다 — 바짝 붙으면 광고가
                  // '목록의 다음 항목'처럼 보인다.
                  if (pinned.length < 10)
                    const SliverToBoxAdapter(
                        child: InlineAdBlock(gapAbove: 120)),
                ],
                // 2026-08-17 소유자 신고 — "목록 맨 아래 것이 버튼 두 개로
                // 우측이 가려진다." 떠 있는 단추 둘이 110보다 높다.
                // 떠 있는 단추(56)에 위아래 여백을 더한 높이.
                // 목록 맨 끝의 빈 칸. 104는 떠 있는 단추를 비켜 주는 값이고,
                // 거기에 물리키 자리를 더한다. 이걸 빼먹으면 마지막 메모가
                // 물리키 밑에 깔린다(2026-08-20 신고).
                SliverToBoxAdapter(
                    child: SizedBox(height: 104 + sysBottom(context))),
              ],
                      ),
                      ),
                    ),
                    // 떠 있는 유리 머리 — 목록이 이 밑으로 비쳐 흐른다.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: kHomeHeaderH,
                        child: Stack(children: [
                          // 편집 화면과 같은 유리(2026-08-27 소유자 지시 —
                          // "같은 유리로 맞추면 더 좋겠다").
                          //
                          // 그전까지 이 머리는 투명이었다. 목록 글자가
                          // 삼선·돋보기·톱니 뒤로 그대로 비쳐서, 굴릴 때마다
                          // 아이콘이 글자 위에서 헤엄쳤다. 두 화면의 머리가
                          // 서로 다른 재료면 그건 한 앱이 아니다.
                          const Positioned.fill(child: _HeadGlass()),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                            child: _searching
                                ? Row(children: [
                                    IconButton(
                                      icon: const Icon(
                                          CupertinoIcons.chevron_left,
                                          size: 22),
                                      tooltip: l.close,
                                      onPressed: () => setState(() {
                                        _searching = false;
                                        _searchCtl.clear();
                                        query = '';
                                      }),
                                    ),
                                    Expanded(
                                        child: TextField(
                                      controller: _searchCtl,
                                      autofocus: true,
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration(
                                        hintText: l.searchHint,
                                        filled: true,
                                        fillColor: context.c.field,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => query = v),
                                    )),
                                    const SizedBox(width: 8),
                                  ])
                                : Row(children: [
                                    // 2026-08-18 소유자 지시 — 왼쪽 끝에
                                    // 삼선, 오른쪽 끝에 톱니, 그 안쪽에
                                    // 돋보기.
                                    //
                                    // 양 끝만 쓰고 가운데를 비운다. 가운데가
                                    // 비면 그 밑으로 목록이 흘러가는 것이
                                    // 보이고, 머리가 뚜껑이 아니라 유리로
                                    // 읽힌다.
                                    //
                                    // 오른쪽 둘의 차례는 손에서 먼 순이다.
                                    // 톱니(한 번 정하고 안 여는 것)가 맨 끝,
                                    // 돋보기(가끔 쓰는 것)가 그 안쪽.
                                    _listMenu(l),
                                    const Spacer(),
                                    // 2026-08-27 — 당기기가 안 잡히는
                                    // 웹·맥을 위해 나란히 둔다. 자세한
                                    // 까닭은 SyncNowButton 머리말.
                                    const SyncNowButton(),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.search,
                                          size: 22),
                                      tooltip: l.searchHint,
                                      onPressed: () =>
                                          setState(() => _searching = true),
                                    ),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.gear_alt,
                                          size: 23),
                                      tooltip: l.menuAppSettings,
                                      onPressed: () async {
                                        await Navigator.push<void>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const SettingsScreen()));
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ]),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
      // 떠 있는 단추 둘 — 2026-08-18 소유자 지시로 글자를 떼고 양쪽
      // 아래 구석으로 갈랐다. "둘다 아이콘만 버튼에 두고 '정리' 같은
      // 말은 빼자. '정리' 아이콘은 하단 좌측에, '글쓰기'는 우측 하단에."
      //
      // 알약 두 개가 세로로 쌓여 있으면 목록의 오른쪽 아래가 통째로
      // 막힌다. 양쪽으로 가르면 가운데가 뚫려서 밑의 글이 보이고, 두
      // 단추가 서로 다른 일이라는 것도 자리만으로 읽힌다.
      //
      // 색으로 서열을 매긴다 — 정리는 채운 하늘, 글쓰기는 연한 하늘.
      // 종이색으로 낮추려던 앞의 시도는 단추를 아예 안 보이게 만들었다.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'paste',
              tooltip: l.pasteAndTidy,
              onPressed: _pasteAndTidy,
              child: const Icon(Icons.content_paste_go, size: 25),
            ),
            // 두 칸 화면(맥·윈도·아이패드 가로)에서는 안 그린다.
            // 오른쪽 편집 칸에 이미 같은 단추가 있다(2026-08-18 소유자 신고).
            if (!widget.embedded)
              FloatingActionButton(
                heroTag: 'new',
                tooltip: l.newNoteTooltip,
                backgroundColor: kAccentSoft,
                foregroundColor: kOnAccentSoft,
                onPressed: () async {
                  final note = Note.fresh();
                  store.notes.insert(0, note);
                  await store.persist();
                  if (!mounted) return;
                  openNote(context, note.id);
                },
                child: const Icon(CupertinoIcons.square_pencil, size: 24),
              ),
          ],
        ),
      ),
    );
  }

  /// 목록의 소제목. [trailing]을 주면 오른쪽 끝에 단추가 붙는다.
  ///
  /// 2026-08-17 소유자 지시로 정렬·필터가 '메모' 소제목 옆에 붙었다.
  /// 자기가 다루는 것 바로 위에 놓이면 무엇을 거르는 단추인지 자리만으로
  /// 알 수 있다.
  Widget _groupLabel(String label,
          {Widget? leading, Widget? trailing, Widget? badge}) =>
      SliverToBoxAdapter(
        child: Padding(
          // 애플 메모의 '고정된 메모' 헤더 실측: 글자높이 52px, 좌측 135px(45pt).
          // 제목 46px=17pt 비율로 환산하면 19.2pt → 애플 .title3(20pt) 굵게.
          // 색도 회색이 아니라 본문색이다.
          //
          // 단추가 붙는 쪽은 위아래 여백을 줄인다. 단추가 이미 자기 여백을
          // 가지고 있어서 그대로 두면 그 줄만 뚱뚱해 보인다.
          padding: EdgeInsets.fromLTRB(
              // 왼쪽에 단추가 붙으면 들여쓰기를 뗀다. 단추는 자기 여백을
              // 이미 갖고 있어서, 그대로 두면 이 줄만 오른쪽으로 밀린다.
              leading == null ? kListRowInset + 16 : 8,
              trailing == null ? 18 : 10,
              8,
              trailing == null ? 8 : 0),
          child: Row(children: [
            if (leading != null) leading,
            Expanded(
              child: Row(children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 10),
                  // 소제목은 크고 굵다. 그 옆에 붙는 것은 작고 옅어야
                  // 소제목을 안 밀어낸다 — 같이 커지면 둘 다 안 읽힌다.
                  Flexible(child: badge),
                ],
              ]),
            ),
            if (trailing != null) trailing,
          ]),
        ),
      );

  /// 목록 위의 폴더 줄.
  ///
  /// 2026-08-17 — 이걸 필터 시트 안에 넣지 않은 이유: 폴더는 '가끔 거르는
  /// 조건'이 아니라 **평소에 오가는 자리**다. 두 번 눌러야 닿는 곳에 두면
  /// 폴더를 만들어 놓고도 안 쓰게 된다.
  Widget _folderBar(L10n l, AppSettings s) {
    final names = folderNames(store.notes.map((n) => n.folder), s.folders);
    Widget chip(String label, bool on, VoidCallback tap) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // 라이트·다크가 같은 값이라 밝기를 따질 일이 없어졌다.
                color: on ? kAccentFill : context.c.field,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? kOnAccentFill : context.c.sub)),
            ),
          ),
        );
    // 2026-08-18 소유자 지시 — "폴더 위/아래 여백을 살짝 줘야할 것 같아.
    // 딱 붙어있는 것이 어색."
    //
    // 맞다. 이 줄은 위로 머리 단추와, 아래로 첫 노트 카드와 맞닿아 있었다.
    // 성격이 다른 셋이 이어져 붙어 있으면 하나로 읽힌다.
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          children: [
            chip(l.filterAll, s.filterFolder.isEmpty, () {
              setState(() => s.filterFolder = '');
              store.persistSettings();
            }),
            for (final f in names)
              chip(f, s.filterFolder == f, () {
                setState(() => s.filterFolder = s.filterFolder == f ? '' : f);
                store.persistSettings();
              }),
          ],
        ),
      ),
    );
  }

  /// 정렬·필터 단추.
  ///
  /// 뭔가 걸려 있으면 아이콘에 색이 들어가 "지금 목록이 전부가 아니다"를
  /// 알린다. 이게 없으면 사용자는 메모가 사라진 줄 안다.
  Widget _sortFilterBtn(L10n l, AppSettings s) => IconButton(
        icon: Icon(Icons.tune,
            color: (s.sortMode != 'updated' ||
                    s.filterSource.isNotEmpty ||
                    s.filterTag.isNotEmpty ||
                    s.filterFolder.isNotEmpty)
                ? context.c.accent
                : context.c.sub),
        tooltip: l.sortFilterTooltip,
        onPressed: () async {
          final r = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const SortFilterSheet(),
          );
          if (!mounted) return;
          // 시트가 'pick'을 들고 닫히면 여러 개 고르기로 들어간다.
          // 시트 안에서 바로 켜지 않고 여기까지 값을 들고 오는 이유:
          // 고르기 상태는 목록 화면의 것이지 시트의 것이 아니다.
          if (r == 'pick') {
            _startPicking();
          } else {
            setState(() {});
          }
        },
      );

  /// '메모' 소제목 왼쪽의 전체 선택. 누를 때마다 전체 선택 ↔ 전체 해제.
  ///
  /// 아이콘 하나로 두 가지 뜻을 나타내는 것이라, 지금 어느 쪽인지 **모양이
  /// 곧 말해 줘야** 한다. 다 골라져 있으면 꽉 찬 동그라미에 하늘색, 아니면
  /// 빈 동그라미에 회색이다. 글자로 '전체 선택/해제'라고 쓰지 않는 이유는
  /// 자리도 자리지만, 아홉 개 언어에서 그 두 낱말의 길이가 제각각이라
  /// 어느 언어에서는 이 줄이 무너지기 때문이다.
  Widget _pickAllBtn(L10n l, List<Note> visible) {
    final all =
        visible.isNotEmpty && visible.every((n) => _picked.contains(n.id));
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(all ? Icons.check_circle : Icons.radio_button_unchecked,
          color: all ? context.c.accent : context.c.sub),
      tooltip: l.selectAllTooltip,
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (all) {
            _picked.clear();
          } else {
            _picked
              ..clear()
              ..addAll(visible.map((n) => n.id));
          }
        });
      },
    );
  }

  /// '메모' 소제목 오른쪽의 [선택 삭제] [삭제완료].
  ///
  /// '선택 삭제'는 고른 것이 없으면 눌리지 않는다. 눌러 놓고 "0개를
  /// 지울까요?"를 묻는 것은 사람을 두 번 일하게 만드는 짓이다.
  ///
  /// '삭제완료'는 지운 뒤에만이 아니라 **고르기를 켠 순간부터** 있다.
  /// 잘못 눌러 들어왔는데 나갈 문이 없으면 그건 기능이 아니라 덫이다.
  Widget _pickActions(L10n l, List<Note> visible) {
    final n = visible.where((x) => _picked.contains(x.id)).length;
    final c = context.c;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: n == 0 ? null : () => _deletePicked(l, visible),
        child: Text(
          n == 0 ? l.deleteSelected : '${l.deleteSelected} $n',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: n == 0 ? c.sub : c.danger),
        ),
      ),
      TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _endPicking,
        child: Text(l.deleteSelectedDone,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  void _startPicking() {
    setState(() {
      _picking = true;
      _picked.clear();
    });
  }

  void _endPicking() {
    setState(() {
      _picking = false;
      _picked.clear();
    });
  }

  void _togglePick(Note n) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_picked.remove(n.id)) _picked.add(n.id);
    });
  }

  /// 고른 것을 한 번에 휴지통으로.
  ///
  /// [visible]과 교집합을 내는 것이 핵심이다. 고르는 도중에 검색어를 치면
  /// 화면에서 사라진 메모가 생기는데, 그것까지 지우면 사용자는 **자기가
  /// 지운 줄도 모르는 메모**를 잃는다. 지금 눈에 보이는 것만 지운다.
  Future<void> _deletePicked(L10n l, List<Note> visible) async {
    final ids = visible
        .where((n) => _picked.contains(n.id))
        .map((n) => n.id)
        .toList();
    if (ids.isEmpty) return;
    final ok = await confirmDialog(
      context,
      title: l.deleteSelectedConfirm,
      body: l.deleteSelectedBody(ids.length),
      okLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    store.deleteNotes(ids);
    setState(() => _picked.clear());
  }

  Widget _groupCard(List<Note> group) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: context.c.panel,
              child: Column(
                children: [
                  for (int i = 0; i < group.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, indent: kListRowInset, color: context.c.line),
                    _noteTile(group[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  String _listDate(L10n l, int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    String p(int x) => x.toString().padLeft(2, '0');
    if (diff == 0) return '${p(d.hour)}:${p(d.minute)}';
    if (diff == 1) return l.yesterday;
    return l.dateShort(d.year, d.month, d.day);
  }

  /// 길게 눌렀을 때 뜨는 미리보기 판.
  ///
  /// 2026-08-17 소유자 요청. 애플 메모의 그 화면을 그대로 본떴다 —
  /// 뒤가 흐려지고, 누른 메모만 카드로 떠오르고, 그 아래 할 수 있는 일이
  /// 붙는다.
  ///
  /// 왜 목록 화면에서 이게 필요한가: 지금은 메모 하나를 옮기거나 지우려면
  /// **열어야 한다.** 열면 방금 있던 자리를 잃는다. 목록에서 스무 개를
  /// 훑으며 정리하는 일은 그래서 스무 번 들어갔다 나오는 일이 된다.
  ///
  /// 스와이프(밀기)를 이미 두 방향 다 쓰고 있어 셋째 손짓을 넣을 자리가
  /// 없었다는 것도 이유다. 길게 누르기는 아직 비어 있었다.
  ///
  /// 애니메이션은 튕기지 않는다. 손가락이 던진 것이 아니라 제자리에서
  /// 떠오르는 것이라 되튐이 붙으면 값싸 보인다(애플 지침: 손짓이 힘을
  /// 실어 준 움직임에만 되튐을 준다).
  Future<void> _peek(Note n) async {
    final l = L10n.of(context);
    final c = context.c;
    // 길게 누르기는 '열지 않고 살짝 보는' 자리다. 잠근 메모를 여기서
    // 보여 주면 자물쇠를 옆문으로 지나가는 셈이 된다.
    final preview = peekBody(locked: n.locked, body: n.body);
    final head = listTitle(locked: n.locked, title: n.title, body: n.body);
    final title = head.isNotEmpty
        ? head.split('\n').first
        : l.untitled;

    // 아이콘은 앱의 하늘색을 쓴다. 소유자: "내 컬러 정체성이 스카이블루이니
    // 블루계통 컬러를 써줘."
    //
    // 다만 **삭제만 빨강으로 남긴다.** 소유자가 본보기로 보내 준 애플 메모의
    // 같은 화면에서도 삭제 하나만 빨갛다. 되돌릴 수 있는 일과 없는 일을 같은
    // 색으로 두면 손이 눈보다 먼저 움직인다. 색이 곧 잠깐 멈추게 하는 장치다.
    // (원하시면 이 하나도 파랑으로 바꾼다 — 다만 그러면 이 줄만 위험하다는
    // 신호가 사라진다.)
    Widget row(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: danger ? c.danger : null)),
              ),
              Icon(icon, size: 20, color: danger ? c.danger : c.accent),
            ]),
          ),
        );

    final act = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l.cancel,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, __, ___) {
        final media = MediaQuery.of(ctx);
        // Material로 감싸는 것이 **꼭 필요하다.**
        //
        // 2026-08-17 소유자 신고 — "롱 프레스하면 뜨는 것인데 노란색 밑줄이
        // 쳐지네. 그리고 빨간색 폰트."
        //
        // 그건 우리가 고른 색이 아니라 플러터가 켜 주는 **경고등**이다.
        // Text가 Material 안에 없으면 물려받을 글자 모양이 없고, 그때
        // 플러터는 '이건 잘못 놓인 글자다'라고 알리려고 빨간 글씨에 노란
        // 이중 밑줄을 그어 준다. 일부러 흉하게 만들어 눈에 띄게 한 것이다.
        //
        // showGeneralDialog는 showDialog와 달리 Material을 **안 씌워 준다.**
        // 그 차이를 모르고 썼다. 화면을 눈으로 보지 않고 코드만 보고 넘긴
        // 자국이 또 하나 나왔다.
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 미리보기 카드. 화면의 45%를 넘지 않는다 — 이건 '읽는
                  // 자리'가 아니라 '어느 메모인지 알아보는 자리'다.
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: media.size.height * 0.45),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.panel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3)),
                            const SizedBox(height: 8),
                            Text(
                              n.locked
                                  ? l.noteLocked
                                  : (preview.isEmpty ? l.bodyHint : preview),
                              maxLines: 14,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15, height: 1.45, color: c.sub),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: c.panel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      // 2026-08-18 소유자 지시 — 맨 위에 '출처·태그'.
                      // 누르면 그 줄이 펴진 채로 편집 화면이 열린다.
                      // 목록에서 길게 누른 사람은 '이 메모를 손보겠다'고
                      // 이미 말한 것이라, 열고 나서 메뉴를 또 열게 하면
                      // 문이 둘이다.
                      row(Icons.sell_outlined, l.metaTooltip,
                          () => Navigator.pop(ctx, 'meta')),
                      Divider(height: 1, color: c.line),
                      row(Icons.folder_outlined, l.folderTitle,
                          () => Navigator.pop(ctx, 'folder')),
                      Divider(height: 1, color: c.line),
                      row(n.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                          n.pinned ? l.unpinTooltip : l.pinTooltip,
                          () => Navigator.pop(ctx, 'pin')),
                      Divider(height: 1, color: c.line),
                      // '복제'는 뺐다(2026-08-18 소유자 지시). 이 앱에서
                      // 메모를 복제할 일은 거의 없는데, 다섯 줄짜리 시트의
                      // 다섯 중 하나를 차지하고 있었다.
                      row(n.locked ? Icons.lock_open : Icons.lock_outline,
                          n.locked ? l.noteUnlock : l.noteLock,
                          () => Navigator.pop(ctx, 'lock')),
                      row(Icons.ios_share, l.exportNote,
                          () => Navigator.pop(ctx, 'share')),
                      Divider(height: 1, color: c.line),
                      row(Icons.delete_outline, l.delete,
                          () => Navigator.pop(ctx, 'del'),
                          danger: true),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
      transitionBuilder: (_, a, __, child) {
        // 0.96에서 1.0으로. 되튐 없이(easeOutCubic) 제자리에서 떠오른다.
        final t = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(t),
              child: child),
        );
      },
    );
    if (act == null || !mounted) return;

    switch (act) {
      case 'lock':
        if (await toggleNoteLock(context, n) && mounted) setState(() {});
      case 'share':
        final ok = await ExportService.shareNote(n);
        if (!ok && mounted) _toast(context, L10n.of(context).exportFailed);
      case 'folder':
        await _moveToFolder(n);
      case 'pin':
        await _setPinned(n, !n.pinned);
      case 'meta':
        await openNote(context, n.id, showMeta: true);
      case 'del':
        final ok = await confirmDialog(context,
            title: L10n.of(context).deleteConfirmTitle,
            okLabel: L10n.of(context).delete,
            destructive: true);
        if (ok) {
          store.deleteNote(n.id);
          if (mounted) setState(() {});
        }
    }
  }

  /// 목록의 핀을 눌렀을 때. **묻고 나서** 푼다.
  ///
  /// 2026-08-18 소유자 지시.
  ///
  /// 왜 묻는가: 이 그림은 원래 **표시**였지 단추가 아니었다. 표시인 줄 알고
  /// 눌러 본 사람이 고정을 잃으면 그건 도움이 아니라 사고다.
  ///
  /// 그리고 다시 거는 길이 '길게 누르기'라 눈에 안 보인다. 그 길을 물음
  /// 안에 적어 둔다 — 되돌리는 법을 모르는 채로 무언가를 없애게 두면 안 된다.
  Future<void> _askUnpin(Note n) async {
    final l = L10n.of(context);
    final ok = await confirmDialog(context,
        title: l.unpinConfirmTitle,
        body: l.unpinConfirmBody,
        okLabel: l.unpinTooltip);
    if (!ok || !mounted) return;
    _setPinned(n, false);
  }

  /// 고정을 켜고 끄는 자리는 셋이다 — 밀기, 길게 누르기 시트, 핀 누르기.
  /// 한 군데로 모은다. 안 그러면 아래의 **시각 올리기**를 어느 하나에서
  /// 반드시 빠뜨린다(오늘 폴더에서 똑같은 사고를 겪었다).
  Future<void> _setPinned(Note n, bool on) async {
    n.pinned = on;
    // 2026-08-18 — 시각을 올린다.
    //
    // 안 올리면 다음 동기화에서 구름에 남아 있는 옛 판이 '더 늦게 고친 것'이
    // 되어 이긴다. 고정을 풀어도 다른 기기를 한 번 켜면 되살아난다. 폴더
    // 지우기에서 오늘 겪은 것과 같은 자리다.
    n.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await store.persist();
    ICloudSync.instance.scheduleUp();
    if (mounted) setState(() {});
  }

  /// 목록에서 바로 폴더를 옮긴다.
  ///
  /// 편집 화면에도 같은 것이 있지만(_pickFolder) 그쪽은 열려 있는 메모
  /// 하나를 상대한다. 여기서는 아무 메모나 받아야 해서 따로 둔다.
  Future<void> _moveToFolder(Note n) async {
    final l = L10n.of(context);
    final s = store.settings;
    final names = folderNames(store.notes.map((x) => x.folder), s.folders);

    Future<void> put(String f) async {
      n.folder = f;
      if (f.isNotEmpty && !s.folders.contains(f)) {
        s.folders.add(f);
        await store.persistSettings();
      }
      n.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await store.persist();
      if (!mounted) return;
      setState(() {});
      _toast(context, f.isEmpty ? l.folderCleared : l.folderMoved(f));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: sheet.c.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.folderTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_off_outlined, color: sheet.c.sub),
                title: Text(l.folderNone),
                trailing: n.folder.isEmpty
                    ? Icon(Icons.check, color: sheet.c.accent)
                    : null,
                onTap: () {
                  Navigator.pop(sheet);
                  put('');
                },
              ),
              for (final f in names)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.folder_outlined, color: sheet.c.sub),
                  title: Text(f),
                  trailing: n.folder == f
                      ? Icon(Icons.check, color: sheet.c.accent)
                      : null,
                  onTap: () {
                    Navigator.pop(sheet);
                    put(f);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteTile(Note n) {
    final l = L10n.of(context);
    final c = context.c;

    // 2026-08-18 소유자 지시 — "좌측 패널에서 메모 리스트 줄간격이 너무
    // 촘촘하다. 줄간격을 20% 늘려주고, 메모와 메모 간의 간격도 20~30%
    // 늘려줘. 지금은 너무 촘촘하고 빡빡하고 답답한 느낌이다."
    //
    // 폰 목록은 그대로 둔다. 그 행 높이(60.3pt)는 애플 메모를 픽셀로 재서
    // 맞춘 값이고, 폰에서는 목록이 화면 전부라 그 밀도가 맞다.
    //
    // 넓은 화면의 왼쪽 칸은 사정이 다르다. 폭이 320으로 묶여 있어 같은
    // 줄 높이라도 글이 더 빽빽해 보이고, 바로 옆에 본문이 훤히 펼쳐져
    // 있어 대비까지 붙는다. 같은 숫자가 자리에 따라 다르게 읽히는 것이라,
    // 폰과 같은 값을 고집하는 것이 오히려 일관성이 아니다.
    // 2026-08-19 — 베어를 기준으로 다시 맞췄다. 소유자: "제목 폰트가 너무
    // 큰 것 같아. 거기서부터 투박함이 느껴져."
    //
    // 크기를 줄이는 것만으로는 안 된다. 문제는 굵고 큰 글자를 좁은 줄에
    // 욱여넣은 것이었다 — 글자가 큰 게 아니라 **글자 둘레에 공기가
    // 없었다.** 그래서 크기를 한 눈금 내리고 줄 높이를 크게 늘렸다.
    //
    // 위계도 다시 세웠다. 크기 차이로 만들지 않고 굵기·색·자리로 만든다.
    // 제목(16 semibold 잉크) → 미리보기(15 보통 회색) → 날짜(13 회색).
    // 위에서 아래로 굵기와 색이 차례로 옅어진다. 그래서 작아도 또렷하다.
    final roomy = widget.embedded;
    final vPad = roomy ? 11.0 : 12.0;
    // 2026-08-18 소유자 지시 — 넓은 화면 왼쪽 칸에서는 본문 석 줄.
    //
    // 첫 줄 하나만 쓰던 것을 빈 줄을 걸러 한 문단으로 이어 붙인다.
    // 첫 줄만 쓰면 그 줄이 짧을 때(제목처럼 한 마디 적어 둔 경우)
    // 미리보기가 한 줄로 끝나 버려서, 석 줄을 내주고도 한 줄만 보인다.
    // 제목이 비면 이 줄이 제목 자리로 올라간다. 잠긴 메모에서는 빈
    // 문자열이 되고, 그래서 제목 줄이 저절로 '제목 없음'으로 떨어진다 —
    // **제목 줄로 본문이 새는** 가장 놓치기 쉬운 구멍이 여기서 막힌다.
    final firstLine = listPreview(locked: n.locked, body: n.body);

    // 두 칸 화면에서 지금 오른쪽에 열려 있는 메모인가.
    //
    // 2026-08-16 — 여태 표시가 없었다. 오른쪽에 글이 떠 있는데 왼쪽
    // 목록에서는 어느 것인지 알 수 없었다. 애플 메모·메일·파인더가
    // 전부 고른 줄을 칠해 주는 데는 까닭이 있다 — 목록과 본문이 같은
    // 화면에 있으면 '지금 이것'을 잇는 실이 있어야 한다.
    final shell = SplitShell.of(context);
    final selected = shell != null && shell.isWide && shell.openId == n.id;

    // 2026-08-16 소유자 요청 — "마우스 오버하거나 선택할 때 색을
    // 스카이블루로."
    //
    // 지금까지 회색이었던 것은 색을 고른 결과가 아니라 **안 골랐기
    // 때문**이다. 안 주면 머티리얼이 중성 회색을 쓴다. 이 앱은 같은
    // 자리를 세 번 겪었다 — 선택 블럭도, 버튼도, 여기도 전부 그랬다.
    //
    // 진하기는 넷을 다르게 준다. 얹었을 때 가장 옅고, 누르는 동안 조금
    // 진해지고, 손을 뗄 때 퍼지는 물결이 가장 진하다. 같은 값을 주면
    // 얹은 것과 누른 것이 구별되지 않아 '반응이 없다'로 느껴진다.
    final hover = c.accent.withValues(alpha: 0.08);
    final press = c.accent.withValues(alpha: 0.13);
    final splash = c.accent.withValues(alpha: 0.18);
    return Dismissible(
      key: ValueKey('dis-${n.id}'),
      // 고르는 중에는 밀기를 끈다. 체크 자리를 누르려다 손이 옆으로
      // 미끄러지면, 고르려던 메모가 그 자리에서 지워진다.
      direction:
          _picking ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        color: context.c.pin,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(n.pinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: context.c.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _setPinned(n, !n.pinned);
          return false;
        }
        final ok = await confirmDialog(context,
            title: L10n.of(context).deleteConfirmTitle,
            okLabel: L10n.of(context).delete,
            destructive: true);
        if (ok) store.deleteNote(n.id);
        return ok;
      },
      // 2026-08-14 소유자 요청: "목록도 메모 앱과 같은 스타일·글자 크기·글꼴로".
      //
      // 눈으로 맞추지 않고 아이폰 16(3x) 스크린샷을 픽셀로 쟀다.
      //             애플 메모      심플텍스트(전)
      //   제목 글자   46px          41px
      //   부제 글자   39px          34px
      //   행 피치    181px(60.3pt)  219px(73pt)
      //   글자 좌측  133px(44.3pt)   98px(32.7pt)
      // 제목 46px를 17pt로 환산(한글 글리프/em 비율 약 0.90)하면 제목 17 · 부제 15가
      // 나오고, 비율(46/41=1.12, 39/34=1.15)도 17/15 · 15/13과 맞아떨어진다.
      // 즉 심플텍스트는 글자가 작으면서 행은 오히려 더 높았다 —
      // 키울 것은 글자, 줄일 것은 행이다.
      //
      // ListTile을 쓰지 않는 이유가 둘 있다.
      //   1) ListTile은 높이를 정확히 못 잡는다. 60.3pt를 맞추려면 패딩을 직접 준다.
      //   2) ListTile을 색 있는 Container 안에 넣으면 프레임워크가
      //      "ink splashes may be invisible" assertion을 던진다(디버그에서 실제로 떴다).
      //      Material을 직접 두면 그 경고가 사라지고 누를 때 반응도 제대로 보인다.
      // 글꼴은 지정하지 않는다 — 기기 시스템 글꼴을 그대로 쓴다(테마의 한글 폴백만 적용).
      // 숫자를 바꿀 일이 생기면 시뮬레이터 스크린샷을 다시 재고 바꿀 것.
      child: Material(
        // 고른 줄은 아예 칠한다. 반투명을 그대로 얹지 않고 미리 섞어
        // 두는 이유: 이 위에 물결이 또 얹히면 두 겹이 겹쳐 탁해진다.
        // 고른 줄도 열린 줄과 같은 칠을 쓴다. 체크 표시 하나로는 스무 줄
        // 가운데 무엇이 골라졌는지 훑어보기 어렵다 — 줄 전체가 물들어야
        // 한눈에 센다.
        color: (selected || (_picking && _picked.contains(n.id)))
            ? Color.alphaBlend(c.accent.withValues(alpha: 0.16), c.panel)
            : c.panel,
        child: InkWell(
          onTap: () {
            if (_picking) {
              _togglePick(n);
            } else {
              openNote(context, n.id);
            }
          },
          // 2026-08-17 소유자 요청 — "애플 메모장처럼 메모 리스트에서 메모
          // 하나를 오래 롱 프레스 누르면 메모의 일부를 보여주고, 할 수 있는
          // 기능들을 할 수 있게 해줘."
          // 고르는 중에는 길게 누르기도 끈다. 미리보기 판이 떠 버리면
          // 고르던 흐름이 끊긴다.
          onLongPress: _picking
              ? null
              : () {
                  // 손끝에 한 번 걸리는 느낌. 길게 누른 것이 먹혔다는
                  // 신호를 화면보다 먼저 준다.
                  HapticFeedback.mediumImpact();
                  _peek(n);
                },
          // 2026-08-18 소유자 지시 — 맥·윈도에서 오른쪽 단추.
          //
          // 마우스를 쓰는 사람에게 '길게 누르기'는 없는 동작이다. 손가락이
          // 하는 일에는 손가락의 문이, 마우스가 하는 일에는 마우스의 문이
          // 있어야 한다 — 같은 방으로 가는 문 둘이다.
          //
          // 그래서 여기서도 _peek 을 그대로 부른다. 다른 화면을 띄우면
          // 두 문이 다른 방으로 가는 것이라, 맥에서 배운 것이 아이폰에서
          // 안 통하게 된다. 진동은 안 준다 — 마우스에는 손끝이 없다.
          onSecondaryTap: _picking ? null : () => _peek(n),
          hoverColor: hover,
          focusColor: hover,
          highlightColor: press,
          splashColor: splash,
          child: Padding(
            // 데스크톱은 애플 메모장처럼 행을 촘촘하게(글자만 줄면 행이 뚱뚱해 보인다).
          padding: EdgeInsets.fromLTRB(kListRowInset, vPad, 16, vPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_picking)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Icon(
                      _picked.contains(n.id)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 22,
                      color: _picked.contains(n.id) ? c.accent : c.sub,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title.isNotEmpty
                            ? n.title
                            : (firstLine.isNotEmpty ? firstLine : l.untitled),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            letterSpacing: -0.2),
                      ),
                      // 미리보기를 두 줄로 편다. 한 줄이면 어차피 잘리는데,
                      // 잘린 한 줄은 '이 글이 무엇인가'를 거의 못 알려 준다.
                      // 두 줄이면 대개 첫 문장이 끝까지 보인다.
                      // 잠긴 메모는 본문 자리에 자물쇠 한 줄만 놓는다.
                      // 빈 자리로 두면 '내용이 없는 메모'로 보인다 — 가린
                      // 것과 없는 것은 다른 말이라 그렇게 보이면 안 된다.
                      if (n.locked) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.lock_outline,
                              size: 14, color: context.c.sub),
                          const SizedBox(width: 5),
                          Text(l.noteLocked,
                              style: TextStyle(
                                  fontSize: 14, color: context.c.sub)),
                        ]),
                      ] else if (firstLine.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(firstLine,
                            // 폰은 둘, 넓은 화면 왼쪽 칸은 셋. 폰에서는
                            // 목록이 화면 전부라 한 화면에 몇 개가 보이느냐가
                            // 더 중요하고, 왼쪽 칸에서는 옆에 본문이 이미
                            // 펼쳐져 있어 '어느 것인지 고르는 일'만 남는다.
                            maxLines: roomy ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.42,
                                color: context.c.sub)),
                      ],
                      // 날짜는 맨 아래 제 줄에. 미리보기 옆에 붙어 있으면
                      // 성격이 다른 둘이 같은 크기 같은 색으로 나란히 서서,
                      // 눈이 어디부터 읽을지 정하지 못한다.
                      const SizedBox(height: 5),
                      Text(_listDate(l, n.updatedAt),
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              color: context.c.sub)),
                    ],
                  ),
                ),
                if (n.pinned)
                  // 2026-08-18 소유자 지시 — 핀을 하늘색으로, 그리고 눌러서
                  // 풀 수 있게.
                  //
                  // 색: 노랑은 이 앱에서 **이 한 자리에만** 쓰이던 색이었다.
                  // 색이 하나 더 있으면 그 색을 볼 때마다 '이건 무슨 뜻이지'를
                  // 한 번 묻게 된다. 하늘색은 이미 '지금 이것'을 뜻한다.
                  //
                  // 손이 닿는 자리를 그림보다 넓게 잡는다. 17픽셀짜리 그림을
                  // 정확히 집으라는 요구는 손가락에게 무리다.
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _askUnpin(n),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                      child: Icon(Icons.push_pin,
                          size: 17, color: context.c.accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- 에디터 ----------------
class EditorScreen extends StatefulWidget {
  final String noteId;
  final bool autoTidy;

  /// 열자마자 제목·태그·출처 줄을 펴 놓는가.
  ///
  /// 2026-08-18 소유자 지시 — 목록에서 길게 눌러 '출처·태그'를 고르면
  /// 그 줄이 이미 펴진 채로 열린다. 열고 나서 메뉴를 한 번 더 여는
  /// 것은 '거기로 가겠다'고 말한 사람에게 문을 하나 더 세우는 짓이다.
  final bool showMeta;

  /// 두 칸 화면의 오른쪽에 들어가 있는가. 그렇다면 뒤로가기 화살표를 안
  /// 그린다 — 돌아갈 화면이 없다. 목록이 이미 왼쪽에 있다.
  final bool embedded;

  const EditorScreen({
    super.key,
    required this.noteId,
    this.autoTidy = false,
    this.showMeta = false,
    this.embedded = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver, _ScrollTopOnStatusBarTap {
  /// 본문은 스스로 구르지 않고 바깥 스크롤을 쓴다(아래 _bodyScroll 주석).
  /// 맨 위로 올릴 것도 그것이다.
  @override
  ScrollController? get topScroller => _bodyScroll;

  final store = Store.instance;
  late Note note;
  late TextEditingController titleCtl;
  // 본문은 표·코드 구간만 등폭으로 그려야 해서 전용 컨트롤러를 쓴다.
  late MonoTextController bodyCtl;
  late TextEditingController tagsCtl;
  bool _found = true;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();
  final FocusNode _tagsFocus = FocusNode();
  bool _showMeta = false;
  final UndoHistoryController _undoCtl = UndoHistoryController();

  bool get _editing => _titleFocus.hasFocus || _bodyFocus.hasFocus || _tagsFocus.hasFocus;

  /// 커서 위치에 삽입, 선택 영역이 있으면 감싼다
  /// 고른 줄들을 목록으로 만든다.
  ///
  /// 2026-08-17 소유자 지시 — "제일 필요한 구분점 목록, 대시 목록, 번호
  /// 목록 이 3가지가 필요하다. 이것은 블록 안 씌웠을 때도 필요하고, 블록을
  /// 씌운 부분도 줄바꿈 되어 있다면 이 3가지 중 하나로 처리해 줘야 한다."
  ///
  /// 한 가지 일만 한다.
  ///   - 블록이 없으면 커서가 있는 그 줄에
  ///   - 블록이 여러 줄에 걸쳐 있으면 걸친 줄 전부에
  ///   - 이미 같은 표시가 붙어 있으면 뗀다
  ///
  /// 줄 가운데를 골라도 그 줄 전체가 대상이다. 목록은 줄 단위의 것이지
  /// 글자 단위의 것이 아니다 — 반쪽만 목록이 되는 일은 아무도 원하지 않는다.
  /// 붙여넣기를 알아채고 출처를 찍는다.
  ///
  /// 2026-08-17 소유자 신고 — "여러 LLM의 답변을 붙여넣기 해 봤더니 출처
  /// 분석을 자동으로 하나도 못하네?"
  ///
  /// 열어 보니 출처를 알아내는 자리가 목록 화면의 '붙여넣고 정리' 하나뿐
  /// 이었다. 새 문서를 만든 뒤 여기서 그냥 붙여넣으면 **검사 자체가 안
  /// 돌았다.** 기능이 약한 게 아니라 없는 자리에서 찾고 있었다.
  ///
  /// 한 번에 [_pasteMin]자 넘게 늘어나면 사람이 친 게 아니라 붙여넣은
  /// 것이다. 아무리 빨리 쳐도 한 번의 변화로 그만큼 늘어나지 않는다.
  static const int _pasteMin = 140;

  /// 직전 본문. 얼마나 늘었는지 재려면 있어야 한다.
  String _lastBody = '';

  void _onBodyChanged(String v) {
    final before = _lastBody;
    _lastBody = v;
    _save();

    if (v.length - before.length < _pasteMin) return;
    // 이미 정해진 출처는 안 건드린다. 사람이 고른 것을 덮으면 최악이다.
    if (note.source.isNotEmpty) return;

    // 새로 들어온 덩이만 본다. 이미 있던 글이 섞이면 그쪽 생김새가
    // 판정을 끌고 간다.
    final chunk = insertedChunk(before, v);
    unawaited(_stampSource(chunk.length >= _pasteMin ? chunk : v));
  }

  /// 붙여넣은 글의 출처를 찍는다.
  ///
  /// 2026-08-27 — **여기에 1단이 없었다.** 목록에서 '붙여넣고 정리'를
  /// 누르는 길에만 클립보드 증거를 물었고, 편집 화면에 그냥 붙여넣는
  /// 길에서는 글의 생김새로만 찍고 있었다. 그런데 사람이 훨씬 자주 쓰는
  /// 것은 이쪽이다. 소유자가 "디텍팅이 거의 안 된다"고 한 까닭의 절반이
  /// 이 빠뜨림이었다.
  ///
  /// 증거를 먼저 묻고, 없을 때만 생김새로 찍는다. 증거는 늙지 않지만
  /// 문체는 프롬프트 한 줄로 바뀐다.
  /// 붙여넣기의 **지문만** 남긴다. 기기 안에만 쌓이고 동기화를 안 탄다.
  ///
  /// 2026-08-27 밤 — 지문표가 짐작이라 제미나이·챗지피티를 놓치고 있다.
  /// 무엇이 맞는지 알려면 실제로 오는 것을 봐야 한다. 최근 여덟 번만
  /// 남긴다. 담는 것은 클래스 이름·id·data-* 이름·호스트뿐이고 글자는
  /// 한 자도 안 담는다(core/capture_sig.dart).
  static Future<void> _recordCaptureSig(String? capture) async {
    try {
      final sig = captureSignature(capture);
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getStringList('captureSigs') ?? const <String>[];
      final at = DateTime.now().toIso8601String().substring(0, 19);
      final next = <String>['$at $sig', ...old].take(8).toList();
      await prefs.setStringList('captureSigs', next);
    } catch (_) {
      // 실험 도구다. 실패해도 붙여넣기를 막지 않는다.
    }
  }

  Future<void> _stampSource(String text) async {
    // 붙여넣은 사실은 출처를 몰라도 남긴다.
    //
    // 2026-08-27 저녁 실측에서 드러난 버그다. 전에는 출처를 못 찾으면
    // 여기서 곧장 돌아갔고, 그래서 **pastedAt 도 안 찍혔다.** 붙여넣은
    // 사실과 어디서 왔는지는 별개인데 하나로 묶여 있었다. 신선도 경고
    // (isStale)가 pastedAt 에 달려 있으므로, 출처를 모르는 글은 영영
    // 낡지 않는 글이 되어 있었다.
    if (note.pastedAt == 0) {
      note.pastedAt = DateTime.now().millisecondsSinceEpoch;
    }

    // 1단 — 복사 순간의 증거. 2단 — 본문에 박힌 링크.
    //
    // 생김새로 찍는 3단(guessSource)은 이제 안 부른다. 까닭은 그 함수의
    // 머리말에 실측과 함께 적어 두었다 — 다섯 중 둘을 틀렸고 둘 다 같은
    // 이름으로 갔다.
    final capture = await ClipboardSource.read();
    unawaited(_recordCaptureSig(capture));
    var g = sourceFromCapture(capture);
    if (!g.isKnown) g = sourceFromBody(text);
    if (!g.isKnown) {
      await _save();
      return;
    }
    // 이 사이에 사람이 손으로 골랐을 수도 있다. 다시 한 번 본다.
    if (note.source.isNotEmpty) {
      await _save();
      return;
    }

    note.source = g.name;
    note.sourceAuto = !g.certain;
    await _save();
    if (!mounted) return;
    setState(() {});
    // 조용히 채워 넣으면 사용자는 자기가 고른 줄 안다.
    _toast(context, L10n.of(context).sourceDetected(g.name));
  }

  /// 글 사이에 구분선 한 줄.
  ///
  /// 2026-08-17 소유자 요청 — "편집 툴바 기능에 '구분선'을 추가해줘."
  ///
  /// 마크다운의 `---`가 아니라 진짜 선을 긋는다. 이 앱이 만드는 것은
  /// **사람이 그대로 읽는 글**이다. 카톡이나 메일에 붙였을 때 `---`는
  /// 하이픈 세 개로 보이고 이것은 선으로 보인다.
  ///
  /// 정리 엔진은 이 줄도 구분선으로 알아본다(같은 정규식에 걸린다).
  /// 그래서 설정의 '구분선' 항목을 그대로 따르고, 글 맨 위나 맨 아래에
  /// 홀로 남으면 정리할 때 걷힌다 — 내용이 없는 자리이기 때문이다.
  static const String kDividerLine = '──────────';

  void _insertDivider() {
    final t = bodyCtl.text;
    final sel = bodyCtl.selection;
    final at = sel.isValid ? sel.end : t.length;
    final before = t.substring(0, at);
    final after = t.substring(at);
    // 줄 한가운데에서 눌러도 구분선은 제 줄을 갖는다. 글자 사이에 선이
    // 끼어드는 것은 아무도 원하지 않는다.
    final head = (before.isEmpty || before.endsWith('\n')) ? '' : '\n';
    final tail = after.startsWith('\n') ? '\n' : '\n\n';
    final ins = '$head$kDividerLine$tail';
    bodyCtl.value = TextEditingValue(
      text: before + ins + after,
      selection: TextSelection.collapsed(offset: at + ins.length),
    );
    _save();
  }

  void _makeList(String kind) {
    final t = bodyCtl.text;
    final sel = bodyCtl.selection;
    final at = sel.isValid ? sel : TextSelection.collapsed(offset: t.length);
    final (a, e) = lineSpan(t, at.start, at.end);
    // pad: 2 — 소유자 지시(2026-08-27). 목록은 본문보다 한 칸 안으로.
    final made = listify(t.substring(a, e),
        kind: kind, bullet: dotBullet(store.settings.bulletChar), pad: 2);
    bodyCtl.value = TextEditingValue(
      text: t.replaceRange(a, e, made),
      // 손댄 곳을 그대로 잡아 둔다. 커서가 엉뚱한 데로 튀면 다음 버튼을
      // 누를 때 다른 줄이 걸린다.
      selection: TextSelection(baseOffset: a, extentOffset: a + made.length),
    );
    HapticFeedback.selectionClick();
    _save();
  }

  /// 커서가 할 일 네모 위에 있으면 켜고 끈다.
  ///
  /// 그리는 규칙과 **같은 함수**(core/rich_spans.dart 의 todoAt)를 쓴다.
  /// 둘이 다른 셈을 쓰면 보이는 네모와 눌리는 자리가 어긋난다.
  void _toggleTodoAtCaret() {
    final sel = bodyCtl.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    final off = sel.baseOffset;
    final t = bodyCtl.text;
    if (off < 0 || off > t.length) return;

    var ls = off > 0 ? t.lastIndexOf('\n', off - 1) : -1;
    ls = ls < 0 ? 0 : ls + 1;

    final f = todoAt(t, ls);
    if (f == null) return;
    // 네모 언저리를 눌렀을 때만. 줄 뒤쪽을 눌러 커서를 옮기려던 것까지
    // 켜 버리면, 글을 고치려다 할 일이 끝난 것이 된다.
    if (off < f.markStart || off > f.markStart + 5) return;

    final now = f.done ? ' ' : 'x';
    bodyCtl.value = TextEditingValue(
      text: t.replaceRange(f.boxAt, f.boxAt + 1, now),
      selection: TextSelection.collapsed(offset: off),
    );
    HapticFeedback.selectionClick();
    _save();
  }

  Widget _kbBtn({String? glyph, IconData? icon, required VoidCallback onTap, String? tip}) {
    final child = glyph != null
        ? Text(glyph, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1))
        : Icon(icon, size: 20);
    return Tooltip(
      message: tip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  /// 아래 도구 막대의 버튼 하나.
  ///
  /// 2026-08-12 — 전에는 글자만 있는 버튼 6개를 Expanded로 6등분했다. 폰 화면에서
  /// 6분의 1은 "되돌리기"가 들어가기에 좁아서 글자가 두 줄로 깨졌다(실제 화면에서 확인).
  /// 아이콘을 위에 두고 글자를 작게 내리면 아이폰 도구 막대의 일반적인 모양이 되고,
  /// 글자가 짧아져 깨지지도 않는다. 그래도 넘칠 때를 대비해 한 줄로 줄여 맞춘다.
  /// 소프트 키보드가 없는 판인가.
  ///
  /// dart:io의 Platform 대신 defaultTargetPlatform을 쓴다. 테스트에서
  /// debugDefaultTargetPlatformOverride로 갈아 끼울 수 있어야 배치를
  /// 테스트로 고정할 수 있고, 웹으로 빌드해도 깨지지 않는다.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// 문자 입력 도구 막대(되돌리기·괄호·따옴표·커서 이동 등).
  ///
  /// 2026-08-14 소유자 요청 — 맥/PC에서는 이 막대를 위로 올리고 기능
  /// 탭바(정리·마법사·표·찾기·복사·되돌리기)를 아래에 항상 고정한다.
  ///
  /// 왜 갈렸나: 휴대폰에서 이 막대는 '키보드 위에 붙는 보조 막대'다.
  /// 그래서 본문에 커서가 있으면 기능 탭바 자리를 차지하는 게 맞다.
  /// 그런데 데스크톱에는 올라올 키보드가 없다. 그 결과 맥에서는 글을
  /// 쓰기 시작하는 순간 기능 탭바가 통째로 사라져 버렸다 — 정리 버튼을
  /// 누르려면 본문 밖을 한 번 눌러 포커스를 풀어야 했다.
  /// 본문 위에 놓는 날짜·시각 한 줄.
  ///
  /// 2026-08-16 소유자 신고 — "편집 화면 위가 너무 딱 붙었다. 조금 여유있게
  /// 띄어줘. 메모앱처럼. 그리고 상단에 현재 시각을 메모앱처럼 자동 기재."
  ///
  /// 애플 메모를 보면 본문 위 가운데에 날짜·시각이 옅게 한 줄 있고, 그
  /// 위아래 여백이 화면을 열어 준다. 여백만 넣으면 빈칸이고, 글자만 넣으면
  /// 또 답답하다 — 둘이 한 벌이라서 같이 넣는다.
  ///
  /// 찍는 값은 이 메모의 마지막 수정 시각이다. 쓰는 동안에는 저장될 때마다
  /// 따라 올라가니 사실상 '지금'이 되고, 나중에 열면 언제 손댔는지가 남는다.
  /// 새 메모를 열자마자 '지금'이 박히는 것도 애플 메모와 같다.
  ///
  /// 12시간제/24시간제는 언어가 아니라 기기 설정을 따른다(맥 캡처가 17:53로
  /// 나온 이유). MediaQuery가 그 설정을 그대로 넘겨 준다.

  // ── 첨부 ────────────────────────────────────────────────────────
  //
  // 2026-08-19 소유자 확정(HANDOVER 8-2절). 알맹이는 이 기기 안에만 있고
  // 클라우드로 안 나간다. 다른 기기에는 "여기 뭐가 붙어 있다"고 알려만 준다.

  /// 이 기기에 실제로 있는 첨부의 파일 자리. 아이디 → 파일.
  ///
  /// 화면을 그릴 때마다 디스크를 묻지 않기 위해 한 번 찾아 들고 있는다.
  /// 값이 null 인 아이디는 '찾아봤는데 없더라'는 뜻이고, 아예 없는 아이디는
  /// '아직 안 찾아봤다'는 뜻이다 — 이 둘은 다르다.
  final Map<String, File?> _attachFiles = {};

  /// 이 기기를 뭐라고 부를 것인가.
  ///
  /// 진짜 기기 이름('성동의 아이폰')을 안 쓴다. 애플이 개인정보로 막아 뒀고,
  /// 막지 않았더라도 그 이름은 동기화 파일에 실려 클라우드로 나간다.
  ///
  /// 아이패드와 아이폰은 코드로 갈리지 않아서 화면 크기로 가른다. 600은
  /// 머티리얼이 '작은 화면'과 '큰 화면'을 가르는 값이다.
  String get _deviceKind {
    final k = AttachStore.deviceKind;
    if (k != 'iphone') return k;
    return MediaQuery.sizeOf(context).shortestSide >= 600 ? 'ipad' : 'iphone';
  }

  Future<void> _loadAttachFiles() async {
    for (final a in note.attachments) {
      if (_attachFiles.containsKey(a.id)) continue;
      _attachFiles[a.id] = await AttachStore.fileOf(note.id, a);
      if (mounted) setState(() {});
    }
  }

  Future<void> _addAttachment() async {
    final l = L10n.of(context);
    final dev = _deviceKind;
    try {
      final picked = await openFiles();
      if (picked.isEmpty || !mounted) return;
      var added = 0;
      for (final x in picked) {
        // 아이디는 시각 + 셈으로 짓는다. 같은 밀리초에 여럿을 고르면
        // 시각만으로는 겹친다 — 겹치면 앞의 파일을 덮어쓴다.
        final id = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
            '${note.attachments.length + added}';
        final meta = await AttachStore.add(
          noteId: note.id,
          name: x.name,
          bytes: x.openRead(),
          device: dev,
          id: id,
        );
        if (meta == null) continue;
        note.attachments.add(meta);
        _attachFiles[meta.id] = await AttachStore.fileOf(note.id, meta);
        added++;
      }
      if (added == 0) {
        if (mounted) _toast(context, l.attachFailed);
        return;
      }
      note.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await store.persist();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _toast(context, l.attachFailed);
    }
  }

  Future<void> _openAttachment(Attach a) async {
    final l = L10n.of(context);
    final f = _attachFiles[a.id];
    if (f == null) {
      // 다른 기기에서 붙인 것. 여기엔 알맹이가 없다.
      _toast(context, l.attachNotHere);
      return;
    }
    if (attachShowsThumb(a.name)) {
      // 그림은 앱 안에서 바로 펼친다. 공유 시트로 내보내면 '보려고 눌렀는데
      // 남에게 보내는 화면'이 뜬다.
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        builder: (ctx) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: Image.file(f, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 44,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ]),
        ),
      );
      return;
    }
    // 그 밖은 시스템에 넘긴다. 미리보기·다른 앱으로 열기·저장이 거기 다 있다
    // — 우리가 뷰어를 만들면 그중 하나만 되는 더 나쁜 물건이 된다.
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
    } catch (_) {
      if (mounted) _toast(context, l.attachFailed);
    }
  }

  Future<void> _removeAttachment(Attach a) async {
    final l = L10n.of(context);
    final ok = await confirmDialog(context,
        title: l.attachRemove,
        body: l.attachRemoveBody,
        okLabel: l.delete,
        destructive: true);
    if (!ok || !mounted) return;
    await AttachStore.remove(note.id, a);
    note.attachments.removeWhere((x) => x.id == a.id);
    _attachFiles.remove(a.id);
    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await store.persist();
    if (mounted) setState(() {});
  }

  Widget _attachStrip(L10n l) {
    final c = context.c;
    final mine = note.attachments.where((a) => a.device == _deviceKind).toList();
    final others = groupOthers(note.attachments, _deviceKind);

    Widget chip(Attach a) {
      final f = _attachFiles[a.id];
      final img = attachShowsThumb(a.name) && f != null;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: c.panel,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openAttachment(a),
            onLongPress: () => _removeAttachment(a),
            onSecondaryTap: () => _removeAttachment(a),
            child: Padding(
              padding: EdgeInsets.fromLTRB(img ? 5 : 10, 5, 10, 5),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (img)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(f,
                        width: 30, height: 30, fit: BoxFit.cover,
                        // 파일이 그 사이 사라졌으면 그림 대신 종이 모양.
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.description_outlined,
                                size: 20, color: c.sub)),
                  )
                else
                  Icon(_attachIcon(a.name), size: 20, color: c.accent),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shortName(a.name),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(humanSize(a.size),
                        style: TextStyle(fontSize: 11, color: c.sub)),
                  ],
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mine.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final a in mine) chip(a)]),
            ),
          // 다른 기기에서 붙인 것은 기기 하나에 한 줄. 파일마다 한 줄이면
          // 다섯 개를 붙인 사람의 화면이 안내문으로 덮인다.
          for (final e in others.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 6),
                  child: Icon(CupertinoIcons.paperclip, size: 13, color: c.sub),
                ),
                Expanded(
                  child: Text(
                    l.attachOther(
                      l.deviceName(e.key),
                      othersSummary(e.value, l.attachAndMore(e.value.length - 1)),
                    ),
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: c.sub),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  IconData _attachIcon(String name) {
    switch (attachKind(name)) {
      case kAttachPdf:
        return CupertinoIcons.doc_richtext;
      case kAttachDoc:
        return CupertinoIcons.doc_text;
      case kAttachSheet:
        return CupertinoIcons.table;
      case kAttachSlide:
        return CupertinoIcons.rectangle_on_rectangle;
      case kAttachAudio:
        return CupertinoIcons.waveform;
      case kAttachVideo:
        return CupertinoIcons.play_rectangle;
      case kAttachArchive:
        return CupertinoIcons.archivebox;
      case kAttachText:
        return CupertinoIcons.doc_plaintext;
      default:
        return CupertinoIcons.doc;
    }
  }

  /// 종이 머리에 적을 날짜 한 줄. 화면의 날짜 줄과 같은 규칙을 쓰되
  /// 위젯이 아니라 글자를 돌려준다 — 종이에는 시계 설정이 없으니 24시간제로.
  String _pdfDate(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final tag = Localizations.localeOf(context).toLanguageTag();
    try {
      return '${DateFormat.yMMMMd(tag).format(t)}  ${DateFormat.Hm(tag).format(t)}';
    } catch (_) {
      return '${DateFormat.yMMMMd().format(t)}  ${DateFormat.Hm().format(t)}';
    }
  }

  Widget _dateLine(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final h24 = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true;
    String text;
    try {
      final d = DateFormat.yMMMMd(tag).format(t);
      final hm = (h24 ? DateFormat.Hm(tag) : DateFormat.jm(tag)).format(t);
      text = '$d  $hm';
    } catch (_) {
      // 자료가 없는 로케일이면 형식만 기본으로 떨어뜨린다. 화면을 비우지 않는다.
      text = '${DateFormat.yMMMMd().format(t)}  ${DateFormat.Hm().format(t)}';
    }
    // 2026-08-16 — 붙여넣은 글이면 '언제 어디서 왔는지'를 같이 적는다.
    // 이게 이 앱이 다른 노트앱과 갈리는 자리다. 저쪽에서 메모는 그냥
    // 글자지만, 우리에게 메모는 출처와 시각이 붙은 AI 답변이다.
    final n = _note;
    final l = L10n.of(context);
    // 2026-08-17 소유자 지시 — 여기 "…에서 …일에 가져옴"을 붙이고 있었다.
    // 뺐다.
    //
    // 날짜 줄은 **글 바로 위에 늘 떠 있는 자리**다. 거기 있는 것은 글을
    // 읽을 때마다 눈에 들어온다. 그러니 거기 놓을 것은 '늘 알고 싶은 것'
    // 이어야 한다.
    //
    // '언제 쓴 글인가'는 늘 알고 싶다. '어디서 가져왔고 그게 추정인가'는
    // 궁금할 때만 궁금하다. 게다가 '(추정)'은 우리가 확신 없다는 고백인데,
    // 그 고백을 글 위에 늘 붙여 놓으면 읽는 내내 거슬린다.
    //
    // 출처를 버리는 것은 아니다. 태그 단추를 누르면 나오는 자리에 그대로
    // 있고 고르고 고칠 수도 있다.

    // 낡은 답에는 한 줄 붙인다. AI 답변은 썩는다 — 모델이 바뀌면 석 달 전
    // 답이 틀린 답이 된다. 직접 쓴 글에는 절대 안 붙인다(잔소리가 된다).
    final stale = n != null &&
        isStale(
            pastedAt: n.pastedAt,
            nowMs: DateTime.now().millisecondsSinceEpoch);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 수정 시각 옆에 '최근 업데이트' — 2026-08-27 소유자 요청.
          // 가운데 정렬을 지키려고 Row 를 min 으로 두고 감쌌다.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.c.sub,
                  ),
                ),
              ),
              const _FreshDot(),
            ],
          ),
          if (stale) ...[
            const SizedBox(height: 6),
            Text(
              l.staleWarn(daysSincePaste(
                  pastedAt: n.pastedAt,
                  nowMs: DateTime.now().millisecondsSinceEpoch)),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, height: 1.35, color: context.c.warnInk),
            ),
          ],
        ],
      ),
    );
  }

  /// 지금 보고 있는 메모. 날짜 줄에서 쓴다.
  Note? get _note {
    for (final n in store.notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
  }

  /// 본문 칸의 스크롤. 종이 줄을 글과 같이 움직이게 하려고 잡는다.
  ///
  /// 글 칸은 안에서 따로 스크롤한다. 배경을 가만히 두면 글만 올라가고
  /// 줄은 제자리라 첫 줄부터 어긋난다 — 종이처럼 안 보이는 가장 흔한
  /// 실패다. 그래서 스크롤 값을 받아 배경을 같은 만큼 밀어 준다.
  final ScrollController _bodyScroll = ScrollController();

  /// 날짜 줄의 높이.
  ///
  /// 2026-08-17 소유자 지시 — "본문 맨 위의 날짜 시간 표시는 고정하지 말고
  /// 스크롤되는 본문과 같이 스크롤되게 해라."
  ///
  /// 옳다. 그 줄은 '늘 봐야 하는 것'이 아니라 '한 번 보면 되는 것'이다.
  /// 늘 떠 있으면 글을 읽는 내내 화면 한 줄을 먹는다.
  ///
  /// 다만 옮기고 나면 셈해야 할 것이 둘 생긴다.
  ///   1) 종이 줄 — 첫 글줄이 화면 맨 위가 아니라 이 머리 아래에서
  ///      시작하므로, 줄도 그만큼 내려 그어야 글자와 맞는다.
  ///   2) 글 끝 아래의 빈칸 — 짧은 메모에서 스크롤이 안 생기게 하려면
  ///      본문 최소 높이에서 이 머리만큼 빼야 한다.
  /// 둘 다 실제 높이가 필요하다. 날짜 줄은 '낡은 답' 경고가 붙으면 두
  /// 줄이 되므로 상수로 박을 수 없다 — 그려 놓고 재는 수밖에 없다.
  final GlobalKey _headKey = GlobalKey();
  double _headH = 0;

  /// 유리 머리(AppBar)가 덮는 높이.
  ///
  /// 2026-08-18 소유자 지시 — "편집화면에서도 상단 고정바에 투명도를
  /// 살짝 줘서 글이 스크롤될 때 살짝 비춰지게."
  ///
  /// 유리로 만들려면 글이 그 밑을 지나가야 한다. 그런데 이 화면에는
  /// 굴러가지 않는 것들이 있다 — 맥의 입력 도구 막대, 그리고 켜 놓았을
  /// 때의 제목·출처·태그 줄. 그것들이 머리 밑에 깔리면 비치는 것이
  /// 아니라 가려지는 것이다.
  ///
  /// 그래서 자리를 두 군데 중 한 군데서만 비운다. 굴러가지 않는 것이
  /// 있으면 스크롤 **바깥**에서(그럼 머리는 그냥 불투명한 것처럼 보인다),
  /// 아무것도 없는 평소에는 스크롤 **안쪽**에서. 안쪽에서 비운 만큼이
  /// 곧 글이 머리 밑으로 흘러 들어가는 길이다.
  static const double _glassInset = kToolbarHeight;

  double get _topInsetOutside => (_isDesktop || _showMeta) ? _glassInset : 0;

  /// 머리에 보여 줄 제목.
  ///
  /// 손으로 적은 것이 먼저다. 없으면 본문 첫 줄에서 뽑는데, 목록이 쓰는
  /// 것과 **같은 함수**(core/auto_meta.dart 의 autoTitle)를 쓴다. 다른
  /// 함수를 쓰면 목록과 머리가 같은 글을 두 이름으로 부른다.
  ///
  /// 둘 다 없으면 빈 글이다. 그때는 안내말을 띄운다 — 빈 자리를 그냥
  /// 두면 눌러서 펼 수 있다는 것을 아무도 모른다.
  String _headTitle(L10n l) {
    final t = titleCtl.text.trim();
    if (t.isNotEmpty) return t;
    final a = autoTitle(bodyCtl.text).trim();
    // 빈 자리에는 이름표가 아니라 **시키는 말**을 둔다. '제목(자동)'은
    // 그 칸이 무엇인지만 말하고 무엇을 하라고는 말하지 않는다
    // (2026-08-19 소유자 신고).
    return a.isEmpty ? l.titleTapHint : a;
  }

  /// 머리에 보여 줄 것이 안내말뿐인가 — 손으로 적은 제목도, 본문에서 뽑을
  /// 것도 없는 상태. 연필을 붙일지와 눌렀을 때 자판을 띄울지를 이걸로 가른다.
  bool get _headTitleEmpty =>
      titleCtl.text.trim().isEmpty && autoTitle(bodyCtl.text).trim().isEmpty;
  double get _topInsetInside => _topInsetOutside > 0 ? 0 : _glassInset;

  /// 본문 칸을 찾아가기 위한 열쇠. 아래 _reshowToolbar에서 쓴다.
  final GlobalKey _bodyKey = GlobalKey();

  /// 직전 선택 범위. '방금 무엇이 바뀌었나'를 알려면 이전 값이 있어야 한다.
  TextSelection _lastSel = const TextSelection.collapsed(offset: -1);

  /// '전체 선택' 뒤에 편집 메뉴(오려두기·복사하기·붙여넣기)가 저절로 안
  /// 뜨던 것.
  ///
  /// 2026-08-17 소유자 신고 — "본문에서 '전체선택'을 하면 바로 이어서
  /// '오려두기, 복사하기, 붙여넣기' 이런 툴팁이 나와야 하는데, 자동으로
  /// 안 나오고 한 번 더 터치해야 나오네."
  ///
  /// 까닭은 우리가 만든 구조에 있다. 이 앱의 본문 칸은 **스스로 구르지
  /// 않는다** — 글 끝에서 반 화면 더 내려가기를 만들려고 스크롤의 임자를
  /// 바깥으로 옮겼기 때문이다(그 자리 주석 참고). 그런데 전체 선택은 잡힌
  /// 자리를 화면에 보이게 하려고 그 바깥 스크롤을 움직이고, 그 움직임이
  /// 방금 뜨려던 편집 메뉴를 밀어낸다.
  ///
  /// 그러니 이건 시스템의 변덕이 아니라 우리 선택의 대가다. 스크롤이 멎은
  /// 뒤에 메뉴를 다시 불러 갚는다.
  ///
  /// **전체 선택일 때만** 부른다. 손가락으로 범위를 끄는 중에 부르면 끄는
  /// 내내 메뉴가 깜빡인다.
  /// 단락 고르개에 지금 적혀 있는 형식. 값이 실제로 달라졌을 때만 다시
  /// 그린다 — 타자 한 자마다 화면을 새로 그리면 긴 글에서 손이 걸린다.
  String _blockSeen = kBlockBody;

  void _watchBlock() {
    final now = _blockNow();
    if (now == _blockSeen) return;
    _blockSeen = now;
    if (mounted) setState(() {});
  }

  void _onSelectionChanged() {
    _watchBlock();
    final sel = bodyCtl.selection;
    if (sel == _lastSel) return;
    final wasCollapsed = _lastSel.isCollapsed;
    _lastSel = sel;
    if (!wasCollapsed || sel.isCollapsed) return;
    final t = bodyCtl.text;
    if (t.isEmpty || sel.start != 0 || sel.end != t.length) return;
    if (kScrollTopOnSelectAll && _bodyScroll.hasClients && _bodyScroll.offset > 0) {
      _bodyScroll.animateTo(0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic);
    }
    _reshowToolbar();
  }

  /// 본문 칸(TextField) 속의 진짜 글 편집기를 찾아 준다.
  ///
  /// TextField 는 껍데기다. 커서·선택·편집 메뉴를 실제로 쥐고 있는 것은 그
  /// 안쪽의 EditableText 이고, 그 손잡이(State)는 밖으로 나오지 않는다.
  /// 그래서 위젯 나무를 한 겹씩 내려가며 찾는다.
  ///
  /// 곱게 생긴 방법은 아니다. 다만 이 앱은 편집 메뉴를 두 자리에서 손대야
  /// 한다(전체 선택 뒤 다시 띄우기, 한 번 두드리면 띄우기). 같은 걸음을
  /// 두 벌 적어 두면 한쪽만 고치는 날이 반드시 온다.
  EditableTextState? _editableState() {
    final ctx = _bodyKey.currentContext;
    if (ctx == null) return null;
    EditableTextState? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is EditableTextState) {
        found = e.state as EditableTextState;
        return;
      }
      e.visitChildren(visit);
    }
    ctx.visitChildElements(visit);
    return found;
  }

  /// 편집 메뉴를 띄운다 — **돋보기를 먼저 끄고.**
  ///
  /// 2026-08-20 소유자 신고 — "돋보기가 특정 위치에 고정 맞춰져있는
  /// 버그." 사진 두 장에서 돋보기가 화면의 똑같은 자리에 떠 있었다.
  ///
  /// 자리 셈은 멀쩡했다(test 로 세 가지 모양을 재 봤고 소수점까지
  /// 같았다). 문제는 **끄는 자리**였다.
  ///
  /// 플러터는 메뉴를 띄울 때 반드시 돋보기를 먼저 끈다 — 둘이 같이
  /// 떠 있으면 안 되기 때문이다. 그런데 이 앱은 showToolbar() 를
  /// **손짓 바깥에서** 두 곳에서 부르면서 그 짝을 안 지었다. 길게
  /// 눌러 돋보기가 떠 있는 동안 이 길로 들어오면 메뉴는 뜨고 돋보기는
  /// 마지막 자리에 남는다. 그 뒤로는 아무도 끄지 않는다 — 그것을 켠
  /// 손짓이 이미 끝났기 때문이다.
  ///
  /// 붙어 있는 게 아니라 **꺼지지 않은 것**이었다.
  ///
  /// 그래서 부르는 자리를 하나로 모은다. 두 군데에 각각 적어 두면
  /// 세 번째 자리가 생기는 날 또 빠뜨린다.
  void _showMenu(EditableTextState st) {
    st.hideMagnifier();
    st.showToolbar();
  }

  /// 손가락이 닿은 그 한 번에 편집 메뉴를 띄운다.
  ///
  /// 2026-08-18 소유자 지시 — "아무데나 터치를 하면 (…) 한번만에 안 나온다.
  /// 몇번 터치를 해야 나온다. 한번에 나오게 해달라."
  ///
  /// 애플의 기본 규칙은 '한 번은 커서를 놓는 일, 그 커서를 다시 눌러야
  /// 메뉴'다. 규칙 자체는 이유가 있다 — 글을 고치다 자리를 옮길 때마다
  /// 메뉴가 따라 뜨면 성가시기 때문이다.
  ///
  /// 그런데 이 앱에서 본문을 두드리는 까닭은 대개 '붙여넣기'다. AI 답변을
  /// 받아 와 넣는 것이 이 앱의 첫 일이니, 그 한 걸음을 줄이는 쪽이 맞다.
  ///
  /// **되돌리려면 kMenuOnFirstTap 을 false 로.** 다른 곳은 손대지 않았다.
  void _menuOnTap() {
    // 2026-08-18 — 네모를 누르면 켜고 꺼진다.
    //
    // 진짜 체크박스 위젯을 글 안에 심는 방법도 있지만, 그러면 글자 수와
    // 커서 자리가 어긋난다('- [ ]'는 다섯 글자인데 위젯은 한 글자로 센다).
    // 그래서 글자는 그대로 두고, **누른 자리가 네모 언저리인지**만 본다.
    //
    // 본문 칸의 onTap 은 하나뿐이라 여기서 먼저 부른다. 다음 프레임에
    // 부르는 까닭은 아래 _menuOnTap 주석과 같다 — **onTap 이 불릴 때는
    // 커서가 아직 새 자리로 안 옮겨져 있다.**
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toggleTodoAtCaret();
    });
    if (!kMenuOnFirstTap) return;
    // 커서가 자리를 잡은 다음에 띄운다. 같은 프레임에 부르면 방금 놓인
    // 커서 자리를 아직 아무도 모른다.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      final st = _editableState();
      if (st != null) _showMenu(st);
    });
  }

  Future<void> _reshowToolbar() async {
    // 스크롤이 멎기를 기다린다. 프레임 하나로는 모자랄 때가 있어 조금 준다.
    // 위에서 맨 위로 올리는 동안(180ms)에 불러 버리면 메뉴가 다시 밀린다.
    await Future<void>.delayed(Duration(
        milliseconds: kScrollTopOnSelectAll ? 260 : 140));
    if (!mounted) return;
    final st = _editableState();
    if (st == null) return;
    if (st.textEditingValue.selection.isCollapsed) return;

    // 손잡이(양 끝의 점)를 눈에 보이게 한다.
    //
    // 2026-08-17 소유자 신고 — "점 포인트(핸들)만 없어서 그렇지, 점
    // 포인트가 있다고 생각하고 드래그를 하니 곧 점 포인트가 생기면서
    // 조절이 되네."
    //
    // 이 한 문장이 원인을 다 말해 준다. 손잡이는 제자리에 있었고 그리기만
    // 안 되고 있었다. 플러터는 선택이 바뀔 때마다 '지금 손잡이를 보여야
    // 하나'를 다시 판정하는데, 메뉴의 '전체 선택'처럼 손가락이 직접 만든
    // 선택이 아니면 그 판정이 false 로 떨어진다. 그러다 그 자리를 문지르면
    // 손가락 사건이 생겨 그때 켜진다.
    //
    // 보이지 않는 조작점은 없는 것과 같다. 있는 줄 알고 더듬어야 잡히는
    // 것은 기능이 아니라 요행이다.
    // selectionOverlay 는 @visibleForTesting 이다. 규칙을 어기는 것을 알고
    // 쓰므로 이유를 적어 둔다.
    //
    // 손잡이를 켜는 공개 통로가 플러터에 없다. EditableTextState 가 밖으로
    // 내주는 것은 showToolbar/hideToolbar 뿐이고, 손잡이는 오버레이 안에만
    // 있다. 우회로로 '이 선택은 길게 누르기였다'고 거짓 신호를 보내는
    // 방법이 있으나, 그건 거짓말을 코드에 심는 것이고 플러터가 그 신호를
    // 어떻게 쓰는지에 우리가 계속 매이게 된다.
    //
    // 보이는 규칙 위반이 안 보이는 우회로보다 낫다. 플러터가 이 이름을
    // 바꾸면 빌드가 깨져서 바로 알게 된다 — 조용히 손잡이만 다시 사라지는
    // 것보다 그편이 안전하다.
    // ignore: invalid_use_of_visible_for_testing_member
    final ov = st.selectionOverlay;
    if (ov != null) {
      ov.handlesVisible = true;
      ov.showHandles();
    }

    // 이미 떠 있으면 false를 돌려주고 아무 일도 안 한다 — 깜빡이지 않는다.
    _showMenu(st);
  }

  void _measureHead() {
    if (!mounted) return;
    final box = _headKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    // 0.5픽셀 문턱을 두는 이유: 이 값이 바뀌면 setState가 돌고, setState가
    // 돌면 다시 재게 된다. 문턱이 없으면 반올림 오차만으로 그 고리가
    // 영원히 돈다.
    if ((h - _headH).abs() < 0.5) return;
    setState(() => _headH = h);
  }

  /// 원고지 한 칸의 너비. 한글 한 글자 폭이다.
  ///
  /// 글자 크기가 바뀔 때만 다시 잰다. 재는 일 자체는 싸지만 build마다
  /// 하면 타자 경로에 얹히고, 그건 이 앱이 방금 걷어낸 종류의 낭비다.
  double _colW = 0;
  double _colWFor = -1;

  double _colWidth(double fontSize) {
    if (_colWFor == fontSize) return _colW;
    final tp = TextPainter(
      // '가'로 재는 이유: 원고지는 한글 한 글자를 한 칸에 넣는 종이다.
      // 영문 글자로 재면 칸이 절반이 된다.
      text: TextSpan(text: '가', style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    _colWFor = fontSize;
    _colW = tp.width;
    return _colW;
  }

  /// 도구 막대의 한 칸. 가름선이면 [divider] 만 참이다.
  ///
  /// 목록으로 한 번 만들어 두고 두 가지 방식으로 그린다 — 폰은 옆으로
  /// 굴리고, 맥과 웹은 넘치는 것을 '더 보기'로 접었다 편다. 같은 목록을
  /// 쓰므로 두 화면의 차례가 어긋날 일이 없다.
  ({IconData? icon, String? glyph, String tip, VoidCallback? onTap, bool divider, bool wide})
      _tool(
              {IconData? icon,
              String? glyph,
              String tip = '',
              VoidCallback? onTap,
              bool divider = false,
              bool wide = false}) =>
          (
            icon: icon,
            glyph: glyph,
            tip: tip,
            onTap: onTap,
            divider: divider,
            wide: wide
          );

  /// 도구 막대에 무엇이 어떤 차례로 있는가.
  ///
  /// 2026-08-27 저녁, 소유자가 블로거(blogger.com)의 도구 막대를 놓고 다시
  /// 지시했다. 그 막대의 차례가 이렇다 — 실행취소 / 글꼴·크기·단락형식 /
  /// 굵게·기울임·밑줄·취소선·색·형광펜 / 링크·그림·영상·이모지 /
  /// 정렬·들여쓰기 / 목록·인용·구분선 / 서식 지우기.
  ///
  /// 그중 우리가 가져온 것과 안 가져온 것.
  ///
  /// **가져온 것** — 서식 지우기. 블로거 막대 맨 오른쪽의 그 단추다.
  /// 우리 앱에서는 특히 뜻이 깊다. 이 앱이 하는 일이 원래 '표시를 걷는
  /// 것'인데, 지금까지 그건 글 전체에 한 번에 하는 일뿐이었다. 한 문단만
  /// 걷고 싶을 때 길이 없었다.
  ///
  /// **안 가져온 것** — 글꼴·글자 크기·글자색·형광펜·정렬. 블로거는 HTML을
  /// 만드는 도구라 그런 것이 뜻이 있지만, 우리 노트는 **맨 글자**다.
  /// 복사하면 표시가 빠지는 것이 이 앱의 약속인데, 마크다운에 없는 문법을
  /// 넣으면 그 약속이 흐려진다.
  ///
  /// 차례는 소유자 지시대로 **찾기가 맨 왼쪽**, 그 오른쪽에 가름선.
  /// 그다음은 하는 일의 결로 묶었다 — 되돌리기 / 문단 / 목록 / 글자 /
  /// 커서 / 걷어내기.
  List<({IconData? icon, String? glyph, String tip, VoidCallback? onTap, bool divider, bool wide})>
      _tools(L10n l) => [
            // 2026-08-27 소유자 지시 — 찾기를 맨 왼쪽으로.
            _tool(icon: Icons.search, tip: l.findTitle, onTap: _showFindDialog),
            // 2026-08-27 밤 소유자 지시 — 구분선(수평선)을 두 번째 자리로.
            //
            // 처음에 나는 이 말을 '세로 가름선을 넣어라'로 읽고 가름선을
            // 넣었다. 다시 같은 말을 들었으니 내가 틀리게 읽은 것이다.
            // 소유자가 말한 구분선은 **본문에 넣는 수평선 단추**다.
            _tool(
                icon: Icons.horizontal_rule,
                tip: l.dividerTip,
                onTap: _insertDivider),
            _tool(divider: true),
            _tool(icon: Icons.undo, tip: l.undoTip, onTap: () => _undoCtl.undo()),
            _tool(icon: Icons.redo, tip: l.redoTip, onTap: () => _undoCtl.redo()),
            _tool(divider: true),
            // ── 단락 형식 ──
            //
            // 2026-08-27 밤 소유자 지시 — 블로거처럼 펼침 목록으로.
            // 돌려 가며 고르던 '제목' 단추와 '인용' 단추가 여기 합쳐졌다.
            // 지금 이 줄이 무슨 형식인지 단추에 그대로 적힌다.
            _tool(
                glyph: _blockLabel(l),
                tip: l.blockFormatTip,
                wide: true,
                onTap: _showBlockMenu),
            _tool(divider: true),
            // ── 목록 넷 ──
            //
            // 아이콘을 글자(1. · -)에서 목록 그림으로 바꿨다(소유자 지시).
            // 글자는 그 자체로 '이 글자를 넣는다'로 읽힌다 — 08-17에 실제로
            // 그 오해가 있었다. 그림은 '이 줄들을 목록으로 만든다'로 읽힌다.
            //
            // 하이픈 목록은 이 앱의 특징이다. 다른 편집기는 대개 점과 번호
            // 둘뿐인데, AI 답변에는 하이픈 목록이 압도적으로 많이 온다.
            _tool(
                icon: Icons.format_list_numbered,
                tip: l.listNumberAction,
                onTap: () => _makeList('number')),
            _tool(
                icon: Icons.format_list_bulleted,
                tip: l.listBulletAction,
                onTap: () => _makeList('bullet')),
            _tool(
                icon: Icons.list,
                tip: l.listDashAction,
                onTap: () => _makeList('dash')),
            // 이제 줄에 하는 일이다. 나란히 있는 네 단추 중 하나만 다르게
            // 굴면 사람은 그걸 고장으로 읽는다.
            _tool(
                icon: Icons.checklist,
                tip: l.todoAction,
                onTap: () => _op(toggleTodo)),
            _tool(
                icon: Icons.format_indent_increase,
                tip: l.indentTip,
                onTap: () => _op(indentLines)),
            _tool(
                icon: Icons.format_indent_decrease,
                tip: l.outdentTip,
                onTap: () => _op(outdentLines)),
            _tool(divider: true),
            // ── 글자 ──
            _tool(
                icon: Icons.format_bold,
                tip: l.boldTip,
                onTap: () => _op((t, a, b) => toggleWrap(t, a, b, '**'))),
            _tool(icon: Icons.code, tip: l.codeTip, onTap: () => _op(toggleCode)),
            _tool(icon: Icons.link, tip: l.linkTip, onTap: () => _op(makeLink)),
            _tool(divider: true),
            // ── 커서 옮기기 ──
            //
            // 한글 입력에서 커서를 정확한 자리에 놓기가 정말 어렵다. 손가락
            // 하나가 글자 두세 개를 덮기 때문이다.
            _tool(
                icon: Icons.keyboard_arrow_left,
                tip: l.cursorLeftTip,
                onTap: () => _moveCaret(-1)),
            _tool(
                icon: Icons.keyboard_arrow_right,
                tip: l.cursorRightTip,
                onTap: () => _moveCaret(1)),
            _tool(divider: true),
            _tool(
                icon: Icons.format_clear,
                tip: l.clearFormatTip,
                onTap: () => _op(stripFormat)),
          ];

  /// 지금 커서가 놓인 줄의 단락 형식 이름.
  String _blockLabel(L10n l) => _blockName(l, _blockNow());

  String _blockNow() {
    final sel = bodyCtl.selection;
    final t = bodyCtl.text;
    final a = sel.isValid ? sel.start : t.length;
    final b = sel.isValid ? sel.end : t.length;
    return blockKind(t, a, b);
  }

  String _blockName(L10n l, String kind) => switch (kind) {
        kBlockH1 => l.blockH1,
        kBlockH2 => l.blockH2,
        kBlockH3 => l.blockH3,
        kBlockQuote => l.blockQuote,
        kBlockCode => l.blockCode,
        _ => l.blockBody,
      };

  /// 단락 형식 펼침 목록. 지금 것에 체크가 붙는다.
  ///
  /// 화면 가운데가 아니라 **눌린 단추 옆**에서 펴진다. 고르개는 제가 선
  /// 자리에서 펴져야 무엇에 대한 목록인지가 설명 없이 읽힌다.
  Future<void> _showBlockMenu() async {
    final l = L10n.of(context);
    final now = _blockNow();
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final at = box.localToGlobal(Offset.zero, ancestor: overlay);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          at.dx + 12, at.dy + 40, at.dx + 220, at.dy + 400),
      items: [
        for (final k in kBlockKinds)
          PopupMenuItem<String>(
            value: k,
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: k == now
                      ? Icon(Icons.check, size: 17, color: context.c.accent)
                      : null,
                ),
                Text(_blockName(l, k),
                    style: TextStyle(
                        fontSize: k == kBlockH1
                            ? 19
                            : k == kBlockH2
                                ? 17
                                : k == kBlockH3
                                    ? 15.5
                                    : 14,
                        fontFamily: k == kBlockCode ? 'D2Coding' : null,
                        fontStyle:
                            k == kBlockQuote ? FontStyle.italic : null,
                        fontWeight: k == kBlockBody || k == kBlockQuote
                            ? FontWeight.w400
                            : FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _op((t, a, b) => applyBlock(t, a, b, picked));
  }

  /// 고른 자리에 셈 하나를 먹인다. 되돌리기가 듣도록 controller 값을
  /// 한 번에 바꾼다.
  void _op(EditResult Function(String, int, int) f) {
    final sel = bodyCtl.selection;
    final text = bodyCtl.text;
    final a = sel.isValid ? sel.start : text.length;
    final b = sel.isValid ? sel.end : text.length;
    final r = f(text, a, b);
    bodyCtl.value = bodyCtl.value.copyWith(
      text: r.text,
      selection: TextSelection(baseOffset: r.start, extentOffset: r.end),
      composing: TextRange.empty,
    );
    _save();
  }

  /// 커서를 한 글자 옮긴다. 고른 것이 있으면 그 끝으로 붙인다 —
  /// 화살표를 눌러 고른 자리가 통째로 지워지는 일은 없어야 한다.
  void _moveCaret(int by) {
    final sel = bodyCtl.selection;
    if (!sel.isValid) return;
    final at = sel.isCollapsed
        ? sel.baseOffset + by
        : (by < 0 ? sel.start : sel.end);
    final n = at.clamp(0, bodyCtl.text.length);
    bodyCtl.selection = TextSelection.collapsed(offset: n);
    if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
  }

  /// 넘친 단추를 펴 두었는가. 맥·웹에서만 쓴다.
  bool _toolsOpen = false;

  Widget _accessoryBar({bool atTop = false}) {
    final l = L10n.of(context);
    final items = _tools(l);
    // 2026-08-16 리퀴드 글래스 — 도구 막대는 이제 유리다.
    return Glass(
      hairlineTop: !atTop,
      hairlineBottom: atTop,
      child: _isDesktop
          ? LayoutBuilder(builder: (_, box) => _barFit(items, box.maxWidth, atTop))
          : SizedBox(
              height: 44,
              child: Row(children: [
                Expanded(
                  // 폰은 옆으로 굴린다. 손가락은 굴리는 것이 자연스럽다.
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: [for (final it in items) _toolWidget(it)],
                  ),
                ),
                if (!atTop) ...[
                  Container(width: 1, height: 26, color: context.c.toolbarLine),
                  _kbBtn(
                    icon: Icons.keyboard_hide_outlined,
                    tip: l.hideKeyboardTip,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ],
              ]),
            ),
    );
  }

  static const double _toolW = 44;
  static const double _dividerW = 9;

  /// 단락 형식 고르개처럼 글자가 들어가는 칸의 너비.
  static const double _wideW = 104;

  /// 들어가는 만큼만 세우고, 넘치는 것은 '⋯'를 눌러 **아래로 편다.**
  ///
  /// 2026-08-27 소유자 지시 — "작은 해상도에서 툴바가 다 못 나오면 ⋯를
  /// 누르면 블로거처럼 기본 한 줄 아래에 2~3줄로 나오게."
  ///
  /// 처음에는 세로 메뉴로 만들었는데, 그건 단추를 **글자 목록**으로 바꾼
  /// 것이라 손이 기억한 그림이 사라진다. 아래로 펴면 같은 그림이 같은
  /// 크기로 남고, 자리만 한 줄 내려간다.
  Widget _barFit(
      List<({IconData? icon, String? glyph, String tip, VoidCallback? onTap, bool divider, bool wide})>
          items,
      double width,
      bool atTop) {
    double w(int i) =>
        items[i].divider ? _dividerW : (items[i].wide ? _wideW : _toolW);
    var total = 0.0;
    for (var i = 0; i < items.length; i++) {
      total += w(i);
    }
    if (total <= width - 8) {
      return SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [for (final it in items) _toolWidget(it)]),
        ),
      );
    }
    // '⋯' 자리를 미리 뺀다.
    final room = width - 8 - _toolW;
    var used = 0.0;
    var cut = 0;
    for (var i = 0; i < items.length; i++) {
      if (used + w(i) > room) break;
      used += w(i);
      cut = i + 1;
    }
    // 접히는 쪽 맨 앞의 가름선은 버린다. 아무것도 안 가르는 선이다.
    final rest = items.sublist(cut);
    while (rest.isNotEmpty && rest.first.divider) {
      rest.removeAt(0);
    }
    final l = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              for (final it in items.take(cut)) _toolWidget(it),
              if (rest.isNotEmpty)
                _kbBtn(
                  icon: _toolsOpen ? Icons.expand_less : Icons.more_horiz,
                  tip: l.moreTools,
                  onTap: () => setState(() => _toolsOpen = !_toolsOpen),
                ),
            ]),
          ),
        ),
        if (_toolsOpen && rest.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Wrap(
              alignment: WrapAlignment.start,
              children: [for (final it in rest) _toolWidget(it)],
            ),
          ),
      ],
    );
  }

  Widget _toolWidget(
      ({IconData? icon, String? glyph, String tip, VoidCallback? onTap, bool divider, bool wide})
          it) {
    if (it.divider) {
      return Container(
          width: 1,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: context.c.toolbarLine);
    }
    if (it.wide) {
      return Tooltip(
        message: it.tip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: it.onTap,
          child: Container(
            width: _wideW - 4,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.c.toolbarLine)),
            child: Row(
              children: [
                Expanded(
                  child: Text(it.glyph ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
      );
    }
    return _kbBtn(
        icon: it.icon, glyph: it.glyph, tip: it.tip, onTap: it.onTap ?? () {});
  }

  @override
  void initState() {
    super.initState();
    _bindStatusBarTap();
    // 붙은 파일이 이 기기에 실제로 있는지 한 번 찾아 둔다. 화면을 그릴
    // 때마다 디스크를 물으면 스크롤이 끊긴다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttachFiles());
    final idx = store.notes.indexWhere((n) => n.id == widget.noteId);
    if (idx < 0) {
      _found = false;
      note = Note.fresh();
    } else {
      note = store.notes[idx];
    }
    titleCtl = TextEditingController(text: note.title);
    bodyCtl = MonoTextController(text: note.body);
    // 붙여넣기를 알아채려면 '직전에 얼마였나'를 알아야 한다.
    _lastBody = note.body;
    // 태그의 진짜 값은 note.tags 하나뿐이다. 이 입력칸은 '새로 칠 것'만 담는다.
    // (전에는 입력칸의 글자가 곧 태그였다 — 그러면 블럭을 지우는 조작을 만들 수 없다)
    tagsCtl = TextEditingController();
    for (final f in [_titleFocus, _bodyFocus, _tagsFocus]) {
      f.addListener(() => setState(() {}));
    }
    // 본문에서 손을 떼면 기다리지 않고 바로 본다. 붙여넣고 곧장 나가는
    // 사람은 6초를 안 채운다 — 그 사람이야말로 태그가 제일 필요하다.
    _bodyFocus.addListener(() {
      if (!_bodyFocus.hasFocus) unawaited(_autoTagQuietly());
    });
    // 선택 범위가 바뀌는 것을 지켜본다. 글자가 바뀔 때(onChanged)와는
    // 다른 일이라 컨트롤러에 직접 붙는다.
    bodyCtl.addListener(_onSelectionChanged);
    // 동기화가 이 노트의 새 판을 받아 오면 화면도 따라 그린다.
    store.addListener(_onStoreChanged);
    // 그리고 여는 순간 조용히 한 바퀴 맞춘다. "이 글이 최신인가"가
    // 궁금해지는 때가 바로 여는 때다. 받아 오면 위의 듣기가 화면을
    // 따라 그린다. (소유자 제안 2026-08-20 — 편집 화면 당기기 대신)
    ICloudSync.instance.scheduleUp();
    if (widget.showMeta) _showMeta = true;
    if (widget.autoTidy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTidyWithPreset(buildPresets().first));
    }
  }

  @override
  void dispose() {
    _unbindStatusBarTap();
    store.removeListener(_onStoreChanged);
    _tagTimer?.cancel();
    bodyCtl.removeListener(_onSelectionChanged);
    _bodyScroll.dispose();
    unawaited(store.flush());
    titleCtl.dispose();
    bodyCtl.dispose();
    tagsCtl.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _tagsFocus.dispose();
    _undoCtl.dispose();
    super.dispose();
  }

  /// 태그 블럭 하나. 색은 반드시 context.c를 거친다(다크 모드).
  Widget _tagChip(String t) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.tagBg,
        border: Border.all(color: c.tagLine),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.tagInk)),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: L10n.of(context).tagRemoveTip,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                note.tags.remove(t);
                await _save();
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close, size: 14, color: c.tagInk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 쉼표나 줄바꿈이 나오면 그 앞까지를 태그로 확정하고, 뒤는 입력칸에 남긴다.
  void _onTagTyped(String v) {
    if (!v.contains(',') && !v.contains('\n')) return;
    final parts = v.split(RegExp(r'[,\n]'));
    final rest = parts.removeLast();
    _commitTags(parts.join(','), clear: false);
    tagsCtl.text = rest;
    tagsCtl.selection = TextSelection.collapsed(offset: rest.length);
  }

  /// 문자열을 태그로 확정한다. 앞의 #은 떼고, 중복(대소문자 무시)은 버린다.
  Future<void> _commitTags(String raw, {required bool clear}) async {
    var changed = false;
    for (var t in raw.split(RegExp(r'[,\n]'))) {
      t = t.trim().replaceFirst(RegExp(r'^#+'), '').trim();
      if (t.isEmpty || t.length > 24) continue;
      if (note.tags.any((e) => e.toLowerCase() == t.toLowerCase())) continue;
      note.tags.add(t);
      changed = true;
    }
    if (clear) tagsCtl.clear();
    if (changed || clear) {
      await _save();
      if (mounted) setState(() {});
    }
  }

  /// 태그 뽑기 전용 시스템 규칙. 편집용(_aiSys)과 목적이 달라 따로 둔다.
  static const _tagSys =
      '너는 문서에서 태그(키워드)를 뽑는 도구다. 규칙: 원문에 실제로 나오는 말만 쓴다. '
      '새 개념을 지어내지 않는다. 각 태그는 24자 이내의 짧은 명사구다. '
      '3~5개를 쉼표로만 구분해 한 줄로 출력한다. 번호·설명·따옴표·해시(#)·코드펜스는 붙이지 않는다. '
      '입력 언어를 그대로 유지한다.';

/// 전체 선택을 하면 문서 맨 위로 올릴 것인가. **실험이다.**
///
/// 2026-08-17 소유자 신고 — "전체 선택을 하면 블록 씌운 범위 선택을 못하는
/// 문제가 여전하다. 범위 선택할 수 있는 핸들이 없어."
///
/// 핸들은 있다. 화면 밖에 있을 뿐이다. 이 앱의 본문 칸은 스스로 구르지
/// 않아서(글 끝 반 화면 여백을 만들려고 스크롤 임자를 바깥에 뒀다) 글
/// 길이만큼 통째로 펼쳐져 있고, 전체 선택을 하면 시작 핸들은 문서 맨
/// 처음에, 끝 핸들은 맨 끝에 놓인다. 긴 메모에서는 둘 다 화면 밖이다.
///
/// 제대로 고치려면 본문 칸이 자기 스크롤을 갖게 해야 하는데, 그러면 날짜
/// 줄·글 끝 여백·광고 자리를 다시 짜야 한다. 그 전에 **가벼운 쪽을 먼저
/// 써 보고 판단하기로 했다**(소유자 지시). 전체 선택 직후 맨 위로 올려
/// 시작 핸들만이라도 손에 닿게 한다.
///
/// **되돌리려면 이 값을 false 로 바꾸면 된다.** 그러면 이 판 이전과
/// 완전히 같아진다 — 다른 곳은 손대지 않았다.
static const bool kScrollTopOnSelectAll = true;

/// 태그를 뽑을 때 훑는 본문 길이.
///
/// 2026-08-17 소유자 지적 — "자동 태그. 제목만 분석하냐?"
///
/// 제목만 보지는 않았다. 다만 1200자만 봤고, 긴 글에서 1200자는 서두다.
/// 서두에는 인사말과 도입이 들어 있어서, 정작 그 글이 무엇에 관한 것인지는
/// 그 아래에 있다. 3000자로 넓혔다 — 이 함수는 기기 안에서 도는 정규식
/// 몇 개라 세 배로 늘어도 사람이 느낄 만한 값이 아니다.
/// 본문을 한 번 두드리면 편집 메뉴를 띄울 것인가.
///
/// 애플 기본은 '두 번'이다 — 한 번은 커서를 놓는 일이고, 그 커서를 다시
/// 눌러야 메뉴가 뜬다. 규칙 자체에는 이유가 있다. 글을 고치다 자리를
/// 옮길 때마다 메뉴가 따라 뜨면 성가시기 때문이다.
///
/// 그런데 이 앱에서 본문을 두드리는 까닭은 대개 **붙여넣기**다. AI 답변을
/// 받아 와 넣는 것이 이 앱의 첫 일이니, 그 한 걸음을 줄이는 쪽이 맞다.
///
/// 성가시면 false 로 바꾸면 애플 기본으로 돌아간다. 다른 곳은 손대지 않았다.
static const bool kMenuOnFirstTap = false;

static const int kTagScanChars = 3000;

  bool _tagAiBusy = false;

  /// 제목과 본문 앞부분에서 태그를 뽑아 넣는다. **AI만 한다.**
  ///
  /// 2026-08-17 소유자 지시 — "태그는 명사로 한정하고 싶다. (…) 이 모든
  /// 것을 ai편집을 위한 이용자 자신의 api키를 넣은 경우에만, 해당 api키를
  /// 활용해서 그 ai의 힘을 빌어서 태그를 추출하게하면 좋겠다."
  ///
  /// 규칙으로 명사만 골라내는 일은 사전 없이는 안 된다. 한국어에서 명사와
  /// 용언은 형태가 겹치기 때문이다 — '사랑'은 명사, '사랑하다'는 동사,
  /// '사랑한'은 활용형이다. 규칙을 늘리면 늘린 만큼 멀쩡한 낱말이 같이
  /// 죽는다(오늘 '보고'·'문서'·'수요'를 살리려고 어미를 두 글자 이상만
  /// 보기로 한 것이 이미 그 타협이었다).
  ///
  /// 그래서 뽑개를 통째로 AI로 옮겼다. 키가 없으면 **이유를 말하고 아무
  /// 것도 하지 않는다.** 어설픈 답을 조용히 내놓는 것보다 낫다.
  Future<void> _autoTags() async {
    _tagTimer?.cancel();
    final l = L10n.of(context);
    if (store.settings.aiKey.trim().isEmpty) {
      _toast(context, l.tagAiNeedKey);
      return;
    }
    setState(() => _tagAiBusy = true);
    final head = note.body.length > kTagScanChars
        ? note.body.substring(0, kTagScanChars)
        : note.body;
    var got = <String>[];
    try {
      final out = await _aiEditCall(
        '이 글의 태그를 뽑아라.',
        '[제목]\n${note.title}\n\n[본문 앞부분]\n$head',
        system: _tagSys,
      );
      got = out
          .split(RegExp(r'[,\n]'))
          .map((s) => s.trim().replaceFirst(RegExp(r'^#+'), '').trim())
          .where((s) => s.isNotEmpty && s.length <= 24)
          .take(5)
          .toList();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tagAiBusy = false);
      final fix = aiRemedy(l, '$e');
      _toast(context, fix.isNotEmpty ? fix : l.aiCallFailed('$e'));
      return;
    }
    // 사용자가 버튼을 눌러 뽑은 태그는 배경 갱신이 덮으면 안 된다.
    note.tagsAuto = false;
    if (!mounted) return;
    setState(() => _tagAiBusy = false);
    if (got.isEmpty) {
      _toast(context, l.tagAiNone);
      return;
    }
    await _commitTags(got.join(','), clear: false);
  }

  /// 태그를 다시 뽑기 위한 타이머. 글자마다 뽑으면 낭비다.
  Timer? _tagTimer;

  /// 이 화면에서 본문이 실제로 바뀌었는가.
  ///
  /// 열어 보기만 한 노트에는 손을 안 댄다. 이것이 없으면 목록을 훑는
  /// 동안 열리는 노트마다 회사를 부른다.
  bool _bodyTouched = false;

  /// 조용한 태그 뽑기가 도는 중.
  bool _autoTagRunning = false;

  /// 글을 고치고 조용해지면 태그를 다시 뽑는다.
  ///
  /// 2026-08-18 소유자 지시로 되살렸다. 걷어냈던 판과 다른 점은 **부르기
  /// 전에 여섯 가지를 본다**는 것이다(core/auto_tag_gate.dart, 시험 13개).
  /// 그중 가장 중요한 것은 '사람이 태그를 만졌으면 영영 손 뗀다'이다.
  ///
  /// 알리지 않는다. 조사에서 반복해 확인된 것 — 제안 알림은 명시적 이탈
  /// 사유다. 그냥 태그가 붙어 있는 상태가 되어 있을 뿐이다.
  void _scheduleAutoTag() {
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(seconds: 6), _autoTagQuietly);
  }

  Future<void> _autoTagQuietly() async {
    if (!mounted || _autoTagRunning || _tagAiBusy) return;
    final s = store.settings;
    if (!shouldAutoTag(
      hasKey: s.aiKey.trim().isNotEmpty,
      enabled: s.autoTagAi,
      tagsAuto: note.tagsAuto,
      bodyLen: note.body.length,
      taggedLen: note.taggedLen,
      tagCount: note.tags.length,
      bodyChanged: _bodyTouched,
    )) {
      return;
    }
    _autoTagRunning = true;
    // 길이는 **부르기 전에** 적는다. 부르는 동안 사람이 계속 치고 있으면
    // 끝난 뒤의 길이는 이미 다른 글의 길이다.
    final len = note.body.length;
    final head = note.body.length > kTagScanChars
        ? note.body.substring(0, kTagScanChars)
        : note.body;
    var got = <String>[];
    try {
      final out = await _aiEditCall(
        '이 글의 태그를 뽑아라.',
        '[제목]\n${note.title}\n\n[본문 앞부분]\n$head',
        system: _tagSys,
      );
      got = out
          .split(RegExp(r'[,\n]'))
          .map((x) => x.trim().replaceFirst(RegExp(r'^#+'), '').trim())
          .where((x) => x.isNotEmpty && x.length <= 24)
          .take(5)
          .toList();
    } catch (_) {
      // 조용히 물러난다. 사용자가 시킨 일이 아니라서, 실패를 알리면
      // 그건 '내가 안 시킨 일이 실패했다'는 알림이 된다.
      _autoTagRunning = false;
      return;
    }
    _autoTagRunning = false;
    if (!mounted || got.isEmpty) return;
    // 부르는 사이에 사람이 태그를 만졌으면 그 뜻을 이긴다.
    if (!note.tagsAuto) return;
    note.taggedLen = len;
    await _commitTags(got.join(','), clear: false);
  }

  /// 저장소가 바뀔 때마다 온다. 이 노트의 **객체 자체**가 바뀌었으면
  /// 동기화가 새 판을 꽂은 것이다. 판단 셈은 core/sync_plan.dart의
  /// editorRefresh — 갈래마다 왜 그런지는 그쪽 주석에 있다.
  void _onStoreChanged() {
    if (!mounted) return;
    final i = store.notes.indexWhere((n) => n.id == note.id);
    // 다른 기기에서 지워졌다. 이 화면은 그대로 둔다 — 보던 글이 눈앞에서
    // 사라지는 것보다, 나가면서 자연히 정리되는 쪽이 덜 놀랍다.
    if (i < 0) return;
    final fresh = store.notes[i];
    switch (editorRefresh(
      sameObject: identical(fresh, note),
      sameContent: fresh.body == bodyCtl.text && fresh.title == titleCtl.text,
      // '치는 중'은 언젠가 손댔다는 뜻이 아니라, **아직 저장 안 된 글자가
      // 지금 화면에 있다**는 뜻이다.
      //
      // 2026-08-27 — 예전에는 붙박이 깃발(_bodyTouched)을 썼다. 한 글자만
      // 쳐도 그 깃발은 편집 화면을 닫을 때까지 켜져 있었고, 그동안 들어오는
      // 남의 글을 30초마다 제 옛 글로 도로 덮었다. 소유자가 웹앱에서 쓴
      // 줄들이 맥앱 때문에 계속 사라진 사건이 이것이다. 깃발은 태그 셈에만
      // 남기고, 여기서는 지금 이 순간의 사실을 묻는다.
      editing: bodyCtl.text != note.body,
    )) {
      case EditorRefresh.keep:
        return;
      case EditorRefresh.rebind:
        // 글자는 그대로 두고 객체만 새것으로 바꾼다. 옛 객체는 이미
        // store.notes 에서 빠졌으므로, 안 바꾸면 이 뒤의 편집이 아무 데도
        // 닿지 않는 유령 객체에 쌓인다.
        note = fresh;
        _lastBody = fresh.body;
        return;
      case EditorRefresh.adopt:
        note = fresh;
        _lastBody = fresh.body;
        if (bodyCtl.text != fresh.body) bodyCtl.text = fresh.body;
        if (titleCtl.text != fresh.title) titleCtl.text = fresh.title;
        setState(() {});
      case EditorRefresh.assertMine:
        note = fresh;
        unawaited(_save());
        setState(() {});
    }
  }

  /// 편집 화면에서 당겨서 맞추기. 목록의 _pullSync 와 같은 규칙이다 —
  /// 동그라미는 '손짓을 받았다'는 표시지 일이 끝났다는 표시가 아니다.
  Future<void> _editorPullSync() async {
    unawaited(HapticFeedback.lightImpact());
    final sync = ICloudSync.instance;
    if (!sync.active || sync.paused) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      return;
    }
    await sync.recheck().timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  Future<void> _save() async {
    if (note.body != bodyCtl.text) {
      _bodyTouched = true;
      _scheduleAutoTag();
    }
    note.body = bodyCtl.text;

    // 제목은 손대기 전까지 본문을 따라간다(소유자 제안 2026-08-16).
    // 규칙은 core/auto_meta.dart에 있고 테스트로 고정되어 있다.
    if (canRetitle(auto: note.titleAuto)) {
      final t = autoTitle(note.body);
      note.title = t;
      if (titleCtl.text != t) titleCtl.text = t;
    } else {
      note.title = titleCtl.text;
    }

    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
    // persist()가 아니라 touch()다. 글자마다 디스크에 쓰지 않는다 — 이유는
    // Store.touch()의 주석에 적었다.
    store.touch();
  }

  // 여기 있던 '타이핑이 멈추면 배경에서 태그를 다시 뽑는다'를 걷어냈다
  // (2026-08-17). 그게 '해야하는데'와 '꺾인'을 붙이고 있던 자리다.
  //
  // AI로 대신할 수도 없다. 글자를 칠 때마다 회사를 부르면 사용자 요금이
  // 샌다. 그러니 태그는 사용자가 단추를 눌렀을 때만 붙는다 — 돈이 드는
  // 일은 시켰을 때만 한다.

  /// 본문에서 뽑은 제목 — core/auto_meta.dart의 규칙을 쓴다.
  static String _titleFrom(String body) => autoTitle(body);

  /// 무료 한도에 걸렸는가. 걸렸으면 프리미엄 안내를 띄우고 true를 준다.
  ///
  /// 2026-08-16 — 핵심 기능을 아예 막지 않는다. 가볍게 쓰는 사람은 한도에
  /// 닿지도 않는다(정리 10회·마법사 3회). 매일 쓰는 사람에게만 결제 이유가
  /// 생기게 하는 선이다. 규칙은 core/usage_gate.dart(테스트로 고정).
  Future<bool> _blockedByLimit({required bool wizard}) async {
    final s = store.settings;
    // 2026-08-17 — 첫 판은 완전 무료다. 한도도, 프리미엄 안내도 없다.
    // 화면만 숨기고 한도를 남기면 빠져나갈 길이 없는 벽이 된다.
    if (!limitsApply(
      paidTierLive: kPaidTierLive,
      legacyFree: s.legacyFree,
      premium: s.premium,
    )) {
      return false;
    }

    final now = DateTime.now();
    // canUse가 아니라 canUseNow다 — canUse는 한도만 보므로 체험 중인
    // 사람을 그대로 막아 버린다. 2026-08-16에 체험을 넣으면서 갈아탔다.
    final ok = canUseNow(
      now: now,
      savedDate: wizard ? s.wizDate : s.tidyDate,
      savedCount: wizard ? s.wizCount : s.tidyCount,
      limit: wizard ? kFreeWizardPerDay : kFreeTidyPerDay,
      premium: s.premium,
      trialDays: s.trialDays,
    );
    if (ok) return false;
    if (!mounted) return true;

    // 체험이 끝나고 '처음으로' 막히는 순간인가.
    //
    // 실행하자마자 뜨는 팝업은 잔소리지만, 방금 쓰려다 막힌 사람에게는
    // 설명이다. 그래서 알림을 이 자리로 옮겼다. 그동안 몇 번 썼는지를
    // 숫자로 보여 준다 — 사람은 가진 적 없는 것보다 가졌다가 잃는 것에
    // 훨씬 민감하고, 그 숫자가 그 감각을 만든다.
    final ended =
        trialJustEnded(trialDays: s.trialDays, noticeShown: s.trialNoticeShown);
    if (ended) {
      s.trialNoticeShown = true;
      await store.persistSettings();
      if (!mounted) return true;
    }

    final go = await confirmDialog(context,
        title: ended ? L10n.of(context).trialEndedTitle : L10n.of(context).limitTitle,
        body: ended
            ? L10n.of(context).trialEndedBody(s.trialTidyTotal, s.trialWizTotal,
                kFreeTidyPerDay, kFreeWizardPerDay)
            : (wizard
                ? L10n.of(context).limitWizardBody(kFreeWizardPerDay)
                : L10n.of(context).limitTidyBody(kFreeTidyPerDay)),
        okLabel: L10n.of(context).limitSeePremium);
    if (go && mounted) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()));
    }
    return true;
  }

  Future<void> _bumpUse({required bool wizard}) async {
    final s = store.settings;
    final now = DateTime.now();
    if (wizard) {
      s.wizCount = nextCount(now: now, savedDate: s.wizDate, savedCount: s.wizCount);
      s.wizDate = usageDateKey(now);
    } else {
      s.tidyCount = nextCount(now: now, savedDate: s.tidyDate, savedCount: s.tidyCount);
      s.tidyDate = usageDateKey(now);
    }
    // 체험 중에만 누적한다. 끝난 뒤에도 세면 "체험 동안 이만큼 쓰셨다"는
    // 문구의 숫자가 계속 커져서 거짓말이 된다.
    if (trialOn(s.trialDays)) {
      if (wizard) {
        s.trialWizTotal++;
      } else {
        s.trialTidyTotal++;
      }
    }
    await store.persistSettings();
  }

  /// 처음 붙여넣은 글로 돌아간다.
  ///
  /// 2026-08-17 소유자 신고 — "'되돌리기'가 1단계 이전으로 가는 것인 줄
  /// 알았더니 '원본으로'구나. (…) 다 편집을 끝냈는데 이거 눌러 버리면 다
  /// 도루묵 되어 버리네."
  ///
  /// 옛 버튼은 `history`의 마지막으로 갔는데, history에는 **정리한 순간만**
  /// 쌓인다. 손으로 고친 것은 안 쌓인다. 그래서 '정리 → 한 시간 손질 →
  /// 되돌리기'를 하면 한 시간이 통째로 날아갔다. 이름은 '되돌리기'라
  /// 사람은 한 칸 뒤로 가는 줄 알고 눌렀다. **이름이 거짓말을 했다.**
  ///
  /// 이름과 동작을 맞췄다. 이제 진짜로 원본으로 간다. 한 칸 뒤로가 필요하면
  /// 버전기록에서 고른다 — 그쪽이 더 정확하다.
  ///
  /// 되돌리기 전의 글을 **버전기록에 넣고 나서** 바꾼다. 그래서 이 동작
  /// 자체를 취소할 수 있다. 사라지는 알림에 '취소' 버튼을 다는 길도 있었지만
  /// 안 했다 — 사라지는 알림의 버튼은 누르려는 순간 사라진다. 버전기록은
  /// 안 사라진다.
  bool get _canRevert {
    final t = _revertTarget;
    return t != null && t != bodyCtl.text;
  }

  String? get _revertTarget {
    if (note.originalBody.isNotEmpty) return note.originalBody;
    if (note.history.isNotEmpty) return note.history.last;
    return null;
  }

  /// 이 메모를 어느 폴더에 둘지 고른다.
  ///
  /// 2026-08-17 — 새 폴더를 여기서 바로 만들 수 있게 했다. 폴더를 먼저
  /// 만들고 다시 들어와 고르게 하면 두 걸음이 되고, 두 걸음이면 대부분은
  /// 그냥 안 넣는다.
  Future<void> _pickFolder() async {
    final l = L10n.of(context);
    final s = store.settings;
    final names = folderNames(store.notes.map((n) => n.folder), s.folders);

    Future<void> put(String f) async {
      note.folder = f;
      if (f.isNotEmpty && !s.folders.contains(f)) {
        s.folders.add(f);
        await store.persistSettings();
      }
      await _save();
      if (!mounted) return;
      setState(() {});
      _toast(context, f.isEmpty ? l.folderCleared : l.folderMoved(f));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: sheet.c.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.folderTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_off_outlined, color: sheet.c.sub),
                title: Text(l.folderNone),
                trailing: note.folder.isEmpty
                    ? Icon(Icons.check, color: sheet.c.accent)
                    : null,
                onTap: () {
                  Navigator.pop(sheet);
                  put('');
                },
              ),
              for (final f in names)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.folder_outlined, color: sheet.c.sub),
                  title: Text(f),
                  trailing: note.folder == f
                      ? Icon(Icons.check, color: sheet.c.accent)
                      : null,
                  onTap: () {
                    Navigator.pop(sheet);
                    put(f);
                  },
                ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.create_new_folder_outlined,
                    color: sheet.c.accent),
                title: Text(l.folderNew,
                    style: TextStyle(
                        color: sheet.c.accent, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(sheet);
                  final name = await _askFolderName(names);
                  if (name != null) await put(name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 새 폴더 이름을 묻는다. 취소하거나 못 쓰는 이름이면 null.
  Future<String?> _askFolderName(List<String> existing) async {
    final l = L10n.of(context);
    final ctl = TextEditingController();
    final name = await showAdaptiveDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(l.folderNew),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: kFolderNameMax,
          decoration: InputDecoration(hintText: l.folderNameHint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(L10n.of(ctx).cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: Text(L10n.of(ctx).done)),
        ],
      ),
    );
    if (name == null) return null;
    final n = normalizeFolder(name);
    if (n.isEmpty) return null;
    // 이미 있으면 새로 만들지 않고 그것을 쓴다. "왜 안 만들어지지"보다
    // "아, 이미 있었구나"가 낫다.
    for (final e in existing) {
      if (e.toLowerCase() == n.toLowerCase()) return e;
    }
    return n;
  }

  Future<void> _revertToOriginal() async {
    final target = _revertTarget;
    if (target == null || target == bodyCtl.text) return;
    final l = L10n.of(context);
    final ok = await confirmDialog(context,
        title: l.revertConfirmTitle,
        body: l.revertConfirmBody,
        okLabel: l.revertConfirmOk,
        destructive: true);
    if (!ok || !mounted) return;

    // 지금 글을 먼저 남긴다. 이 순서가 뒤바뀌면 되돌리기를 되돌릴 수 없다.
    final before = bodyCtl.text;
    note.pushHistory(before, why: 'revert');
    note.body = target;
    note.lastReport = '';
    bodyCtl.text = target;
    await _save();
    if (!mounted) return;
    setState(() {});
    // 2026-08-19 소유자 신고 — 잘못 눌러 놓고 되찾는 길을 몰랐다.
    //
    // 되돌릴 수 있다는 사실이 화면 어디에도 없었다. 기록에는 멀쩡히
    // 남아 있는데 그걸 알려 주는 줄이 하나도 없으면, 그건 남아 있지 않은
    // 것과 같다. 그래서 둘을 겹쳐 둔다.
    //
    //   1. 창 하나로 **어디로 가면 되는지**를 알려 준다(소유자 지시).
    //      경고 알럿에도 같은 말이 이미 있었지만 못 보고 지나쳤다 —
    //      있는데 안 읽히는 말은 없는 말이다. 그래서 일이 벌어진 **뒤에**,
    //      화면 한가운데에서 다시 말한다.
    //   2. 창을 닫으면 아래 막대에 '실행 취소'가 남는다. 안내를 읽고
    //      "아 잘못 눌렀네" 한 사람이 그 자리에서 바로 되돌릴 수 있어야
    //      한다. 창을 먼저 띄우는 것은 그래서다 — 막대를 먼저 띄우면
    //      창이 그 위를 덮고, 창을 닫을 즈음 막대는 사라져 있다.
    await infoDialog(context,
        title: l.revertDoneTitle, body: l.revertDoneBody);
    if (!mounted) return;
    _toastUndo(context, L10n.of(context).revertedToast, () async {
      note.popHistoryIf(before);
      note.body = before;
      note.lastReport = '';
      bodyCtl.text = before;
      await _save();
      if (mounted) setState(() {});
    });
  }

  /// [forcePreview]가 참이면 설정과 무관하게 미리보기를 먼저 보여 준다.
  ///
  /// 2026-08-17 소유자 지시 — "'정리 미리보기' 기능을 편집 메뉴에 넣어줘.
  /// 메뉴 맨 위에."
  ///
  /// 그동안 미리보기는 **설정에 숨은 스위치**였다. 켜면 늘 거치고 끄면
  /// 절대 안 거친다. 그런데 사람이 실제로 원하는 건 그 중간이다 — 평소엔
  /// 그냥 정리하고, 낯선 글 하나를 만났을 때만 먼저 보고 싶다. 그건
  /// 설정이 아니라 **그때 고르는 일**이므로 메뉴에 있어야 한다.
  Future<void> _runTidyWithPreset(Preset preset,
      {bool forcePreview = false}) async {
    if (await _blockedByLimit(wizard: false)) return;
    await _save();
    final r = tidy(note.body, store.effOpts(preset, noteRules: note.rules));
    if (!mounted) return;
    final l = L10n.of(context);
    // 미리보기를 끈 사람은 바로 적용된다. 되돌리기가 있으니 안전하다
    // (2026-08-14 소유자 요청 — 매번 미리보기를 거치는 게 번거롭다).
    final apply = (store.settings.previewBeforeApply || forcePreview)
        ? await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => PreviewScreen(
                    presetName: l.presetName(preset.id, preset.name),
                    before: note.body,
                    result: r,
                    manual: forcePreview)),
          )
        : true;
    if (apply == true) {
      await _bumpUse(wizard: false);
      note.pushHistory(note.body, why: 'tidy');
      if (note.originalBody.isEmpty) note.originalBody = note.body;
      // 제목은 "본문 맨 위 한 줄"이다(소유자 확정 2026-08-14).
      // 정리하면서 맨 윗줄이 바뀔 수 있으므로(출력 시각 줄 제거 등) 다시 뽑는다.
      // 단 사용자가 손으로 쓴 제목은 건드리지 않는다 — 정리 전 첫 줄과 같을 때만
      // "자동으로 붙은 제목"으로 보고 갱신한다.
      // 예전에는 "정리 전 첫 줄과 같으면 자동으로 붙은 제목"이라고 짐작했다.
      // 이제는 짐작하지 않고 note.titleAuto가 기억한다(2026-08-16).
      final wasAuto = note.titleAuto;
      note.body = r.text;
      note.lastReport = r.summary;
      // 정리가 끝난 순간. 눈으로는 글이 확 바뀌는데 손에는 아무것도 없으면
      // '되긴 된 건가' 싶다. 가벼운 한 번이 그 틈을 메운다.
      HapticFeedback.lightImpact();
      if (wasAuto) {
        note.title = _titleFrom(r.text);
        titleCtl.text = note.title;
      }
      bodyCtl.text = note.body;
      await _save();
      if (mounted) {
        setState(() {});
        // 아래에서 올라오는 막대 대신 글 한가운데에 잠깐 떠올랐다 사라진다
        // (2026-08-17 소유자 요청). 되돌리기 버튼은 안 붙인다 — 사라지는
        // 알림에 버튼을 달면 누르려는 순간 사라진다. 되돌리기는 아래 도구
        // 막대에 늘 있고, 무엇이 바뀌었는지는 밑줄에 계속 남는다.
        // 요약은 안 넘긴다. 몇 개를 지웠는지는 사용자가 알고 싶은 것이
        // 아니다(2026-08-17 소유자 지적). 자세한 셈은 편집 화면 밑줄에
        // 그대로 남는다.
        unawaited(showMagic(context, L10n.of(context).appliedTitle, ''));
      }
    }
  }

  /// 글자 상자 — 보기 글과 결과를 같은 옷으로 보여 준다.
  ///
  /// 등폭 글꼴을 쓰는 까닭은 여기 담기는 것이 **표**이기도 하기 때문이다.
  /// 줄 맞춘 표를 프로포셔널 글꼴로 그리면 맞춰 놓은 칸이 다시 어긋나
  /// 보여서, 정작 보여 주려던 것이 안 보인다.
  Widget _sampleBox(BuildContext ctx, String text) {
    final c = ctx.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.codeBg,
        border: Border.all(color: c.codeLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: const TextStyle(
            fontFamily: MonoTextController.fontFamily,
            fontSize: 11.5,
            height: 1.55),
      ),
    );
  }

  /// 갈래 한 칸 — 이름 · 한 줄 설명 · 이렇게 됩니다.
  Widget _wayTile(BuildContext ctx, String name, String? desc, String out,
      VoidCallback onTap) {
    final c = ctx.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(desc, style: TextStyle(fontSize: 12.5, height: 1.35, color: c.sub)),
            ],
            const SizedBox(height: 8),
            _sampleBox(ctx, out),
          ],
        ),
      ),
    );
  }

  /// 보기 글 하나를 여러 갈래에 통과시켜 나란히 보여 주는 창.
  ///
  /// 2026-08-18 소유자 지시로 들어왔다. 자세한 까닭은 l10n 의 tidySample
  /// 머리말에 적었다.
  void _showWaysSheet(String sample, List<Widget> Function(BuildContext) rows) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx2, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(L10n.of(ctx).originalLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ctx.c.sub)),
            ),
            _sampleBox(ctx, sample),
            const SizedBox(height: 6),
            ...rows(ctx),
          ],
        ),
      ),
    );
  }

  void _showPresetSheet() {
    final sample = L10n.of(context).tidySample;
    _showWaysSheet(
      sample,
      (ctx) => [
        for (final p in buildPresets())
          _wayTile(
            ctx,
            L10n.of(ctx).presetName(p.id, p.name),
            L10n.of(ctx).presetDesc(p.id, p.desc),
            tidy(sample, store.effOpts(p)).text,
            () {
              Navigator.pop(ctx);
              _runTidyWithPreset(p);
            },
          ),
      ],
    );
  }

  /// 표 도구.
  ///
  /// 2026-08-14 소유자 지적: "표1 · 3열 5행"만 봐서는 본문의 어느 표인지 알 수 없다.
  /// 그래서 표를 실제 모양 그대로(등폭·칸 맞춰) 보여 주고, 큰 창에서 세로로
  /// 넘겨 보며 고르게 한다. 표가 가로로 길 수 있으니 가로 스크롤도 둔다.
  Future<void> _showTables() async {
    await _save();
    final r = extractTables(note.body);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // 큰 창으로 — 기본 절반 높이로는 표가 안 보인다
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtl) => SafeArea(
          child: r.tables.isEmpty
              ? Padding(padding: const EdgeInsets.all(30), child: Text(L10n.of(ctx).noTablesFound))
              : ListView.separated(
                  controller: scrollCtl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: r.tables.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (ctx, i) {
                    final t = r.tables[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L10n.of(ctx).tableInfo(i + 1, t.header.length, t.rows.length),
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: context.c.sub),
                        ),
                        const SizedBox(height: 6),
                        // 본문에 보이는 그 모양 그대로. 이게 있어야 "아, 그 표"가 된다.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: context.c.codeBg,
                              border: Border.all(color: context.c.codeLine),
                              borderRadius: BorderRadius.circular(10)),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              tableToAligned(t),
                              style: const TextStyle(
                                  fontFamily: MonoTextController.fontFamily,
                                  fontSize: 12.5,
                                  height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(spacing: 8, children: [
                          FilledButton.tonal(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: tableToTSV(t)));
                              Navigator.pop(ctx);
                              _toast(context, L10n.of(context).copiedSpreadsheet);
                            },
                            child: Text(L10n.of(ctx).forSpreadsheet),
                          ),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: tableToCSV(t)));
                              Navigator.pop(ctx);
                              _toast(context, L10n.of(context).copiedCsv);
                            },
                            child: const Text('CSV'),
                          ),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: tableToMarkdown(t)));
                              Navigator.pop(ctx);
                              _toast(context, L10n.of(context).copiedMarkdown);
                            },
                            child: const Text('Markdown'),
                          ),
                        ]),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  static const _aiSys =
      '너는 텍스트 편집 도구다. 사용자의 지시대로만 본문을 편집한다. 규칙: 숫자·날짜·통화·퍼센트·고유명사·URL은 절대 바꾸지 않는다. 요청하지 않은 사실을 추가하지 않고, 요청하지 않은 내용을 삭제하지 않는다. 입력 언어를 유지한다. 결과 본문만 출력하고 설명·인사·코드펜스는 붙이지 않는다.';

  /// [system]을 주면 그 규칙으로 부른다(태그 뽑기처럼 편집이 아닌 용도).
  ///
  /// 2026-08-16 — 회사(엔드포인트) 판정을 모델 이름이 아니라 키에서 한다.
  /// 전에는 모델 드롭다운이 회사 선택을 겸했다. 그래서 OpenAI 키를 넣어도
  /// 기본 모델이 Gemini면 구글 서버로 가서 무조건 거절당했다 — 소유자의
  /// "키를 넣어도 마법사가 안 된다"가 정확히 이것이었다.
  ///
  /// 모델 폐지도 여기서 스스로 회복한다. 쓰던 모델이 거절되면 예비
  /// 사다리(core/ai_provider.dart)를 위에서부터 시도하고, 성공한 모델을
  /// 설정에 저장한 뒤 한 줄로 알린다. 1년에 두어 번 있는 "제일 싼 모델
  /// 폐지"가 앱 업데이트 없이 지나가게 하기 위한 장치다(소유자 질문).
  Future<String> _aiEditCall(String instruction, String body, {String? system}) async {
    final s = store.settings;
    final p = s.aiProvider.isNotEmpty
        ? s.aiProvider
        : (providerOfKey(s.aiKey) ?? providerOfModel(s.aiModel) ?? 'google');
    final cands = <String>[
      if (s.aiModel.isNotEmpty && modelMatchesProvider(s.aiModel, p)) s.aiModel,
      ...defaultLadder(p).where((m) => m != s.aiModel),
    ];
    Object lastErr = Exception('no model');
    for (var i = 0; i < cands.length; i++) {
      try {
        final out = await _aiCallOnce(p, cands[i], system ?? _aiSys, instruction, body);
        if (s.aiModel != cands[i] || s.aiProvider != p) {
          s.aiModel = cands[i];
          s.aiProvider = p;
          await store.persistSettings();
          if (mounted) _toast(context, L10n.of(context).aiModelSwitched(cands[i]));
        }
        return out;
      } catch (e) {
        lastErr = e;
      }
    }
    // 2026-08-16 — Exception을 또 Exception으로 싸면 화면에
    // "Exception: Exception: ..."이 두 겹으로 나온다(소유자 화면에서 확인).
    // 마지막 오류를 그대로 던진다.
    throw lastErr; // ignore: only_throw_errors
  }


  Future<String> _aiCallOnce(String provider, String model, String sys,
          String instruction, String body) =>
      aiCallOnce(
        provider: provider,
        model: model,
        key: store.settings.aiKey,
        sys: sys,
        instruction: instruction,
        body: body,
      );

  Future<void> _showWizardDialog() async {
    if (await _blockedByLimit(wizard: true)) return;
    await _bumpUse(wizard: true);
    final cmdCtl = TextEditingController();
    List<String> applied = [];
    List<String> unknown = [];
    bool aiBusy = false;
    // 2026-08-14 소유자 지적: 애플식 알림창(AlertDialog.adaptive)은 폭이 좁고
    // 버튼이 가장자리까지 꽉 차 답답하다. 이 창은 '알림'이 아니라 입력+결과를
    // 보여 주는 작업창이므로 여백을 갖춘 일반 대화상자로 쓴다.
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final l = L10n.of(ctx);
          final w = MediaQuery.of(ctx).size.width;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l.wizardTitle),
            content: SizedBox(
              // 화면이 좁으면 화면을 꽉 채우고(양옆 여백만 남기고), 넓으면 480에서 멈춘다.
              width: w < 520 ? w : 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: cmdCtl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l.wizardHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 2026-08-14 소유자 요청: 자주 쓰는 지시문을 등록해 두고 골라 쓴다.
                    // 같은 지시를 매번 다시 치지 않게 하는 것이 목적이다.
                    //
                    // '선택'은 입력칸에 채워 넣기만 하고 바로 실행하지 않는다.
                    // 대개 "이번엔 조금 다르게"가 붙기 때문에 손볼 틈이 있어야 한다.
                    // 소유자 지시도 "편집가능 상태로"였다.
                    //
                    // 고른 지시문은 다시 맨 위로 올라간다 — 등록만이 아니라
                    // '사용'도 최근 기록이다. 순서 규칙은 core/mru.dart가 갖고
                    // 있고 테스트로 고정돼 있다.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final t = cmdCtl.text.trim();
                          if (t.isEmpty) return;
                          mruInsert(store.settings.favPrompts, t);
                          await store.persistSettings();
                          setD(() {});
                          if (mounted) _toast(context, L10n.of(context).favSavedToast);
                        },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: Text(l.favSaveButton),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(l.favListTitle,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.c.sub)),
                    ),
                    Container(
                      // 등록이 늘어나도 창이 길어지지 않게 높이를 묶고 안에서 굴린다.
                      height: 168,
                      decoration: BoxDecoration(
                        color: context.c.codeBg,
                        border: Border.all(color: context.c.codeLine),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: store.settings.favPrompts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(l.favEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14, color: context.c.guideInk)),
                              ),
                            )
                          : Scrollbar(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: store.settings.favPrompts.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: context.c.codeLine),
                                itemBuilder: (_, i) {
                                  final p = store.settings.favPrompts[i];
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 4, 2, 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(p,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 14, height: 1.3)),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            cmdCtl.text = p;
                                            cmdCtl.selection = TextSelection.collapsed(
                                                offset: cmdCtl.text.length);
                                            mruInsert(store.settings.favPrompts, p);
                                            await store.persistSettings();
                                            setD(() {});
                                          },
                                          child: Text(l.favUse),
                                        ),
                                        IconButton(
                                          tooltip: l.favRemove,
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () async {
                                            store.settings.favPrompts.remove(p);
                                            await store.persistSettings();
                                            setD(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    for (final a in applied)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.appliedPrefix(a),
                            style: TextStyle(color: context.c.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    // 한 줄로 합쳐 보여 준다.
                    //
                    // 규칙 엔진은 지시문을 문장 단위로 쪼개는데, 쪼갠 조각마다
                    // "해석 불가"를 한 줄씩 찍고 있었다. 지시 하나를 넣었는데
                    // 실패가 셋으로 보이니, 사용자에게는 세 배로 고장 난
                    // 것처럼 읽힌다. 못 알아들은 것은 하나다 — 그 지시.
                    // 도는 동안에는 돈다고 말한다. 이 자리에 '해석 불가'가
                    // 떠 있으면, 일이 되고 있는 중에 고장 났다고 적힌
                    // 셈이다(2026-08-19 소유자 신고).
                    if (aiBusy)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.aiWorking,
                            style: TextStyle(
                                color: context.c.accent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      )
                    else if (unknown.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        // 경고색을 뺐다. 이건 실패가 아니라 **다음 차례**다.
                        child: Text(l.unknownPrefix(unknown.join(' ')),
                            style: TextStyle(color: context.c.sub, fontSize: 12.5)),
                      ),
                    if (!aiBusy &&
                        unknown.isNotEmpty &&
                        store.settings.aiKey.isEmpty &&
                        aiUiVisible())
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(l.aiKeyPromo,
                            style: TextStyle(fontSize: 12, color: context.c.sub)),
                      ),
                    // 여기 있던 단추 둘('해석 불가 명령을 AI로 실행',
                    // 'AI 결과 적용')과 결과 미리보기 상자를 걷어냈다.
                    // 아래 하나뿐인 단추가 그 일을 다 한다.
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
              const SizedBox(width: 8),
              // ── 단추 하나가 전부 한다 ────────────────────────────────
              //
              // 2026-08-17 소유자 지적: "적용 버튼이 너무 많다. 한번에
              // 되어야하지, 뭐가 저렇게 복잡하냐?"
              //
              // 옳다. 규칙 엔진이 먼저 보고 못 알아들은 것만 AI로 넘긴다는
              // 것은 **우리 사정**이다. 값을 아끼려고 그렇게 짜 놓고는, 그
              // 절약의 대가를 사용자에게 단추 세 개로 청구하고 있었다.
              // 순서는 그대로 두되 물어보지 않는다 — 규칙으로 안 되면 곧장
              // AI로 가고, 결과는 바로 적용한다.
              //
              // 미리보기를 없앤 것이 마음에 걸릴 수 있으나, 고치기 전 글은
              // 이미 버전기록에 넣고 있다. 되돌리기 한 번이면 돌아온다.
              // 되돌릴 수 있는 일을 미리 확인받는 것은 안전이 아니라 절차다.
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                onPressed: aiBusy
                    ? null
                    : () async {
                        final before = bodyCtl.text;
                        final r = applyWizard(
                            command: cmdCtl.text, settings: store.settings, body: before);
                        var text = r.bodyChanged ? r.body : before;
                        await store.persistSettings();

                        var usedAi = false;
                        var guard = '';
                        if (r.unknown.isNotEmpty &&
                            store.settings.aiKey.trim().isNotEmpty) {
                          setD(() {
                            aiBusy = true;
                            applied = r.applied;
                            unknown = r.unknown;
                          });
                          try {
                            // **원래 지시문을 그대로 보낸다.**
                            //
                            // 여기가 "한번에 안되고 다시 한번 해야 된다"의
                            // 진짜 원인이었다. 그동안 AI에게 넘긴 것은
                            // 규칙 엔진이 문장 단위로 쪼개 놓은 조각들을
                            // 마침표로 이어 붙인 것이었다. 그래서
                            //
                            //   "문서 맨 위나 맨 아래의 ai답변 시간인.
                            //    날짜와 시간 표시를 모두 삭제해.
                            //    (예시 : 2026-08-14(금) 08:16)"
                            //
                            // 처럼 첫 조각이 목적어를 잃은 채 끊긴 문장이
                            // 갔다. 사람도 못 알아들을 말을 보내 놓고
                            // 모델이 못 알아들었다고 할 수는 없다.
                            var out = (await _aiEditCall(
                                    cmdCtl.text.trim(), text))
                                .trim();
                            out = out
                                .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
                                .replaceFirst(RegExp(r'\n?```$'), '');
                            if (out.isEmpty) throw Exception(l.aiEmptyResponse);
                            guard = numberGuard(text, out);
                            text = out;
                            usedAi = true;
                          } catch (e) {
                            setD(() => aiBusy = false);
                            if (!mounted) return;
                            // 짧게 지나가는 알림에는 처방을 띄운다. 영어 예외
                            // 문자열을 2초 보여 주는 것은 아무것도 안 보여
                            // 주는 것과 같다.
                            final ll = L10n.of(context);
                            final fix = aiRemedy(ll, '$e');
                            _toast(context,
                                fix.isNotEmpty ? fix : ll.aiCallFailed('$e'));
                            return;
                          }
                        }

                        if (text != before) {
                          note.pushHistory(before, why: 'ai');
                          bodyCtl.text = text;
                        }
                        await _save();
                        if (mounted) setState(() {});

                        // 창을 남기는 경우는 하나뿐이다 — 규칙이 못 알아들었고
                        // AI 키도 없어서 더 해 볼 것이 없을 때. 그때는 무엇이
                        // 안 됐는지 보여 줘야 한다. 그 밖에는 닫는다. 창이
                        // 남아 있으면 "적용이 된 건가?" 하고 헷갈린다
                        // (2026-08-14 소유자 지적).
                        if (r.unknown.isNotEmpty && !usedAi) {
                          setD(() {
                            applied = r.applied;
                            unknown = r.unknown;
                            aiBusy = false;
                          });
                          return;
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        final ll = L10n.of(context);
                        if (guard.isNotEmpty) {
                          // 숫자가 달라졌다. 이건 그냥 지나가면 안 된다 —
                          // 이 앱으로 다루는 글에는 수익률과 종가가 들어 있다.
                          _toast(context, guard);
                        } else if (usedAi) {
                          _toast(context, ll.aiAppliedToast);
                        } else {
                          _toast(
                              context,
                              r.applied.isEmpty
                                  ? ll.wizardNothingToDo
                                  : ll.wizardAppliedToast(r.applied.length));
                        }
                      },
                child: Text(aiBusy ? l.aiBusyLabel : l.interpretApply),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 찾기 — 그리고 필요하면 바꾸기.
  ///
  /// 2026-08-27 소유자 지시로 앞뒤를 뒤집었다. 전에는 이 창이 '바꾸기'
  /// 창이었고 찾기 칸은 그 재료였다. 그런데 사람이 훨씬 자주 하는 일은
  /// **찾기**다. 바꾸기는 찾은 다음에 가끔 하는 일이다.
  ///
  /// 그래서 기본은 찾기 하나뿐이고, '대치'를 누르면 그때 바꿀 말 칸이
  /// 펴지면서 '바꾸기'와 '모두 바꾸기'가 살아난다. 자주 하는 일을 앞에
  /// 두고 가끔 하는 일을 한 겹 뒤에 두는 것 — 이 앱이 메뉴를 두 뎁스로
  /// 접을 때 쓴 규칙과 같다.
  Future<void> _showFindDialog() async {
    final findCtl = TextEditingController();
    final withCtl = TextEditingController();
    bool useRegex = false;
    bool showReplace = false;
    bool saveRule = false;
    bool ruleForAll = true;
    // 어디부터 찾을까. 창을 열 때의 커서 자리에서 시작해서, '바꾸기'를
    // 누를 때마다 앞으로 나아간다.
    int cursor = bodyCtl.selection.isValid ? bodyCtl.selection.end : 0;

    await showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final l = L10n.of(ctx);
          final find = findCtl.text;
          final hits = findAll(bodyCtl.text, find, regex: useRegex);

          /// 찾은 자리로 커서를 옮기고 창을 닫는다. 창이 떠 있는 동안에는
          /// 본문이 손을 놓고 있어서 고른 자리가 안 보인다 — 보여 주려면
          /// 닫고 본문에 손을 돌려줘야 한다.
          void jump(({int start, int end}) m) {
            Navigator.pop(ctx);
            bodyCtl.selection =
                TextSelection(baseOffset: m.start, extentOffset: m.end);
            _bodyFocus.requestFocus();
          }

          Future<void> replaceOne() async {
            final m = findNextAfter(bodyCtl.text, find, cursor, regex: useRegex);
            if (m == null) return;
            final raw = withCtl.text;
            var repl = raw.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
            if (useRegex) {
              try {
                final one = RegExp(find).firstMatch(
                    bodyCtl.text.substring(m.start, m.end));
                if (one != null) {
                  for (int g = 1; g <= one.groupCount; g++) {
                    repl = repl.replaceAll('\$$g', one.group(g) ?? '');
                  }
                }
              } catch (_) {}
            }
            note.pushHistory(bodyCtl.text, why: 'replace');
            bodyCtl.text = bodyCtl.text.replaceRange(m.start, m.end, repl);
            cursor = m.start + repl.length;
            await _save();
            setD(() {});
          }

          return AlertDialog.adaptive(
            title: Text(l.findTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: findCtl,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l.findLabel),
                    onChanged: (_) => setD(() {}),
                  ),
                  // 몇 개인지 바로 말해 준다. 이 한 줄이 없으면 사람은
                  // '찾기'를 눌러 봐야만 있는지 없는지 안다.
                  if (find.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        hits.isEmpty ? l.findNone : l.findHits(hits.length),
                        style: TextStyle(
                            fontSize: 13,
                            color: hits.isEmpty
                                ? Theme.of(ctx).hintColor
                                : ctx.c.accent),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(children: [
                    // 대치 펴기. 켜면 아래가 열리고 단추가 바뀐다.
                    TextButton.icon(
                      onPressed: () => setD(() => showReplace = !showReplace),
                      icon: Icon(
                          showReplace
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18),
                      label: Text(l.showReplaceLabel),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Spacer(),
                    // 정규식은 찾기에도 쓰이므로 늘 보인다.
                    Text(l.regexLabel, style: const TextStyle(fontSize: 13)),
                    Checkbox(
                      value: useRegex,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setD(() => useRegex = v ?? false),
                    ),
                  ]),
                  if (showReplace) ...[
                    TextField(
                      controller: withCtl,
                      decoration:
                          InputDecoration(labelText: l.replaceWithLabel),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.saveAsRule,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(l.saveAsRuleSub,
                          style: const TextStyle(fontSize: 12)),
                      value: saveRule,
                      onChanged: (v) => setD(() => saveRule = v ?? false),
                    ),
                    // 2026-08-24 소유자 지시 — 저장할 때 범위를 고른다.
                    if (saveRule) ...[
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l.ruleScopeAll,
                            style: const TextStyle(fontSize: 13)),
                        value: true,
                        groupValue: ruleForAll,
                        onChanged: (v) => setD(() => ruleForAll = v ?? true),
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l.ruleScopeNote,
                            style: const TextStyle(fontSize: 13)),
                        value: false,
                        groupValue: ruleForAll,
                        onChanged: (v) => setD(() => ruleForAll = v ?? true),
                      ),
                    ],
                  ],
                  // 이 노트 전용 규칙 목록. 지우는 길이 여기 하나뿐이므로
                  // 목록 없이 저장만 되게 두면 규칙이 유령이 된다.
                  if (showReplace && note.rules.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(l.noteRules,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(ctx).hintColor)),
                    for (int i = 0; i < note.rules.length; i++)
                      Row(children: [
                        Expanded(
                          child: Text(
                            '${note.rules[i].find} → ${note.rules[i].replace}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            note.rules.removeAt(i);
                            unawaited(_save());
                            setD(() {});
                          },
                        ),
                      ]),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              if (!showReplace)
                FilledButton(
                  // 찾은 것이 없으면 죽어 있다. 눌러도 아무 일 없는 단추는
                  // 없는 것보다 나쁘다.
                  onPressed: hits.isEmpty
                      ? null
                      : () {
                          final m = findNextAfter(
                              bodyCtl.text, find, cursor, regex: useRegex);
                          if (m != null) jump(m);
                        },
                  child: Text(l.findAction),
                )
              else ...[
                TextButton(
                  onPressed: hits.isEmpty ? null : () => unawaited(replaceOne()),
                  child: Text(l.replaceOneAction),
                ),
                FilledButton(
                  onPressed: hits.isEmpty
                      ? null
                      : () async {
                          final rawRepl = withCtl.text;
                          final repl = rawRepl
                              .replaceAll(r'\n', '\n')
                              .replaceAll(r'\t', '\t');
                          int count = 0;
                          String result = bodyCtl.text;
                          try {
                            if (useRegex) {
                              final re = RegExp(find);
                              count = re.allMatches(bodyCtl.text).length;
                              result =
                                  bodyCtl.text.replaceAllMapped(re, (m) {
                                var r2 = repl;
                                for (int g = 1; g <= m.groupCount; g++) {
                                  r2 = r2.replaceAll('\$$g', m.group(g) ?? '');
                                }
                                return r2;
                              });
                            } else {
                              count = find.allMatches(bodyCtl.text).length;
                              result = bodyCtl.text.split(find).join(repl);
                            }
                          } catch (_) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              _toast(context, L10n.of(context).invalidRegex);
                            }
                            return;
                          }
                          Navigator.pop(ctx);
                          if (count == 0) {
                            if (mounted) {
                              _toast(context, L10n.of(context).noMatches);
                            }
                            return;
                          }
                          note.pushHistory(bodyCtl.text, why: 'replace');
                          bodyCtl.text = result;
                          if (saveRule) {
                            final rule = CustomRule(
                                find: find,
                                replace: rawRepl,
                                regex: useRegex);
                            if (ruleForAll) {
                              store.settings.customRules.add(rule);
                              await store.persistSettings();
                            } else {
                              // 노트 전용 — 아래 _save()가 도장 찍어 저장하고
                              // 동기화가 노트와 함께 나른다.
                              note.rules.add(rule);
                            }
                          }
                          await _save();
                          if (mounted) {
                            setState(() {});
                            final lm = L10n.of(context);
                            _toast(context,
                                '${lm.replacedCount(count)}${saveRule ? lm.savedRuleSuffix : ''}');
                          }
                        },
                  child: Text(l.replaceAllAction),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 복사 종류 고르기.
  ///
  /// 2026-08-18 소유자 지시 — "복사할 종류도 좀더 알기 쉽게, 직관적으로.
  /// 예시를 들어서."
  ///
  /// 정리 방식과 같은 얼개다. 보기 글 하나를 네 갈래로 통과시킨다. '전체
  /// 복사'와 '마크다운 그대로 복사'의 차이는 말로 하면 한 문단이지만
  /// 나란히 놓으면 한 눈이다.
  void _showCopyMenu() {
    final sample = L10n.of(context).tidySample;
    final sampleTables = extractTables(sample);
    _showWaysSheet(sample, (ctx) {
      final l = L10n.of(ctx);
      return [
        // 2026-08-18 — 복사하면 표시가 벗겨진다. 이 앱의 컨셉이다.
        // 노트에는 마크다운을 담아 두어 굵게 보여 주고, 밖으로 나가는
        // 순간 맨 글자가 된다.
        _wayTile(ctx, l.copyAll, l.copyPlainSub, toPlain(sample), () {
          Clipboard.setData(ClipboardData(text: toPlain(bodyCtl.text)));
          Navigator.pop(ctx);
          _toast(context, L10n.of(context).copiedAll);
        }),
        // 마크다운을 아는 곳(노션·슬랙·깃허브·옵시디언)에 붙일 때는
        // 표시가 있어야 굵게가 살아난다.
        _wayTile(ctx, l.copyRaw, l.copyRawSub, sample, () {
          Clipboard.setData(ClipboardData(text: bodyCtl.text));
          Navigator.pop(ctx);
          _toast(context, L10n.of(context).copiedAll);
        }),
        _wayTile(ctx, l.tidyCopy, l.tidyCopySub,
            tidy(sample, store.effOpts(buildPresets().first)).text, () {
          final r = tidy(bodyCtl.text,
              store.effOpts(buildPresets().first, noteRules: note.rules));
          Clipboard.setData(ClipboardData(text: r.text));
          Navigator.pop(ctx);
          _toast(context, L10n.of(context).tidyCopied(r.summary));
        }),
        _wayTile(
            ctx,
            l.copyTableSpreadsheet,
            null,
            sampleTables.tables.map(tableToTSV).join('\n\n'), () {
          final r = extractTables(bodyCtl.text);
          Navigator.pop(ctx);
          if (r.tables.isEmpty) {
            _toast(context, L10n.of(context).noTablesFound);
          } else {
            Clipboard.setData(
                ClipboardData(text: r.tables.map(tableToTSV).join('\n\n')));
            _toast(context, L10n.of(context).copiedTableSpreadsheet);
          }
        }),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    if (!_found) {
      return Scaffold(body: Center(child: Text(l.noteNotFound)));
    }
    // 날짜 줄의 높이는 그려 봐야 안다. 다음 프레임에 재고, 달라졌을
    // 때만 한 번 더 그린다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHead());
    // 설정을 바꾸면 다음 build에서 바로 반영된다(컨트롤러가 매번 이 값을 본다).
    bodyCtl.monoEnabled = store.settings.monoEditor;
    bodyCtl.bodyFontSize = store.settings.bodyFontSize;
    bodyCtl.lineHeight = store.settings.bodyLineHeight;
    // 마크다운을 눈에 보이게 그릴 때 쓸 색(2026-08-18).
    bodyCtl.subColor = context.c.sub;
    bodyCtl.accentColor = context.c.accent;

    // 종이. 고르지 않았으면 paper.id == kPaperNone이고 아래 색은 안 쓴다.
    final paper = paperById(store.settings.paperMode);
    final onPaper = paper.id != kPaperNone;
    final darkNow = Theme.of(context).brightness == Brightness.dark;
    final paperBg = onPaper ? Color(paper.bgOf(darkNow)) : context.c.panel;
    final paperInk = onPaper ? Color(paper.inkOf(darkNow)) : null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _save();
          // 화면을 나가는 순간은 모아 둘 이유가 없다. 바로 쓴다.
          unawaited(store.flush());
        }
      },
      child: Scaffold(
        backgroundColor: paperBg,
        // 키보드는 안쪽 Scaffold 하나만 맡는다.
        //
        // 2026-08-16 소유자 신고 — "키보드 올라오면 툴바가 붕 떠서 위로
        // 올라가고 본문이 안 보인다." 원인이 바로 여기였다.
        //
        // 플러터 원본(_ScaffoldLayout.performLayout)의 셈은 이렇다.
        //   아래막대의 위치 = max(0, 높이 - 아래막대높이)
        //   본문 높이       = 높이 - max(키보드, 아래막대높이)
        //
        // 이 화면은 Scaffold가 둘이라 키보드를 둘이 나눠 맡고 있었다.
        //   1) 바깥이 키보드만큼 줄인다 → 안쪽에 388 남는다
        //   2) 바깥은 자기 body로 넘길 때 viewInsets를 지운다
        //      (removeBottomInset) → 안쪽은 키보드가 없다고 본다
        //   3) 그런데 아래 막대의 MediaQuery.of(context)는 이 build 메서드의
        //      context, 즉 두 Scaffold보다 **위**다. 지워지기 전 345가 온다
        //   → 아래 막대가 44+345=389를 요구, 남은 높이는 388.
        //     389 > 388 이라 막대 위치가 max(0, -1) = 0, 즉 화면 맨 위.
        //     본문 높이는 0이 된다. 정확히 신고된 그림이다.
        //
        // 한 픽셀 차이였다. 광고 배너가 자리를 먹고 한글 키보드(추천줄 포함)가
        // 올라온 조합에서 경계를 넘었다. 이런 건 '가끔'이 아니라 '경계를
        // 넘는 순간부터 항상'이다.
        //
        // 그래서 임자를 하나로 못 박는다. 배너는 화면 꼭대기에 있으니
        // 키보드를 피할 이유가 애초에 없다.
        resizeToAvoidBottomInset: false,
        // 2026-08-16 소유자 지시 — 배너는 상단바(뒤로가기 줄)보다도 위,
        // 화면 진짜 꼭대기다. 원래 화면 전체(상단바 포함)를 안쪽
        // Scaffold로 감싸 배너 아래로 넣는다.
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            if (!widget.embedded) const TopBannerBar(),
            Expanded(
              child: Scaffold(
        // 종이는 화면 전체에 깔린다. 글 칸만 색을 바꾸면 위아래로 흰 띠가
        // 남아서 '색을 잘못 칠한 화면'으로 보인다. 실제 수첩도 종이가
        // 먼저 있고 그 위에 줄이 있다.
        backgroundColor: paperBg,
        // 키보드의 임자는 여기 하나다(위 주석 참고). 기본값이지만 일부러
        // 적어 둔다 — 이 값이 바깥과 겹치면 방금 그 사고가 다시 난다.
        resizeToAvoidBottomInset: true,
        // 머리 밑으로 종이가 이어지게 한다. 종이가 머리에서 끊기면
        // 유리 너머로 보이는 것이 흰 띠뿐이라 비치는 뜻이 없다.
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          // 머리 밑으로 글이 흘러 들어가되, **읽히지는 않게** 한다.
          //
          // 2026-08-27 소유자 지시 — 클로드 앱처럼. 그전까지 이 머리는
          // 그냥 투명이었다. 글이 제목 뒤로 그대로 비쳐서 두 줄이 겹쳐
          // 읽혔고, 제목도 본문도 안 읽혔다. 비치는 것이 멋인 줄 알았지만
          // 읽히는 것이 먼저다.
          //
          // 흐림(BackdropFilter)을 쓴다. 색만 얹어 가리면 그건 유리가
          // 아니라 뚜껑이다 — 밑에 뭔가 흐르고 있다는 감각이 사라진다.
          // 흐리면 색과 움직임은 남고 글자만 죽는다. 애플이 이 재료를
          // 쓰는 까닭이 그것이다.
          //
          // 아래 끝은 선을 긋지 않고 흐림째로 사라지게 한다(ShaderMask).
          // 실선을 그으면 머리가 종이에서 떨어진 별개의 판으로 보이고,
          // 흐림만 뚝 끊으면 그 자리에 눈에 거슬리는 턱이 생긴다.
          flexibleSpace: const _HeadGlass(),
          automaticallyImplyLeading: !widget.embedded,
          // 넓은 화면에서만 나오는 목록 접기 단추.
          //
          // 자리를 여기로 잡은 이유: 접었을 때 다시 펼 수 있는 곳은 남아
          // 있는 칸뿐이다. 목록 쪽에 두면 접는 순간 같이 사라진다.
          // 애플의 사이드바 단추도 같은 자리에 있다.
          leading: widget.embedded && SplitShell.of(context) != null
              ? IconButton(
                  tooltip: l.toggleListTooltip,
                  icon: Icon(SplitShell.of(context)!.listOpen
                      ? Icons.menu_open
                      : Icons.menu),
                  onPressed: () => SplitShell.of(context)!.toggleList(),
                )
              : null,
          centerTitle: true,
          // 2026-08-19 소유자 지시 — "편집 화면 맨 위 중앙에 글 제목이
          // 나오면 좋겠다. 그거 터치하면 글제목 태그 편집 화면으로.
          // 그리고 한번 더 터치하면 글제목 태그 편집 사라지고."
          //
          // 여기는 비어 있었다. 2026-08-16 에 제목 칸을 평소엔 숨기기로
          // 했는데(자동으로 붙으니까), 그러고 나니 **이 화면이 무슨 글인지
          // 알려 주는 것이 하나도 남지 않았다.** 목록에서 방금 눌러
          // 들어왔으면 알지만, 앱을 다시 열면 마지막 글이 그냥 열린다.
          //
          // 그래서 머리에는 보여 주기만 하고, 고치려면 눌러서 편다.
          // 숨긴 까닭과 알려 줄 필요를 둘 다 지킨다.
          //
          // Listenable.merge 로 두 칸을 함께 듣는 까닭 — 제목은 손으로 적은
          // 것이 없으면 본문에서 뽑는다. setState 로 하면 글자를 칠 때마다
          // 화면 전체를 다시 그려야 하고, 안 하면 머리가 옛 제목에 멈춘다.
          // 여기서 듣게 하면 머리 글자 하나만 다시 그린다.
          title: AnimatedBuilder(
            animation: Listenable.merge([titleCtl, bodyCtl]),
            builder: (_, __) {
              final empty = _headTitleEmpty;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 뭔가가 열리고 닫히는 순간이다. 이런 데만 준다.
                  HapticFeedback.selectionClick();
                  final opening = !_showMeta;
                  setState(() => _showMeta = opening);
                  // 2026-08-19 소유자 신고 — "제목 입력란을 못 찾는 유저가
                  // 있음." 펴 주기만 하고 손을 놓으면, 칸이 나와도 어디를
                  // 눌러야 하는지 또 찾아야 한다. 제목이 비어 있으면 그
                  // 칸으로 바로 데려간다. 이미 제목이 있으면 안 데려간다 —
                  // 보려고 편 사람의 손에서 자판이 튀어나오면 방해다.
                  if (opening && empty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _titleFocus.requestFocus();
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _headTitle(l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            // 빈 자리의 안내말은 제목이 아니다. 덜 굵게 해서
                            // 진짜 제목과 눈으로 구별되게 둔다.
                            fontWeight:
                                empty ? FontWeight.w600 : FontWeight.w700,
                            // 펴 두었을 때 색이 바뀐다. 눌러서 뭔가 됐다는
                            // 것을 알려 주는 가장 조용한 방법이다.
                            color:
                                _showMeta ? context.c.accent : context.c.sub),
                      ),
                    ),
                    // 제목 바로 오른쪽의 연필 (2026-08-27 소유자 지시).
                    //
                    // 처음에는 머리 오른쪽 끝, 동기화 단추가 있던 자리에
                    // 뒀다. 소유자 지적 — "지금은 '글쓰기' 버튼처럼
                    // 보이잖아." 맞다. **아이콘의 뜻은 모양이 아니라 자리가
                    // 정한다.** 머리 오른쪽 끝의 연필은 어느 앱에서나 '새
                    // 글 쓰기'다. 같은 연필이라도 제목에 붙어 있으면 '이
                    // 제목을 고친다'가 된다.
                    //
                    // 제목이 있을 때는 아이콘이 시끄럽다고 여겨 숨겼던
                    // 것도 이번에 걷는다. 숨겨 놓으니 아무도 제목이
                    // 눌린다는 것을 몰랐다 — 08-19 신고가 그것이었다.
                    // 작게 둔다(2026-08-27 소유자 지시 — 30% 작게).
                    // 크면 여전히 '새 글 쓰기' 단추로 읽힌다. 이건 누르라고
                    // 부르는 단추가 아니라 **여기가 눌린다는 귀띔**이다.
                    // 귀띔은 작을수록 귀띔답다.
                    const SizedBox(width: 5),
                    Icon(_showMeta ? Icons.edit : Icons.edit_outlined,
                        size: 11,
                        color: _showMeta ? context.c.accent : context.c.sub),
                  ],
                ),
              );
            },
          ),
          actions: [
            if (_editing)
              TextButton(
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Text(l.done, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            // 2026-08-17 소유자 지시 — 위쪽 '정리' 버튼을 뺐다.
            //
            // 이건 아래 막대의 '정리'가 한 번에 안 되던 시절의 잔재다. 그때는
            // 아래 것을 누르면 어떤 방식으로 정리할지 고르는 창이 떴고, 손이
            // 위에 있을 때 바로 누를 지름길이 따로 필요했다.
            //
            // 그 뒤 아래 것이 한 번 누르면 바로 도는 쪽으로 바뀌면서
            // (문을 하나로 합쳤다) 지름길과 목적지가 같아졌다. 같은 일을
            // 하는 버튼이 한 화면에 둘 있으면 사용자는 둘이 다른 일인가
            // 의심한다 — 이 앱은 '정리'와 '자동 정리'가 따로 있어서 같은
            // 신고를 이미 한 번 받았다.
            // 2026-08-19 — 태그와 핀을 메뉴로 내렸다.
            //
            // 둘 다 이 화면에 오래 머물 자격이 없었다. 태그는 글을 다 쓴
            // 뒤 한 번, 핀은 몇 달에 한 번 누른다. 그런데 매번 여는 화면의
            // 맨 위에 늘 앉아 있었다.
            //
            // 무엇을 위에 둘지는 '얼마나 중요한가'가 아니라 '얼마나 자주
            // 누르는가'로 정한다. 중요한 것을 위에 두면 만든 사람이 중요하게
            // 여기는 것이 올라오고, 자주 누르는 것을 위에 두면 쓰는 사람이
            // 자주 하는 일이 올라온다.
            // 2026-08-16 소유자 요청 — 애플 메모장처럼 '...' 메뉴.
            // 이 메모에 대한 설정이 앞으로 여기에 쌓인다. 지금은 삭제 하나.
            PopupMenuButton<String>(
              // 목록 화면과 같은 삼선. 한쪽만 바꾸면 같은 일을 하는 버튼이
              // 두 모양이 된다(2026-08-17).
              icon: const Icon(Icons.menu),
              tooltip: l.moreTooltip,
              // 2026-08-16 소유자 신고 — 메뉴가 '...' 버튼 위를 덮어서, 같은
              // 자리를 다시 눌러 닫는 토글이 안 됐다. 기본값이 버튼을 중심에
              // 두고 펼치는 방식(over)이라 그렇다. under로 바꾸면 버튼 아래로
              // 내려가 버튼이 계속 보이고, 그 자리를 다시 누르면 닫힌다.
              position: PopupMenuPosition.under,
              offset: const Offset(0, 6),
              onSelected: (v) async {
                // 2026-08-16 소유자 요청 — '...' 맨 아래에 앱 설정을 둔다.
                // 위쪽은 앞으로도 편집 관련 항목 자리이고(지금은 삭제 하나),
                // 앱 설정은 편집과 직접 상관이 없어 구분선으로 갈라 놨다.
                if (v.startsWith('set:')) {
                  final a = v.substring(4);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(anchor: a.isEmpty ? null : a),
                    ),
                  );
                  if (mounted) setState(() {});
                  return;
                }
                if (v == 'wizard') {
                  _showWizardDialog();
                  return;
                }
                if (v == 'tables') {
                  _showTables();
                  return;
                }
                if (v == 'replace') {
                  _showFindDialog();
                  return;
                }
                if (v == 'copy') {
                  _showCopyMenu();
                  return;
                }
                if (v == 'meta') {
                  setState(() => _showMeta = !_showMeta);
                  return;
                }
                if (v == 'pin') {
                  note.pinned = !note.pinned;
                  // 뭔가가 '딸깍' 하고 자리를 잡는 순간이다. 이런 데만 준다.
                  HapticFeedback.selectionClick();
                  await store.persist();
                  if (mounted) setState(() {});
                  return;
                }
                if (v == 'preview') {
                  // 설정이 꺼져 있어도 이번 한 번은 먼저 보여 준다.
                  await _runTidyWithPreset(buildPresets().first,
                      forcePreview: true);
                  return;
                }
                if (v == 'folder') {
                  await _pickFolder();
                  return;
                }
                if (v == 'revert') {
                  await _revertToOriginal();
                  return;
                }
                if (v == 'history') {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => HistorySheet(note: note),
                  );
                  if (!mounted) return;
                  bodyCtl.text = note.body;
                  titleCtl.text = note.title;
                  setState(() {});
                  return;
                }
                if (v == 'append') {
                  final text = await ImportService.pickAppendText();
                  if (text == null || !mounted) return;
                  bodyCtl.text = bodyCtl.text.trimRight() + text;
                  await _save();
                  if (mounted) setState(() {});
                  return;
                }
                if (v == 'preset') {
                  // 길게 누르기는 맥·PC에서 자연스럽지 않다. 여기 하나 더
                  // 두어 어느 기기에서든 찾을 수 있게 한다.
                  _showPresetSheet();
                  return;
                }
                if (v == 'export') {
                  final ok = await ExportService.shareNote(note);
                  if (!ok && mounted) {
                    _toast(context, L10n.of(context).exportFailed);
                  }
                  return;
                }
                if (v == 'attach') {
                  await _addAttachment();
                  return;
                }
                if (v == 'lock') {
                  if (await toggleNoteLock(context, note) && mounted) {
                    setState(() {});
                  }
                  return;
                }
                if (v == 'pdf' || v == 'print') {
                  final ok = v == 'print'
                      ? await PdfService.printNote(note,
                          dateLabel: _pdfDate(note.updatedAt))
                      : await PdfService.sharePdf(note,
                          dateLabel: _pdfDate(note.updatedAt));
                  if (!ok && mounted) {
                    _toast(context, L10n.of(context).pdfFailed);
                  }
                  return;
                }
                if (v != 'delete') return;
                final ok = await confirmDialog(context,
                    title: L10n.of(context).deleteConfirmTitle,
                    okLabel: L10n.of(context).delete,
                    destructive: true);
                if (ok && mounted) {
                  store.deleteNote(note.id);
                  Navigator.pop(context);
                }
              },
              itemBuilder: (ctx) {
                final lm = L10n.of(ctx);
                // 2026-08-19 — 아래 막대에 있던 넷과 위에 있던 둘이
                // 여기로 들어왔다. 메뉴로 옮긴 것을 아무도 못 찾는 일이
                // 없도록 아이콘과 이름을 그대로 가져왔다 — 손가락은
                // 자리를 기억하지만 눈은 모양을 기억한다.
                PopupMenuItem<String> act(String v, IconData ic, String label,
                        {bool enabled = true, Color? tint, bool bold = false}) =>
                    PopupMenuItem<String>(
                      value: v,
                      enabled: enabled,
                      // 48이 기본인데 열다섯 줄이면 720이다. 그러면 메뉴가
                      // 화면에 안 들어가서 플러터가 위로 밀어 올리고, 밀어
                      // 올린 메뉴가 삼선 단추를 덮는다(소유자 신고).
                      //
                      // 2026-08-27 — 42도 모자랐다. 소유자 신고: "해상도가
                      // 낮은 기기에서 메뉴 하단 항목이 안 보인다." 36으로
                      // 죈다. 열다섯 줄에 가름선 넷이면 570 남짓이라 작은
                      // 아이폰에서도 들어간다.
                      //
                      // 손가락이 놓칠 만큼 좁지는 않은가. 애플이 권하는
                      // 최소 손가락 자리는 44인데, 그건 **화면에 흩어져
                      // 있는 단추** 이야기다. 메뉴는 줄이 위아래로 붙어
                      // 있어서 겨냥이 세로 한 줄로 좁혀지고, 잘못 눌러도
                      // 옆줄이지 딴 세상이 아니다. 애플 메모의 메뉴도 이
                      // 언저리다.
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(children: [
                        Icon(ic,
                            size: 18,
                            color: (tint ?? ctx.c.guideInk).withValues(
                                alpha: enabled ? 1.0 : 0.4)),
                        const SizedBox(width: 10),
                        Text(label,
                            style: TextStyle(
                                fontSize: 15,
                                color: tint,
                                fontWeight:
                                    bold ? FontWeight.w600 : FontWeight.w400)),
                      ]),
                    );

                return [
                  // 2026-08-18 소유자 지시로 차례를 통째로 다시 짰다.
                  //
                  // 스물세 줄이 한 폭에 다 나와 있었다. 그중 여덟은 설정
                  // 화면의 목차를 그대로 베껴 온 것이었는데, 서랍을 열면
                  // 그 안에 다른 서랍의 목차까지 붙어 있는 꼴이었다.
                  // 그 여덟을 '앱 설정' 한 줄로 접었다 — 두 뎁스로 가는
                  // 것이 줄을 줄이는 유일하게 정직한 방법이다.
                  //
                  // 남은 것을 네 무리로 묶었다.
                  //   1. 이 메모가 무엇인가        출처·태그, 폴더
                  //   2. 정리                      미리보기, 방식 고르기
                  //   3. 글을 손대는 일            마법사, 표, 붙이기,
                  //                                복사, 내보내기
                  //   4. 되돌리고 지우는 일        버전 기록, 원본 복귀, 삭제
                  //
                  // '상단 고정'은 뺐다. 목록에서 길게 눌러 하는 편이
                  // 빠르고, 몇 달에 한 번 누르는 것이 매번 여는 서랍의
                  // 한 줄을 차지할 이유가 없다.
                  // '바꾸기'는 자판 위 도구 막대로 내려갔다.
                  act('meta', _showMeta ? Icons.sell : Icons.sell_outlined,
                      lm.metaTooltip),
                  act(
                      'folder',
                      note.folder.isEmpty
                          ? Icons.folder_outlined
                          : Icons.folder,
                      note.folder.isEmpty ? lm.folderTitle : note.folder,
                      tint: note.folder.isEmpty ? null : ctx.c.accent),
                  // 잠금은 '이 메모가 무엇인가' 무리에 둔다. 정리·복사와
                  // 달리 글을 손대는 일이 아니라 이 메모의 성격이다.
                  act(
                      'lock',
                      note.locked ? Icons.lock : Icons.lock_outline,
                      note.locked ? lm.noteUnlock : lm.noteLock,
                      tint: note.locked ? ctx.c.accent : null),
                  const PopupMenuDivider(height: 6),
                  act('preview', CupertinoIcons.eye, lm.menuTidyPreview,
                      tint: ctx.c.accent, bold: true),
                  act('preset', CupertinoIcons.wand_stars, lm.choosePreset),
                  const PopupMenuDivider(height: 6),
                  act('wizard', CupertinoIcons.sparkles, lm.wizardAction),
                  act('tables', CupertinoIcons.table, lm.tableAction),
                  // 클립은 '첨부'에 준다. 여태 '붙이기'(다른 파일의 글을
                  // 본문 뒤에 잇는 일)가 쓰고 있었는데, 클립이 뜻하는 것은
                  // 어디서나 파일을 매다는 일이다. 이름과 그림이 어긋나
                  // 있으면 둘 다 못 찾는다.
                  act('append', CupertinoIcons.tray_arrow_down, lm.importAppend),
                  act('attach', CupertinoIcons.paperclip, lm.attachAdd),
                  act('copy', CupertinoIcons.doc_on_doc, lm.copyAction),
                  act('export', CupertinoIcons.square_arrow_up, lm.exportNote),
                  // 2026-08-19 — 종이. '내보내기'가 마크다운 파일을
                  // 건네는 일이라면 이 둘은 **다 그려진 결과**를 건네는
                  // 일이다. 받는 사람이 이 앱을 안 써도 그대로 읽힌다.
                  act('pdf', CupertinoIcons.doc_richtext, lm.exportPdf),
                  act('print', CupertinoIcons.printer, lm.printAction),
                  const PopupMenuDivider(height: 6),
                  // 버전 기록과 원본 복귀는 붙여 둔다. 되돌린 뒤 마음이
                  // 바뀌면 바로 위 줄에서 되찾을 수 있다는 것이 눈에
                  // 보여야 한다. 셋 다 '되돌리거나 없애는 일'이라 삭제와
                  // 같은 무리에 둔다.
                  act('history', CupertinoIcons.clock, lm.historyTitle),
                  act('revert', CupertinoIcons.arrow_uturn_left,
                      lm.revertAction,
                      enabled: _canRevert),
                  act('delete', CupertinoIcons.trash, lm.delete,
                      tint: ctx.c.danger),
                  const PopupMenuDivider(height: 6),
                  act('set:', CupertinoIcons.gear_alt, lm.menuAppSettings,
                      tint: ctx.c.accent, bold: true),
                ];
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 유리 머리가 덮는 자리 — 굴러가지 않는 것이 있을 때만 비운다.
            if (_topInsetOutside > 0) SizedBox(height: _topInsetOutside),
            // 맥/PC: 입력 도구 막대는 위. 아래는 기능 탭바가 늘 지킨다.
            if (_isDesktop)
              _accessoryBar(atTop: true),
            // 날짜 줄은 여기 있었다. 2026-08-17에 본문 스크롤 안으로
            // 옮겼다 — 아래 _headKey를 찾을 것.
            // 2026-08-16 소유자 요청 — 제목은 자동으로 붙으니 평소엔 숨긴다.
            // 태그 버튼(_showMeta)을 켜면 제목·출처·태그가 함께 나와 고칠 수
            // 있다. 위 여백 10은 "윗줄과 바짝 붙었다"는 신고의 답.
            if (_showMeta)
            Padding(
              // 위 여백 0 — 날짜 줄이 이미 띄워 놨다. 여기서 또 띄우면 벌어진다.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextField(
                controller: titleCtl,
                focusNode: _titleFocus,
                decoration: InputDecoration(
                    hintText: l.titleHint, border: InputBorder.none, isDense: true),
                // 큰 글자는 자간을 좁혀야 한다. 글자가 커질수록 사이가
                // 벌어져 보이기 때문이다(애플 타이포 지침). 23px에서 -0.02em
                // 은 약 -0.45다. 본문은 0 그대로 둔다.
                style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45),
                onChanged: (v) {
                  // 한 글자라도 쓰면 그 뒤로는 우리가 안 건드린다.
                  // 비우기만 한 것은 "네가 알아서 해"에 가까우므로 안 끈다.
                  if (stopAutoTitle(v)) note.titleAuto = false;
                  _save();
                },
              ),
            ),
            if (_showMeta)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  // 2026-08-17 소유자 신고 — "수동으로 출처를 선택해도 이게
                  // 바로 저장이 된 것인지, 따로 저장 버튼을 눌러야 하는지
                  // 직관적이지 않다."
                  //
                  // 저장은 원래 즉시 되고 있었다. 문제는 그걸 아무도 말해
                  // 주지 않았다는 것이고, 이름표가 없어 그 칸이 무엇인지도
                  // 흐렸다는 것이다.
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(l.sourceFieldLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.c.sub)),
                  ),
                  DropdownButton<String>(
                    value: note.source.isEmpty ? '' : note.source,
                    items: [
                      DropdownMenuItem(value: '', child: Text(l.sourceNone)),
                      const DropdownMenuItem(value: 'ChatGPT', child: Text('ChatGPT')),
                      const DropdownMenuItem(value: 'Claude', child: Text('Claude')),
                      const DropdownMenuItem(value: 'Gemini', child: Text('Gemini')),
                      const DropdownMenuItem(value: 'Grok', child: Text('Grok')),
                      const DropdownMenuItem(value: 'Perplexity', child: Text('Perplexity')),
                      // 저장 값('기타')은 데이터 호환을 위해 유지, 표시만 번역한다
                      DropdownMenuItem(value: '기타', child: Text(l.sourceOther)),
                    ],
                    onChanged: (v) async {
                      note.source = v ?? '';
                      // 손으로 고른 순간부터는 추측이 아니다.
                      note.sourceAuto = false;
                      await _save();
                      if (!mounted) return;
                      setState(() {});
                      // 눌렀는데 아무 일도 안 일어난 것처럼 보이면, 사람은
                      // 저장 버튼을 찾는다. 없는 버튼을.
                      _toast(
                          context,
                          note.source.isEmpty
                              ? L10n.of(context).sourceCleared
                              : L10n.of(context).sourceSaved(note.source));
                    },
                  ),
                  const Spacer(),
                  // 2026-08-14 소유자 요청: "태그 AI 자동입력" 버튼.
                  // 키가 없으면 앱이 직접 뽑는다(소유자 확정) — _autoTags 참고.
                  // 심사 지침 3.1.1 — 아이폰·아이패드에서 키가 없으면 숨긴다.
                  if (aiUiVisible())
                  TextButton.icon(
                    onPressed: _tagAiBusy ? null : _autoTags,
                    icon: _tagAiBusy
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_tagAiBusy ? l.tagAiWorking : l.tagAiButton,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // 태그 상자.
            // 소유자 요청: 한 줄이 아니라 '입력칸처럼' 보이고 여러 줄로 늘어날 것,
            // 그리고 태그 하나하나를 쉽게 지울 수 있을 것.
            // 그래서 블럭(칩) + 뒤따르는 입력칸을 한 상자 안에 넣는다.
            // 블럭이 늘어나면 상자가 저절로 여러 줄이 된다.
            if (_showMeta)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tagsFocus.requestFocus(),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: context.c.panel,
                      border: Border.all(color: context.c.line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final t in note.tags) _tagChip(t),
                        SizedBox(
                          width: 170,
                          child: TextField(
                            controller: tagsCtl,
                            focusNode: _tagsFocus,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: note.tags.isEmpty ? l.tagsHint : l.tagsBoxHint,
                            ),
                            onChanged: _onTagTyped,
                            onSubmitted: (v) {
                              note.tagsAuto = false;
                              _commitTags(v, clear: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 첨부 줄. 붙은 것이 없으면 자리도 안 차지한다.
            if (note.attachments.isNotEmpty) _attachStrip(l),
            Expanded(
              child: Padding(
                // 2026-08-19 소유자 — "편집화면 본문의 폭도 여백미가 너무
                // 없는 거 아닐까? bear 정도가 딱 좋은 것 같다."
                //
                // 16이었다. 글자가 화면 가장자리에 거의 닿는다. 종이에
                // 인쇄된 글은 그렇게 놓이지 않는다 — 여백은 남는 자리가
                // 아니라 글을 붙잡아 주는 자리다.
                //
                // 넓은 화면에서 더 주는 이유: 글 칸의 폭은 이미 묶어 뒀지만
                // (SplitShell.readWidth), 그 안에서도 글이 상자에 꽉 차
                // 있으면 갇혀 보인다.
                padding: EdgeInsets.symmetric(
                    horizontal: (_isDesktop || widget.embedded) ? 32 : 22),
                // fit: expand 인 이유 — 본문 칸은 expands: true 라서 높이를
                // 꽉 채워 받아야 한다. Stack 기본값(loose)이면 최소 0이 되어
                // 칸이 납작하게 접힌다.
                child: Stack(fit: StackFit.expand, children: [
                  // 종이의 줄은 글 뒤에 있다. 그리는 일은 선 몇 개뿐이라
                  // 싸지만, RepaintBoundary로 감싸서 스크롤할 때 글 칸까지
                  // 다시 그리지 않게 막는다.
                  if (onPaper && paper.ruling != kRulingNone)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _bodyScroll,
                          builder: (_, __) => CustomPaint(
                            painter: _PaperPainter(
                              ruling: paper.ruling,
                              color: Color(paper.ruleOf(darkNow)),
                              // 줄 간격을 사람이 바꾸면 종이의 줄도 같이
                              // 움직여야 한다. 이 둘이 어긋나면 화면 아래로
                              // 갈수록 글자가 줄에서 떠오른다.
                              lineHeight: store.settings.bodyFontSize *
                                  store.settings.bodyLineHeight,
                              colWidth: _colWidth(store.settings.bodyFontSize),
                              // 스크롤이 붙기 전 첫 프레임에는 offset을 물으면
                              // 죽는다. 그때는 0이 맞다.
                              scroll: _bodyScroll.hasClients
                                  ? _bodyScroll.offset
                                  : 0,
                              // 날짜 줄이 본문 위에 같이 굴러가므로 그만큼
                              // 줄을 내려 긋는다. 안 그러면 줄이 글자
                              // 한가운데를 가로지른다.
                              headPad: _headH + _topInsetInside,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 2026-08-17 소유자 지시 — "화면의 반 정도는 스크롤되게.
                  // 그래야 하단에 뭔가 더 입력할 수 있다는 느낌이 든다."
                  //
                  // 이건 취향이 아니라 글 쓰는 도구의 기본이다. 마지막 줄이
                  // 화면 맨 아래에 붙어 있으면 (1) 거기가 끝인지 더 있는지
                  // 눈으로 알 수 없고 (2) 그 줄을 고칠 때 손가락이 가린다.
                  //
                  // **스크롤의 임자를 바꿨다.** 전에는 본문 칸이 자기 안에서
                  // 스스로 굴렀는데(expands + 내부 스크롤), 그 방식에서는
                  // '글 끝보다 더 내려가기'를 만들 수 없다 — 굴릴 수 있는
                  // 양이 글 길이로 정해지기 때문이다. 아래에 여백을 주면
                  // 칸이 작아져서 보이는 글만 줄어든다.
                  //
                  // 이제 본문 칸은 글 길이만큼 늘어나기만 하고, 스크롤은
                  // 이것을 감싼 바깥이 맡는다. 바깥이 [글 + 빈칸]을 함께
                  // 굴리므로 글 끝을 지나 빈칸까지 내려갈 수 있다.
                  LayoutBuilder(builder: (_, box) {
                    // 빈칸은 화면의 절반. 마지막 줄을 화면 한가운데까지
                    // 끌어올릴 수 있는 양이다.
                    // 2026-08-17 소유자 신고 — "본문과 광고의 간격이 너무
                    // 멀다. 이래서는 누가 광고를 보겠나. 본문은 아래 여백으로
                    // 2줄 정도 남기고 광고가 오게 해."
                    //
                    // 이 빈칸은 원래 '마지막 줄을 화면 한가운데까지 끌어올릴
                    // 자리'로 둔 것이다(화면의 절반). 그 뜻은 여전히 맞다.
                    // 다만 **광고가 아래에 붙으면 광고 자체가 그 자리를
                    // 준다.** 250픽셀짜리 네모가 이미 굴릴 거리를 만든다.
                    // 그러니 광고가 뜰 판에서는 빈칸을 두 줄로 줄인다.
                    //
                    // 광고가 없는 날·맥·윈도우에서는 예전 그대로 절반이다.
                    // 그때는 아래에 아무것도 없어서 빈칸이 유일한 자리다.
                    final lineH = store.settings.bodyFontSize *
                        store.settings.bodyLineHeight;
                    final blank =
                        inlineAdLikely() ? lineH * 2 : box.maxHeight * 0.5;
                    // 본문 칸의 최소 높이를 이렇게 두면, 글이 짧을 때
                    // [머리 + 본문 + 빈칸]이 정확히 한 화면이라 스크롤이 안
                    // 생긴다. 한 줄짜리 메모에서 화면이 덜컹거리면 더
                    // 이상하다. 날짜 줄을 안으로 들인 뒤로는 그 높이도
                    // 빼야 셈이 맞는다.
                    final minBody =
                        (box.maxHeight - blank - _headH - _topInsetInside)
                            .clamp(0.0, double.infinity);
                    // 편집 화면에서도 당겨서 맞추기(2026-08-27 소유자
                    // 요청). 손짓이 잡히는 곳에서만 돈다 — 웹·맥의
                    // 트랙패드 굴림은 끌기로 안 잡히고, 그 자리는 머리의
                    // 단추가 맡는다.
                    //
                    // 글을 치는 중에는 안 건다. 자판이 올라와 있을 때
                    // 아래로 쓸어내리는 손짓은 '자판 내리기'이지
                    // '새로 고침'이 아니다.
                    return RefreshIndicator(
                      onRefresh: _editorPullSync,
                      notificationPredicate: (n) =>
                          !_editing && n.depth == 0,
                      color: context.c.accent,
                      backgroundColor: context.c.panel,
                      displacement: 24,
                      child: SingleChildScrollView(
                      controller: _bodyScroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      // 굴림은 이제 앱 하나로 정해 둔다(GlideScrollBehavior).
                      // 여기 클램핑을 박아 뒀던 것은 '손으로 글을 끌어
                      // 고를 때 튕김이 방해된다'는 짐작이었는데, 정작
                      // 들어온 신고는 반대쪽이었다 — 뻑뻑하다는 것이다.
                      // 짐작으로 박은 값을 뗀다.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 유리 머리가 덮는 자리. 이것이 스크롤 **안**에
                          // 있어서, 굴리면 날짜 줄과 글이 머리 밑으로
                          // 흘러 들어간다.
                          if (_topInsetInside > 0)
                            SizedBox(height: _topInsetInside),
                          // 날짜 줄. 고정이 아니라 글의 첫머리다 —
                          // 종이 맨 위에 적힌 날짜처럼, 읽어 내려가면
                          // 같이 올라가 사라진다.
                          KeyedSubtree(
                              key: _headKey,
                              child: _dateLine(note.updatedAt)),
                          ConstrainedBox(
                            constraints: BoxConstraints(minHeight: minBody),
                            child: TextField(
                  key: _bodyKey,
                  controller: bodyCtl,
                  focusNode: _bodyFocus,
                  // 목록에서 엔터를 치면 다음 항목이 따라온다
                  // (2026-08-27 소유자 신고). 규칙은 core/list_continue.dart
                  // 에 있고 시험으로 못 박았다.
                  inputFormatters: const [ListContinueFormatter()],
                  // 빈 메모를 열면 커서가 이미 깜빡이고 있어야 한다.
                  //
                  // 2026-08-16 조사에서 애플 메모의 사랑받는 이유 1위가
                  // '켜자마자 바로 쓸 수 있음'이었다. 한 번 더 눌러야 쓰기가
                  // 시작되는 것은 기능이 아니라 마찰이다.
                  autofocus: bodyCtl.text.isEmpty,
                  undoController: _undoCtl,
                  // expands를 뗐다. 이제 이 칸은 글 길이만큼 늘어나고,
                  // 굴리는 일은 바깥이 맡는다.
                  maxLines: null,
                  // 선택 돋보기는 TextField가 기본으로 켜 준다(따로 지정할 필요 없음).
                  // 2026-08-14에 명시적으로 넣으려다 이름을 틀려 빌드가 깨졌고,
                  // 확인해 보니 어차피 기본값이었다. 즉 선택 조작감 문제의 원인은
                  // 돋보기가 아니다 — 기기에서 직접 만져 보며 찾아야 한다.
                  //
                  // 블록을 끌 때 화면 끝에 닿으면 플러터가 캐럿을 보이게
                  // 스크롤한다. 그 한 번에 움직이는 양이 이 여백만큼이라,
                  // 기본값(20)보다 줄이면 덜 뛴다. 0으로 두지는 않는다 —
                  // 캐럿이 화면 가장자리에 딱 붙으면 손가락에 가려진다.
                  scrollPadding: const EdgeInsets.all(12),
                  decoration: InputDecoration(hintText: l.bodyHint, border: InputBorder.none),
                  // 줄글은 기기 기본 글꼴 그대로 두고, 표·코드 구간만 등폭으로
                  // 바꿔 그린다(2026-08-14 소유자 요청). 어디가 표인지는
                  // core/mono_spans.dart가, 실제로 글꼴을 입히는 일은
                  // core/mono_controller.dart가 한다.
                  // 표에 등폭이 필요한 이유: 공백으로 맞춘 칸은 글자 폭이 일정해야
                  // 줄이 맞는다. 비례 글꼴에서는 원리적으로 맞출 수 없다.
                  style: TextStyle(
                      fontSize: store.settings.bodyFontSize,
                      height: store.settings.bodyLineHeight,
                      // 고른 본문 글꼴. '기본'이면 여기 null 이 들어가고
                      // 테마가 정한 글꼴이 그대로 쓰인다(core/body_font.dart).
                      fontFamily: bodyFontFamily(store.settings.bodyFont,
                          webDefault: kIsWeb ? kWebFontFamily : null),
                      // 자간 0 (2026-08-24 소유자 신고 "클로드 앱 폰트가
                      // 좋은데 다르다"). 글꼴은 이미 시스템 것이었고,
                      // 다른 건 머티리얼 기본 자간 +0.5였다 — 영문 SF용
                      // 값이라 한글에 얹으면 벌어져 보인다. 애플 메모도
                      // 클로드 앱도 한글 본문 자간은 0이다.
                      letterSpacing: 0,
                      // 종이를 골랐으면 잉크도 종이 것을 쓴다. 아이보리
                      // 종이에 순검정을 얹으면 인쇄물이 아니라 스캔한
                      // 종이처럼 보인다. 색은 core/paper.dart에서 명암비를
                      // 계산해 정해 뒀다.
                      color: paperInk),
                  onChanged: _onBodyChanged,
                  onTap: _menuOnTap,
                  // ── 편집 메뉴를 우리가 그린다 ──────────────────────
                  //
                  // 2026-08-18 소유자 지시 — "'붙여넣기 / 선택 / 전체선택 >'이
                  // 나오게 하고, '텍스트 스캔'은 '>'을 누르면 나오게 해줘."
                  //
                  // 그동안 이 자리에는 **iOS 가 통째로 그리는 메뉴**가 떴다.
                  // 요즘 플러터는 iOS 16 이상이면 시스템 메뉴를 쓰는 것이
                  // 기본값이고, 시스템 메뉴는 우리가 순서를 정할 수 없다.
                  // '텍스트 스캔'이 거기 섞여 있던 것도 그래서다 — 그건
                  // 우리가 넣은 것이 아니라 운영체제가 넣은 것이다.
                  //
                  // 순서를 정하려면 메뉴를 우리가 그려야 하고, 우리가 그리면
                  // **'텍스트 스캔'은 못 가져온다.** 카메라로 글자를 읽어
                  // 오는 그 기능은 운영체제 안에만 있고 밖으로 나오지 않는다.
                  // 소유자가 그것을 '>' 뒤로 밀라고 한 뜻은 '거의 안 쓴다'
                  // 이므로, 잃는 쪽을 택했다.
                  //
                  // 버튼이 넘치면 플러터가 알아서 '>'로 접는다. 그러니
                  // 우리가 할 일은 **중요한 것을 앞에 놓는 것**뿐이다.
                  contextMenuBuilder: (ctx, ets) {
                    final ll = L10n.of(ctx);
                    ContextMenuButtonItem? paste;
                    ContextMenuButtonItem? selectAll;
                    final rest = <ContextMenuButtonItem>[];
                    for (final b in ets.contextMenuButtonItems) {
                      switch (b.type) {
                        // 2026-08-18 — 고른 글을 복사할 때도 표시를 벗긴다.
                        case ContextMenuButtonType.copy:
                          rest.add(ContextMenuButtonItem(
                            type: ContextMenuButtonType.copy,
                            onPressed: () {
                              final v = ets.textEditingValue;
                              Clipboard.setData(ClipboardData(
                                  text: toPlain(
                                      v.selection.textInside(v.text))));
                              ets.hideToolbar();
                            },
                          ));
                        case ContextMenuButtonType.paste:
                          paste = b;
                        case ContextMenuButtonType.selectAll:
                          selectAll = b;
                        default:
                          rest.add(b);
                      }
                    }
                    final items = <ContextMenuButtonItem>[];
                    if (paste != null) items.add(paste);
                    // '선택' — 커서가 놓인 낱말 하나만 잡는다.
                    //
                    // 전체 선택과 손으로 끌기 사이가 비어 있었다. 한 낱말을
                    // 고치려는데 고를 방법이 '전부' 아니면 '손으로 정확히
                    // 끌기'뿐이면, 작은 화면에서는 후자가 거의 안 된다.
                    if (ets.textEditingValue.selection.isCollapsed &&
                        ets.textEditingValue.text.isNotEmpty) {
                      items.add(ContextMenuButtonItem(
                        label: ll.selectWord,
                        onPressed: () {
                          ets.renderEditable
                              .selectWord(cause: SelectionChangedCause.toolbar);
                          // 잡아 놓고 메뉴가 사라지면 다음에 뭘 할지 모른다.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ets.showToolbar();
                          });
                        },
                      ));
                    }
                    if (selectAll != null) items.add(selectAll);
                    items.addAll(rest);
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: ets.contextMenuAnchors,
                      buttonItems: items,
                    );
                  },
                            ),
                          ),
                          // 글 끝 아래의 빈칸.
                          //
                          // 그냥 두면 눌러도 아무 일이 없다 — 본문 칸 밖이기
                          // 때문이다. 종이 아래쪽을 짚었는데 펜이 안 잡히는
                          // 셈이라, 누르면 커서를 글 맨 끝에 놓는다.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _bodyFocus.requestFocus();
                              bodyCtl.selection = TextSelection.collapsed(
                                  offset: bodyCtl.text.length);
                            },
                            child: SizedBox(height: blank),
                          ),
                          // 글보다 아래, 빈칸보다 아래. 타자를 치는 동안에는
                          // 눈에 들어오지 않는 자리다(2026-08-17 소유자 지시).
                          const InlineAdBlock(),
                        ],
                      ),
                      ),
                    );
                  }),
                ]),
              ),
            ),
            // 2026-08-17 소유자 지시 — "편집 화면 맨 아래에 정리된 내역을
            // 한 줄로 보여 주는 거 없애 줘. 아무 의미 없다."
            //
            // 맞다. '마커 51개 제거 · 제목 5개 정리'는 **우리가 열심히
            // 했다는 증거**지 사용자가 알고 싶은 것이 아니다. 알고 싶은
            // 것은 '글이 깨끗해졌나' 하나뿐이고 그건 글을 보면 안다.
            //
            // 값(note.lastReport)은 남겨 둔다. 저장 형식을 바꾸면 예전
            // 저장본과 아이클라우드에 올라간 파일까지 건드리게 되는데,
            // 화면에서 한 줄 빼자고 치를 값이 아니다. 안 보여 줄 뿐이다.
          ],
        ),
        bottomNavigationBar: Padding(
          // 키보드 높이만큼 막대를 들어 올린다. Scaffold는 아래 막대를 화면
          // 진짜 바닥에 두기 때문에(bottom - 아래막대높이) 그냥 두면
          // 키보드에 가린다.
          //
          // 상한을 두는 이유: 이 값이 Scaffold 높이에 닿으면 막대가 화면 맨
          // 위로 튀어 오르고 본문이 사라진다(2026-08-16 실제 사고). 위에서
          // 구조를 고쳐 여유가 344까지 벌어졌지만, 화면이나 키보드가 어떻게
          // 바뀌든 다시는 그 선을 넘지 않게 여기서도 막는다. 화면의 60%를
          // 넘겨 올리는 키보드는 없다.
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom.clamp(
                  0.0, MediaQuery.sizeOf(context).height * 0.6)),
          child: SafeArea(
            child: (_bodyFocus.hasFocus && !_isDesktop)
                ? _accessoryBar()
                // 2026-08-19 — 다섯 칸 막대를 걷어냈다. 이제 아래에 남는
                // 것은 글자를 칠 때 뜨는 보조 막대뿐이다.
                : const SizedBox.shrink(),
          ),
        ),
        // 떠 있는 단추 둘. 목록 화면과 **똑같은** 문법이다 — 정리가 왼쪽
        // 채운 하늘, 글쓰기가 오른쪽 연한 하늘. 화면마다 문법이 다르면
        // 그건 두 앱이다.
        //
        // 2026-08-18 소유자 신고 — 한쪽만 글자를 달고 있어서 둘이 같은
        // 무리로 안 보였고, 종이색 글쓰기 단추는 "못 찾을 정도"였다.
        //
        // 글자를 치는 동안에는 감춘다. 키보드 위에 보조 막대가 뜨는데
        // 그 위에 단추가 또 겹치면 손가락 갈 곳이 없다.
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: (_bodyFocus.hasFocus && !_isDesktop)
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 정리 — 이 화면의 존재 이유. 길게 누르면 다른 방식을
                    // 고를 수 있다(2026-08-16에 문을 하나로 합치면서 만든 길).
                    GestureDetector(
                      onLongPress: _showPresetSheet,
                      child: FloatingActionButton(
                        heroTag: 'ed-tidy',
                        tooltip: l.tidyAction,
                        onPressed: () =>
                            _runTidyWithPreset(buildPresets().first),
                        child:
                            const Icon(CupertinoIcons.wand_stars, size: 25),
                      ),
                    ),
                    // 새 노트 — 이 메모와 무관한 일이라 한 계단 옅다.
                    FloatingActionButton(
                      heroTag: 'ed-new',
                      tooltip: l.newNoteTooltip,
                      backgroundColor: kAccentSoft,
                      foregroundColor: kOnAccentSoft,
                      onPressed: () async {
                        await _save();
                        final fresh = Note.fresh(body: '');
                        store.notes.insert(0, fresh);
                        await store.persist();
                        if (!mounted) return;
                        await openNote(context, fresh.id);
                      },
                      child: const Icon(CupertinoIcons.square_pencil, size: 24),
                    ),
                  ],
                ),
              ),
      ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ---------------- 정리 미리보기 ----------------
/// 2026-08-14 소유자 요청: 미리보기를 건너뛸 수 있어야 한다. '적용' 바로 위에
/// 체크를 두고, 켜면 다음부터 정리가 바로 적용된다. 되돌리려면 설정에서 켠다.
class PreviewScreen extends StatefulWidget {
  final String presetName;
  final String before;
  final TidyResult result;

  /// 메뉴에서 '정리 미리보기'를 눌러 온 것인가.
  ///
  /// 2026-08-17 소유자 지적 — "메뉴에 새로 추가된 미리보기 화면에서 '앞으로
  /// 미리보기 생략'은 없애줘. 미리보기 화면인데, '미리보기 생략'한다는 것은
  /// 모순이다."
  ///
  /// 맞다. 그 체크는 **설정을 켜 둬서 매번 이 화면을 거치는 사람**에게 주는
  /// 탈출구다. 방금 손으로 '미리보기'를 골라 들어온 사람에게 "앞으로는
  /// 보지 마세요"라고 묻는 것은, 문을 열고 들어온 사람에게 문을 잠그겠냐고
  /// 묻는 격이다. 게다가 그 체크를 켜면 설정이 꺼지는데, 이 사람은 애초에
  /// 설정을 켠 적이 없다. 자기가 안 켠 것이 꺼진다.
  final bool manual;

  const PreviewScreen({
    super.key,
    required this.presetName,
    required this.before,
    required this.result,
    this.manual = false,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final store = Store.instance;
  bool _skipNext = false;

  /// 두 칸을 같이 굴릴 것인가. 켠 채로 시작한다.
  ///
  /// 2026-08-17 소유자 지시 — "위는 원본, 아래는 정리된 것으로 해서, 하나를
  /// 스크롤하면 2개가 같이 스크롤되서 이 부분이 어떻게 바뀌는지 볼 수 있게
  /// 해줘. 프로팅된 '동시 스크롤' 옵션 체크가 기본."
  ///
  /// 전에는 결과 전문을 다 보여 주고 그 아래에 원본 전문을 붙였다. 화면
  /// 하나에 둘 다 안 들어가니 **비교가 아니라 기억력 시험**이었다. 위를
  /// 읽고 한참 내려가 아래에서 그 자리를 다시 찾아야 했다.
  bool _sync = true;

  final ScrollController _origCtl = ScrollController();
  final ScrollController _tidyCtl = ScrollController();

  /// 서로가 서로를 밀어 무한히 도는 것을 막는 빗장.
  bool _busy = false;

  String get presetName => widget.presetName;
  String get before => widget.before;
  TidyResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _origCtl.addListener(() => _mirror(_origCtl, _tidyCtl));
    _tidyCtl.addListener(() => _mirror(_tidyCtl, _origCtl));
  }

  @override
  void dispose() {
    _origCtl.dispose();
    _tidyCtl.dispose();
    super.dispose();
  }

  /// 한쪽이 움직이면 다른 쪽을 **같은 비율**로 옮긴다.
  ///
  /// 픽셀을 그대로 맞추지 않는 이유가 있다. 정리한 글은 원본보다 짧다 —
  /// 그게 이 앱이 하는 일이다. 픽셀로 맞추면 짧은 쪽이 먼저 바닥에
  /// 닿아 버려서, 원본을 절반쯤 내려갔을 때 결과는 이미 끝에 붙어 있다.
  /// 비율로 맞추면 '원본의 여기쯤'과 '결과의 여기쯤'이 늘 마주 본다.
  void _mirror(ScrollController from, ScrollController to) {
    if (!_sync || _busy) return;
    if (!from.hasClients || !to.hasClients) return;
    final fMax = from.position.maxScrollExtent;
    final tMax = to.position.maxScrollExtent;
    if (tMax <= 0) return;
    final ratio = fMax <= 0 ? 0.0 : (from.offset / fMax).clamp(0.0, 1.0);
    final target = ratio * tMax;
    // 반 픽셀 문턱. 없으면 반올림 오차만으로 둘이 서로를 계속 민다.
    if ((to.offset - target).abs() < 0.5) return;
    _busy = true;
    to.jumpTo(target);
    _busy = false;
  }

  Widget _pane(String label, String text, ScrollController ctl,
      {required bool tidied}) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(children: [
            // 정리된 쪽에만 색을 준다. 둘 다 회색이면 어느 쪽이 결과인지
            // 이름표를 읽어야 안다.
            Icon(tidied ? CupertinoIcons.wand_stars : Icons.description_outlined,
                size: 14, color: tidied ? c.accent : c.sub),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tidied ? c.accent : c.sub)),
          ]),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            decoration: BoxDecoration(
                color: c.codeBg,
                border: Border.all(color: tidied ? c.accent : c.codeLine),
                borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              controller: ctl,
              padding: const EdgeInsets.all(12),
              child: SelectableText(text,
                  style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: Text(l.previewTitle(presetName))),
      body: Column(
        children: [
          // 여기 '마커 51개 제거 · 제목 5개 정리' 같은 줄이 있었다.
          // 2026-08-17에 뺐다 — 몇 개를 지웠는지는 우리가 열심히 했다는
          // 증거지 사용자가 알고 싶은 것이 아니다. 이 화면은 글이 어떻게
          // 바뀌었는지를 두 칸으로 보여 주려고 만든 것이고, 그 위에 숫자
          // 줄이 앉으면 화면의 목적과 싸운다.
          //
          // 경고는 남긴다. 그건 자랑이 아니라 '이건 좀 봐 달라'는 말이다.
          for (final w in result.warnings)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: c.warnBg, borderRadius: BorderRadius.circular(10)),
                child: Text(l.warningPrefix(w),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.warnInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(
            child: LayoutBuilder(builder: (_, box) {
              // 2026-08-17 소유자 지시 — "아이패드 가로모드는 위 아래로
              // 하지 말고, 좌/우로 해줘. 좌는 원본, 우는 정리 결과로."
              //
              // 잣대를 '아이패드인가'가 아니라 '가로가 넓은가'로 둔다.
              // 아이패드를 세워 들면 위아래가 맞고, 아이폰을 눕히면 좌우가
              // 맞다. 기기 이름으로 가르면 그 둘을 다 놓친다. 720은 두 칸에
              // 각각 글줄 하나가 온전히 들어가는 폭이다.
              final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;
              // 원본이 먼저다 — 넓으면 왼쪽, 좁으면 위. 어느 쪽이든 읽는
              // 방향과 시간의 방향이 같다.
              final first =
                  _pane(l.originalLabel, before, _origCtl, tidied: false);
              final second =
                  _pane(l.tidyResultLabel, result.text, _tidyCtl, tidied: true);
              return Stack(children: [
              if (wide)
                Row(children: [
                  Expanded(child: first),
                  Expanded(child: second),
                ])
              else
                Column(children: [
                  Expanded(child: first),
                  Expanded(child: second),
                ]),
              // 떠 있는 '동시 스크롤'. 두 칸 위에 얹혀 있어야 무엇에 대한
              // 스위치인지 자리만으로 안다.
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: c.panel,
                    elevation: 3,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        setState(() => _sync = !_sync);
                        // 다시 켠 순간 두 칸이 어긋나 있으면 켠 보람이 없다.
                        if (_sync) _mirror(_origCtl, _tidyCtl);
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(6, 2, 16, 2),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Checkbox.adaptive(
                            value: _sync,
                            onChanged: (v) {
                              setState(() => _sync = v ?? false);
                              if (_sync) _mirror(_origCtl, _tidyCtl);
                            },
                          ),
                          Text(l.syncScroll,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              ]);
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 버튼 바로 위 — 여기서 켜면 다음부터 이 화면을 건너뛴다.
              // 손으로 미리보기를 골라 들어온 자리에서는 안 보인다.
              if (!widget.manual)
              InkWell(
                onTap: () => setState(() => _skipNext = !_skipNext),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Checkbox.adaptive(
                        value: _skipNext,
                        onChanged: (v) => setState(() => _skipNext = v ?? false),
                      ),
                      Expanded(
                        child: Text(l.skipPreviewCheck,
                            style: TextStyle(fontSize: 13, color: context.c.sub)),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                        onPressed: () async {
                          // 체크는 '적용'할 때만 반영한다. 취소하면서 끄는 것은
                          // 뜻이 애매하다.
                          if (_skipNext) {
                            store.settings.previewBeforeApply = false;
                            await store.persistSettings();
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: Text(l.apply, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- 프리미엄 안내 ----------------
/// 2026-08-16 소유자 요청 — 유료 결제·구독 유도 페이지.
/// 실제 결제(StoreKit/Play 결제)는 스토어 제출 작업에서 붙는다. 지금은
/// 안내와 버튼 자리를 만들고, 누르면 준비 중임을 알린다. 후원 시트와
/// 설정 상단 배너가 여기로 이끈다.
/// 휴지통 — 지운 메모를 30일 동안 되돌릴 수 있는 곳.
/// 넓은 화면에서 내용을 가운데 한정 폭으로 묶는다.
///
/// 2026-08-18. 설정 화면이 쓰던 셈을 이름 붙여 뺐다. 앞으로 만드는
/// 화면은 이걸 부르기만 하면 된다 — 규칙을 옮겨 적는 일이 없어야
/// 옮겨 적기를 잊는 일도 없어진다.
Widget narrowBody(BuildContext context, Widget child) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: SplitShell.readWidth(context)),
        child: child,
      ),
    );

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final store = Store.instance;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = store.trash;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.trashTitle),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: L10n.of(context).trashEmptyAll,
                    body: L10n.of(context).trashEmptyConfirm,
                    okLabel: L10n.of(context).delete,
                    destructive: true);
                if (ok) {
                  store.emptyTrash();
                  if (mounted) setState(() {});
                }
              },
              child: Text(l.trashEmptyAll, style: TextStyle(color: c.danger)),
            ),
        ],
      ),
      body: narrowBody(
        context,
        items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 46, color: c.sub),
                    const SizedBox(height: 12),
                    Text(l.trashEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: c.guideInk)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
              itemBuilder: (_, i) {
                final e = items[i];
                final j = (e['note'] as Map).cast<String, dynamic>();
                final at = (e['deletedAt'] ?? 0) as int;
                final title = ((j['title'] ?? '') as String).trim();
                final body = ((j['body'] ?? '') as String).trim();
                // 2026-08-18 소유자 지시 — "휴지통 안에 리스트에서 내용을
                // 3줄 정도 보여줘. 그래야 무슨 노트인지 알 것 같애."
                //
                // 제목 한 줄과 '며칠 남음'만 있었다. 이 앱의 제목은 대개
                // 앱이 지어 준 것이라, 지우고 나서 다시 볼 때 그 한 줄로는
                // 어느 것이었는지 못 알아본다. **되살릴지 말지 정하는
                // 자리에서 정작 무엇인지가 안 보였다.**
                //
                // 빈 줄을 걸러 낸 뒤 한 문단으로 이어 붙이고 세 줄에서
                // 자른다. 줄바꿈을 그대로 두면 짧은 줄 셋으로 석 줄을 다
                // 써 버려서 보이는 글자가 오히려 줄어든다.
                // 잠긴 메모를 지우면 휴지통에서 본문이 보였다. 지운 것은
                // 아직 지워진 게 아니고 되살릴 수 있는 것이라, 여기서 새면
                // 잠금이 그대로 뚫린다.
                final locked = (j['locked'] ?? false) as bool;
                final lines = locked
                    ? const <String>[]
                    : body
                        .split('\n')
                        .map((x) => x.trim())
                        .where((x) => x.isNotEmpty)
                        .toList();
                final shown =
                    title.isNotEmpty ? title : (lines.isEmpty ? l.untitled : lines.first);
                // 제목이 없어 첫 줄을 제목으로 쓴 판에서는 그 줄을 뺀다.
                // 같은 문장이 위아래로 두 번 나오면 두 줄을 버리는 셈이다.
                final preview = locked
                    ? l.noteLocked
                    : (title.isNotEmpty ? lines : lines.skip(1)).join('  ');
                final left = trashDaysLeft(deletedAt: at, nowMs: now);
                return ListTile(
                  isThreeLine: true,
                  titleAlignment: ListTileTitleAlignment.top,
                  contentPadding:
                      const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  title: Text(shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(preview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14, height: 1.42, color: c.sub)),
                      ],
                      const SizedBox(height: 5),
                      Text(l.trashDaysLeftLabel(left),
                          style: TextStyle(fontSize: 12.5, color: c.sub)),
                    ],
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(
                      onPressed: () {
                        store.restoreNote(j['id'] as String);
                        setState(() {});
                        _toast(context, l.trashRestored);
                      },
                      child: Text(l.trashRestore),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever_outlined, color: c.danger),
                      tooltip: l.trashDeleteNow,
                      onPressed: () {
                        store.purgeFromTrash(j['id'] as String);
                        setState(() {});
                      },
                    ),
                  ]),
                );
              },
            ),
      ),
    );
  }
}


/// 폴더 관리 — 이름을 바꾸고, 지우고, 더하고, 차례를 바꾼다.
///
/// 2026-08-18 소유자 지시.
///
/// **폴더를 지워도 노트는 안 지운다.** 이것이 이 화면의 유일하게 위험한
/// 대목이라 규칙을 여기 적어 둔다 — 폴더는 '어디에 두었나'이지 '무엇인가'가
/// 아니다. 서랍을 치운다고 그 안의 종이를 태우지는 않는다. 지울 때 그
/// 안에 몇 장이 있었고 어디로 가는지를 글로 보여 주고 나서 지운다.
class FolderManageScreen extends StatefulWidget {
  const FolderManageScreen({super.key});

  @override
  State<FolderManageScreen> createState() => _FolderManageScreenState();
}

class _FolderManageScreenState extends State<FolderManageScreen> {
  final store = Store.instance;

  /// 이 이름을 쓰고 있는 메모 수.
  int _count(String name) {
    final low = normalizeFolder(name).toLowerCase();
    return store.notes
        .where((n) => normalizeFolder(n.folder).toLowerCase() == low)
        .length;
  }

  /// 화면에 보이는 차례를 설정에 그대로 박아 둔다.
  ///
  /// 보이는 것과 저장된 것이 다르면, 다음에 이 화면을 열었을 때 차례가
  /// 달라 보인다. 눈에 보인 것이 곧 저장된 것이어야 한다.
  Future<void> _pin(List<String> names) async {
    store.settings.folders = List<String>.from(names);
    await store.persistSettings();
    // 고친 것을 곧바로 올려 보낸다. 다음에 앱이 앞으로 나올 때까지
    // 기다리면, 그 사이에 앱을 다시 깔았을 때(개발 중에는 늘 그렇다)
    // 지운 일이 없던 일이 된다 — 새로 깐 기기는 아이클라우드를 그대로
    // 받아 오기 때문이다.
    ICloudSync.instance.scheduleUp();
  }

  Future<String?> _ask(String title, String initial, List<String> taken) async {
    final ctl = TextEditingController(text: initial);
    final l = L10n.of(context);
    final got = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: kFolderNameMax,
          decoration: InputDecoration(hintText: l.folderNameHint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: Text(l.done)),
        ],
      ),
    );
    ctl.dispose();
    if (got == null || !mounted) return null;
    final name = normalizeFolder(got);
    if (name.isEmpty) return null;
    // 자기 이름 그대로는 겹침이 아니다(대소문자만 고친 경우).
    final others =
        taken.where((e) => e.toLowerCase() != initial.toLowerCase()).toList();
    if (!canAddFolder(name, others)) {
      _toast(context, l.folderDupName);
      return null;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    final s = store.settings;
    final names = folderNames(store.notes.map((n) => n.folder), s.folders);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.folderManage),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            tooltip: l.folderNew,
            onPressed: () async {
              final name = await _ask(l.folderNew, '', names);
              if (name == null) return;
              await _pin([...names, name]);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: narrowBody(
        context,
        names.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_outlined, size: 46, color: c.sub),
                  const SizedBox(height: 12),
                  Text(l.folderManageEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: c.guideInk)),
                ]),
              ),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.folderReorderHint,
                      style: TextStyle(fontSize: 13, color: c.sub)),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: scrollPad(context),
                  itemCount: names.length,
                  onReorder: (from, to) async {
                    HapticFeedback.selectionClick();
                    await _pin(reorderFolders(names, from, to));
                    if (mounted) setState(() {});
                  },
                  itemBuilder: (ctx, i) {
                    final f = names[i];
                    final n = _count(f);
                    return ListTile(
                      key: ValueKey('folder-$f'),
                      leading: Icon(Icons.folder_outlined, color: c.sub),
                      title: Text(f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Text(l.folderNoteCount(n),
                          style: TextStyle(fontSize: 13, color: c.sub)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.pencil, color: c.sub),
                          tooltip: l.folderRename,
                          onPressed: () async {
                            final name = await _ask(l.folderRename, f, names);
                            if (name == null || name == f) return;
                            final now =
                                DateTime.now().millisecondsSinceEpoch;
                            for (final note in store.notes) {
                              if (normalizeFolder(note.folder).toLowerCase() ==
                                  f.toLowerCase()) {
                                note.folder = name;
                                // 안 올리면 아이클라우드의 옛 판이 이긴다.
                                note.updatedAt = now;
                              }
                            }
                            if (s.filterFolder.toLowerCase() ==
                                f.toLowerCase()) {
                              s.filterFolder = name;
                            }
                            await _pin([
                              for (final x in names) x == f ? name : x,
                            ]);
                            await store.persist();
                            if (!mounted) return;
                            setState(() {});
                            _toast(context, l.folderRenamed);
                          },
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.trash, color: c.danger),
                          tooltip: l.folderDelete,
                          onPressed: () async {
                            final ok = await confirmDialog(context,
                                title: l.folderDelete,
                                body: l.folderDeleteBody(f, n),
                                okLabel: l.delete,
                                destructive: true);
                            if (!ok || !mounted) return;
                            // 폴더만 떼고 노트는 그대로 둔다.
                            final now =
                                DateTime.now().millisecondsSinceEpoch;
                            for (final note in store.notes) {
                              if (normalizeFolder(note.folder).toLowerCase() ==
                                  f.toLowerCase()) {
                                note.folder = '';
                                // 안 올리면 아이클라우드의 옛 판이 이긴다.
                                note.updatedAt = now;
                              }
                            }
                            if (s.filterFolder.toLowerCase() ==
                                f.toLowerCase()) {
                              s.filterFolder = '';
                            }
                            await _pin(names.where((x) => x != f).toList());
                            await store.persist();
                            if (!mounted) return;
                            setState(() {});
                            _toast(context, l.folderDeleted);
                          },
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 6),
                            child: Icon(Icons.drag_handle, color: c.sub),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]),
      ),
    );
  }
}

/// 버전 기록 — 이전 판으로 되돌린다.
///
/// 2026-08-16. 조사에서 나온 것 중 값어치 대비 가장 싼 항목이다. 애플 메모를
/// **떠나는** 가장 큰 이유가 버전 기록이 없다는 것이고, 에버노트에 **남는**
/// 이유 중 하나가 있다는 것이다. 한 사용자의 말이 정확하다 — "거의 안 쓰지만
/// 필요한 그 한 번이 값을 한다."
///
/// 우리는 되돌리기용 이전 판을 이미 쌓고 있었다(정리·바꾸기를 할 때마다).
/// 데이터는 다 있었고 화면만 없었다.
class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key, required this.note});

  final Note note;

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  final store = Store.instance;

  Future<void> _restore(String text) async {
    final n = widget.note;
    // 되돌리기 자체도 되돌릴 수 있어야 한다. 지금 글을 먼저 기록에 넣는다 —
    // 안 그러면 '되돌리기'가 곧 '지금 글을 버리기'가 된다.
    n.pushHistory(n.body, why: 'restore');
    n.body = text;
    n.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await store.persist();
    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    final n = widget.note;
    final tag = Localizations.localeOf(context).toLanguageTag();

    // 최신 것이 위로. 그리고 맨 아래에 붙여넣은 원본을 둔다.
    //
    // 2026-08-19 — 곁줄(시각·까닭)을 **끝에서부터** 맞춘다. 앞에서부터
    // 세면 오늘 남긴 시각이 몇 달 전 판에 붙는다. 까닭은
    // core/history_align.dart 에 적어 뒀고 시험으로 못 박아 뒀다.
    final items = <(String, String, String, String)>[];
    for (var i = n.history.length - 1; i >= 0; i--) {
      final at = n.historyTimeOf(i);
      final why = _whyLabel(l, n.historyWhyOf(i));
      String when;
      if (at > 0) {
        final t = DateTime.fromMillisecondsSinceEpoch(at);
        try {
          when = '${DateFormat.MMMd(tag).format(t)} ${DateFormat.Hm(tag).format(t)}';
        } catch (_) {
          when = DateFormat.Hm().format(t);
        }
      } else {
        when = l.historyUnknownTime(i + 1);
      }
      items.add((when, n.history[i], _peek(n.history[i]), why));
    }
    final orig = n.originalBody.trim();
    final hasOrig = orig.isNotEmpty && orig != n.body.trim();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: c.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l.historyTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(l.historySub,
                style: TextStyle(fontSize: 14, height: 1.4, color: c.sub)),
            const SizedBox(height: 12),
            if (items.isEmpty && !hasOrig)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(l.historyEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: c.guideInk)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final it in items)
                      _row(it.$1, it.$3, () => _restore(it.$2), why: it.$4),
                    if (hasOrig)
                      _row(l.historyOriginal, _peek(n.originalBody),
                          () => _restore(n.originalBody),
                          accent: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _peek(String s) {
    final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return one.length > 90 ? '${one.substring(0, 90)}…' : one;
  }

  /// 부호를 그때의 언어로. 모르는 부호(옛 저장본, 다음 판이 붙일 새 부호)는
  /// 빈 글자로 두고 시각만 보여 준다 — 모르면 아무 말도 안 하는 편이 낫다.
  static String _whyLabel(L10n l, String code) {
    switch (code) {
      case 'tidy':
        return l.historyWhyTidy;
      case 'ai':
        return l.historyWhyAi;
      case 'replace':
        return l.historyWhyReplace;
      case 'revert':
        return l.historyWhyRevert;
      case 'restore':
        return l.historyWhyRestore;
      default:
        return '';
    }
  }

  Widget _row(String when, String peek, VoidCallback onTap,
      {bool accent = false, String why = ''}) {
    final c = context.c;
    final l = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    // 까닭이 앞, 시각이 뒤. 사람이 기억하는 것은 '몇 시'가
                    // 아니라 '무엇을 하기 전'이다. 오후 두 시에 남은 판이
                    // 셋이면 시각으로는 고를 수 없다.
                    child: Text(why.isEmpty ? when : '$why  ·  $when',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent ? c.accent : c.guideInk)),
                  ),
                  Text(l.historyRestore,
                      style: TextStyle(fontSize: 13.5, color: c.accent)),
                ]),
                const SizedBox(height: 4),
                Text(peek,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, height: 1.4, color: c.sub)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 정렬과 필터를 고르는 시트.
///
/// 메뉴가 아니라 시트인 이유: 태그가 여러 개면 메뉴로는 감당이 안 되고,
/// 지금 무엇이 걸려 있는지 한눈에 보여 줘야 하기 때문이다. 목록에 메모가
/// 안 보이는데 왜 안 보이는지 모르는 상태가 가장 나쁘다.
class SortFilterSheet extends StatefulWidget {
  const SortFilterSheet({super.key});

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  final store = Store.instance;

  Future<void> _save() async {
    setState(() {});
    await store.persistSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    final s = store.settings;

    // 실제로 쓰인 출처·태그만 보여 준다. 안 쓰는 항목을 늘어놓으면
    // 고르는 일이 일이 된다.
    final sources = <String>{};
    final tagCount = <String, int>{};
    for (final n in store.notes) {
      if (n.source.trim().isNotEmpty) sources.add(n.source);
      for (final t in n.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
    }
    final tags = tagCount.keys.toList()
      ..sort((a, b) => tagCount[b]!.compareTo(tagCount[a]!));
    final topTags = tags.take(14).toList();

    Widget chip(String label, bool on, VoidCallback tap) => Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: on,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              tap();
            },
            showCheckmark: false,
            selectedColor: kAccentFill,
            labelStyle: TextStyle(
                color: on ? kOnAccentFill : c.guideInk,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500),
          ),
        );

    Widget section(String title, List<Widget> chips) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: c.sub)),
            ),
            Wrap(children: chips),
          ],
        );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: c.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Expanded(
                  child: Text(l.sortFilterTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                // 2026-08-17 소유자 지시 — '초기화' 왼쪽에 붙는다.
                //
                // 왜 하필 여기인가: 목록을 정리하겠다고 마음먹은 사람이
                // 제일 먼저 여는 곳이 이 시트다. 필터로 범위를 좁히고
                // (예: 태그 하나만 남기고) 곧바로 그 범위를 통째로 지우는
                // 흐름이 자연스럽다. 목록 화면 어딘가에 상시로 두면
                // 평소에 안 쓰는 단추가 늘 자리를 먹는다.
                //
                // 여기서 지우지는 않는다. 시트를 닫고 목록으로 돌려보낼
                // 뿐이다. 무엇이 지워지는지 눈으로 보고 고르게 해야 한다.
                //
                // 그래서 **빨강이 아니라 하늘색이다.**
                //
                // 2026-08-17 소유자 지시로 바꿨는데, 바꾸고 나니 처음부터
                // 이게 맞았다. 빨강은 이 앱에서 '되돌릴 수 없는 일'을 뜻하는
                // 색이고 그래서 아껴 써야 힘이 남는다. 이 단추가 하는 일은
                // 고르기 상태로 들어가는 것뿐이다 — 아무것도 지우지 않고,
                // 누른 뒤에 마음이 바뀌면 '삭제완료'로 그냥 나오면 된다.
                //
                // 위험하지 않은 것을 빨갛게 칠하면 두 가지를 잃는다. 진짜
                // 위험한 자리(목록의 '선택 삭제', 밀어서 삭제)의 빨강이
                // 흔해져서 안 무서워지고, 이 단추는 쓸데없이 무서워져서
                // 손이 안 간다. 빨강은 여기서 아껴 저기서 쓴다.
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.pop(context, 'pick'),
                  child: Text(l.multiSelectStart,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.accent)),
                ),
                // '초기화'는 뺐다(2026-08-17 소유자 지시).
                //
                // 빼고 나서 왜 필요 없었는지가 보인다 — 이 시트의 모든 갈래에
                // 이미 '전체' 칩이 하나씩 있다. 출처를 풀려면 출처의 '전체',
                // 태그를 풀려면 태그의 '전체'를 누르면 된다. 정렬도 세 개
                // 가운데 하나라 언제든 '최근 수정순'으로 돌아간다.
                //
                // 즉 '초기화'는 없는 일을 하는 단추가 아니라 **이미 있는 길을
                // 한 번 더 낸 단추**였다. 그런 단추는 편의가 아니라 짐이다.
                // 화면에 놓인 것이 하나 늘 때마다 사람은 그것이 무엇인지
                // 한 번 더 읽어야 하고, 여기서는 그 값을 못 한다.
              ]),
              section(l.sortLabel, [
                chip(l.sortUpdated, s.sortMode == 'updated', () {
                  s.sortMode = 'updated';
                  _save();
                }),
                chip(l.sortCreated, s.sortMode == 'created', () {
                  s.sortMode = 'created';
                  _save();
                }),
                chip(l.sortByTitle, s.sortMode == 'title', () {
                  s.sortMode = 'title';
                  _save();
                }),
              ]),
              if (sources.isNotEmpty)
                section(l.filterSourceLabel, [
                  chip(l.filterAll, s.filterSource.isEmpty, () {
                    s.filterSource = '';
                    _save();
                  }),
                  for (final v in sources)
                    chip(v, s.filterSource == v, () {
                      s.filterSource = s.filterSource == v ? '' : v;
                      _save();
                    }),
                ]),
              if (topTags.isNotEmpty)
                section(l.filterTagLabel, [
                  chip(l.filterAll, s.filterTag.isEmpty, () {
                    s.filterTag = '';
                    _save();
                  }),
                  for (final t in topTags)
                    chip(t, s.filterTag == t, () {
                      s.filterTag = s.filterTag == t ? '' : t;
                      _save();
                    }),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 종이의 줄을 그린다.
///
/// 간격을 눈으로 정하지 않는다 — 글줄 높이를 그대로 받아 쓴다. 조금이라도
/// 어긋나면 화면 아래로 갈수록 글자가 줄에서 떠오르거나 잠긴다. 좌표를 내는
/// 셈은 core/paper.dart에 있고 테스트로 고정돼 있다.
class _PaperPainter extends CustomPainter {
  final String ruling;
  final Color color;
  final double lineHeight;
  final double colWidth;
  final double scroll;

  /// 글 칸 위에 같이 굴러가는 머리(날짜 줄)의 높이.
  ///
  /// 2026-08-17에 날짜 줄이 본문과 같이 스크롤되도록 바뀌면서 생겼다.
  /// 이제 첫 글줄은 화면 맨 위가 아니라 이 머리 아래에서 시작하므로,
  /// 줄도 그만큼 내려 그어야 글자와 맞는다. 이 값을 안 넣으면 종이 줄이
  /// 글자 한가운데를 가로지른다.
  final double headPad;

  const _PaperPainter({
    required this.ruling,
    required this.color,
    required this.lineHeight,
    required this.colWidth,
    required this.scroll,
    required this.headPad,
  });

  /// 글 칸이 안쪽으로 두는 위 여백. 테두리 없는 TextField의 기본값이다
  /// (InputDecorator: 테두리 없고 dense 아님 → 위아래 12).
  static const double _topPad = 12;

  /// 줄을 글자 밑선보다 살짝 아래로 내린다. 글줄 상자의 맨 밑에 그대로
  /// 그으면 다음 줄 글자에 닿아 보인다.
  static const double _nudge = 3;

  @override
  void paint(Canvas canvas, Size size) {
    // 줄 없는 종이는 아무것도 그리지 않는다. 이 한 줄이 없어서 세피아·
    // 종이·크라프트·월넛·하늘의 견본이 전부 모눈으로 나왔다(2026-08-17).
    if (!drawsHorizontal(ruling)) return;

    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..isAntiAlias = false; // 1px 선은 안티에일리어싱하면 흐려진다

    for (final y in ruleOffsets(
      lineHeight: lineHeight,
      viewHeight: size.height,
      scroll: scroll,
      topPad: _topPad + headPad,
    )) {
      final yy = y - _nudge;
      if (yy < 0 || yy > size.height) continue;
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), p);
    }

    if (!drawsVertical(ruling)) return;

    // 모눈은 줄 높이와 같은 정사각이라 어느 글꼴에서도 맞는다.
    // 원고지는 한글 한 글자 폭으로 잰 칸이다.
    final w = ruling == kRulingManuscript ? colWidth : lineHeight;
    for (final x in columnOffsets(colWidth: w, viewWidth: size.width)) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.ruling != ruling ||
      old.color != color ||
      old.lineHeight != lineHeight ||
      old.colWidth != colWidth ||
      old.headPad != headPad ||
      old.scroll != scroll;
}

/// 아이클라우드가 꺼져 있을 때 여는 안내.
///
/// 왜 '설정으로 바로 가기'가 아니라 글인가: 애플이 앱에서 열 수 있게 허용한
/// 설정 화면은 '이 앱의 설정' 페이지 하나뿐이다. iCloud 항목으로 직접 뛰는
/// 주소(prefs:root=CASTLE)는 비공개 API라 쓰면 심사에서 반려된다. 그래서
/// 열어 줄 수 있는 데까지 열고, 그 다음 길은 순서대로 적어 준다.
/// 동기화가 잠들었을 때 목록 맨 위에 눕는 안내 띠.
///
/// 언제 보일지는 core/sync_plan.dart의 syncBanner가 정한다(시험으로
/// 못 박혀 있다). 여기는 그 결정을 그리고, 누름을 받는 것만 한다.
///
/// wake(허락 만료)일 때 누르면 그 자리에서 허락 창을 띄운다 — 누름
/// 자체가 브라우저가 요구하는 사용자의 손짓이라 이것이 가능하다.
/// 실패하면 동기화 시트를 열어 긴 안내로 넘긴다.
/// 첫 동기화가 도는 동안 목록 위에 눕는 띠.
///
/// 2026-08-27 소유자 신고 — 로그인 직후 목록에 샘플 문서 하나만 있으면
/// 사람들이 "왜 로그인했는데 동기화가 안 되지?"라고 묻는다. 텅 비어
/// 있으니 에러 난 줄 안다.
///
/// 사람은 침묵을 고장으로 읽는다. 방금 무언가를 허락한 직후에는 더
/// 그렇다 — 내가 한 일이 통했는지 확인하고 싶은데 화면이 아무 말도
/// 안 하면, 통하지 않았다고 결론 내린다.
///
/// 도는 막대를 쓰는 까닭. 글자만으로는 "지금도 돌고 있다"가 안 전해진다.
/// 멈춘 글자는 멈춘 것으로 읽힌다. 움직이는 것이 하나라도 있어야 사람은
/// 기다린다.
///
/// 언제 사라지나 — **이 기기에서 첫 바퀴가 끝나는 순간.** 그 뒤로는 앱을
/// 껐다 켜도 다시 안 나온다. 켤 때마다 몇 초씩 뜨면 그건 안내가 아니라
/// 잔소리다. 셈은 core/sync_plan.dart 의 showSyncingBanner 에 있다.
class SyncBusyBanner extends StatelessWidget {
  const SyncBusyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sync = ICloudSync.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync.state, sync.lastSyncMs]),
      builder: (_, __) {
        final show = showSyncingBanner(
          active: sync.active,
          paused: sync.paused,
          everSynced: sync.everSynced,
          running: sync.state.value == SyncState.running,
        );
        if (!show) return const SizedBox.shrink();
        final c = context.c;
        return Container(
          width: double.infinity,
          color: c.accent.withValues(alpha: 0.10),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.syncFirstTitle,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.accent)),
                        const SizedBox(height: 3),
                        Text(l.syncFirstSub,
                            style: TextStyle(
                                fontSize: 13.5, height: 1.4, color: c.sub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 아래 실 한 줄. 동그라미만으로도 되지만, 띠 전체가 살아
            // 있다는 것을 이 줄이 말한다.
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: c.accent.withValues(alpha: 0.15),
                color: c.accent,
              ),
            ),
          ]),
        );
      },
    );
  }
}

class SyncNapBanner extends StatefulWidget {
  const SyncNapBanner({super.key});

  @override
  State<SyncNapBanner> createState() => _SyncNapBannerState();
}

class _SyncNapBannerState extends State<SyncNapBanner> {
  /// 허락 창이 떠 있는 동안 또 누르는 것을 막는다.
  bool _busy = false;

  Future<void> _wake() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await DriveAuth.instance.authorizeDrive();
    if (ok) {
      // 첫 맞추기를 기다리며 단추를 붙잡아 두지 않는다 (2026-08-26).
      // 배너는 맞추기가 끝나면 스스로 사라진다 — 기다릴 이유가 없다.
      unawaited(applySyncBackend().then((_) => ICloudSync.instance.rebind()));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _sheet();
  }

  void _sheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SyncHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: ICloudSync.instance.state,
      builder: (context, st, _) => ValueListenableBuilder<int>(
        valueListenable: DriveAuth.instance.revision,
        builder: (context, _, __) {
          final auth = DriveAuth.instance;
          final need = syncBanner(
            gdrive: Store.instance.settings.syncBackend == 'gdrive',
            healthy: st == SyncState.ok || st == SyncState.running,
            signedIn: auth.signedIn,
            authExpired: auth.authExpired,
          );
          if (need == SyncBanner.none) return const SizedBox.shrink();
          final l = L10n.of(context);
          final c = context.c;
          final wake = need == SyncBanner.wake;
          // 2026-08-21 소유자 지시 — "확실히 눈에 띄어야 하니까. 아주
          // 눈에 띄게 해줘." 회색 띠는 안내가 아니라 배경이었다. 브랜드
          // 색을 통째로 깔고 글씨를 키운다. 정상일 땐 여전히 0px라서
          // 요란해도 되는 자리다 — 이 띠가 보이는 날은 눌러야 하는 날이다.
          final dark = Theme.of(context).brightness == Brightness.dark;
          final ink = dark ? Colors.black : Colors.white;
          return Material(
            color: c.accent,
            child: InkWell(
              onTap: _busy ? null : (wake ? _wake : _sheet),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                child: Row(children: [
                  Icon(
                    wake
                        ? Icons.lock_clock_outlined
                        : Icons.cloud_off_outlined,
                    size: 22,
                    color: ink,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      wake ? l.syncStateExpiredGdrive : l.syncStateOffGdrive,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: ink),
                    ),
                  ),
                  if (_busy)
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ink))
                  else
                    Icon(Icons.chevron_right, size: 22, color: ink),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 동기화 기록 화면 (2026-08-27).
///
/// 소유자 요청 — "동기화 기록 기능을 이어서 넣어라." 앞선 이틀 동안
/// "맥에서 쓴 글이 아이폰에 몇 시간째 안 온다", "한 문장 중 앞부분만
/// 왔다" 같은 신고가 있었는데, 그때마다 답할 근거가 없었다. 화면에는
/// '켜짐'이라는 초록 글씨뿐이었기 때문이다.
///
/// 이 화면은 고치는 화면이 아니라 **보는 화면**이다. 무엇이 언제 몇 개
/// 오갔고 얼마나 걸렸는지만 보여 준다. 그것만 있으면 "안 온다"가
/// "8시 5분에 올렸는데 10시 35분에 받았다"로 바뀐다.
///
/// 노트 내용은 한 글자도 남기지 않는다. 화면 아래에 그렇게 적어 둔다 —
/// 기록이 남는다는 말을 들으면 사람은 먼저 그것을 걱정한다.
/// 마지막으로 **받은** 시각을 짧게. 오늘이면 시:분만, 아니면 날짜도.
String syncFreshWhen(BuildContext context, int ms) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final tag = Localizations.localeOf(context).toLanguageTag();
  final h24 = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true;
  String hm;
  try {
    hm = (h24 ? DateFormat.Hm(tag) : DateFormat.jm(tag)).format(t);
  } catch (_) {
    hm = DateFormat.Hm().format(t);
  }
  if (t.year == now.year && t.month == now.month && t.day == now.day) return hm;
  try {
    return '${DateFormat.Md(tag).format(t)} $hm';
  } catch (_) {
    return '${DateFormat.Md().format(t)} $hm';
  }
}

/// '최근 업데이트 11:34' — 이 기기가 마지막으로 **받아 온** 시각.
///
/// 2026-08-27 소유자 요청. 올린 시각이 아니라 받은 시각인 까닭은 그 말이
/// "뭔가 업데이트된 게 있다면"이었기 때문이다. 내가 쓴 글이 올라간 것은
/// 업데이트가 아니다 — 내 화면에는 이미 있다. 남이 쓴 것이 도착했을
/// 때에만 뜻이 있다.
///
/// 받은 적이 한 번도 없으면 아무것도 안 그린다. 빈 자리가 거짓말보다 낫다.
/// 날짜 줄 옆에 붙는 '· 최근 업데이트 11:34'. 받은 적이 없으면 가운뎃점도
/// 안 찍는다 — 아무것도 없는데 구분점만 남으면 그게 더 이상하다.
class _FreshDot extends StatelessWidget {
  const _FreshDot();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sync = ICloudSync.instance;
    if (!sync.active || sync.paused) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: sync.logRevision,
      builder: (_, __, ___) {
        final ms = sync.log.lastDownMs;
        if (ms == null) return const SizedBox.shrink();
        return Text(
          '   ${l.syncUpdatedAt(syncFreshWhen(context, ms))}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.c.sub),
        );
      },
    );
  }
}

class SyncFreshLabel extends StatelessWidget {
  final TextAlign? align;
  final double size;
  const SyncFreshLabel({super.key, this.align, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sync = ICloudSync.instance;
    if (!sync.active || sync.paused) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: sync.logRevision,
      builder: (_, __, ___) {
        final ms = sync.log.lastDownMs;
        if (ms == null) return const SizedBox.shrink();
        return Text(
          l.syncUpdatedAt(syncFreshWhen(context, ms)),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: context.c.sub),
        );
      },
    );
  }
}

/// 손으로 지금 맞추기. 목록 머리와 편집 화면 머리에 같은 모양으로 둔다.
///
/// 2026-08-27 소유자 지시 — 웹과 맥에서는 당겨서 새로 고치기가 안 잡힌다.
/// 트랙패드 두 손가락 굴림을 브라우저가 '굴림 신호'로 보내지 '끌기'로
/// 보내지 않아서다. 플러터가 고칠 수 있는 자리가 아니다. 그러니 손짓이
/// 안 되는 곳에도 길은 있어야 한다 — 당기기는 그대로 두고 단추를 나란히
/// 놓는다.
///
/// 이 단추가 자주 눌린다면 그건 동기화가 느리다는 뜻이다. 목표는 이걸
/// 아무도 안 누르는 것이다.
class SyncNowButton extends StatefulWidget {
  final double size;
  const SyncNowButton({super.key, this.size = 21});

  @override
  State<SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends State<SyncNowButton> {
  /// **내가 눌러서** 도는 중인가.
  ///
  /// 2026-08-27 소유자 지시 — "자동으로 될 때는 애니메이션을 할 필요
  /// 없고, 수동으로 할 때만 나오게 해줘. 자동으로 되는 것은 잘 되기만
  /// 하면 되지."
  ///
  /// 맞는 말이다. 이제 3초마다 한 번씩 도는데(짧은 물음), 그때마다
  /// 머리에서 뭔가가 빙글거리면 **잘 되고 있다는 사실이 오히려 소란이
  /// 된다.** 잘 도는 기계는 조용하다.
  ///
  /// 그래서 동기화 상태(sync.state)를 안 듣는다. 내 손가락만 듣는다.
  bool _spin = false;

  Future<void> _go() async {
    if (_spin) return;
    setState(() => _spin = true);
    unawaited(HapticFeedback.lightImpact());
    final sw = Stopwatch()..start();
    try {
      await ICloudSync.instance
          .recheck()
          .timeout(const Duration(seconds: 8), onTimeout: () {});
    } catch (_) {
      // 실패해도 단추는 조용히 멈춘다. 무슨 일인지는 설정의 동기화 줄이
      // 말한다 — 목록 머리에서 사람을 붙잡을 일이 아니다.
    }
    // 너무 빨리 끝나면 깜빡임으로만 스친다. 눌렀다는 답이 되려면 눈에
    // 잠깐은 남아야 한다.
    final left = 600 - sw.elapsedMilliseconds;
    if (left > 0) {
      await Future<void>.delayed(Duration(milliseconds: left));
    }
    if (mounted) setState(() => _spin = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sync = ICloudSync.instance;
    if (!sync.active || sync.paused) return const SizedBox.shrink();
    final size = widget.size;
    return IconButton(
      tooltip: _spin ? l.syncNowBusy : l.syncNowAction,
      icon: _spin
          ? SizedBox(
              width: size - 4,
              height: size - 4,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.c.accent),
            )
          : Icon(Icons.cloud_sync_outlined, size: size),
      onPressed: _spin ? null : () => unawaited(_go()),
    );
  }
}

class SyncLogScreen extends StatelessWidget {
  const SyncLogScreen({super.key});

  static String _stamp(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${DateFormat.Md().format(d)} ${DateFormat.Hms().format(d)}';
  }

  static String _short(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${DateFormat.Md().format(d)} ${DateFormat.Hm().format(d)}';
  }

  /// 걸린 시간. 1초가 안 되면 밀리초로 — 0.0초가 줄줄이 늘어서면
  /// 빠르다는 사실이 오히려 안 보인다.
  static String _took(int ms) =>
      ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(1)}s';

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sync = ICloudSync.instance;
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: context.c.bg,
        title: Text(l.syncLogTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: narrowBody(
        context,
        ValueListenableBuilder<int>(
          valueListenable: sync.logRevision,
          builder: (_, __, ___) {
            final log = sync.log;
            final up = log.lastUpMs;
            final down = log.lastDownMs;
            return ListView(
              padding: scrollPad(context, top: 10),
              children: [
                _card(context, [
                  _line(context, l.syncLogLastUp(up == null ? l.syncLogNever : _short(up)),
                      strong: up != null),
                  _sep(context),
                  _line(context, l.syncLogLastDown(down == null ? l.syncLogNever : _short(down)),
                      strong: down != null),
                ]),
                const SizedBox(height: 18),
                if (log.isEmpty)
                  _card(context, [_line(context, l.syncLogEmpty)])
                else
                  _card(context, [
                    for (var i = 0; i < log.events.length; i++) ...[
                      if (i > 0) _sep(context),
                      _eventRow(context, l, log.events[i]),
                    ],
                  ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 14, 32, 8),
                  child: Text(l.syncLogNote,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.45, color: context.c.sub)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _eventRow(BuildContext context, L10n l, SyncEvent e) {
    final parts = <String>[
      if (e.up > 0) '${l.syncLogUp} ${e.up}',
      if (e.down > 0) '${l.syncLogDown} ${e.down}',
      if (!e.ok) '${l.syncLogFailed} (${e.err})',
      _took(e.ms),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(children: [
        Icon(
            e.ok
                ? (e.up > 0 && e.down > 0
                    ? Icons.swap_vert
                    : e.up > 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                : Icons.error_outline,
            size: 18,
            color: e.ok ? context.c.accent : context.c.sub),
        const SizedBox(width: 12),
        Expanded(
          child: Text(_stamp(e.atMs),
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: context.c.guideInk)),
        ),
        Text(parts.join(' · '),
            style: TextStyle(fontSize: 13.5, color: context.c.sub)),
      ]),
    );
  }

  Widget _line(BuildContext context, String t, {bool strong = false}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Text(t,
            style: TextStyle(
                fontSize: 15,
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                color: strong ? context.c.guideInk : context.c.sub)),
      );

  Widget _card(BuildContext context, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: context.c.panel,
            child: Column(children: children),
          ),
        ),
      );

  Widget _sep(BuildContext context) =>
      Divider(height: 1, indent: 16, color: context.c.line);
}

class SyncHelpSheet extends StatefulWidget {
  const SyncHelpSheet({super.key});

  @override
  State<SyncHelpSheet> createState() => _SyncHelpSheetState();
}

class _SyncHelpSheetState extends State<SyncHelpSheet> {
  bool _checking = false;

  /// 2026-08-20 소유자 신고 — "로그인한지 4분 넘어도 이러네."
  ///
  /// 아래 알림 상자는 **단추를 누른 그 순간의 답**이었고 그 뒤로 안
  /// 바뀌었다. 뒤에서 잘 맞춰지고 있어도 화면은 계속 안 된다고 말한다.
  /// 4분 동안 그대로인 것이 아니라 4분 전 것이 그대로 떠 있었던 것이다.
  ///
  /// **말이 사실을 안 따라가면 그 말은 거짓말이 된다.** 상태를 듣는다.
  @override
  void initState() {
    super.initState();
    ICloudSync.instance.state.addListener(_onSyncState);
    // 웹에서는 로그인 결과가 스트림으로 온다. 구글 단추를 누른 뒤
    // 화면이 저절로 다음 걸음으로 바뀌어야 한다.
    DriveAuth.instance.revision.addListener(_onDriveState);
  }

  void _onDriveState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ICloudSync.instance.state.removeListener(_onSyncState);
    DriveAuth.instance.revision.removeListener(_onDriveState);
    super.dispose();
  }

  void _onSyncState() {
    if (!mounted) return;
    if (ICloudSync.instance.state.value != SyncState.ok) return;
    setState(() {
      _checking = false;
      _saidBad = false;
      _said = L10n.of(context).syncRecheckOk;
    });
    Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  /// 지금 고른 창고가 구글인가.
  ///
  /// 2026-08-20 소유자 신고 — "구글 로그인 버튼을 누르니 아이클라우드
  /// 안내가 나온다." 이 창은 통째로 아이클라우드 전용이었다. 제목도
  /// '아이클라우드 켜는 법', 단추도 '설정 앱 열기'.
  ///
  /// 창고를 둘로 늘리면서 **이 창을 안 따라 고쳤다.** 창고를 아는
  /// 자리가 늘 때마다 빠뜨린 자리가 하나씩 나온다.
  bool get _gdrive => Store.instance.settings.syncBackend == 'gdrive';

  /// 마지막으로 확인한 결과를 사람 말로 적어 둔 것. 비어 있으면 아직
  /// 아무것도 안 눌렀다는 뜻이다.
  ///
  /// 2026-08-16 소유자 신고 — "'다시 확인'은 무슨 기능인가? 눌러도
  /// 무반응." 성공하면 창이 닫히는데 실패하면 아무 일도 안 일어났다.
  /// **실패야말로 말을 해 줘야 하는 쪽인데 거꾸로였다.**
  String? _said;
  bool _saidBad = false;

  Future<void> _recheck() async {
    setState(() {
      _checking = true;
      _said = null;
    });
    final sync = ICloudSync.instance;
    // 확인이 눈 깜짝할 새에 끝나면 사람은 아무 일도 안 일어났다고 느낀다.
    // 최소한 돌아가는 표시가 한 번 보일 만큼은 잡아 둔다. 일부러 느리게
    // 만드는 것이 아니라, 일했다는 사실이 보이게 만드는 것이다.
    await Future.wait<void>([
      sync.recheck(),
      Future<void>.delayed(const Duration(milliseconds: 650)),
    ]);
    // 됐다는 말을 읽을 틈을 준 뒤에 닫는다. 곧바로 닫으면 무엇이 바뀌었는지
    // 모른 채 창만 사라진다 — 그것도 '무반응'으로 느껴진다.
    await _report();
  }

  /// 구글 계정에 다시 붙는다.
  ///
  /// 아이클라우드 쪽의 '설정 앱 열기'와 자리는 같지만 하는 일이 다르다.
  /// 애플 쪽은 우리가 켜 줄 수 없어 길만 적어 주는 것이고, 구글 쪽은
  /// **여기서 바로 붙일 수 있다.** 길을 적어 줄 이유가 없다.
  /// 웹의 두 번째 걸음 — 드라이브 권한.
  Future<void> _allowDrive() async {
    setState(() {
      _checking = true;
      _said = null;
    });
    final ok = await DriveAuth.instance.authorizeDrive();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _checking = false;
        _saidBad = true;
        _said = L10n.of(context).driveSignInFailed;
      });
      return;
    }
    // 첫 맞추기를 기다리지 않는다 — 까닭은 _googleIn 에 적었다.
    unawaited(_fetchInBackground());
    await _sayFetching();
  }

  Future<void> _googleIn() async {
    setState(() {
      _checking = true;
      _said = null;
    });
    final ok = await DriveAuth.instance.signIn();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _checking = false;
        _saidBad = true;
        _said = L10n.of(context).driveSignInFailed;
      });
      return;
    }
    // 붙었다. **첫 맞추기를 기다리지 않는다** (2026-08-26 소유자 지시).
    //
    // 여태는 첫 맞추기가 다 끝날 때까지 이 시트를 열어 둔 채 기다렸다.
    // 노트가 많으면 1~2분이고, 하필 인증 창에서 막 돌아온 예민한 때다 —
    // 그 사이 아이폰이 검은 화면으로 남았다는 신고가 있었다(8/26 아침).
    //
    // 받아오기는 뒤에서 이어져도 되는 일이다. 앱이 잠들면 쉬었다가
    // 돌아올 때 onResume 이 이어받는다(icloud_sync.dart). 그러니 사람
    // 에게는 바로 답하고 창을 닫는다. 기다리게 하지 않는 것이 맞다.
    unawaited(_fetchInBackground());
    await _sayFetching();
  }

  /// 통로를 갈아 끼우고 처음부터 다시 맞춘다 — 화면과 상관없이 돈다.
  ///
  /// 화면을 만지지 않으므로 시트가 닫힌 뒤에 끝나도 안전하다.
  Future<void> _fetchInBackground() async {
    await applySyncBackend();
    await ICloudSync.instance.rebind();
  }

  /// "받아오는 중"이라고 말하고 창을 닫는다.
  ///
  /// 쓰는 말은 진단 줄과 **같은 것**을 쓴다. 같은 사실을 두 벌로 적어
  /// 두면 한쪽만 고치는 날이 온다 — 이 말은 9개 언어에 이미 있다.
  Future<void> _sayFetching() async {
    if (!mounted) return;
    setState(() {
      _checking = false;
      _saidBad = false;
      _said = L10n.of(context).syncDiagPreparingGdrive;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  /// 확인한 결과를 사람 말로 알리고, 됐으면 창을 닫는다.
  ///
  /// 다시 확인과 구글 로그인이 같은 말을 해야 한다. 두 벌 적어 두면
  /// 한쪽만 고치는 날이 온다.
  Future<void> _report() async {
    if (!mounted) return;
    final l = L10n.of(context);
    final ok = ICloudSync.instance.state.value == SyncState.ok;
    setState(() {
      _checking = false;
      _saidBad = !ok;
      _said = ok
          ? l.syncRecheckOk
          : (_gdrive ? l.syncRecheckStillGdrive : l.syncRecheckStill);
    });
    if (!ok) return;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _open() async {
    final ok = await ICloudSync.instance.openSettings();
    if (!mounted) return;
    if (ok) return;
    // 2026-08-17 — 못 열 수도 있다. 애플이 앱에서 열도록 허용한 주소는
    // '이 앱의 설정 페이지' 하나뿐이고, 그 페이지는 앱이 설정 앱에 항목을
    // 가지고 있을 때만 열린다. 우리가 어쩔 수 있는 것이 아니다.
    //
    // 그래서 '못 열었다'고 크게 알리지 않는다 — 사용자는 자기가 뭘 잘못한
    // 줄 안다. 대신 직접 가는 길을 적어 준다.
    setState(() {
      _saidBad = false;
      _said = L10n.of(context).syncOpenManual;
    });
  }

  /// 지금 무엇이 막고 있는지 한 줄로.
  ///
  /// 절차만 여섯 줄 늘어놓고 "안 되면 알아서 하세요"는 안내가 아니다.
  /// 기기에 물어본 사실 그대로를 먼저 말해 준다.
  (String, IconData) _diagnosis(L10n l) {
    // 구글은 물어볼 것이 하나뿐이다 — 붙었는가. 애플처럼 '자리를
    // 받았는가'가 따로 없다(드라이브의 방은 계정에 딸려 온다).
    if (_gdrive) {
      if (!DriveAuth.instance.signedIn) {
        return (l.syncDiagSignedOutGdrive, Icons.person_off_outlined);
      }
      // 붙어 있는데 허락이 끊긴 자리. '받아오는 중'이라고 하면 기다리면
      // 되는 줄 알고 계속 기다리게 된다 — 눌러야 풀리는 것이다.
      if (DriveAuth.instance.authExpired) {
        return (l.syncStateExpiredGdrive, Icons.lock_clock_outlined);
      }
      return (l.syncDiagPreparingGdrive, Icons.hourglass_bottom);
    }
    final sync = ICloudSync.instance;
    // 2026-08-17 — 순서를 뒤집었다.
    //
    // 전에는 '로그인했는가'를 먼저 물었다. 그런데 그 값은 로그인이 되어
    // 있어도 nil이 나올 수 있어서, 멀쩡한 기기에 "로그인되어 있지
    // 않습니다"를 띄웠다(소유자 아이폰에서 실제로 그랬다).
    //
    // 먼저 물을 것은 **자리를 실제로 받았는가**다. 그건 사실이고,
    // 로그인 여부는 못 받았을 때 까닭을 설명하는 데만 쓴다.
    if (sync.containerReady) {
      return (l.syncDiagPreparing, Icons.hourglass_bottom);
    }
    if (!sync.signedIn) return (l.syncDiagSignedOut, Icons.person_off_outlined);
    return (l.syncDiagNoContainer, Icons.cloud_off_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                      color: c.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: c.infoBg,
                  child: Icon(Icons.cloud_off_outlined, size: 30, color: c.accent),
                ),
              ),
              const SizedBox(height: 14),
              Text(_gdrive ? l.syncHelpTitleGdrive : l.syncHelpTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const SizedBox(height: 12),
              // 무엇이 막고 있는지 먼저. 절차는 그다음이다.
              Builder(builder: (_) {
                final d = _diagnosis(l);
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: c.infoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(d.$2, size: 20, color: c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(d.$1,
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: c.accent)),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 14),
              Text(_gdrive ? l.syncHelpStepsGdrive : l.syncHelpSteps,
                  style: TextStyle(fontSize: 15.5, height: 1.75, color: c.guideInk)),
              const SizedBox(height: 16),
              // 웹은 두 걸음이다. 구글이 그린 단추로 계정을 고르고,
              // 그다음 우리 단추로 드라이브 권한을 받는다. 권한 창은
              // **사람이 누른 그 자리**에서만 열린다 — 붙자마자 우리가
              // 알아서 열면 브라우저가 팝업 차단으로 막는다.
              if (kIsWeb && _gdrive && !DriveAuth.instance.signedIn)
                Center(child: googleSignInButton())
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: _checking
                      ? null
                      : (_gdrive ? (kIsWeb ? _allowDrive : _googleIn) : _open),
                  child: Text(
                      _gdrive
                          ? (kIsWeb ? l.syncAllowDrive : l.syncSignInGoogle)
                          : l.syncOpenSettings,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 9),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                onPressed: _checking ? null : _recheck,
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.syncRecheck),
              ),
              // 버튼 이름만 보고는 무슨 일이 일어나는지 알 수 없다.
              // 눌렀을 때 실제로 하는 일을 그대로 적는다.
              const SizedBox(height: 6),
              if (!_gdrive)
                Text(l.syncRecheckWhat,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.4, color: c.sub)),
              // 눌렀으면 반드시 무언가 대답한다.
              if (_said != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: _saidBad ? c.warnBg : c.infoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(_saidBad ? Icons.info_outline : Icons.check_circle,
                        size: 19, color: _saidBad ? c.warnInk : c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_said!,
                          style: TextStyle(
                              fontSize: 14.5,
                              height: 1.4,
                              color: _saidBad ? c.warnInk : c.accent)),
                    ),
                  ]),
                ),
              ],
              // 2026-08-17 — 여기 '사실 한 줄'을 잠깐 뒀다가 내렸다.
              //
              // 그 줄이 결정적인 답을 줬다("No implementation found for
              // method root on channel skyblue/icloud" — 다리가 아예 연결된
              // 적이 없었다). 짐작으로 세 판을 쓴 뒤였다.
              //
              // 그리고 소유자 지적대로 내린다 — "이런 것은 사용자에게 굳이
              // 보여 줄 필요 없다. 복잡하고 어렵게만 보일 뿐이다." 맞다.
              // 그건 **나를 위한 줄**이었지 쓰는 사람을 위한 줄이 아니었다.
              // 제 몫을 했으니 내린다. 값 자체(ICloudSync.facts)는 남겨
              // 둔다 — 다음에 또 막히면 한 줄만 도로 붙이면 된다.
              const SizedBox(height: 12),
              Text(_gdrive ? l.syncHelpNoteGdrive : l.syncHelpNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: c.sub)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 유료 등급이 살아 있는가.
///
/// 2026-08-17 소유자 결정 — **첫 판은 완전 무료로 낸다.**
///
/// 가격이 적힌 화면을 남겨 두면 애플이 두 눈으로 본다. 2.1(되지 않는
/// 기능이 있는 앱)과 3.1.1(디지털 상품 가격을 보여 주면서 애플 결제를
/// 안 쓰는 앱). 둘 다 "고쳐서 다시 내라"로 끝난다.
///
/// 그런데 **화면만 숨기고 하루 한도를 남기면 더 나쁘다.** 사용자는
/// 빠져나갈 길이 없는 벽을 만나고, 안내문은 없는 프리미엄을 가리킨다.
/// 그래서 한도까지 같이 끈다. 첫 판은 광고만 두고 전부 열어 둔다.
///
/// 지우지 않고 끄는 이유: 지웠다가 다시 쓰면 그 사이에 규칙이 어긋나고,
/// 어긋난 것은 결제가 걸린 자리에서 제일 아프다. StoreKit을 붙이는 날
/// 이 값 하나만 true로 되돌리면 전부 살아난다.
///
/// const가 아니라 final인 이유: const로 두면 분석기가 아래 코드를 전부
/// '죽은 코드'로 보고 경고한다. 죽은 게 아니라 **잠깐 꺼 둔 것**이다.
// 2026-08-26 — 상수를 손으로 고쳤다 되돌리는 짓을 그만둔다. 빌드할 때
// --dart-define=PAID_TIER=true 를 실으면 켜진다. 샌드박스 검증이 끝나면
// 여기 기본값을 true 로 바꾼다.
// ignore: prefer_const_declarations
final bool kPaidTierLive = const bool.fromEnvironment('PAID_TIER');

/// 켜고 나면 곧장 결제 화면을 연다 — **디버그 전용**.
///
/// 심사용 스크린샷을 찍을 때 화면을 손으로 뒤지지 않기 위해서다.
/// simctl 로 띄우고 simctl io ... screenshot 으로 바로 찍는다.
// ignore: prefer_const_declarations
final bool kShowPaywallOnStart = const bool.fromEnvironment('SHOW_PAYWALL');

/// 이 기기가 어느 스토어의 식구인가 — core/purchase_gate.dart의 갈래로 옮긴다.
///
/// 기본 등급이 '산 스토어의 기기군'에서만 열리기 때문에, 판정에는 반드시
/// 이 값이 필요하다. 순수 함수 쪽에 Platform을 부르는 코드를 넣지 않으려고
/// 바깥에서 정해 넣는다(시험에서 못 돌리게 되는 것을 막는다).
String deviceFamily() {
  if (kIsWeb) return kFamilyWeb;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return kFamilyApple;
    case TargetPlatform.android:
      return kFamilyGoogle;
    default:
      return kFamilyOther; // 윈도우·리눅스 — 살 스토어가 없다
  }
}

/// 프리미엄 안내 화면.
///
/// 2026-08-17 — 지금은 **아무 데서도 부르지 않는다**([kPaidTierLive]).
/// StoreKit이 붙는 날 다시 연결한다.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _svc = PurchaseService.instance;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    _wasPremium = Store.instance.settings.premium;
    _svc.revision.addListener(_tick);
    Store.instance.addListener(_tick);
    // 화면에 들어온 김에 값을 한 번 더 받아 온다. 처음 시동 때 스토어가
    // 느렸거나 인터넷이 없었으면 목록이 비어 있을 수 있다.
    unawaited(_svc.loadProducts());
  }

  @override
  void dispose() {
    _svc.revision.removeListener(_tick);
    Store.instance.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final now = Store.instance.settings.premium;
    if (now && !_wasPremium) {
      _wasPremium = true;
      _toast(context, L10n.of(context).premiumThanks);
    }
    setState(() {});
  }

  bool get _apple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _open(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> _buy(String id) async {
    final p = _svc.product(id);
    if (p == null) {
      _toast(context, L10n.of(context).premiumLoading);
      return;
    }
    await _svc.buy(p);
  }

  /// 값 한 줄. 스토어가 준 값을 그대로 쓴다 — 나라마다 다르고, 우리가 적어 둔
  /// 숫자는 반드시 언젠가 실제와 어긋난다.
  Widget _plan({
    required String id,
    required String title,
    String? note,
    String? badge,
    bool filled = false,
  }) {
    final c = context.c;
    final p = _svc.product(id);
    // 스토어가 준 값이 언제나 먼저다. 개발 중(디버그)에만, 그리고 스토어가
    // 아직 아무것도 안 줬을 때만 우리가 적어 둔 미국 값으로 자리를 채운다.
    final price = p?.price ?? (kDebugMode ? kDevUsdPrice[id] : null);
    final body = Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.accent)),
                ),
              ],
            ]),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(note,
                    style: const TextStyle(fontSize: 12.5, height: 1.25)),
              ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Text(price ?? '···',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    ]);
    final onTap = (_svc.busy || price == null) ? null : () => unawaited(_buy(id));
    final style = ButtonStyle(
      padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: filled
          ? FilledButton(style: style, onPressed: onTap, child: body)
          : OutlinedButton(style: style, onPressed: onTap, child: body),
    );
  }

  Widget _sectionTitle(String title, String scope) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(scope,
                style: TextStyle(
                    fontSize: 12.5, height: 1.35, color: context.c.sub)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    final s = Store.instance.settings;
    final now = DateTime.now();
    final family = deviceFamily();
    final tier = tierOf(e: s.ent, now: now);
    final offerUp = shouldOfferUpgrade(e: s.ent, family: family, now: now);

    final body = <Widget>[
      Center(
        child: CircleAvatar(
          radius: 34,
          backgroundColor: c.infoBg,
          child: Icon(Icons.workspace_premium, size: 38, color: c.accent),
        ),
      ),
      const SizedBox(height: 16),
      Text(l.premiumPitch,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(l.premiumPerks,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.4, color: c.accent)),
    ];

    // 체험 중이면 남은 날을 여기서도 보여 준다. 끝나는 날을 미리 알고 있으면
    // 종료가 배신이 아니라 예고가 된다.
    if (trialOn(s.trialDays)) {
      body.addAll([
        const SizedBox(height: 10),
        Text(l.trialBadge(trialLeft(s.trialDays)),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: c.accent)),
      ]);
    }

    // 이미 가진 사람에게는 무엇을 가졌는지부터 알려 준다.
    if (tier > 0) {
      body.addAll([
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.infoBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text('${l.premiumHave} · ${tier == 2 ? l.premiumPlanAll : l.premiumPlanBase}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            if (offerUp) ...[
              const SizedBox(height: 6),
              Text(l.premiumUpgradeHere,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
          ]),
        ),
      ]);
    }

    body.addAll([
      const SizedBox(height: 14),
      Text(l.premiumBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.55, color: c.guideInk)),
    ]);

    if (!_svc.supported) {
      // 웹·윈도우에는 붙일 스토어가 없다. 단추를 그려 놓고 눌러도 아무 일이
      // 없게 두는 것보다, 어디서 사면 되는지 말해 주는 편이 정직하다.
      body.addAll([
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.glassLine),
          ),
          child: Text(l.premiumNoStore,
              style: const TextStyle(fontSize: 13.5, height: 1.5)),
        ),
      ]);
    } else {
      body.addAll([
        _sectionTitle(l.premiumPlanAll, l.premiumScopeAll),
        _plan(
          id: kProductLifetime,
          title: l.premiumLifetime,
          note: l.premiumLifetimeNote,
          filled: true,
        ),
        _plan(
          id: kProductAllYearly,
          title: l.premiumYearly,
          badge: l.premiumBestValue,
        ),
        _plan(id: kProductAllMonthly, title: l.premiumMonthly),
        _sectionTitle(l.premiumPlanBase, l.premiumScopeBase),
        _plan(id: kProductYearly, title: l.premiumYearly),
        _plan(id: kProductMonthly, title: l.premiumMonthly),
        const SizedBox(height: 10),
        // 자동 갱신 고지 — 애플이 결제 화면에서 반드시 찾는 문장이다.
        Text(l.premiumAutoRenew,
            style: TextStyle(fontSize: 11.5, height: 1.5, color: c.sub)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            TextButton(
              onPressed: _svc.busy ? null : () => unawaited(_svc.restore()),
              child: Text(l.premiumRestore),
            ),
            if (_apple)
              TextButton(
                onPressed: () => unawaited(_open(appleEulaUrl())),
                child: Text(l.premiumTerms),
              ),
            TextButton(
              onPressed: () => unawaited(_open(privacyUrl())),
              child: Text(l.premiumPrivacy),
            ),
          ],
        ),
      ]);
      if (!_svc.hasProducts) {
        body.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.premiumLoading,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.sub)),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: body,
      ),
    );
  }
}

/// 설정 화면들이 함께 쓰는 '줄 그리기'.
///
/// 2026-08-17 — 정리 규칙 세부를 한 화면 안쪽으로 옮기면서 뺐다. 두 화면이
/// 같은 모양의 줄을 그려야 하는데, 복사해서 두 벌로 두면 반드시 어긋난다.
/// 이 프로젝트에서만 이미 세 번 겪었다(아이클라우드 다리의 스위프트 두 벌,
/// 되돌리기 두 벌, 그리고 그때마다 analyze나 사고가 알려 줬다).
///
/// 타입 인자를 W로 둔 이유: 안에 있는 _dropRow<T>의 T와 이름이 겹치면
/// 다트가 어느 T인지 가리지 못한다.
mixin SettingsRows<W extends StatefulWidget> on State<W> {
  Store get store => Store.instance;

  /// 고르는 줄.
  ///
  /// 2026-08-18 소유자 지적 — "안내 멘트가 왜 좌측에 있지? 안내 멘트는
  /// 위에 있고 설정이 그 아래에 있어야 할 것 같아. 이렇게 2단으로 하는 건
  /// 이상해."
  ///
  /// ListTile 을 쓰고 있었다. 그것은 subtitle 을 **제목 아래 왼쪽**에 두고
  /// trailing 을 오른쪽에 둔다. 안내문구가 한 줄이면 괜찮지만 세 줄이 되면
  /// 왼쪽에 글 덩어리가 서고 오른쪽에 고르개가 따로 떠서 **두 단짜리 표**로
  /// 보인다. 눈이 어디부터 읽을지 정하지 못한다.
  ///
  /// 이름과 고르개는 한 줄에(그 둘은 짝이다), 안내는 그 아래 통째로 편다.
  /// 이 화면에서 두 단인 자리는 여기 하나뿐이었다.
  Widget _dropRow<T>(String label, String? sub, T value,
      List<(T, String)> options, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 17)),
            ),
            DropdownButton<T>(
              value: value,
              underline: const SizedBox.shrink(),
              items: options
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onChanged(v);
                  store.persistSettings();
                  setState(() {});
                }
              },
            ),
          ]),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Text(sub,
                  style: TextStyle(
                      fontSize: 14, height: 1.4, color: context.c.sub)),
            ),
        ],
      ),
    );
  }

  /// 애플 설정 앱식 작은 회색 머리글.
  Widget _secHeader(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 22, 16, 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: context.c.sub)),
      );

  /// 둥근 카드 한 장.
  ///
  /// Material로 감싸는 이유가 있다. 색 있는 Container 안에 ListTile을 넣으면
  /// 프레임워크가 "ink splashes may be invisible" assertion을 던진다 —
  /// 2026-08-14에 홈 목록에서 실제로 겪었다. Material을 직접 두면 그 경고가
  /// 사라지고 눌렀을 때 반응도 제대로 보인다. 여기도 안에 ListTile이 들어간다.
  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: context.c.panel,
            child: Column(children: children),
          ),
        ),
      );

  Widget _sep() => Divider(height: 1, indent: 16, color: context.c.line);

  Widget _switchRow(String title, String? sub, bool value, ValueChanged<bool> apply) =>
      SwitchListTile.adaptive(
        // 2026-08-14 소유자 요청: 설정 글자가 너무 작다. 항목은 기본 크기(17),
        // 안내문구도 같은 17에 아주 진한 회색(다크에서는 흰색에 가까운 회색).
        // 애플 설정 앱은 안내문구를 13pt 회색으로 쓰지만, 여기서는 소유자가
        // 명시적으로 크게 해 달라고 했다 — 관습보다 사용자 지시가 우선이다.
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        // 2026-08-18 소유자 지시 — "설정에서 군데군데 폰트 사이즈 크게
        // 나오는 부분이 있다. 세련되게 해줘."
        //
        // 08-14에 "설정 글자가 너무 작다"는 말을 듣고 안내문구까지 17로
        // 올렸는데, 그때 커져야 했던 것은 **항목 이름**뿐이었다. 안내문구가
        // 같은 크기가 되니 무엇이 이름이고 무엇이 설명인지 구별이 사라졌다.
        // **크기가 같으면 위계가 없다.**
        //
        // 이름 17, 설명 14. 애플은 13을 쓰지만 한글은 한 눈금 크게 잡는다.
        subtitle: sub == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(sub,
                    style: TextStyle(
                        fontSize: 14, height: 1.4, color: context.c.sub)),
              ),
        value: value,
        onChanged: (v) {
          apply(v);
          store.persistSettings();
          setState(() {});
        },
      );
}

/// 정리 규칙 세부 화면.
///
/// 2026-08-17 소유자 지적 — "설정에서 정리 규칙의 세부는 한 뎁스 더 들어가서
/// 설정하게. 너무 다 꺼내 놓는 게 마음에 안 든다."
///
/// 아홉 줄이 설정 첫 화면에 통째로 펼쳐져 있었다. 그중 여덟은 한 번 정하고
/// 다시 안 여는 것들이다. 애플 설정 앱이 하는 방식이 이것이다 — 첫 화면에는
/// 이름만, 세부는 들어가서.
///
/// 줄을 그리는 도구는 SettingsRows를 함께 쓴다. 복사해서 두 벌로 두면
/// 반드시 어긋난다.
class TidyRulesScreen extends StatefulWidget {
  const TidyRulesScreen({super.key});

  @override
  State<TidyRulesScreen> createState() => _TidyRulesScreenState();
}

class _TidyRulesScreenState extends State<TidyRulesScreen> with SettingsRows {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: context.c.bg,
        title: Text(l.tidyRulesTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: scrollPad(context, top: 6),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 12),
            child: Text(l.tidyRulesSub,
                style: TextStyle(
                    fontSize: 15, height: 1.35, color: context.c.guideInk)),
          ),
          _card([
            // 2026-08-18 — 기본값이 '그대로 두기'로 바뀌었으니 맨 위도
            // 바꾼다. 목록의 첫 줄은 '보통 이렇게 씁니다'라는 말이다.
            _dropRow(l.emphTitle, l.emphSub, s.emphStyle, [
              ('keep', l.keepLabel),
              ('remove', l.removeLabel),
              ('quoteSingle', l.emphQuoteSingle),
              ('quoteDouble', l.emphQuoteDouble),
            ], (v) => s.emphStyle = v),
            _sep(),
            _dropRow(l.headingTitle, null, s.headingMode, [
              ('keep', l.headingKeep),
              ('strip', l.headingStrip),
              ('prefix', l.headingPrefix),
              ('bracket', l.headingBracket),
            ], (v) => s.headingMode = v),
            _sep(),
            // 2026-08-18 — 제목·강조와 한 줄로 세운다. 셋이 같은 가족인데
            // 하나만 다르게 두면, 왜 이것만 지워지는지 아무도 모른다.
            _dropRow(l.quoteTitle, null, s.quoteMode, [
              ('keep', l.keepLabel),
              ('strip', l.removeLabel),
            ], (v) => s.quoteMode = v),
            _sep(),
            _dropRow(l.hrTitle, null, s.hrMode, [
              ('keep', l.keepLabel),
              ('remove', l.removeLabel),
            ], (v) => s.hrMode = v),
            _sep(),
            _dropRow(l.bulletTitle, null, s.bulletChar, [
              ('-', l.bulletHyphen),
              ('·', l.bulletMiddot),
              ('•', l.bulletDot),
              ('◦', l.bulletWhite),
              ('keep', l.bulletKeep),
            ], (v) => s.bulletChar = v),
            _sep(),
            _dropRow(l.bulletIndentTitle, null, s.bulletIndent, [
              (2, l.indent2),
              (4, l.indent4),
              (0, l.indentNone),
            ], (v) => s.bulletIndent = v),
            _sep(),
            _switchRow(l.headingPadTitle, l.headingPadSub, s.headingPad,
                (v) => s.headingPad = v),
            _sep(),
            _switchRow(l.fillerHeadingTitle, l.fillerHeadingSub, s.smartFillerHeading,
                (v) => s.smartFillerHeading = v),
            _sep(),
            _switchRow(l.dashListTitle, l.dashListSub, s.smartDashList,
                (v) => s.smartDashList = v),
            _sep(),
            _switchRow(l.citationsTitle, l.citationsSub, s.removeCitations,
                (v) => s.removeCitations = v),
          ]),
        ],
      ),
    );
  }
}

/// ---------------- 정리 규칙 설정 ----------------
/// 앱 전체 설정.
///
/// 2026-08-16 소유자 요청 — 제목이 '정리 규칙 설정'이었는데 이 화면은
/// 정리 규칙만 있는 곳이 아니다(화면 모드·글자 크기·AI 키까지 들어 있다).
/// 이름과 내용이 어긋나 있었다. '설정'으로 바꿨다.
///
/// [anchor]를 주면 열자마자 그 자리로 스크롤한다. 편집 화면 '...' 메뉴에서
/// 바로 뛰어오기 위한 것이다 — 설정이 길어져서, 문을 열어 주는 것만으로는
/// 원하는 항목을 찾기까지 여전히 훑어야 했다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.anchor});

  /// 'theme' | 'fontsize' | 'mono' | 'tidy' | 'rules' | 'ai'
  final String? anchor;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SettingsRows {

  /// 바로가기가 겨냥하는 자리들.
  ///
  /// 목록을 ListView가 아니라 SingleChildScrollView + Column으로 그리는
  /// 이유가 여기 있다. ListView는 화면 밖 항목을 아직 배치하지 않아서
  /// GlobalKey에 context가 없고, 그러면 ensureVisible이 조용히 아무것도
  /// 하지 않는다. 설정은 길어야 화면 몇 장이라 전부 배치해도 무겁지 않다.
  final Map<String, GlobalKey> _anchors = {
    'theme': GlobalKey(),
    'fontsize': GlobalKey(),
    'paper': GlobalKey(),
    'lock': GlobalKey(),
    'mono': GlobalKey(),
    'tidy': GlobalKey(),
    'rules': GlobalKey(),
    'ai': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final a = widget.anchor;
    if (a == null) return;
    // 첫 프레임이 그려진 뒤라야 각 자리의 위치를 안다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchors[a]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        // 0.0 = 겨냥한 자리를 화면 맨 위에 붙인다(소유자 요청).
        alignment: 0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }
  bool _aiChecking = false;
  bool _aiAdvOpen = false;
  String _aiMsg = '';

  /// 붙여넣고 잠깐 기다렸다가 저절로 확인에 들어가는 시계.
  ///
  /// 2026-08-17 소유자 지시 — "'고급설정' 같은 건 안된다. 나도 지금 이렇게
  /// api키 설정이 어려운데, 일반인들에게는 불가능한 설정이다."
  ///
  /// 맞는 말이고, 사실 '키 확인'을 누르게 하는 것부터가 한 단계 더다.
  /// 붙여넣었으면 그게 곧 "이걸 써 달라"는 뜻이다. 한 글자 칠 때마다
  /// 부르지 않으려고 잠깐만 기다린다.
  Timer? _aiAutoTimer;

  /// 고급에서 보여 줄 모델 후보. 받아 온 목록이 있으면 그것을, 없으면
  /// 예비 사다리를 보여 준다.
  List<String> _aiPickList() {
    final s = store.settings;
    final p = s.aiProvider.isNotEmpty ? s.aiProvider : (providerOfKey(s.aiKey) ?? '');
    if (s.aiModels.isNotEmpty && p.isNotEmpty) {
      final f = filterChatModels(p, s.aiModels);
      if (f.isNotEmpty) return f;
    }
    return p.isEmpty ? const [] : defaultLadder(p);
  }

  String _aiStatusLine(L10n l) {
    final s = store.settings;
    if (s.aiKey.trim().isEmpty) return '';
    final p = s.aiProvider.isNotEmpty ? s.aiProvider : providerOfKey(s.aiKey);
    if (p == null || p.isEmpty) return l.aiKeyUnknownFormat;
    final m = s.aiModel.isNotEmpty ? s.aiModel : defaultLadder(p).first;
    return l.aiAutoLabel(providerLabel(p), m);
  }

  /// 회사별 '모델 목록' API. 여기가 이 설계의 심장이다 — 오늘 무슨 모델이
  /// 있는지는 코드가 아니라 회사에 물어본다.
  Future<List<String>> _fetchModelIds(String provider, String key) async {
    if (provider == 'google') {
      final ids = <String>[];
      var page = '';
      for (var i = 0; i < 5; i++) {
        final res = await http.get(Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models?pageSize=200&key=${Uri.encodeComponent(key)}${page.isEmpty ? '' : '&pageToken=$page'}'));
        if (res.statusCode != 200) throw Exception(_apiErr2(res.statusCode, res.bodyBytes));
        final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        for (final m in (j['models'] ?? []) as List) {
          final methods =
              List<String>.from(((m as Map)['supportedGenerationMethods'] ?? const []) as List);
          if (!methods.contains('generateContent')) continue;
          ids.add(((m['name'] ?? '') as String).replaceFirst('models/', ''));
        }
        page = (j['nextPageToken'] ?? '') as String;
        if (page.isEmpty) break;
      }
      return ids;
    }
    if (provider == 'anthropic') {
      final res = await http.get(Uri.parse('https://api.anthropic.com/v1/models?limit=100'),
          headers: {'x-api-key': key, 'anthropic-version': '2023-06-01'});
      if (res.statusCode != 200) throw Exception(_apiErr2(res.statusCode, res.bodyBytes));
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return [for (final m in (j['data'] ?? []) as List) ((m as Map)['id'] ?? '') as String];
    }
    final base = provider == 'xai' ? 'https://api.x.ai' : 'https://api.openai.com';
    final res = await http.get(Uri.parse('$base/v1/models'),
        headers: {'authorization': 'Bearer $key'});
    if (res.statusCode != 200) throw Exception(_apiErr2(res.statusCode, res.bodyBytes));
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return [for (final m in (j['data'] ?? []) as List) ((m as Map)['id'] ?? '') as String];
  }

  static String _apiErr2(int code, List<int> bodyBytes) {
    try {
      final j = jsonDecode(utf8.decode(bodyBytes));
      final e = j is Map ? j['error'] : null;
      final m = (e is Map ? e['message'] : e)?.toString() ?? '';
      if (m.isNotEmpty) {
        return 'API $code: ${m.length > 140 ? m.substring(0, 140) : m}';
      }
    } catch (_) {}
    return 'API $code';
  }

  /// 키를 넣으면 회사도 모델도 우리가 알아낸다.
  ///
  /// 2026-08-17 소유자 신고 — 구글 AI 스튜디오 키를 넣었는데 "키 형식을
  /// 인식하지 못했습니다"가 뜨고, 고급 목록에는 **엉뚱하게 GPT 모델들**이
  /// 그대로 남아 있었다.
  ///
  /// 두 가지가 겹친 사고였다.
  ///
  ///   1. 회사를 **키 앞글자로만** 판정했다. 앞글자는 회사가 언제든 바꿀 수
  ///      있는 것이고, 실제로 못 알아본 키가 나왔다. 앞글자 표를 늘리는 것은
  ///      해결이 아니다 — 다음에 또 바뀌면 또 막힌다.
  ///   2. 키를 바꿔도 **앞서 알아낸 회사·모델·목록이 그대로 남아 있었다.**
  ///      그래서 구글 키를 넣은 화면에 ChatGPT와 gpt-5-nano가 떠 있었다.
  ///      데이터가 아니라 화면이 거짓말을 한 셈이다.
  ///
  /// 그래서 판정 방식을 바꾼다. **앞글자는 짐작일 뿐이고, 진짜 판정은 서버가
  /// 한다.** 회사마다 모델 목록 주소가 다르니, 받아 주는 곳이 곧 그 키의
  /// 주인이다. 앞글자가 짚이면 그 회사를 맨 앞에 놓아 한 번에 끝내고,
  /// 못 짚으면 네 곳에 차례로 물어본다.
  ///
  /// 남의 회사에 키를 보내는 일은 최소로 한다 — 짚이는 회사가 있으면 거기만
  /// 부르고, **거절당했을 때만** 다음으로 넘어간다. 거절이 아니라 '잔액 없음'
  /// 같은 답이 오면 그건 주인을 찾은 것이므로 거기서 멈춘다.
  Future<void> _verifyAiKey() async {
    final s = store.settings;
    final key = s.aiKey.trim();
    if (key.isEmpty) return;
    _aiAutoTimer?.cancel();

    final guess = providerOfKey(key);
    final order = <String>[
      if (guess != null) guess,
      for (final p in const ['google', 'openai', 'anthropic', 'xai'])
        if (p != guess) p,
    ];

    setState(() {
      _aiChecking = true;
      _aiMsg = L10n.of(context).aiDetecting;
    });

    String lastErr = '';
    for (var i = 0; i < order.length; i++) {
      final p = order[i];
      List<String> ids;
      try {
        ids = await _fetchModelIds(p, key);
      } catch (e) {
        lastErr = '$e';
        final lo = lastErr.toLowerCase();
        // 이 회사 것이 아니다 → 다음 회사. 그 밖의 사유(잔액·한도·그물)는
        // 주인을 찾았다는 뜻이므로 여기서 멈춘다.
        final wrongOwner = lo.contains('api 401') ||
            lo.contains('api 403') ||
            lo.contains('api 400') ||
            lo.contains('api key not valid') ||
            lo.contains('invalid api key') ||
            lo.contains('incorrect api key');
        if (wrongOwner && i < order.length - 1) continue;
        // 짚이는 회사가 있었는데 딴 사유로 막힌 경우 — 그 회사로 확정하고
        // 예비 사다리로 넘어간다.
        if (!mounted) return;
        s.aiProvider = p;
        if (s.aiModel.isEmpty || !modelMatchesProvider(s.aiModel, p)) {
          s.aiModel = defaultLadder(p).first;
        }
        await store.persistSettings();
        if (!mounted) return;
        setState(() {
          _aiChecking = false;
          _aiMsg = L10n.of(context).aiListFailed(lastErr);
        });
        return;
      }

      // 받아 줬다 = 이 키의 주인이다.
      s.aiProvider = p;
      s.aiModels = ids;
      s.aiModel = pickCheapest(p, ids) ?? defaultLadder(p).first;
      await store.persistSettings();
      if (!mounted) return;
      final found =
          L10n.of(context).aiModelsFound(filterChatModels(p, ids).length);
      // 목록을 받았다는 것과 쓸 수 있다는 것은 다르다. 진짜로 한 번 불러 본다.
      setState(() => _aiMsg = '$found\n${L10n.of(context).aiPinging}');
      try {
        await aiPing(provider: p, model: s.aiModel, key: key);
        if (!mounted) return;
        setState(() {
          _aiChecking = false;
          _aiMsg = '$found\n${L10n.of(context).aiPingOk}';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _aiChecking = false;
          _aiMsg = '$found\n${L10n.of(context).aiPingFailed('$e')}';
        });
      }
      return;
    }

    // 네 곳 모두 아니라고 했다.
    if (!mounted) return;
    s.aiProvider = '';
    s.aiModels = [];
    await store.persistSettings();
    setState(() {
      _aiChecking = false;
      _aiMsg = L10n.of(context).aiKeyUnknownFormat;
    });
  }


  /// 글자 크기 — 쓰던 앱과 눈으로 맞출 수 있게 견본을 같이 보여 준다.
  /// 숫자를 코드에 박아 두면 맞출 때마다 설치 왕복이 생긴다(2026-08-14).
  /// 견본 문장은 소유자 지정: 자국어와 영어가 섞인 세 줄짜리 문장이다.
  /// 한쪽 글자만 보고 맞추면 다른 쪽이 어긋나기 때문이다.
  /// 종이 고르개.
  ///
  /// 자유 색상 고르개를 주지 않는 이유는 core/paper.dart 머리말에 적어
  /// 뒀다 — 짧게는, 배경을 마음대로 고르게 하면 사람은 반드시 글자가
  /// 안 읽히는 조합을 만들고 그건 우리가 못 만든 화면으로 보인다.
  ///
  /// 이름만 적지 않고 실제 색과 줄을 그대로 보여 준다. 종이는 글로
  /// 설명할 수 있는 것이 아니다.
  /// 잠금을 켜고 끄는 일.
  ///
  /// 켤 때도 끌 때도 먼저 확인을 받는다.
  ///
  ///  - 켤 때 확인하는 이유: 확인이 안 되는 기기에서 켜 버리면 그 순간부터
  ///    앱이 안 열린다. 켜기 전에 실제로 되는지 봐야 한다.
  ///  - 끌 때 확인하는 이유: 확인을 안 받으면 잠긴 앱을 남이 열었을 때
  ///    설정에서 잠금을 꺼 버릴 수 있다. 그러면 잠금은 장식이다.
  Future<void> _toggleLock(bool want) async {
    final l = L10n.of(context);
    final s = store.settings;
    if (want && !await LockService.instance.available()) {
      if (!mounted) return;
      _toast(context, l.lockUnavailable(lockVendor));
      return;
    }
    final ok = await LockService.instance
        .ask(want ? l.lockReasonOn : l.lockReasonOff);
    if (!ok || !mounted) return;
    setState(() => s.lockOn = want);
    await store.persistSettings();
  }

  Widget _paperBlock(L10n l, AppSettings s) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    String nameOf(String id) => switch (id) {
          'moleskine' => l.paperMoleskine,
          'sepia' => l.paperSepia,
          'manuscript' => l.paperManuscript,
          'frost' => l.paperFrost,
          'plain' => l.paperPlain,
          'kraft' => l.paperKraft,
          'walnut' => l.paperWalnut,
          'sky' => l.paperSky,
          _ => l.paperNone,
        };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.paperTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
          const SizedBox(height: 2),
          Text(l.paperSub,
              style: TextStyle(fontSize: 15, color: context.c.guideInk)),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kPapers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = kPapers[i];
                final on = s.paperMode == p.id;
                final isNone = p.id == kPaperNone;
                return GestureDetector(
                  onTap: () {
                    // 뭔가가 '딸깍' 하고 자리를 잡는 순간이다.
                    HapticFeedback.selectionClick();
                    setState(() => s.paperMode = p.id);
                    store.persistSettings();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isNone
                              ? context.c.panel
                              : Color(p.bgOf(dark)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: on ? context.c.accent : context.c.line,
                            width: on ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isNone
                            ? Icon(Icons.block,
                                size: 20, color: context.c.sub)
                            : Stack(children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _PaperPainter(
                                      ruling: p.ruling,
                                      color: Color(p.ruleOf(dark)),
                                      // 견본은 실제 글자 크기와 상관없이
                                      // 좁게 그린다 — 62×76 안에 결이
                                      // 보여야 한다.
                                      lineHeight: 11,
                                      colWidth: 11,
                                      scroll: 0,
                                      headPad: 0,
                                    ),
                                  ),
                                ),
                                // 글자는 딱 하나만 그린다.
                                //
                                // 2026-08-17 소유자 신고로 고친 자리다. 여기에
                                // Text가 둘 있었다 — CustomPaint의 child로 '가',
                                // 그 위에 '가 T'. 둘 다 Center라 같은 자리에
                                // 정확히 포개져 글자가 뭉갰다.
                                //
                                // 영어 한 낱말로 정한 것도 소유자 지시다. 어느
                                // 언어로 쓰든 이 칩이 보여 줄 것은 '이 바탕에
                                // 이 글자색'이지 글자 그 자체가 아니다.
                                Center(
                                  child: Text('sample',
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                          color: Color(p.inkOf(dark)))),
                                ),
                              ]),
                      ),
                      const SizedBox(height: 5),
                      Text(nameOf(p.id),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w400,
                              color: on ? context.c.accent : context.c.sub)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      // 2026-08-17 소유자 지시 — "버전을 설정페이지 맨 밑에 표시하는데,
      // 설정 페이지 맨 위에 표시해줘. 가운데는 '설정'이라고 나오고, 우측에
      // 버전을 기본 폰트 사이즈로 표시해줘."
      //
      // 판 번호를 확인하려고 설정을 끝까지 굴려 내려가야 했다. 배포가
      // 실제로 닿았는지 보려고 여는 것이 대부분인데, 그걸 보려면 맨
      // 아래까지 가야 하는 것은 순서가 뒤집힌 것이다.
      //
      // SelectableText 그대로 둔다 — 길게 눌러 복사할 수 있어야 한다는
      // 2026-08-14 요청은 자리를 옮겨도 유효하다.
      appBar: AppBar(
        title: Text(l.settingsTitle),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SelectableText(
                appVersionLabel,
                style: TextStyle(fontSize: 15, color: context.c.sub),
              ),
            ),
          ),
        ],
      ),
      // 2026-08-18 소유자 지시 — "설정도 너무 넙대대하다. 본문처럼 한정
      // 폭으로 가운데 정렬로."
      //
      // 넓은 화면에서 설정을 화면 폭만큼 늘리면 왼쪽 이름과 오른쪽 스위치가
      // 한 뼘 넘게 떨어진다. 눈이 그 사이를 건너다니느라 무엇이 무엇의
      // 스위치인지 매번 다시 확인하게 된다 — 표에서 줄이 길어질수록 칸이
      // 헷갈리는 것과 같은 일이다.
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: SplitShell.readWidth(context)),
          child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 2026-08-16 소유자 요청 — 설정 맨 위에 프리미엄(결제) 유도 배너.
          //
          // 2026-08-17 — 첫 판은 완전 무료라 이 배너를 끈다. 가격이 적힌
          // 화면으로 가는 문이 하나라도 열려 있으면 애플이 3.1.1로 본다.
          if (kPaidTierLive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Material(
              color: context.c.infoBg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.workspace_premium, color: context.c.accent, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.premiumPitch,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: context.c.accent)),
                            const SizedBox(height: 3),
                            // 체험 중에는 남은 날을 대신 띄운다. 첫날부터
                            // 보이게 두는 게 핵심이다 — 조용히 끝났다가
                            // 어느 날 갑자기 막히면 사람은 지갑이 아니라
                            // 삭제 버튼을 누른다.
                            Text(
                                trialOn(store.settings.trialDays)
                                    ? l.trialBadge(
                                        trialLeft(store.settings.trialDays))
                                    : l.premiumPitchSub,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    fontWeight: trialOn(store.settings.trialDays)
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: trialOn(store.settings.trialDays)
                                        ? context.c.accent
                                        : context.c.guideInk)),
                          ]),
                    ),
                    Icon(Icons.chevron_right, color: context.c.sub),
                  ]),
                ),
              ),
            ),
          ),
          // 2026-08-14 소유자 요청: 설정 메뉴를 그룹으로 묶는다.
          //
          // 전에는 열여섯 줄이 한 줄로 늘어서 있었고, 성격이 다른 것들이 섞여
          // 있었다 — 글자 크기(화면) 다음에 미리보기(동작), 그 다음에 등폭
          // 글꼴(화면), 그 다음에 출처 제거(정리 규칙) 하는 식이었다.
          // 사용자는 목록을 위에서 아래로 훑으며 "지금 내가 무엇을 고르는
          // 중이지?"를 계속 다시 물어야 했다.
          //
          // 묶는 기준은 사용자가 던지는 질문으로 잡았다.
          //   "이 앱이 어떻게 보이나"        → 보기
          //   "정리를 누르면 무엇이 바뀌나"   → 정리 규칙
          //   "정리를 누르면 어떻게 되나"     → 정리할 때
          // 화면 생김새는 애플 설정 앱의 관습을 그대로 따른다(작은 회색
          // 머리글 + 둥근 흰 카드 + 카드 안 구분선). 독자 설계 금지 원칙.
          // 2026-08-16 — 아이클라우드 상태 한 줄. 켜졌는지 꺼졌는지를
          // 사용자가 알 수 있어야 한다. 애플 기기가 아니면 아예 안 보인다.
          // 2026-08-16 소유자 신고 — "이건 어떻게 설정하라는 건지 모르겠다."
          // 맞는 말이다. '꺼짐'이라고만 쓰고 끝내면 사용자가 할 수 있는 게
          // 없다. 그래서 세 가지를 바꿨다.
          //   ① 원인을 갈랐다(로그인 안 됨 / 앱에서 꺼짐)
          //   ② 줄 전체를 누를 수 있게 하고, 누르면 순서를 글로 보여 준다
          //   ③ 그 안에 [설정 열기]와 [다시 확인]을 넣었다
          // 아이클라우드 항목으로 바로 뛰는 주소는 비공개 API라 심사에서
          // 반려된다 — 그래서 '설정 앱까지'만 열어 주고 나머지는 글로 잡는다.
          if (syncVisible) ...[
            _secHeader(l.syncTitle),
            _card([
              // 2026-08-19 소유자 지시 — "베어는 설정에 '동기화' 부분 따로
              // 2depth 설정 상세히 하던데, 우리는 이보다 더 상세히 해야
              // 하는 거 아닐까?"
              //
              // 맞다. 그리고 까닭이 베어보다 하나 더 있다. 우리는 창고를
              // **고르게** 한다. 애플만 쓰던 때는 켜짐/꺼짐이면 됐지만,
              // 아이클라우드와 구글 드라이브 중에 고르는 순간 사람은
              // "내 노트가 지금 어디에 있나"를 알아야 한다. 그건 한 줄에
              // 안 들어간다.
              //
              // 그래서 여기는 문패만 둔다. 상태 한 줄과 화살표.
              ValueListenableBuilder<SyncState>(
                valueListenable: ICloudSync.instance.state,
                builder: (_, st, __) {
                  final s2 = store.settings;
                  final paused = s2.syncBackend == 'none';
                  final ok = !paused && st == SyncState.ok;
                  final busy = !paused && st == SyncState.running;
                  final say = SyncSay.of(l, st,
                      paused: paused,
                      everSynced: ICloudSync.instance.lastSyncMs.value > 0);
                  final title = say.title;
                  final sub = say.sub;
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => const SyncSettingsScreen()));
                      if (mounted) setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                      child: Row(children: [
                        Icon(
                            paused
                                ? Icons.cloud_off_outlined
                                : ok
                                    ? Icons.cloud_done_outlined
                                    : busy
                                        ? Icons.cloud_sync_outlined
                                        : Icons.cloud_off_outlined,
                            size: 22,
                            color: ok ? context.c.accent : context.c.sub),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: ok
                                          ? context.c.accent
                                          : context.c.guideInk)),
                              if (sub != null) ...[
                                const SizedBox(height: 2),
                                Text(sub,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: context.c.sub)),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: context.c.sub),
                      ]),
                    ),
                  );
                },
              ),
            ]),
          ],
          KeyedSubtree(
              key: _anchors['theme'], child: _secHeader(l.settingsSecView)),
          _card([
            // 2026-08-16 소유자 요청 — 다크 모드 선택(기기 따름/라이트/다크).
            // 2026-08-17 소유자 요청 — "'다크 모드 시간에는 다크 모드로'
            // 등의 옵션도 같이 설정받아야 할 듯."
            //
            // 이건 이미 되고 있었다. '기기 설정 따름'이 그 일을 한다 —
            // 아이폰·안드로이드 모두 해 질 녘에 어두운 모드로 바꾸는 일정을
            // 갖고 있고 우리는 그걸 그대로 따른다. 문제는 그 사실이
            // '기기 설정 따름'이라는 말에서 안 읽혔다는 것이다.
            //
            // 기능을 새로 만드는 것보다, 이미 있는 기능이 있다고 말해 주는
            // 쪽이 먼저다.
            _dropRow(l.themeTitle, l.themeSystemNote, s.themeMode, [
              ('system', l.themeSystem),
              ('light', l.themeLight),
              ('dark', l.themeDark),
            ], (v) => s.themeMode = v),
            _sep(),
            // 2026-08-18 — 설정 두 뎁스, 둘째.
            //
            // 글자 크기와 줄 간격은 미닫이 둘에 견본 상자 하나, 세 조각이다.
            // 오늘 글자 크기를 안 바꿀 사람도 그 세 조각을 지나쳐야 다음
            // 항목에 닿았다.
            //
            // 지금 값을 오른쪽에 적어 둔다 — 들어가 보지 않고도 몇이고
            // 얼마인지 알 수 있으면, 안 들어가도 되는 날이 생긴다. 그게
            // 뎁스를 하나 더 두면서 잃는 것을 되갚는 유일한 방법이다.
            KeyedSubtree(
              key: _anchors['fontsize'],
              child: ListTile(
                leading: Icon(Icons.text_fields, color: context.c.sub),
                title: Text(l.typographyTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      '${s.bodyFontSize.round()}pt · '
                      '${s.bodyLineHeight.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 15, color: context.c.sub)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: context.c.sub),
                ]),
                onTap: () async {
                  await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TypographyScreen()));
                  if (mounted) setState(() {});
                },
              ),
            ),
            _sep(),
            KeyedSubtree(key: _anchors['paper'], child: _paperBlock(l, s)),
          ]),
          if (lockVisible)
            KeyedSubtree(
                key: _anchors['lock'], child: _secHeader(l.lockSectionTitle)),
          if (lockVisible)
            _card([
            // _switchRow를 안 쓴다. 그건 값을 바로 바꾸고 저장하는데,
            // 잠금은 **확인을 받은 뒤에만** 바뀌어야 한다. 확인이 안 되면
            // 스위치가 원래 자리로 돌아와야 하고, 그러려면 값을 우리가
            // 직접 쥐고 있어야 한다.
            SwitchListTile.adaptive(
              title: Text(l.lockTitle,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l.lockSub(lockVendor),
                    style: TextStyle(
                        fontSize: 17, height: 1.35, color: context.c.guideInk)),
              ),
              value: s.lockOn,
              onChanged: (v) => unawaited(_toggleLock(v)),
            ),
            if (s.lockOn) ...[
              _sep(),
              _dropRow<int>(l.lockDelayTitle, null, s.lockGraceSec, [
                (kLockNow, l.lockDelayNow),
                (kLockAfter1m, l.lockDelay1m),
                (kLockAfter5m, l.lockDelay5m),
              ], (v) => s.lockGraceSec = v),
            ],
            _sep(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(l.lockNote,
                  style: TextStyle(fontSize: 15, color: context.c.guideInk)),
            ),
          ]),
          KeyedSubtree(
              key: _anchors['tidy'], child: _secHeader(l.settingsSecTidy)),
          _card([
            // 2026-08-17 소유자 지적 — "세부 정리 규칙은 한 뎁스 더 들어가서
            // 설정할 수 있게. 너무 다 꺼내 놓는 게 마음에 안 든다."
            //
            // 아홉 줄이 첫 화면에 통째로 펼쳐져 있었다. 그중 여덟은 한 번
            // 정하고 다시 안 여는 것들이다. 애플 설정 앱이 하는 방식이
            // 이것이다 — 첫 화면에는 이름만, 세부는 들어가서.
            ListTile(
              leading: Icon(Icons.tune, color: context.c.sub),
              title: Text(l.tidyRulesTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: Text(l.tidyRulesSub,
                  style: TextStyle(fontSize: 14, color: context.c.guideInk)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () async {
                await Navigator.push<void>(context,
                    MaterialPageRoute(builder: (_) => const TidyRulesScreen()));
                if (mounted) setState(() {});
              },
            ),
            // 붙여넣기 물음 안내. 처음 붙여넣을 때 한 번 저절로 뜨지만,
            // 그때 '나중에'를 눌렀거나 다른 기기에서 다시 필요할 수 있으니
            // 늘 찾을 수 있는 자리에도 둔다. 아이폰에서만 뜻이 있다.
            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
              _sep(),
              ListTile(
                leading: Icon(Icons.content_paste_go, color: context.c.sub),
                title: Text(l.pasteTipTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                subtitle: Text(l.pasteTipSub,
                    style: TextStyle(fontSize: 14, color: context.c.guideInk)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => showPasteTip(context),
              ),
            ],
          ]),
          _secHeader(l.settingsSecWhen),
          _card([
            // 미리보기 화면에서 '앞으로 생략'을 켜면 여기로 돌아와 다시 켤 수 있다.
            _switchRow(l.previewTitle2, l.previewSub2, s.previewBeforeApply,
                (v) => s.previewBeforeApply = v),
          ]),
          // 2026-08-16 소유자 요청 — 자동 바꾸기 규칙을 AI 위로 올린다.
          // 정리 규칙 바로 뒤에 붙는 게 맞다. 둘 다 '정리를 누르면 글이
          // 어떻게 바뀌나'에 답하는 항목이고, AI는 그 다음 이야기다.
          // 2026-08-18 소유자 지시 — "'자동 바꾸기 규칙'은 설정에 다
          // 나오게 하지 말고, 한 depth 더 들어가서. 이런 식으로 설정을
          // 1depth에서 다 설정하게 할 수는 없어."
          //
          // 규칙 하나가 입력칸 둘에 체크박스에 지우기 단추까지 네 조각이다.
          // 열 개를 만들면 설정 화면의 절반이 그 표가 된다. **설정 화면은
          // 무엇을 정할 수 있는지 훑어보는 곳이지 정하는 곳이 아니다.**
          // 훑어보는 곳에 정하는 도구가 펼쳐져 있으면 훑어볼 수가 없다.
          //
          // 여기 남는 것은 이름과 개수와 꺾쇠 하나다. 몇 개를 만들어
          // 뒀는지는 여기서 알 수 있고, 손대는 일은 안으로 들어가서 한다.
          KeyedSubtree(
              key: _anchors['rules'], child: _secHeader(l.rulesSectionTitle)),
          _card([
            ListTile(
              leading: Icon(Icons.find_replace, color: context.c.sub),
              title: Text(l.rulesSectionTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: Text(l.rulesSectionDesc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: context.c.guideInk)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (s.customRules.isNotEmpty)
                  Text('${s.customRules.length}',
                      style: TextStyle(fontSize: 16, color: context.c.sub)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.c.sub),
              ]),
              onTap: () async {
                await Navigator.push<void>(context,
                    MaterialPageRoute(builder: (_) => const RulesScreen()));
                if (mounted) setState(() {});
              },
            ),
          ]),
          // 심사 지침 3.1.1 — 아이폰·아이패드에서 키가 없으면 이 구역
          // 전체(키 입력·안내·자동 태그 스위치·모델 고르기)가 없다.
          if (aiUiVisible()) ...[
          KeyedSubtree(
              key: _anchors['ai'], child: _secHeader(l.aiSectionTitle)),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 6),
            child: Text(l.aiSectionDesc,
                style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
          ),
          // 2026-08-16 소유자 요청 — 메모는 동기화되는데 키는 안 된다는 것을
          // 여기서 분명히 말해 준다. 말 안 하면 사용자는 다른 기기에서 키가
          // 비어 있는 것을 '버그'로 읽는다. 실제로는 우리가 일부러 안 보낸다.
          if (syncVisible && !s.aiKeySync)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lock_outline, size: 17, color: context.c.sub),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(l.aiKeyNotSynced,
                      style: TextStyle(
                          fontSize: 15, height: 1.4, color: context.c.sub)),
                ),
              ]),
            ),
          _card([
            // 2026-08-18 소유자 지시 — 글을 고치고 조용해지면 태그를
            // 다시 뽑는다. 남의 API 요금을 쓰는 일이라 끄는 길을 둔다.
            _switchRow(l.autoTagTitle, l.autoTagSub, s.autoTagAi,
                (v) => s.autoTagAi = v),
            // 2026-08-20 소유자 지시 — "api키 동기화 : 최소한 아이클라우드는
            // 하자. 구글 드라이브도 하자."
            //
            // 설명이 창고에 따라 달라진다. 두 길은 성질이 다르기 때문이다 —
            // 애플은 애플도 못 읽고, 구글은 구글이 읽는다. 한 문장으로
            // 덮으면 둘 중 하나는 거짓말이 된다.
            if (syncVisible) ...[
              _sep(),
              _switchRow(
                  l.aiKeySyncTitle,
                  s.syncBackend == 'gdrive'
                      ? l.aiKeySyncSubGdrive
                      : l.aiKeySyncSubApple,
                  s.aiKeySync,
                  (v) => s.aiKeySync = v),
            ],
            _sep(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 키 한 칸이 전부다. 회사도 모델도 키에서 알아낸다.
                  // (소유자: "키 발급 시 모델을 알려주지 않는데?" — 맞는 말이라
                  //  모델 선택을 기본 화면에서 치웠다. 2026-08-16 승인)
                  // 2026-08-17 소유자 지시 — "입력칸에 소제목을 넣지 말고,
                  // 그냥 소제목으로 빼고, 입력칸은 입력칸스럽게 보이게 해줘."
                  //
                  // 그동안 'API 키 (Gemini · Claude · ChatGPT · Grok)'가
                  // 칸 **안**에 힌트로 들어가 있었다. 힌트는 글자를 한 자라도
                  // 치면 사라진다. 즉 이 칸이 무엇을 받는 칸인지 알려 주는
                  // 유일한 글자가, 값을 넣는 순간 없어졌다. 나중에 다시 와서
                  // 보면 점 마흔 개만 있고 이게 무슨 칸인지 알 길이 없다.
                  //
                  // 이름표는 칸 밖에서 늘 보여야 하고, 칸 안에는 **모양의
                  // 본보기**만 있으면 된다. 회사 이름은 이름표로 올리고,
                  // 안에는 키가 어떻게 생겼는지를 둔다.
                  //
                  // 테두리 없는 밑줄 칸도 고쳤다. 밑줄 하나로는 '여기를 눌러
                  // 넣으라'는 신호가 약하다 — 칸처럼 보여야 칸으로 쓴다.
                  Text(l.aiKeyHint,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: s.aiKey,
                          obscureText: true,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            // 나라말이 필요 없는 자리다. 어느 말을 쓰든
                            // 키는 이렇게 생겼다.
                            hintText: 'sk-…  ·  AIza…  ·  sk-ant-…  ·  xai-…',
                            hintStyle:
                                TextStyle(fontSize: 14, color: context.c.sub),
                            filled: true,
                            fillColor: context.c.field,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: context.c.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: context.c.accent, width: 2),
                            ),
                          ),
                          onChanged: (v) {
                            final nv = v.trim();
                            if (nv == s.aiKey) return;
                            s.aiKey = nv;
                            // 키가 바뀌면 앞서 알아낸 것은 **전부 남의
                            // 것이다.** 이걸 안 지워서, 구글 키를 넣은
                            // 화면에 ChatGPT와 gpt-5-nano가 남아 있었다.
                            s.aiProvider = '';
                            s.aiModel = '';
                            s.aiModels = [];
                            _aiMsg = '';
                            store.persistSettings();
                            setState(() {});
                            // 붙여넣었으면 그게 곧 "써 달라"는 뜻이다.
                            // 누를 단추를 하나라도 줄인다.
                            _aiAutoTimer?.cancel();
                            if (nv.length >= 20) {
                              _aiAutoTimer = Timer(
                                  const Duration(milliseconds: 900),
                                  _verifyAiKey);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _aiChecking ? null : _verifyAiKey,
                        child: Text(_aiChecking ? l.aiKeyChecking : l.aiKeyVerify),
                      ),
                    ],
                  ),
                  if (_aiStatusLine(l).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_aiStatusLine(l),
                          style: TextStyle(fontSize: 14, height: 1.3, color: context.c.guideInk)),
                    ),
                  if (_aiMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_aiMsg,
                          style: TextStyle(fontSize: 14, height: 1.3, color: context.c.guideInk)),
                    ),
                  // 회사가 준 줄 밑에 우리 말 처방을 붙인다. 회사 줄을
                  // 지우지 않는 이유: 그건 우리가 지어낼 수 없는 정보이고,
                  // 검색해서 해결하려는 사람에게는 그 원문이 필요하다.
                  if (aiRemedy(l, _aiMsg).isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: context.c.warnBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: context.c.warnInk),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(aiRemedy(l, _aiMsg),
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: context.c.warnInk)),
                            ),
                          ]),
                    ),
                  // 소유자 지적: "어떤 LLM API 키 발급에 가더라도 세부
                  // 모델명을 안내해 주지 않는데 사용자가 어떻게 아냐?"
                  //
                  // 맞다. 그래서 원래 설계가 키 하나로 끝난다 — 회사를
                  // 알아내고, 회사에 물어 목록을 받고, 제일 싼 것을 고른다.
                  // 고급은 **비상구**이지 거쳐야 하는 단계가 아닌데, 그
                  // 사실이 화면에서 안 읽혔다. 한 줄로 적어 둔다.
                  // 고급은 **알아내기가 실패했을 때만** 나온다.
                  //
                  // 2026-08-17 소유자 지시 — "'고급설정' 같은 건 안된다. (…)
                  // 내가 llm 마다 api키 다 들어가봐도 세부 모델이 나오는 게
                  // 없어. 그러니 이걸 설정을 사용자에게 맡길 수는 없다."
                  //
                  // 옳다. 어느 회사도 키 발급 화면에서 모델 이름을 알려 주지
                  // 않는다. 알 수 없는 것을 고르라고 내미는 칸은 도움이 아니라
                  // 벽이다. 게다가 늘 보이면 사람은 그걸 **거쳐야 하는
                  // 단계**로 읽는다 — 비상구를 복도 한가운데 두면 아무도
                  // 그게 비상구인 줄 모른다.
                  //
                  // 그래서 성공한 화면에서는 아예 안 보인다. 우리가 회사를
                  // 못 알아냈을 때만, 그때 처음 나타난다.
                  if (s.aiKey.trim().isNotEmpty &&
                      s.aiProvider.isEmpty &&
                      !_aiChecking) ...[
                    TextButton(
                      onPressed: () => setState(() => _aiAdvOpen = !_aiAdvOpen),
                      child: Text(l.aiAdvancedLabel),
                    ),
                    if (!_aiAdvOpen)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(l.aiAdvancedNote,
                            style:
                                TextStyle(fontSize: 13, color: context.c.sub)),
                      ),
                  ],
                  if (_aiAdvOpen && s.aiProvider.isEmpty) ...[
                    if (_aiPickList().isNotEmpty)
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _aiPickList().contains(s.aiModel) ? s.aiModel : null,
                        hint: Text(s.aiModel, overflow: TextOverflow.ellipsis),
                        items: [
                          for (final m in _aiPickList())
                            DropdownMenuItem(
                                value: m, child: Text(m, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            s.aiModel = v;
                            store.persistSettings();
                            setState(() {});
                          }
                        },
                      ),
                    // 목록에도 사다리에도 없는 신형을 쓸 때의 비상구.
                    TextFormField(
                      // 2026-08-17 — 값이 바뀌어도 칸은 처음 값을 붙들고
                      // 있었다. 그래서 고르개와 이 칸이 서로 다른 모델
                      // 이름을 보여 줬다. 데이터가 아니라 화면이 거짓말을
                      // 한 것이다. 키를 붙여 값이 바뀌면 새로 그리게 한다.
                      key: ValueKey('aiModel:${s.aiModel}'),
                      initialValue: s.aiModel,
                      decoration: InputDecoration(hintText: l.aiManualModelHint, isDense: true),
                      onFieldSubmitted: (v) {
                        if (v.trim().isEmpty) return;
                        s.aiModel = v.trim();
                        store.persistSettings();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ]),
          // 2026-08-17 소유자 지적 — "'파일에서 가져오기' '내보내기' '백업
          // 파일 저장'은 설정 안에 있는 게 아니라 '메뉴'의 항목이어야 한다."
          //
          // 맞다. 이 셋은 **하는 일**이지 **정하는 일**이 아니다. 설정은 한
          // 번 정해 놓고 안 여는 곳이다. 원래 여기 넣었던 것은 넣을 자리가
          // 거기밖에 없어서였고, 목록 화면에 메뉴가 생겼으니 옮길 게 아니라
          // 여기서 빼야 한다.
          //
          // 두 군데에 다 두는 것도 답이 아니다. 같은 일이 두 곳에 있으면
          // 사용자는 둘이 다른 일인가 의심한다.
          //
          // 내보내기가 왜 있어야 하는지에 대한 조사 결론은 그대로다 —
          // "갇힌다"는 인상은 그 자체로 이탈 사유이고, 네이버 메모 종료를
          // 겪은 한국 사용자는 더 그렇다. 그건 기능이 아니라 약속이다.
          // 약속은 그대로 두고 자리만 옮겼다.

          ],
          // 2026-08-16 — 휴지통. 조사에서 "휴지통 없음"이 앱을 미완성으로
          // 느끼게 하는 여섯 원인 중 하나로 나왔다. 애플 메모 30일, 구글 킵
          // 7일이 관습이라 30일을 따랐다(독자 설계 금지).
          // 2026-08-18 소유자 지시로 휴지통을 뺐다 — 목록의 삼선 메뉴에
          // 이미 있다. 한 가지 일로 가는 문이 둘이면 사용자는 둘이 다른
          // 것인가 의심한다. 자주 여는 쪽(목록)에 남긴다.
          _secHeader(l.settingsSecInfo),
          _card([
            // 2026-08-24 소유자 지시 — "다른 앱들처럼 앱공유와
            // 평가해주세요를 설정 하단에 만들어줘."
            //
            // 공유는 웹만 뺀다 — 브라우저의 공유 시트는 기기마다 있고
            // 없고가 갈려서, 안 되는 단추를 보여 주느니 뺀다.
            // 평가는 스토어 등록 페이지가 있는 iOS·iPadOS에서만 보인다.
            // 맥 직배포판과 안드로이드 테스트판에는 아직 리뷰 쓸 곳이
            // 없다 — 문을 열어 줬는데 빈 벽이면 앱이 미완성으로 보인다.
            if (!kIsWeb) ...[
              ListTile(
                leading: Icon(
                    isApplePlatform ? Icons.ios_share : Icons.share_outlined,
                    color: context.c.sub),
                title: Text(l.shareAppTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                onTap: () => unawaited(SharePlus.instance.share(ShareParams(
                    text: l.shareAppMsg +
                        '\n' +
                        shareUrl(
                            isIOS: !kIsWeb &&
                                defaultTargetPlatform ==
                                    TargetPlatform.iOS)))),
              ),
              _sep(),
            ],
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
              ListTile(
                leading: Icon(Icons.star_outline, color: context.c.sub),
                title: Text(l.rateAppTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                onTap: () => unawaited(launchUrl(
                    Uri.parse(appStoreReviewUrl()),
                    mode: LaunchMode.externalApplication)),
              ),
              _sep(),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Text(l.settingsFooter,
                  style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
            ),
            // 버전은 이 화면 맨 위 오른쪽으로 옮겼다(2026-08-17).
            // 같은 것을 두 곳에 두면 한 곳은 반드시 뒤처진다.
          ]),
          // 바로가기(앵커)가 겨냥한 자리를 화면 '맨 위'에 붙이려면 그 아래에
          // 화면 한 장만큼의 여유가 있어야 한다. 없으면 목록 끝에 가까운
          // 항목은 아무리 스크롤해도 중간까지만 올라온다 — 맥처럼 창이 큰
          // 기기에서 특히 그렇다. 맨 아래 항목을 골랐을 때만 티가 나는
          // 빈칸이라 이 정도는 값을 치를 만하다.
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.55),
          ],
        ),
      ),
        ),
      ),
    );
  }

}

/// 글자와 줄 간격 — 설정에서 한 뎁스 들어온 곳.
///
/// 2026-08-18 소유자 지시로 설정 첫 화면에서 내려왔다. 까닭은 부르는
/// 쪽(설정 화면)에 적어 뒀다.
///
/// 등폭 스위치를 여기로 같이 데려왔다. '표와 코드를 등폭으로'는 결국
/// **글자를 어떻게 그릴 것인가**에 대한 답이라, 글자 크기·줄 간격과
/// 한 방에 있는 것이 맞다. 설정 첫 화면에서 저 셋이 따로 앉아 있었던
/// 것은 그냥 만든 차례대로 쌓인 것이었다.
class TypographyScreen extends StatefulWidget {
  const TypographyScreen({super.key});

  @override
  State<TypographyScreen> createState() => _TypographyScreenState();
}

class _TypographyScreenState extends State<TypographyScreen> {
  final store = Store.instance;

  Widget _block(L10n l, AppSettings s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 본문 글꼴 ──
            //
            // 2026-08-27 밤 소유자 지시. 크기와 줄 간격은 있었는데 글꼴이
            // 없었다. 왜 셋뿐인지는 core/body_font.dart 머리말에 있다.
            Text(l.bodyFontTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: kBodyFontSystem,
                      label: Text(l.bodyFontSystem,
                          style: const TextStyle(fontSize: 13))),
                  ButtonSegment(
                      value: kBodyFontNoto,
                      label: Text(l.bodyFontNoto,
                          style: const TextStyle(
                              fontSize: 13, fontFamily: 'NotoSansKR'))),
                  ButtonSegment(
                      value: kBodyFontMono,
                      label: Text(l.bodyFontMono,
                          style: const TextStyle(
                              fontSize: 13, fontFamily: 'D2Coding'))),
                ],
                selected: {s.bodyFont},
                onSelectionChanged: (v) {
                  setState(() => s.bodyFont = v.first);
                  store.persistSettings();
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(l.bodyFontSizeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                ),
                Text('${s.bodyFontSize.round()}',
                    style: TextStyle(fontSize: 15, color: context.c.guideInk)),
              ],
            ),
            Slider.adaptive(
              value: s.bodyFontSize,
              min: MonoTextController.minBodyFontSize,
              max: MonoTextController.maxBodyFontSize,
              divisions: (MonoTextController.maxBodyFontSize -
                      MonoTextController.minBodyFontSize)
                  .round(),
              onChanged: (v) => setState(() => s.bodyFontSize = v),
              onChangeEnd: (_) => store.persistSettings(),
            ),
            // 2026-08-18 소유자 지시 — "'본문 글자 크기'와 더불어서 '본문
            // 줄 간격(행 간격)' 설정도 될까?"
            //
            // 견본은 아래 하나를 같이 쓴다. 둘을 따로 두면 사람이 두 군데를
            // 번갈아 보며 맞춰야 하는데, 글자 크기와 줄 간격은 원래 **같이
            // 보고 정하는 것**이다. 하나를 키우면 다른 하나가 좁아 보인다.
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(l.bodyLineHeightTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 17)),
                ),
                Text(s.bodyLineHeight.toStringAsFixed(1),
                    style: TextStyle(fontSize: 15, color: context.c.guideInk)),
              ],
            ),
            Slider.adaptive(
              value: s.bodyLineHeight,
              min: MonoTextController.minBodyHeight,
              max: MonoTextController.maxBodyHeight,
              // 0.1씩. 그보다 잘게 나누면 손가락으로는 같은 자리이고,
              // 숫자만 흔들려서 고른 값을 다시 못 찾는다.
              divisions: ((MonoTextController.maxBodyHeight -
                          MonoTextController.minBodyHeight) *
                      10)
                  .round(),
              onChanged: (v) => setState(() => s.bodyLineHeight = v),
              onChangeEnd: (_) => store.persistSettings(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.c.codeBg,
                  border: Border.all(color: context.c.codeLine),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(l.bodyFontSizeSample,
                  style: TextStyle(
                      fontSize: s.bodyFontSize,
                      height: s.bodyLineHeight,
                      // 견본은 고른 글꼴 그대로 보여 준다. 견본이 다른
                      // 글꼴이면 견본이 아니다.
                      fontFamily: bodyFontFamily(s.bodyFont,
                          webDefault: kIsWeb ? kWebFontFamily : null))),
            ),
          ],
        ),
      );

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: context.c.panel,
            child: Column(children: children),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.typographyTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: SplitShell.readWidth(context)),
          child: ListView(
            padding: scrollPad(context, top: 14),
            children: [
              _card([_block(l, s)]),
              const SizedBox(height: 14),
              _card([
                SwitchListTile.adaptive(
                  title: Text(l.monoEditorTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 17)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l.monoEditorSub,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: context.c.guideInk)),
                  ),
                  value: s.monoEditor,
                  onChanged: (v) {
                    s.monoEditor = v;
                    store.persistSettings();
                    setState(() {});
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 자동 바꾸기 규칙 — 설정에서 한 뎁스 들어온 곳.
///
/// 2026-08-18. 이 화면이 따로 있는 까닭은 위(설정 화면)에 적어 뒀다.
///
/// 카드 모양을 설정 화면에서 그대로 베껴 왔다. 함수를 같이 쓰게 묶지
/// 않은 이유는 하나다 — 저쪽은 State의 메서드라 context를 몸에 지니고
/// 있고, 여기로 끌어오려면 그 둘을 다 뜯어야 한다. 열 줄짜리 모양 하나
/// 때문에 잘 돌고 있는 화면을 건드리는 것은 남는 장사가 아니다.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final store = Store.instance;

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: context.c.panel,
            child: Column(children: children),
          ),
        ),
      );

  Widget _sep() => Divider(height: 1, indent: 16, color: context.c.line);

  Widget _ruleRow(int i) {
    final l = L10n.of(context);
    final s = store.settings;
    final r = s.customRules[i];

    void setRegex(bool v) {
      s.customRules[i] = CustomRule(find: r.find, replace: r.replace, regex: v);
      store.persistSettings();
      setState(() {});
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: r.find,
              decoration: InputDecoration(hintText: l.findLabel, isDense: true),
              onChanged: (v) {
                s.customRules[i] = CustomRule(find: v, replace: r.replace, regex: r.regex);
                store.persistSettings();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: r.replace,
              decoration: InputDecoration(hintText: l.replaceAction, isDense: true),
              onChanged: (v) {
                s.customRules[i] = CustomRule(find: r.find, replace: v, regex: r.regex);
                store.persistSettings();
              },
            ),
          ),
          // 2026-08-18 소유자 신고 — "ㅁ 체크박스가 앞의 것인지 뒤의
          // 것인지 헷갈린다."
          //
          // 머티리얼의 Checkbox 는 손가락이 닿을 자리를 48×48 로 잡는다.
          // 네모 자체는 18인데 둘레에 보이지 않는 여백이 15씩 붙는 것이다.
          // 그래서 화면에서는 네모가 제 이름표에서 멀찍이 떨어지고, 바로
          // 왼쪽 입력칸에 더 가까워 보인다. **가까움이 곧 소속**이라, 눈은
          // 가까운 쪽의 것으로 읽는다.
          //
          // 여백을 걷어 붙이고(shrinkWrap), 둘을 한 덩어리로 묶어 이름표를
          // 눌러도 켜지게 한다. 손가락 자리는 그대로 넓으면서 눈에는
          // 'ㅁ정규식' 한 덩어리로 보인다 — 줄여서 잃은 것을 이름표가
          // 되돌려 준다.
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setRegex(!r.regex),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: r.regex,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) => setRegex(v ?? false),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(l.regexLabel, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              s.customRules.removeAt(i);
              store.persistSettings();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.rulesSectionTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: SplitShell.readWidth(context)),
          child: ListView(
            padding: scrollPad(context),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(l.rulesSectionDesc,
                    style: TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        color: context.c.guideInk)),
              ),
              _card([
                for (int i = 0; i < s.customRules.length; i++) ...[
                  if (i > 0) _sep(),
                  _ruleRow(i),
                ],
                if (s.customRules.isNotEmpty) _sep(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      s.customRules.add(const CustomRule(find: ''));
                      store.persistSettings();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l.addRule),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 회사에 한 번 물어본다.
///
/// 2026-08-17 — 편집 화면 안에만 있던 것을 밖으로 뺐다. 설정 화면의
/// '키 확인'도 **진짜로 한 번 불러 봐야** 하는데, 안에 있으니 쓸 수가
/// 없었다. 그래서 설정은 목록만 받아 보고 "확인했습니다"라고 말했다.
/// 목록 API는 키가 살아 있기만 하면 누구에게나 답한다 — 잔액이 0이어도,
/// 그 키에 대화 권한이 없어도.
Future<String> aiCallOnce({
  required String provider,
  required String model,
  required String key,
  required String sys,
  required String instruction,
  required String body,
}) async {
    final user = '[지시]\n$instruction\n\n[본문]\n$body';
    if (provider == 'google') {
      final res = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeComponent(key)}'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {'parts': [{'text': sys}]},
          'contents': [{'role': 'user', 'parts': [{'text': user}]}],
        }),
      );
      if (res.statusCode != 200) throw Exception(_apiErr(res.statusCode, res.bodyBytes));
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final cands = (j['candidates'] ?? []) as List;
      if (cands.isEmpty) return '';
      final parts = ((cands[0]['content'] ?? {})['parts'] ?? []) as List;
      return parts.map((p) => (p['text'] ?? '') as String).join();
    }
    if (provider == 'anthropic') {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'content-type': 'application/json',
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 8000,
          'system': sys,
          'messages': [{'role': 'user', 'content': user}],
        }),
      );
      if (res.statusCode != 200) throw Exception(_apiErr(res.statusCode, res.bodyBytes));
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = (j['content'] ?? []) as List;
      return content.isEmpty ? '' : ((content[0]['text'] ?? '') as String);
    }
    // OpenAI(ChatGPT)와 xAI(Grok)는 동일한 chat/completions 형식
    final base = provider == 'xai' ? 'https://api.x.ai' : 'https://api.openai.com';
    final res = await http.post(
      Uri.parse('$base/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${key}',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': sys},
          {'role': 'user', 'content': user},
        ],
      }),
    );
    if (res.statusCode != 200) throw Exception(_apiErr(res.statusCode, res.bodyBytes));
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = (j['choices'] ?? []) as List;
    return choices.isEmpty ? '' : (((choices[0]['message'] ?? {})['content'] ?? '') as String);
  }

/// 키가 **진짜로 쓸 수 있는지** 한 번 불러 본다.
///
/// 글자 몇 개짜리 호출이라 값은 거의 안 든다. 이걸 안 하면 "목록은 받았는데
/// 편집은 안 되는" 상태를 사용자가 편집을 눌러 보고서야 알게 된다.
/// 초록불을 보고 갔는데 길이 막혀 있는 것은 안 알려 주는 것보다 나쁘다.
Future<void> aiPing({
  required String provider,
  required String model,
  required String key,
}) async {
  await aiCallOnce(
    provider: provider,
    model: model,
    key: key,
    sys: 'Reply with the single word: OK',
    instruction: 'OK',
    body: 'OK',
  );
}

/// 오류 본문에서 사람이 읽을 한 줄을 뽑는다.
///
/// 전에는 'API 400'만 던져서 무엇이 문제인지(키가 틀렸는지, 모델이 없는지,
/// 잔액이 없는지) 알 수 없었다. 회사가 준 문장을 그대로 보여 주는 것이
/// 우리가 지어낸 어떤 안내문보다 낫다.
///
/// 2026-08-17 — aiCallOnce를 클래스 밖으로 빼면서 이것도 같이 나왔다.
/// **둘은 한 덩이다.** 부르는 코드와 그 답을 읽는 코드는 언제나 같이
/// 움직인다.
/// 회사가 준 오류 한 줄을 **무엇을 해야 하는지**로 옮긴다.
///
/// 2026-08-17 소유자 신고 — "api키 잘 넣었는데도 api호출 실패로 나온다."
///
/// 화면에 찍혀 있던 것은 이랬다.
///
///   Exception: API 429: You have no credits remaining. Add credits to
///   continue using the API at https://platform.openai.com/settings/...
///
/// 이 줄은 **거짓이 아니다.** 키도 멀쩡했고(모델 69개를 받아 왔다) 앱도
/// 제 할 일을 했다. 회사가 "잔액이 없다"고 답한 것을 그대로 옮겼을 뿐이다.
///
/// 그런데 사용자에게는 이게 '앱이 안 되는 것'으로 읽힌다. 영어고, 앞에
/// Exception이 붙어 있고, 무엇보다 **다음에 뭘 해야 하는지가 없다.** 원인을
/// 정확히 말하는 것과 길을 알려 주는 것은 다른 일이다.
///
/// 그래서 회사 문장은 그대로 두고(그건 우리가 지어낼 수 없는 정보다) 그
/// 아래에 우리 말로 처방을 한 줄 붙인다. 짚이는 데가 없으면 빈 문자열을
/// 돌려주고 아무것도 안 붙인다 — 모르면서 아는 척하는 안내가 제일 나쁘다.
String aiRemedy(L10n l, String raw) {
  final s = raw.toLowerCase();
  // 잔액을 먼저 본다. 잔액 없음도 429로 오기 때문에 순서를 바꾸면
  // '잠시 뒤에 다시'라는 엉뚱한 처방이 나간다 — 기다려도 영영 안 된다.
  if (s.contains('no credits') ||
      s.contains('insufficient_quota') ||
      s.contains('insufficient quota') ||
      s.contains('billing') ||
      s.contains('exceeded your current quota')) {
    return l.aiErrNoCredits;
  }
  if (s.contains('api 401') ||
      s.contains('api 403') ||
      s.contains('invalid api key') ||
      s.contains('unauthorized') ||
      s.contains('api key not valid')) {
    return l.aiErrBadKey;
  }
  if (s.contains('api 429')) return l.aiErrRateLimit;
  if (s.contains('api 404')) return l.aiErrNoModel;
  if (s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('timed out') ||
      s.contains('connection refused')) {
    return l.aiErrNetwork;
  }
  return '';
}

String _apiErr(int code, List<int> bodyBytes) {
  try {
    final j = jsonDecode(utf8.decode(bodyBytes));
    final e = j is Map ? j['error'] : null;
    final m = (e is Map ? e['message'] : e)?.toString() ?? '';
    if (m.isNotEmpty) {
      return 'API $code: ${m.length > 140 ? m.substring(0, 140) : m}';
    }
  } catch (_) {}
  return 'API $code';
}
