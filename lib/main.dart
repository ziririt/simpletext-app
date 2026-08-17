/// 심플텍스트 (SimpleText) — Flutter MVP
/// AI 답변을 붙여넣으면, 바로 쓸 수 있는 글이 됩니다.
///
/// 2026-08-12 i18n: UI 문자열은 전부 lib/l10n/으로 분리했다 (한/영/일/중간·번체/스/포/독/프).
/// 엔진(tidy_engine)·마법사(wizard)가 만드는 리포트 문구는 JS 엔진과의 대칭 규칙 때문에
/// 이번 범위에서 제외 — 로드맵의 후속 항목이다. 프리셋 이름은 Preset.id를 UI 층에서 매핑한다.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart'
    show CupertinoAlertDialog, CupertinoDialogAction, CupertinoIcons;
// material.dart는 defaultTargetPlatform을 내보내지 않는다(TargetPlatform은 내보낸다).
// 2026-08-14에 이걸 몰라서 analyze가 undefined_identifier로 잡았다.
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_service.dart';
import 'clipboard_source.dart';
import 'core/ai_provider.dart';
import 'core/auto_meta.dart';
import 'core/folders.dart';
import 'core/hangul.dart';
import 'core/listify.dart';
import 'core/lock.dart';
import 'core/mono_controller.dart';
import 'core/mru.dart';
import 'core/paper.dart';
import 'core/source_detect.dart';
import 'core/tag_suggest.dart';
import 'core/tidy_engine.dart';
import 'core/trash.dart';
import 'core/usage_gate.dart';
import 'core/wizard.dart';
import 'export_service.dart';
import 'import_service.dart';
import 'lock_service.dart';
import 'mac_menu.dart';
import 'share_intake.dart';
import 'icloud_sync.dart';
import 'l10n/l10n.dart';
import 'version.dart';

void main() {
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
  // 광고 시동(모바일에서만 동작 — 맥·윈도우에서는 아무것도 안 한다).
  AdsService.instance.boot();
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
const _accent = Color(0xFF0070BE);

/// 하늘색 위에 얹는 글자·아이콘 색(다크). 브랜드 '딥'이다.
///
/// 다크에서 채운 버튼은 **밝은 하늘 바탕에 진한 글자**여야 맑아 보인다.
/// 어두운 바탕에 밝은 글자로 만들면 아무리 색을 골라도 가라앉는다 —
/// 소유자가 신고한 그림이 정확히 그것이었다.
/// 명암비 #08205A on #4FC3F7 = 7.7:1
const _onAccentDark = Color(0xFF08205A);
// 밝은 하늘색은 큰 글자엔 흐려서 시드(파생 색 뿌리)로만 쓴다.
const _sky = Color(0xFF3FB2F0);

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
    sub: Color(0xFF7C8A96), // 회색도 하늘 쪽으로 살짝 (바탕 대비 3.2:1)
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
    guideInk: Color(0xFF34404A), // 진한 회색도 하늘 쪽으로 (on 흰 배경 11.4:1)
    // 2026-08-16 브랜드 하늘색으로 통일. 계산값:
    //   선택 블럭 #3FB2F0 40%+흰 배경 = #B2E0F9 → 검정 글자 14.9:1
    //   손잡이 #0070BE on 흰 배경 5.2:1 (조작점 기준 3:1)
    //   태그 글자 #0070BE on #E1F4FF 4.7:1
    selBg: Color(0x663FB2F0),
    selHandle: _accent,
    glass: Color(0xCCFFFFFF),
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
    sub: Color(0xFF919CA6),
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
    glass: Color(0xC615191D),
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
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      theme: _theme(Brightness.light, AppC.light),
      darkTheme: _theme(Brightness.dark, AppC.dark),
      // 2026-08-16 소유자 신고 — 맥 앱 글자가 애플 메모장보다 훨씬 크다.
      // 모바일 크기(본문 17 등)를 그대로 데스크톱에 내보내고 있었다.
      // 애플 메모장 맥판 본문은 13~14 상당 — 데스크톱 전체를 0.8배로 줄이면
      // 17이 13.6으로 정확히 그 자리에 떨어진다. 화면마다 값을 따로 두면
      // 반드시 한 군데를 빠뜨리므로 한 곳에서 전역으로 줄인다.
      builder: (ctx, child) {
        Widget w = child!;
        if (isDesktopPlatform) {
          final mq = MediaQuery.of(ctx);
          w = MediaQuery(
            data: mq.copyWith(textScaler: const TextScaler.linear(0.8)),
            child: w,
          );
        }
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

  static ThemeData _theme(Brightness b, AppC c) {
    final isDark = b == Brightness.dark;
    // 하늘색 위에 얹는 글자 색.
    //
    // 라이트에서는 진한 하늘 바탕에 흰 글자(5.2:1), 다크에서는 밝은 하늘
    // 바탕에 진한 남색 글자(7.7:1)다. 다크에서 뒤집는 것이 핵심이다 —
    // 어두운 바탕에 밝은 글자로 버튼을 만들면 아무리 색을 골라도 가라앉는다.
    final onAccent = isDark ? _onAccentDark : Colors.white;

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
      primary: c.accent,
      onPrimary: onAccent,
      primaryContainer: c.tagBg,
      onPrimaryContainer: c.tagInk,
      secondary: c.accent,
      onSecondary: onAccent,
      secondaryContainer: c.tagBg,
      onSecondaryContainer: c.tagInk,
      // 떠 있는 판에 머티리얼이 섞어 넣는 물빛. 이걸 하늘색으로 두면
      // 카드가 미묘하게 하늘 기운을 띤다 — 색을 더 쓰되 시끄럽지 않게.
      surfaceTint: c.accent,
      error: c.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.accent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      // 떠 있는 둥근 버튼. 기본값은 primaryContainer(연한 판)라서
      // 다크에서 '칙칙한 남색 판에 옅은 글자'가 됐다 — 신고된 그림이다.
      // 채운 하늘색으로 못 박는다.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: onAccent,
        elevation: 3,
      ),
      // 돌아가는 표시, 스위치, 슬라이더가 전부 primary를 따라간다.
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      // 체크 표시도 하늘색으로. 기본값은 자동 색표라 또 가라앉는다.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? c.accent : null),
        checkColor: WidgetStateProperty.all(onAccent),
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
      textTheme: base.textTheme.apply(fontFamilyFallback: _hangulFallback),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamilyFallback: _hangulFallback),
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

  /// 각 이전 판을 남긴 시각. history와 같은 자리끼리 짝이다.
  ///
  /// 2026-08-16 — 예전 저장본에는 이 칸이 없다. 없으면 빈 목록이고, 그때는
  /// 화면에 시각 대신 '이전 판 n'이라고 쓴다. 짝이 안 맞아도 죽지 않는다.
  List<int> historyAt;

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
    this.lastReport = '',
    this.pastedAt = 0,
    this.sourceAuto = false,
    this.titleAuto = true,
    this.tagsAuto = true,
    this.folder = '',
  })  : tags = tags ?? [],
        history = history ?? [],
        historyAt = historyAt ?? [];

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

  Map<String, dynamic> toJson() => {
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
        'lastReport': lastReport,
        'pastedAt': pastedAt,
        'sourceAuto': sourceAuto,
        'titleAuto': titleAuto,
        'tagsAuto': tagsAuto,
        'folder': folder,
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
  static const int settingsRev = 2;

  // 2026-08-14 소유자 신고 — **굵게**가 '굵게'로 바뀌어 나온다.
  // 따옴표가 필요 없는 자리에까지 따옴표가 붙어서 붙여넣기 뒤에 손이 간다.
  // 소유자 지시: "**를 모두 삭제처리해줘. 외따옴표 처리하지 말고.
  // 기본 정리 규칙에도 넣어줘."
  //
  // 엔진(TidyOptions)의 기본값은 원래부터 'remove'였다. 따옴표는 여기,
  // 앱 설정의 기본값이 'quoteSingle'이라서 붙던 것이다(effOpts가 엔진
  // 기본값을 덮어쓴다). 그래서 고칠 자리는 엔진이 아니라 여기다.
  String emphStyle = 'remove';
  String hrMode = 'keep';
  String headingMode = 'strip';
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
  String aiKey = '';
  // 2026-08-16 소유자 승인 — 모델은 키에서 자동으로 정한다.
  // 키 앞글자로 회사를 판정하고, 그 회사의 모델 목록을 받아 와서 제일 싼
  // 등급의 최신을 고른다. 버전 번호를 코드에 박으면 그 모델이 폐지되는
  // 날 앱이 죽는다. 등급 이름(flash-lite·haiku·nano·fast)은 안 바뀐다.
  // 판정·선별 규칙과 예비 사다리는 core/ai_provider.dart (테스트로 고정).
  String aiProvider = ''; // google | anthropic | openai | xai | ''(미판정)
  String aiModel = 'gemini-2.5-flash-lite';
  List<String> aiModels = []; // '키 확인' 때 받아 온 실제 모델 목록

  /// 프리미엄 구매 여부. 실제 결제(StoreKit/Play)는 스토어 제출 작업에서
  /// 붙는다 — 그때 이 값을 영수증으로 채운다. 지금은 항상 false.
  bool premium = false;

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

  // 2026-08-16 — 정렬과 필터. 조사해 보니 "정렬 옵션이 없다"는 것이 앱을
  // 미완성으로 느끼게 만드는 대표 원인 중 하나였다. 있으면 아무도 눈치
  // 못 채고, 없으면 리뷰에 남는 종류다.
  //
  // 규칙과 달리 이건 기기마다 다른 게 자연스러워서 동기화하지 않는다
  // (맥에서는 제목순, 폰에서는 최근순으로 보고 싶을 수 있다).
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
  /// 기기마다 다른 게 자연스러워서(맥은 큰 화면이라 모눈, 폰은 몰스킨처럼)
  /// 정렬·필터와 같이 동기화하지 않는다.
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
        'aiKey': aiKey,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'aiModels': aiModels,
        'adFreeDate': adFreeDate,
        'themeMode': themeMode,
        'paperMode': paperMode,
        'lockOn': lockOn,
        'lockGraceSec': lockGraceSec,
        'premium': premium,
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
    s.hrMode = (j['hrMode'] ?? s.hrMode) as String;
    s.headingMode = (j['headingMode'] ?? s.headingMode) as String;
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
    s.aiKey = (j['aiKey'] ?? s.aiKey) as String;
    s.aiProvider = (j['aiProvider'] ?? s.aiProvider) as String;
    s.aiModel = (j['aiModel'] ?? s.aiModel) as String;
    s.aiModels = List<String>.from((j['aiModels'] ?? const []) as List);
    s.adFreeDate = (j['adFreeDate'] ?? s.adFreeDate) as String;
    s.themeMode = (j['themeMode'] ?? s.themeMode) as String;
    s.premium = (j['premium'] ?? s.premium) as bool;
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
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
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
    persist();
  }

  void emptyTrash() {
    trash.clear();
    persist();
  }

  /// 프리셋 + 사용자 설정 병합 (웹의 effOpts와 동일 규칙)
  TidyOptions effOpts(Preset p) {
    final s = settings;
    final o = p.opts.copyWith();
    if (o.stripEmphasis) o.emphStyle = s.emphStyle;
    if (o.removeHr) o.hrMode = s.hrMode;
    if (o.stripHeadings) {
      o.headingMode = s.headingMode;
      o.headingSymbol = s.headingSymbol;
    }
    if (o.bulletsToDot) o.bulletChar = s.bulletChar;
    if (o.smartDashList) o.smartDashList = s.smartDashList;
    if (o.smartFillerHeading) o.smartFillerHeading = s.smartFillerHeading;
    if (o.stripEmphasis) o.customRules = s.customRules.where((r) => r.find.isNotEmpty).toList();
    if (o.stripHeadings || o.smartFillerHeading) {
      o.headingPad = s.headingPad;
      o.headingPadAbove = s.headingPadAbove;
      o.headingPadBelow = s.headingPadBelow;
    }
    if (o.bulletsToDot) o.bulletIndent = s.bulletIndent;
    if (o.removeCitations) o.removeCitations = s.removeCitations;
    return o;
  }

  /// 시드 메모 — 위젯 트리 밖이라 L10n.system()으로 시스템 로케일을 따른다
  static Note _seedNote() {
    final l = L10n.system();
    final now = DateTime.now().millisecondsSinceEpoch;
    return Note(
      id: 'seed-$now',
      title: l.seedTitle,
      body: l.seedBody,
      originalBody: l.seedBody,
      pinned: true,
      tags: [l.seedTag],
      createdAt: now,
      updatedAt: now,
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
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
class Glass extends StatelessWidget {
  final Widget child;
  final bool hairlineTop;
  final bool hairlineBottom;
  final BorderRadius? radius;
  const Glass({
    super.key,
    required this.child,
    this.hairlineTop = false,
    this.hairlineBottom = false,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: c.glass,
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
      ),
    );
  }
}

/// 메모를 연다 — 화면이 넓으면 오른쪽 칸에, 좁으면 새 화면으로 민다.
///
/// 메모를 여는 자리가 앱 안에 네 군데 있다. 규칙을 이 함수 하나에 모으지
/// 않았다면 넓은 화면을 지원하면서 그중 하나는 반드시 빠뜨렸을 것이다.
Future<void> openNote(BuildContext context, String id,
    {bool autoTidy = false}) async {
  final shell = SplitShell.of(context);
  if (shell != null && shell.isWide) {
    shell.open(id, autoTidy: autoTidy);
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => EditorScreen(noteId: id, autoTidy: autoTidy)),
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

  /// 목록 칸의 폭. 애플 메모·메일과 비슷한 값이다.
  static const double kListWidth = 320;

  static SplitShellState? of(BuildContext c) =>
      c.findAncestorStateOfType<SplitShellState>();

  @override
  State<SplitShell> createState() => SplitShellState();
}

class SplitShellState extends State<SplitShell> {
  String? _openId;
  bool _autoTidy = false;

  /// 지금 오른쪽 칸에 열려 있는 메모. 목록이 그것을 표시하려고 본다.
  String? get openId => _openId;

  bool get isWide => MediaQuery.sizeOf(context).width >= SplitShell.kWideAt;

  void open(String id, {bool autoTidy = false}) {
    setState(() {
      _openId = id;
      _autoTidy = autoTidy;
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
              const SizedBox(
                  width: SplitShell.kListWidth,
                  child: HomeScreen(embedded: true)),
              VerticalDivider(width: 1, thickness: 1, color: c.line),
              Expanded(
                child: !alive
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            L10n.of(context).splitEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, height: 1.5, color: c.sub),
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
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
                          embedded: true,
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

class _HomeScreenState extends State<HomeScreen> {
  final store = Store.instance;
  String query = '';

  /// 앱이 다시 앞으로 나올 때 아이클라우드를 한 번 훑기 위한 것.
  /// 다른 기기에서 고친 메모는 대개 이 순간에 들어온다.
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
    _life = AppLifecycleListener(onResume: ICloudSync.instance.onResume);
    // 아이클라우드는 메모를 다 읽은 **뒤에** 켠다. 먼저 켜면 아직 비어 있는
    // 목록을 "이 기기에는 메모가 없다"로 읽고, 그 상태로 남의 기기 것과
    // 합친 결과를 기기에 되쓴다 — 메모가 통째로 날아가는 길이다.
    store.load().then((_) => ICloudSync.instance.boot());
    // 다른 앱에서 보낸 글 받기(2026-08-17). 목록 화면이 살아 있는 동안
    // 계속 듣는다.
    _wireShare();
    // 맥 상단의 '파일' 메뉴. 첫 프레임 뒤에 단다 — 그때라야 L10n이 있다.
    if (MacMenu.supported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _installMacMenu());
    }
  }

  @override
  void dispose() {
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
            case 'trash':
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()));
              if (mounted) setState(() {});
          }
        },
        itemBuilder: (ctx) {
          PopupMenuItem<String> row(String v, IconData ic, String label) =>
              PopupMenuItem<String>(
                value: v,
                child: Row(children: [
                  Icon(ic, size: 19, color: ctx.c.sub),
                  const SizedBox(width: 10),
                  Text(label),
                ]),
              );
          return [
            // --- 이 화면에서 하는 일 (앞으로 여기에 더 붙는다) ---
            row('import', Icons.file_open_outlined, l.importFiles),
            row('exportMd', Icons.folder_zip_outlined, l.exportAllMd),
            row('backup', Icons.settings_backup_restore, l.exportBackup),
            const PopupMenuDivider(),
            // 2026-08-17 소유자 지시 — '앱 설정'을 메뉴에서 뺐다.
            //
            // 설정은 메뉴 안에 있을 이유가 없다. 메뉴 안의 것들은 가끔 하는
            // 일이고 설정은 자주 여는 곳이다. 한 번 더 눌러야 열리는 것은
            // 그만한 이유가 있을 때만 그렇게 둔다. 이제 위 줄 오른쪽 끝에
            // 톱니바퀴로 나와 있다.
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
    final fromUrl = sourceFromUrl(await ClipboardSource.read());
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
    final guess = known.isKnown ? known : guessSource(text);
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
      return hangulContains(
          '${n.title} ${n.body} ${n.tags.join(' ')} ${n.source}', q);
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

    return Scaffold(
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          // 2026-08-16 소유자 요청: 큰 '메모' 타이틀을 없애고 검색을 설정
          // 톱니 왼쪽으로. 그 위 최상단은 배너 자리다(광고 없는 날은 0px).
          : SafeArea(
              bottom: false,
              child: Column(children: [
                if (!widget.embedded) const TopBannerBar(),
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: CustomScrollView(
              slivers: [
                // 유리 머리 높이만큼 비워서 목록이 그 밑으로 흘러 들어간다.
                const SliverToBoxAdapter(child: SizedBox(height: kHomeHeaderH)),
                // 폴더 줄. 폴더가 하나도 없으면 아예 안 보인다 —
                // 쓰지도 않는 줄이 자리를 먹으면 그게 더 나쁘다.
                if (folderNames(store.notes.map((n) => n.folder), s.folders)
                    .isNotEmpty)
                  _folderBar(l, s),
                if (pinned.isEmpty && rest.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l.emptyList, textAlign: TextAlign.center)),
                  ),
                if (pinned.isNotEmpty) _groupLabel(l.pinnedLabel),
                // 고정 목록도 같은 규칙이다(2026-08-17 소유자 지시).
                // 고정을 스무 개씩 해 두는 사람에게는 고정 목록이 곧
                // '그 사람의 목록'이라, 거기를 안 지나면 아무 데도 안 지난다.
                if (pinned.length >= 10) ...[
                  _groupCard(pinned.take(5).toList()),
                  const SliverToBoxAdapter(child: InlineAdBlock(gapAbove: 20)),
                  _groupCard(pinned.skip(5).toList()),
                ] else if (pinned.isNotEmpty)
                  _groupCard(pinned),
                if (rest.isNotEmpty)
                  _groupLabel(l.notesLabel, trailing: _sortFilterBtn(l, s)),
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
                  const SliverToBoxAdapter(child: InlineAdBlock(gapAbove: 20)),
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
                const SliverToBoxAdapter(child: SizedBox(height: 176)),
              ],
                      ),
                    ),
                    // 떠 있는 유리 머리 — 목록이 이 밑으로 비쳐 흐른다.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Glass(
                        hairlineBottom: true,
                        child: SizedBox(
                          height: kHomeHeaderH,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                            child: Row(children: [
                              Expanded(
                                  child: TextField(
                                decoration: InputDecoration(
                                  hintText: l.searchHint,
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: context.c.field,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none),
                                ),
                                onChanged: (v) => setState(() => query = v),
                              )),
                              // 2026-08-17 소유자 지시 — 자리를 바꿨다.
                              //
                              // 전에는 [검색] [필터] [메뉴]였는데, 셋 중
                              // 필터만 성격이 다르다. 검색과 필터는 '지금
                              // 보이는 목록을 좁히는 일'이고 메뉴는 '앱에
                              // 대해 하는 일'인데, 필터가 메뉴 옆에 붙어
                              // 있으니 같은 무리로 보였다.
                              //
                              // 필터는 '메모' 소제목 옆으로 내렸다(_groupLabel).
                              // 자기가 다루는 것 바로 위에 놓이면 무엇을
                              // 거르는 단추인지 자리만으로 알 수 있다.
                              //
                              // 이제 [검색] [메뉴] [설정]이다. 왼쪽에서
                              // 오른쪽으로 갈수록 '이 목록'에서 '이 앱'으로
                              // 넓어진다.
                              _listMenu(l),
                              IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: l.menuAppSettings,
                                onPressed: () async {
                                  await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const SettingsScreen()));
                                  if (mounted) setState(() {});
                                },
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2026-08-14 소유자 요청: 아이콘만으로는 무슨 버튼인지 알 수 없어
          // 두 버튼 다 글자를 붙인다.
          FloatingActionButton.extended(
            heroTag: 'new',
            tooltip: l.newNoteTooltip,
            backgroundColor: context.c.panel,
            foregroundColor: context.c.accent,
            onPressed: () async {
              final note = Note.fresh();
              store.notes.insert(0, note);
              await store.persist();
              if (!mounted) return;
              openNote(context, note.id);
            },
            icon: const Icon(Icons.add),
            label: Text(l.newNoteTooltip, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'paste',
            onPressed: _pasteAndTidy,
            icon: const Icon(Icons.content_paste_go),
            label: Text(l.pasteAndTidy, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// 목록의 소제목. [trailing]을 주면 오른쪽 끝에 단추가 붙는다.
  ///
  /// 2026-08-17 소유자 지시로 정렬·필터가 '메모' 소제목 옆에 붙었다.
  /// 자기가 다루는 것 바로 위에 놓이면 무엇을 거르는 단추인지 자리만으로
  /// 알 수 있다.
  Widget _groupLabel(String label, {Widget? trailing}) => SliverToBoxAdapter(
        child: Padding(
          // 애플 메모의 '고정된 메모' 헤더 실측: 글자높이 52px, 좌측 135px(45pt).
          // 제목 46px=17pt 비율로 환산하면 19.2pt → 애플 .title3(20pt) 굵게.
          // 색도 회색이 아니라 본문색이다.
          //
          // 단추가 붙는 쪽은 위아래 여백을 줄인다. 단추가 이미 자기 여백을
          // 가지고 있어서 그대로 두면 그 줄만 뚱뚱해 보인다.
          padding: EdgeInsets.fromLTRB(
              kListRowInset + 16, trailing == null ? 18 : 10, 8,
              trailing == null ? 8 : 0),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
                color: on ? context.c.accent : context.c.field,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF08205A)
                              : Colors.white)
                          : context.c.sub)),
            ),
          ),
        );
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
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
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const SortFilterSheet(),
          );
          if (mounted) setState(() {});
        },
      );

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
    final preview = n.body.trim();
    final title = n.title.trim().isNotEmpty
        ? n.title.trim()
        : (preview.split('\n').firstWhere((x) => x.trim().isNotEmpty,
            orElse: () => l.untitled));

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
                              preview.isEmpty ? l.bodyHint : preview,
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
                      row(Icons.ios_share, l.exportNote,
                          () => Navigator.pop(ctx, 'share')),
                      Divider(height: 1, color: c.line),
                      row(Icons.folder_outlined, l.folderTitle,
                          () => Navigator.pop(ctx, 'folder')),
                      Divider(height: 1, color: c.line),
                      row(n.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                          n.pinned ? l.unpinTooltip : l.pinTooltip,
                          () => Navigator.pop(ctx, 'pin')),
                      Divider(height: 1, color: c.line),
                      row(Icons.copy_all_outlined, l.noteDuplicate,
                          () => Navigator.pop(ctx, 'dup')),
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
      case 'share':
        final ok = await ExportService.shareNote(n);
        if (!ok && mounted) _toast(context, L10n.of(context).exportFailed);
      case 'folder':
        await _moveToFolder(n);
      case 'pin':
        n.pinned = !n.pinned;
        await store.persist();
        if (mounted) setState(() {});
      case 'dup':
        final copy = Note.fresh(body: n.body)
          ..title = n.title
          ..tags = List<String>.from(n.tags)
          ..source = n.source
          ..sourceAuto = n.sourceAuto
          ..titleAuto = n.titleAuto
          ..tagsAuto = n.tagsAuto
          ..folder = n.folder
          // 붙여넣은 시각은 원본의 것을 그대로 물려준다. 그 시각의 뜻은
          // '이 답을 받은 때'라서 복제한 날로 바뀌면 거짓이 된다.
          ..pastedAt = n.pastedAt;
        store.notes.insert(0, copy);
        await store.persist();
        if (!mounted) return;
        setState(() {});
        _toast(context, L10n.of(context).noteDuplicated);
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
    final firstLine = n.body.split('\n').firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');

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
          n.pinned = !n.pinned;
          await store.persist();
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
        color: selected
            ? Color.alphaBlend(c.accent.withValues(alpha: 0.16), c.panel)
            : c.panel,
        child: InkWell(
          onTap: () => openNote(context, n.id),
          // 2026-08-17 소유자 요청 — "애플 메모장처럼 메모 리스트에서 메모
          // 하나를 오래 롱 프레스 누르면 메모의 일부를 보여주고, 할 수 있는
          // 기능들을 할 수 있게 해줘."
          onLongPress: () {
            // 손끝에 한 번 걸리는 느낌. 길게 누른 것이 먹혔다는 신호를
            // 화면보다 먼저 준다.
            HapticFeedback.mediumImpact();
            _peek(n);
          },
          hoverColor: hover,
          focusColor: hover,
          highlightColor: press,
          splashColor: splash,
          child: Padding(
            // 데스크톱은 애플 메모장처럼 행을 촘촘하게(글자만 줄면 행이 뚱뚱해 보인다).
          padding: EdgeInsets.fromLTRB(
              kListRowInset, isDesktopPlatform ? 5 : 10, 16, isDesktopPlatform ? 5 : 10),
            child: Row(
              children: [
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
                            fontSize: 17, fontWeight: FontWeight.w600, height: 1.25),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(_listDate(l, n.updatedAt),
                              style: TextStyle(fontSize: 15, height: 1.2, color: context.c.sub)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(firstLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, height: 1.2, color: context.c.sub)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (n.pinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.push_pin, size: 17, color: context.c.pin),
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

  /// 두 칸 화면의 오른쪽에 들어가 있는가. 그렇다면 뒤로가기 화살표를 안
  /// 그린다 — 돌아갈 화면이 없다. 목록이 이미 왼쪽에 있다.
  final bool embedded;

  const EditorScreen({
    super.key,
    required this.noteId,
    this.autoTidy = false,
    this.embedded = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
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
    final g = guessSource(chunk.length >= _pasteMin ? chunk : v);
    if (!g.isKnown) return;

    note.source = g.name;
    note.sourceAuto = !g.certain;
    if (note.pastedAt == 0) {
      note.pastedAt = DateTime.now().millisecondsSinceEpoch;
    }
    _save();
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
    final made = listify(t.substring(a, e),
        kind: kind, bullet: dotBullet(store.settings.bulletChar));
    bodyCtl.value = TextEditingValue(
      text: t.replaceRange(a, e, made),
      // 손댄 곳을 그대로 잡아 둔다. 커서가 엉뚱한 데로 튀면 다음 버튼을
      // 누를 때 다른 줄이 걸린다.
      selection: TextSelection(baseOffset: a, extentOffset: a + made.length),
    );
    HapticFeedback.selectionClick();
    _save();
  }

  void _insertText(String left, [String right = '']) {
    final sel = bodyCtl.selection;
    final text = bodyCtl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final ins = '$left$selected$right';
    bodyCtl.value = bodyCtl.value.copyWith(
      text: text.replaceRange(start, end, ins),
      selection: TextSelection.collapsed(
          offset: right.isEmpty ? start + ins.length : start + left.length + selected.length),
    );
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
  Widget _barBtn(IconData icon, String label, VoidCallback? onTap,
      {bool primary = false, VoidCallback? onLongPress}) {
    final on = onTap != null;
    final color = !on
        ? context.c.sub.withValues(alpha: 0.5)
        : (primary ? context.c.accent : context.c.accent);
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        onLongPress: onLongPress,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          minimumSize: const Size(0, 52),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: color,
                  fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.c.sub,
            ),
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
  void _onSelectionChanged() {
    final sel = bodyCtl.selection;
    if (sel == _lastSel) return;
    final wasCollapsed = _lastSel.isCollapsed;
    _lastSel = sel;
    if (!wasCollapsed || sel.isCollapsed) return;
    final t = bodyCtl.text;
    if (t.isEmpty || sel.start != 0 || sel.end != t.length) return;
    _reshowToolbar();
  }

  Future<void> _reshowToolbar() async {
    // 스크롤이 멎기를 기다린다. 프레임 하나로는 모자랄 때가 있어 조금 준다.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ctx = _bodyKey.currentContext;
    if (ctx == null) return;
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
    final st = found;
    if (st == null) return;
    if (st.textEditingValue.selection.isCollapsed) return;
    // 이미 떠 있으면 false를 돌려주고 아무 일도 안 한다 — 깜빡이지 않는다.
    st.showToolbar();
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

  Widget _accessoryBar({bool atTop = false}) {
    final l = L10n.of(context);
    // 2026-08-16 리퀴드 글래스 — 도구 막대는 이제 유리다.
    return Glass(
      hairlineTop: !atTop,
      hairlineBottom: atTop,
      child: SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                // 2026-08-17 소유자 지시로 다시 한 번 정리했다.
                //
                // 낱글자를 넣던 단추 둘('·' '-')을 없앴다. 이것이 이번 판의
                // 고장을 낳은 자리다 — '·'가 두 뜻으로 쓰이고 있었다.
                // 하나는 '가운뎃점 한 글자 넣기', 다른 하나는 '이 줄들을 점
                // 목록으로 바꾸기'. 겉모습이 같으니 어느 쪽이 눌린 건지
                // 사람이 알 수가 없었고, 소유자는 "'·'는 -와 같은 결과가
                // 나온다"고 신고했다.
                //
                // 이제 '·'와 '-'는 **목록 단추 하나씩**이다. 낱글자는 자판에
                // 이미 있다. 순서는 소유자가 고른 대로 1. → · → -.
                _kbBtn(icon: Icons.undo, tip: l.undoTip, onTap: () => _undoCtl.undo()),
                _kbBtn(icon: Icons.redo, tip: l.redoTip, onTap: () => _undoCtl.redo()),
                Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: context.c.toolbarLine),
                _kbBtn(
                    icon: Icons.horizontal_rule,
                    tip: l.dividerTip,
                    onTap: _insertDivider),
                Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: context.c.toolbarLine),
                // 목록 셋. 글을 쓰다가 목록으로 바꾸는 순간은 자판이 올라와
                // 있는 순간이라 여기가 제자리다. 아래 기능 막대는 글을 다
                // 쓰고 나서 누르는 것들이라 결이 다르다.
                _kbBtn(
                    glyph: '1.',
                    tip: l.listNumberAction,
                    onTap: () => _makeList('number')),
                _kbBtn(
                    glyph: '·',
                    tip: l.listBulletAction,
                    onTap: () => _makeList('bullet')),
                _kbBtn(
                    glyph: '-',
                    tip: l.listDashAction,
                    onTap: () => _makeList('dash')),
                _kbBtn(
                    icon: Icons.format_indent_increase,
                    tip: l.indentTip,
                    onTap: () => _insertText('  ')),
              ],
            ),
          ),
          // 내릴 키보드가 없는 데스크톱에서는 이 버튼이 뜻이 없다.
          if (!atTop) ...[
            Container(width: 1, height: 26, color: context.c.toolbarLine),
            _kbBtn(
              icon: Icons.keyboard_hide_outlined,
              tip: l.hideKeyboardTip,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
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
    // 선택 범위가 바뀌는 것을 지켜본다. 글자가 바뀔 때(onChanged)와는
    // 다른 일이라 컨트롤러에 직접 붙는다.
    bodyCtl.addListener(_onSelectionChanged);
    if (widget.autoTidy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTidyWithPreset(buildPresets().first));
    }
  }

  @override
  void dispose() {
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

  bool _tagAiBusy = false;

  /// 제목과 본문 앞부분에서 태그를 뽑아 넣는다.
  ///
  /// AI 키가 있으면 AI가, 없거나 실패하면 앱이 뽑는다(소유자 확정 2026-08-14).
  /// 앱이 뽑았을 때는 그 사실을 알려 준다 — 어느 쪽이 뽑았는지 모르면
  /// 사용자가 결과 품질을 오해한다.
  Future<void> _autoTags() async {
    final l = L10n.of(context);
    setState(() => _tagAiBusy = true);
    final head = note.body.length > 1200 ? note.body.substring(0, 1200) : note.body;
    var got = <String>[];
    var byAi = false;
    try {
      if (store.settings.aiKey.trim().isNotEmpty) {
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
        byAi = got.isNotEmpty;
      }
    } catch (_) {
      got = const [];
    }
    if (got.isEmpty) got = suggestTags(note.title, head);
    // 사용자가 버튼을 눌러 뽑은 태그는 배경 갱신이 덮으면 안 된다.
    note.tagsAuto = false;
    if (!mounted) return;
    setState(() => _tagAiBusy = false);
    if (got.isEmpty) {
      _toast(context, l.tagAiNone);
      return;
    }
    await _commitTags(got.join(','), clear: false);
    if (mounted && !byAi) _toast(context, l.tagAiLocalNote);
  }

  /// 태그를 다시 뽑기 위한 타이머. 글자마다 뽑으면 낭비다.
  Timer? _tagTimer;

  Future<void> _save() async {
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
    _scheduleAutoTags();
  }

  /// 타이핑이 멈춘 뒤에 한 번만 태그를 다시 뽑는다.
  ///
  /// 제목은 첫 줄만 보면 되니 글자마다 다시 지어도 싸지만, 태그는 글 전체를
  /// 훑는다. 글자마다 하면 긴 메모에서 손이 무거워진다.
  void _scheduleAutoTags() {
    if (!note.tagsAuto) return;
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted || !note.tagsAuto) return;
      final head = note.body.length > 1200 ? note.body.substring(0, 1200) : note.body;
      // 기기 안에서만 뽑는다. 배경에서 AI를 부르면 사용자 요금이 샌다.
      final got = suggestTags(note.title, head, max: 3);
      if (got.isEmpty) return;
      if (got.length == note.tags.length &&
          got.every((t) => note.tags.contains(t))) {
        return; // 바뀐 게 없으면 저장도 화면 갱신도 하지 않는다
      }
      note.tags = got;
      await store.persist();
      if (mounted) setState(() {});
    });
  }

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
    if (!kPaidTierLive) return false;

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
    note.history.add(bodyCtl.text);
    note.historyAt.add(DateTime.now().millisecondsSinceEpoch);
    if (note.history.length > 30) {
      note.history.removeAt(0);
      if (note.historyAt.isNotEmpty) note.historyAt.removeAt(0);
    }
    note.body = target;
    note.lastReport = '';
    bodyCtl.text = target;
    await _save();
    if (!mounted) return;
    setState(() {});
    _toast(context, L10n.of(context).revertedToast);
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
    final r = tidy(note.body, store.effOpts(preset));
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
      note.history.add(note.body);
      note.historyAt.add(DateTime.now().millisecondsSinceEpoch);
      if (note.history.length > 30) {
        note.history.removeAt(0);
        if (note.historyAt.isNotEmpty) note.historyAt.removeAt(0);
      }
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

  void _showPresetSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: buildPresets()
              .map((p) => ListTile(
                    title: Text(L10n.of(ctx).presetName(p.id, p.name),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(L10n.of(ctx).presetDesc(p.id, p.desc),
                        style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _runTidyWithPreset(p);
                    },
                  ))
              .toList(),
        ),
      ),
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
    String? aiResult;
    String aiGuard = '';
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
                    for (final u in unknown)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.unknownPrefix(u),
                            style: TextStyle(color: context.c.warnInk, fontSize: 12.5)),
                      ),
                    if (unknown.isNotEmpty && store.settings.aiKey.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(l.aiKeyPromo,
                            style: TextStyle(fontSize: 12, color: context.c.sub)),
                      ),
                    if (unknown.isNotEmpty && store.settings.aiKey.isNotEmpty && aiResult == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton(
                          onPressed: aiBusy
                              ? null
                              : () async {
                                  setD(() => aiBusy = true);
                                  try {
                                    var out = (await _aiEditCall(unknown.join('. '), bodyCtl.text)).trim();
                                    out = out
                                        .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
                                        .replaceFirst(RegExp(r'\n?```$'), '');
                                    if (out.isEmpty) throw Exception(l.aiEmptyResponse);
                                    setD(() {
                                      aiResult = out;
                                      aiGuard = numberGuard(bodyCtl.text, out);
                                      aiBusy = false;
                                    });
                                  } catch (e) {
                                    setD(() => aiBusy = false);
                                    if (mounted) _toast(context, L10n.of(context).aiCallFailed('$e'));
                                  }
                                },
                          child: Text(aiBusy ? l.aiBusyLabel : l.aiRunUnknown),
                        ),
                      ),
                    if (aiResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: context.c.codeBg,
                            border: Border.all(color: context.c.codeLine),
                            borderRadius: BorderRadius.circular(10)),
                        child: SingleChildScrollView(
                            child: Text(aiResult!, style: const TextStyle(fontSize: 13.5, height: 1.5))),
                      ),
                      if (aiGuard.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(aiGuard,
                              style: TextStyle(color: context.c.warnInk, fontSize: 12.5)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton(
                          onPressed: () async {
                            note.history.add(bodyCtl.text);
                            note.historyAt.add(DateTime.now().millisecondsSinceEpoch);
                            if (note.history.length > 30) {
                              note.history.removeAt(0);
                              if (note.historyAt.isNotEmpty) note.historyAt.removeAt(0);
                            }
                            bodyCtl.text = aiResult!;
                            await _save();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              setState(() {});
                              _toast(context, L10n.of(context).aiAppliedToast);
                            }
                          },
                          child: Text(l.aiApplyResult),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                onPressed: () async {
                  final r = applyWizard(
                      command: cmdCtl.text, settings: store.settings, body: bodyCtl.text);
                  if (r.bodyChanged) {
                    note.history.add(bodyCtl.text);
                    note.historyAt.add(DateTime.now().millisecondsSinceEpoch);
                    if (note.history.length > 30) {
                      note.history.removeAt(0);
                      if (note.historyAt.isNotEmpty) note.historyAt.removeAt(0);
                    }
                    bodyCtl.text = r.body;
                  }
                  await store.persistSettings();
                  await _save();
                  if (mounted) setState(() {});
                  // 다 해석됐으면 창을 닫는다. 창이 그대로 남아 있으면 "적용이 된 건가?"
                  // 하고 헷갈린다(2026-08-14 소유자 지적). 못 알아들은 지시가 있을
                  // 때만 남겨서 무엇이 안 됐는지 보여 준다.
                  if (r.unknown.isEmpty) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      _toast(
                          context,
                          r.applied.isEmpty
                              ? L10n.of(context).wizardNothingToDo
                              : L10n.of(context).wizardAppliedToast(r.applied.length));
                    }
                    return;
                  }
                  setD(() {
                    applied = r.applied;
                    unknown = r.unknown;
                    aiResult = null;
                  });
                },
                child: Text(l.interpretApply),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReplaceDialog() async {
    final findCtl = TextEditingController();
    final withCtl = TextEditingController();
    bool useRegex = false;
    bool saveRule = false;
    await showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final l = L10n.of(ctx);
          return AlertDialog.adaptive(
            title: Text(l.replaceTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: findCtl, decoration: InputDecoration(labelText: l.findLabel)),
                TextField(controller: withCtl, decoration: InputDecoration(labelText: l.replaceWithLabel)),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.regexLabel, style: const TextStyle(fontSize: 14)),
                  value: useRegex,
                  onChanged: (v) => setD(() => useRegex = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.saveAsRule, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(l.saveAsRuleSub, style: const TextStyle(fontSize: 12)),
                  value: saveRule,
                  onChanged: (v) => setD(() => saveRule = v ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              FilledButton(
                onPressed: () async {
                  final find = findCtl.text;
                  if (find.isEmpty) return;
                  final rawRepl = withCtl.text;
                  final repl = rawRepl.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
                  int count = 0;
                  String result = bodyCtl.text;
                  try {
                    if (useRegex) {
                      final re = RegExp(find);
                      count = re.allMatches(bodyCtl.text).length;
                      result = bodyCtl.text.replaceAllMapped(re, (m) {
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
                    if (mounted) _toast(context, L10n.of(context).invalidRegex);
                    return;
                  }
                  Navigator.pop(ctx);
                  if (count == 0) {
                    if (mounted) _toast(context, L10n.of(context).noMatches);
                    return;
                  }
                  note.history.add(bodyCtl.text);
                  note.historyAt.add(DateTime.now().millisecondsSinceEpoch);
                  if (note.history.length > 30) {
                    note.history.removeAt(0);
                    if (note.historyAt.isNotEmpty) note.historyAt.removeAt(0);
                  }
                  bodyCtl.text = result;
                  if (saveRule) {
                    store.settings.customRules.add(CustomRule(find: find, replace: rawRepl, regex: useRegex));
                    await store.persistSettings();
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
          );
        },
      ),
    );
  }

  void _showCopyMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(L10n.of(ctx).copyAll),
              onTap: () {
                Clipboard.setData(ClipboardData(text: bodyCtl.text));
                Navigator.pop(ctx);
                _toast(context, L10n.of(context).copiedAll);
              },
            ),
            ListTile(
              title: Text(L10n.of(ctx).tidyCopy),
              subtitle: Text(L10n.of(ctx).tidyCopySub, style: const TextStyle(fontSize: 12)),
              onTap: () {
                final r = tidy(bodyCtl.text, store.effOpts(buildPresets().first));
                Clipboard.setData(ClipboardData(text: r.text));
                Navigator.pop(ctx);
                _toast(context, L10n.of(context).tidyCopied(r.summary));
              },
            ),
            ListTile(
              title: Text(L10n.of(ctx).copyTableSpreadsheet),
              onTap: () {
                final r = extractTables(bodyCtl.text);
                Navigator.pop(ctx);
                if (r.tables.isEmpty) {
                  _toast(context, L10n.of(context).noTablesFound);
                } else {
                  Clipboard.setData(ClipboardData(text: r.tables.map(tableToTSV).join('\n\n')));
                  _toast(context, L10n.of(context).copiedTableSpreadsheet);
                }
              },
            ),
          ],
        ),
      ),
    );
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
        appBar: AppBar(
          backgroundColor: paperBg,
          automaticallyImplyLeading: !widget.embedded,
          title: const SizedBox.shrink(),
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
            IconButton(
              icon: Icon(_showMeta ? Icons.sell : Icons.sell_outlined),
              tooltip: l.metaTooltip,
              onPressed: () => setState(() => _showMeta = !_showMeta),
            ),
            IconButton(
              icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: note.pinned ? l.unpinTooltip : l.pinTooltip,
              onPressed: () async {
                note.pinned = !note.pinned;
                // 뭔가가 '딸깍' 하고 자리를 잡는 순간이다. 이런 데만 준다.
                HapticFeedback.selectionClick();
                await store.persist();
                setState(() {});
              },
            ),
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
                PopupMenuItem<String> jump(String a, String label) =>
                    PopupMenuItem<String>(
                      value: 'set:$a',
                      height: 38,
                      child: Padding(
                        // 들여쓰기로 '앱 설정 아래 항목'임을 보인다.
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(label,
                            style: TextStyle(fontSize: 14, color: ctx.c.sub)),
                      ),
                    );
                return [
                  // --- 편집 관련 (앞으로 여기에 더 붙는다) ---
                  // 맨 위는 '정리 미리보기'다(2026-08-17 소유자 지시).
                  // 이 앱에서 가장 많이 누르는 단추가 '정리'이고, 그
                  // 단추가 하는 일을 미리 볼 수 있다는 것을 아는 사람이
                  // 설정을 열어 본 사람뿐이면 안 된다.
                  PopupMenuItem<String>(
                    value: 'preview',
                    child: Row(children: [
                      Icon(CupertinoIcons.eye, size: 19, color: ctx.c.accent),
                      const SizedBox(width: 10),
                      Text(lm.menuTidyPreview,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  // 원본복귀는 버전기록 바로 위에 둔다. 되돌린 뒤 마음이
                  // 바뀌면 바로 아래 항목에서 되찾을 수 있다는 것이 눈에
                  // 보여야 한다(소유자가 짚은 배치).
                  PopupMenuItem<String>(
                    value: 'folder',
                    child: Row(children: [
                      Icon(
                          note.folder.isEmpty
                              ? Icons.folder_outlined
                              : Icons.folder,
                          size: 19,
                          color: note.folder.isEmpty ? ctx.c.sub : ctx.c.accent),
                      const SizedBox(width: 10),
                      Text(note.folder.isEmpty ? lm.folderTitle : note.folder),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'revert',
                    enabled: _canRevert,
                    child: Row(children: [
                      Icon(CupertinoIcons.arrow_uturn_left,
                          size: 19,
                          color: _canRevert ? ctx.c.sub : ctx.c.sub.withValues(alpha: 0.4)),
                      const SizedBox(width: 10),
                      Text(lm.revertAction),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'history',
                    child: Row(children: [
                      Icon(Icons.history, size: 19, color: ctx.c.sub),
                      const SizedBox(width: 10),
                      Text(lm.historyTitle),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'append',
                    child: Row(children: [
                      Icon(Icons.attach_file, size: 19, color: ctx.c.sub),
                      const SizedBox(width: 10),
                      Text(lm.importAppend),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'preset',
                    child: Row(children: [
                      Icon(CupertinoIcons.wand_stars, size: 19, color: ctx.c.sub),
                      const SizedBox(width: 10),
                      Text(lm.choosePreset),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(children: [
                      Icon(Icons.ios_share, size: 19, color: ctx.c.sub),
                      const SizedBox(width: 10),
                      Text(lm.exportNote),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 20, color: ctx.c.danger),
                      const SizedBox(width: 10),
                      Text(lm.delete, style: TextStyle(color: ctx.c.danger)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  // --- 앱 전체 설정 ---
                  PopupMenuItem<String>(
                    value: 'set:',
                    child: Row(children: [
                      Icon(Icons.settings_outlined, size: 20, color: ctx.c.accent),
                      const SizedBox(width: 10),
                      Text(lm.menuAppSettings,
                          style: TextStyle(
                              color: ctx.c.accent, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  jump('theme', lm.themeTitle),
                  jump('fontsize', lm.bodyFontSizeTitle),
                  jump('paper', lm.paperTitle),
                  jump('lock', lm.lockTitle),
                  jump('mono', lm.monoEditorTitle),
                  jump('tidy', lm.settingsSecTidy),
                  jump('rules', lm.rulesSectionTitle),
                  jump('ai', lm.menuAiKey),
                ];
              },
            ),
            // 새 노트 — 이 메모와 무관한 지시라서 일부러 '떠 있는' 동그란
            // 버튼으로 다르게 생겼다(소유자: 직관적으로 구분, 둥둥 뜨는 느낌).
            // 납작한 아이콘들 사이에서 유일하게 색이 차 있고 그림자가 있다.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              child: Material(
                color: context.c.accent,
                elevation: 3,
                shadowColor: context.c.accent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    await _save();
                    final fresh = Note.fresh(body: '');
                    store.notes.insert(0, fresh);
                    await store.persist();
                    if (!mounted) return;
                    // 두 칸 화면에서는 오른쪽 칸만 바뀌면 된다.
                    // pushReplacement는 밀어 넣을 화면이 있을 때만 뜻이 있다.
                    await openNote(context, fresh.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(CupertinoIcons.square_pencil, size: 19, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              lineHeight: store.settings.bodyFontSize *
                                  MonoTextController.bodyHeight,
                              colWidth: _colWidth(store.settings.bodyFontSize),
                              // 스크롤이 붙기 전 첫 프레임에는 offset을 물으면
                              // 죽는다. 그때는 0이 맞다.
                              scroll: _bodyScroll.hasClients
                                  ? _bodyScroll.offset
                                  : 0,
                              // 날짜 줄이 본문 위에 같이 굴러가므로 그만큼
                              // 줄을 내려 긋는다. 안 그러면 줄이 글자
                              // 한가운데를 가로지른다.
                              headPad: _headH,
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
                        MonoTextController.bodyHeight;
                    final blank =
                        inlineAdLikely() ? lineH * 2 : box.maxHeight * 0.5;
                    // 본문 칸의 최소 높이를 이렇게 두면, 글이 짧을 때
                    // [머리 + 본문 + 빈칸]이 정확히 한 화면이라 스크롤이 안
                    // 생긴다. 한 줄짜리 메모에서 화면이 덜컹거리면 더
                    // 이상하다. 날짜 줄을 안으로 들인 뒤로는 그 높이도
                    // 빼야 셈이 맞는다.
                    final minBody =
                        (box.maxHeight - blank - _headH).clamp(0.0, double.infinity);
                    return SingleChildScrollView(
                      controller: _bodyScroll,
                      // 튕기는 스크롤은 블록을 씌우는 중에 문서가 더 크게
                      // 흔들려 보이게 한다.
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                      height: MonoTextController.bodyHeight,
                      // 종이를 골랐으면 잉크도 종이 것을 쓴다. 아이보리
                      // 종이에 순검정을 얹으면 인쇄물이 아니라 스캔한
                      // 종이처럼 보인다. 색은 core/paper.dart에서 명암비를
                      // 계산해 정해 뒀다.
                      color: paperInk),
                  onChanged: _onBodyChanged,
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
                : Glass(
                    hairlineTop: true,
                    child: Row(
                    children: [
                      // 2026-08-16 소유자 지적 — '정리'와 '자동 정리'가 따로
                      // 있어서 뭐가 다른지 알 수 없었다. 이름 문제가 아니라
                      // 구조 문제였다: 같은 기능에 문이 둘이었다.
                      //
                      // 문을 하나로 합쳤다. 누르면 기본 정리가 **바로** 돈다.
                      // 다른 방식이 필요하면 길게 누르거나 '...' 메뉴에서
                      // 고른다. 흔한 경우(대부분)는 한 번 누르면 끝난다.
                      _barBtn(CupertinoIcons.wand_stars, l.tidyAction,
                          () => _runTidyWithPreset(buildPresets().first),
                          primary: true, onLongPress: _showPresetSheet),
                      _barBtn(CupertinoIcons.sparkles, l.wizardAction, _showWizardDialog),
                      _barBtn(CupertinoIcons.table, l.tableAction, _showTables),
                      _barBtn(CupertinoIcons.search, l.replaceAction, _showReplaceDialog),
                      _barBtn(CupertinoIcons.doc_on_doc, l.copyAction, _showCopyMenu),
                      // 2026-08-17 — 여기 있던 '되돌리기'를 뺐다.
                      // 하루에 스무 번 누르는 버튼들 옆에, 한 번 누르면 한
                      // 시간이 사라지는 버튼이 같은 크기 같은 모양으로 있었다.
                      // 손가락은 자리를 기억하지 뜻을 기억하지 않는다.
                      // '...' 메뉴로 옮겼다(_revertToOriginal).
                    ],
                  )),
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
      body: items.isEmpty
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
                final shown = title.isNotEmpty
                    ? title
                    : (body.isEmpty ? l.untitled : body.split('\n').first);
                final left = trashDaysLeft(deletedAt: at, nowMs: now);
                return ListTile(
                  title: Text(shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l.trashDaysLeftLabel(left),
                      style: TextStyle(fontSize: 13.5, color: c.sub)),
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
    n.history.add(n.body);
    n.historyAt.add(DateTime.now().millisecondsSinceEpoch);
    if (n.history.length > 30) {
      n.history.removeAt(0);
      if (n.historyAt.isNotEmpty) n.historyAt.removeAt(0);
    }
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
    final items = <(String, String, String)>[];
    for (var i = n.history.length - 1; i >= 0; i--) {
      final at = i < n.historyAt.length ? n.historyAt[i] : 0;
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
      items.add((when, n.history[i], _peek(n.history[i])));
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
                      _row(it.$1, it.$3, () => _restore(it.$2)),
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

  Widget _row(String when, String peek, VoidCallback onTap,
      {bool accent = false}) {
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
                    child: Text(when,
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
            selectedColor: c.accent,
            labelStyle: TextStyle(
                color: on ? Colors.white : c.guideInk,
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () {
                    s.sortMode = 'updated';
                    s.filterSource = '';
                    s.filterTag = '';
                    s.filterFolder = '';
                    _save();
                  },
                  child: Text(l.filterReset),
                ),
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

    if (ruling == kRulingLine) return;

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
class SyncHelpSheet extends StatefulWidget {
  const SyncHelpSheet({super.key});

  @override
  State<SyncHelpSheet> createState() => _SyncHelpSheetState();
}

class _SyncHelpSheetState extends State<SyncHelpSheet> {
  bool _checking = false;

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
    if (!mounted) return;
    final l = L10n.of(context);
    final ok = sync.state.value == SyncState.ok;
    setState(() {
      _checking = false;
      _saidBad = !ok;
      _said = ok ? l.syncRecheckOk : l.syncRecheckStill;
    });
    if (!ok) return;
    // 됐다는 말을 읽을 틈을 준 뒤에 닫는다. 곧바로 닫으면 무엇이 바뀌었는지
    // 모른 채 창만 사라진다 — 그것도 '무반응'으로 느껴진다.
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
              Text(l.syncHelpTitle,
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
              Text(l.syncHelpSteps,
                  style: TextStyle(fontSize: 15.5, height: 1.75, color: c.guideInk)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                onPressed: _open,
                child: Text(l.syncOpenSettings,
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
              Text(l.syncHelpNote,
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
// ignore: prefer_const_declarations
final bool kPaidTierLive = false;

/// 프리미엄 안내 화면.
///
/// 2026-08-17 — 지금은 **아무 데서도 부르지 않는다**([kPaidTierLive]).
/// StoreKit이 붙는 날 다시 연결한다.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: context.c.infoBg,
              child: Icon(Icons.workspace_premium, size: 38, color: context.c.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.premiumPitch,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          // 체험 중이면 남은 날을 여기서도 보여 준다. 끝나는 날을 미리
          // 알고 있으면 종료가 배신이 아니라 예고가 된다.
          if (trialOn(Store.instance.settings.trialDays)) ...[
            const SizedBox(height: 10),
            Text(l.trialBadge(trialLeft(Store.instance.settings.trialDays)),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.c.accent)),
          ],
          const SizedBox(height: 10),
          Text(l.premiumBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.55, color: context.c.guideInk)),
          const SizedBox(height: 24),
          // 2026-08-16 확정 가격(경쟁 앱 조사 후): 평생이 주력, 연간이
          // 물량, 월간은 진입용. 평생 정가 US\$39.99는 UpNote와 같은 값이고
          // 연간의 2.7배라 구독을 잠식하지 않는다. 출시 3개월은 기념가.
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _toast(context, l.premiumComingSoon),
            child: Column(children: [
              Text(l.premiumLifetime,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(l.premiumLifetimeNote,
                  style: const TextStyle(fontSize: 12.5, height: 1.3)),
            ]),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _toast(context, l.premiumComingSoon),
            child: Text(l.premiumYearly,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _toast(context, l.premiumComingSoon),
            child: Text(l.premiumMonthly,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
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

  Widget _dropRow<T>(String label, String? sub, T value, List<(T, String)> options, ValueChanged<T> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
      subtitle: sub == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub,
                  style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
            ),
      trailing: DropdownButton<T>(
        value: value,
        items: options.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2))).toList(),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
            store.persistSettings();
            setState(() {});
          }
        },
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
        subtitle: sub == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(sub,
                    style: TextStyle(
                        fontSize: 17, height: 1.35, color: context.c.guideInk)),
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
        padding: const EdgeInsets.only(top: 6, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 12),
            child: Text(l.tidyRulesSub,
                style: TextStyle(
                    fontSize: 15, height: 1.35, color: context.c.guideInk)),
          ),
          _card([
            // 기본값이 '제거'라서 맨 위에 둔다.
            _dropRow(l.emphTitle, l.emphSub, s.emphStyle, [
              ('remove', l.removeLabel),
              ('quoteSingle', l.emphQuoteSingle),
              ('quoteDouble', l.emphQuoteDouble),
              ('keep', l.keepLabel),
            ], (v) => s.emphStyle = v),
            _sep(),
            _dropRow(l.headingTitle, null, s.headingMode, [
              ('strip', l.headingStrip),
              ('keep', l.headingKeep),
              ('prefix', l.headingPrefix),
              ('bracket', l.headingBracket),
            ], (v) => s.headingMode = v),
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

  Future<void> _verifyAiKey() async {
    final s = store.settings;
    final key = s.aiKey.trim();
    if (key.isEmpty) return;
    final p = providerOfKey(key);
    if (p == null) {
      setState(() => _aiMsg = L10n.of(context).aiKeyUnknownFormat);
      return;
    }
    setState(() {
      _aiChecking = true;
      _aiMsg = '';
    });
    try {
      final ids = await _fetchModelIds(p, key);
      s.aiProvider = p;
      s.aiModels = ids;
      final pick = pickCheapest(p, ids);
      if (pick != null) s.aiModel = pick;
      await store.persistSettings();
      if (!mounted) return;
      final found = L10n.of(context).aiModelsFound(filterChatModels(p, ids).length);
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
    } catch (e) {
      // 목록을 못 받아도 회사 판정은 살리고 예비 사다리로 넘어간다.
      s.aiProvider = p;
      if (s.aiModel.isEmpty || !modelMatchesProvider(s.aiModel, p)) {
        s.aiModel = defaultLadder(p).first;
      }
      await store.persistSettings();
      if (!mounted) return;
      setState(() {
        _aiChecking = false;
        _aiMsg = L10n.of(context).aiListFailed('$e');
      });
    }
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
      _toast(context, l.lockUnavailable);
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
          'grid' => l.paperGrid,
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

  Widget _fontSizeBlock(L10n l, AppSettings s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.c.codeBg,
                  border: Border.all(color: context.c.codeLine),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(l.bodyFontSizeSample,
                  style: TextStyle(
                      fontSize: s.bodyFontSize, height: MonoTextController.bodyHeight)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SingleChildScrollView(
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
          if (ICloudSync.supported) ...[
            _secHeader(l.syncTitle),
            _card([
              ValueListenableBuilder<SyncState>(
                valueListenable: ICloudSync.instance.state,
                builder: (_, st, __) {
                  final ok = st == SyncState.ok;
                  final busy = st == SyncState.running;
                  // 2026-08-17 소유자 지시 — "'켜짐'과 설명구는 처음부터
                  // 두 줄로. '켜짐'은 더 주인공스럽게."
                  //
                  // 전에는 한 줄에 상태와 설명을 대시로 이어 붙였다. 좁은
                  // 화면에서 잘렸고, 무엇이 중요한지도 안 보였다. **한 줄에
                  // 두 가지를 넣으면 둘 다 작아 보인다.**
                  //
                  // 설정의 다른 줄들이 전부 '제목 + 그 아래 설명' 모양인데
                  // 여기만 달랐던 것이기도 하다.
                  final title = ok
                      ? l.syncOnTitle
                      : busy
                          ? l.syncStateSyncing
                          : st == SyncState.signedOut
                              ? l.syncSignedOutTitle
                              : l.syncOffTitle;
                  final sub = busy
                      ? null
                      : ok
                          ? l.syncStateOn
                          : st == SyncState.signedOut
                              ? l.syncStateSignedOut
                              : l.syncStateOff;
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
            KeyedSubtree(
                key: _anchors['fontsize'], child: _fontSizeBlock(l, s)),
            _sep(),
            KeyedSubtree(key: _anchors['paper'], child: _paperBlock(l, s)),
            _sep(),
            KeyedSubtree(
              key: _anchors['mono'],
              child: _switchRow(l.monoEditorTitle, l.monoEditorSub, s.monoEditor,
                  (v) => s.monoEditor = v),
            ),
          ]),
          KeyedSubtree(
              key: _anchors['lock'], child: _secHeader(l.lockSectionTitle)),
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
                child: Text(l.lockSub,
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
          KeyedSubtree(
              key: _anchors['rules'], child: _secHeader(l.rulesSectionTitle)),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 6),
            child: Text(l.rulesSectionDesc,
                style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
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
          if (ICloudSync.supported)
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 키 한 칸이 전부다. 회사도 모델도 키에서 알아낸다.
                  // (소유자: "키 발급 시 모델을 알려주지 않는데?" — 맞는 말이라
                  //  모델 선택을 기본 화면에서 치웠다. 2026-08-16 승인)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: s.aiKey,
                          obscureText: true,
                          decoration: InputDecoration(hintText: l.aiKeyHint, isDense: true),
                          onChanged: (v) {
                            s.aiKey = v.trim();
                            store.persistSettings();
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
                  // 소유자 지적: "어떤 LLM API 키 발급에 가더라도 세부
                  // 모델명을 안내해 주지 않는데 사용자가 어떻게 아냐?"
                  //
                  // 맞다. 그래서 원래 설계가 키 하나로 끝난다 — 회사를
                  // 알아내고, 회사에 물어 목록을 받고, 제일 싼 것을 고른다.
                  // 고급은 **비상구**이지 거쳐야 하는 단계가 아닌데, 그
                  // 사실이 화면에서 안 읽혔다. 한 줄로 적어 둔다.
                  TextButton(
                    onPressed: () => setState(() => _aiAdvOpen = !_aiAdvOpen),
                    child: Text(l.aiAdvancedLabel),
                  ),
                  if (!_aiAdvOpen)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(l.aiAdvancedNote,
                          style: TextStyle(fontSize: 13, color: context.c.sub)),
                    ),
                  if (_aiAdvOpen) ...[
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

          // 2026-08-16 — 휴지통. 조사에서 "휴지통 없음"이 앱을 미완성으로
          // 느끼게 하는 여섯 원인 중 하나로 나왔다. 애플 메모 30일, 구글 킵
          // 7일이 관습이라 30일을 따랐다(독자 설계 금지).
          _secHeader(l.trashTitle),
          _card([
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.c.sub),
              title: Text(l.trashTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: Text(l.trashSubtitle,
                  style: TextStyle(fontSize: 14, color: context.c.guideInk)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (store.trash.isNotEmpty)
                  Text('${store.trash.length}',
                      style: TextStyle(fontSize: 16, color: context.c.sub)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.c.sub),
              ]),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()));
                if (mounted) setState(() {});
              },
            ),
          ]),
          _secHeader(l.settingsSecInfo),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Text(l.settingsFooter,
                  style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
            ),
            _sep(),
            // 버전은 여기서 눈으로 확인한다. 업데이트가 실제로 반영됐는지
            // 이 숫자 하나로 알 수 있어야 한다(소유자 요청 2026-08-12).
            // 2026-08-14: 눈으로 읽고 옮겨 적는 대신 그대로 복사할 수 있어야
            // 한다는 요청. SelectableText면 길게 눌러 선택 → 복사 —
            // 애플 기본 방식 그대로다(탭 한 번에 복사되는 독자 동작은 안 만든다).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SelectableText(appVersionLabel,
                  style: TextStyle(fontSize: 15, color: context.c.guideInk)),
            ),
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
    );
  }

  Widget _ruleRow(int i) {
    final l = L10n.of(context);
    final s = store.settings;
    final r = s.customRules[i];
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
          Checkbox(
            value: r.regex,
            onChanged: (v) {
              s.customRules[i] = CustomRule(find: r.find, replace: r.replace, regex: v ?? false);
              store.persistSettings();
              setState(() {});
            },
          ),
          Text(l.regexLabel, style: const TextStyle(fontSize: 15)),
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
