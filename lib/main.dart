/// 심플텍스트 (SimpleText) — Flutter MVP
/// AI 답변을 붙여넣으면, 바로 쓸 수 있는 글이 됩니다.
///
/// 2026-08-12 i18n: UI 문자열은 전부 lib/l10n/으로 분리했다 (한/영/일/중간·번체/스/포/독/프).
/// 엔진(tidy_engine)·마법사(wizard)가 만드는 리포트 문구는 JS 엔진과의 대칭 규칙 때문에
/// 이번 범위에서 제외 — 로드맵의 후속 항목이다. 프리셋 이름은 Preset.id를 UI 층에서 매핑한다.
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
// material.dart는 defaultTargetPlatform을 내보내지 않는다(TargetPlatform은 내보낸다).
// 2026-08-14에 이걸 몰라서 analyze가 undefined_identifier로 잡았다.
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_service.dart';
import 'core/ai_provider.dart';
import 'core/mono_controller.dart';
import 'core/mru.dart';
import 'core/tag_suggest.dart';
import 'core/tidy_engine.dart';
import 'core/wizard.dart';
import 'l10n/l10n.dart';
import 'version.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고 시동(모바일에서만 동작 — 맥·윈도우에서는 아무것도 안 한다).
  AdsService.instance.boot();
  runApp(const SimpleTextApp());
}

// 2026-08-16 — 주조색을 브랜드(Cloudfall) 팔레트로 전환했다(소유자 지시:
// "컬러 주조색은 모두 skyblue 기조로", "밝고 맑고 경쾌하게, 다크는
// 눈부시지 않게").
// 브랜드 팔레트: 글로우 #9BEDFF · 하늘 #3FB2F0 · 바탕/텍스트 #1A5FCB
// · 딥 #08205A. 브랜드 가이드 규칙: 한 가지 색만 써야 하는 자리에서는
// #1A5FCB를 쓴다 — 그래서 글자·아이콘용 강조색이 #1A5FCB다.
// 명암비는 전부 계산으로 검증했다(값을 바꾸면 반드시 재계산):
//   #1A5FCB on 흰 배경 5.9:1 · on #F2F2F7 5.3:1 · on 정보카드 5.3:1
const _accent = Color(0xFF1A5FCB);
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

  static const light = AppC(
    bg: Color(0xFFF2F2F7),
    panel: Colors.white,
    line: Color(0xFFEDEDEF),
    sub: Color(0xFF8E8E93),
    accent: _accent,
    field: Color(0xFFE3E3E8),
    toolbar: Color(0xFFF2F2F0),
    toolbarLine: Color(0xFFE0E0DC),
    infoBg: Color(0xFFE8F5FE), // 하늘빛 정보 카드 (#1A5FCB 글자 5.3:1)
    warnBg: Color(0xFFFDF3E7),
    warnInk: Color(0xFF9A6A1F),
    codeBg: Color(0xFFF6F6F4),
    codeLine: Color(0xFFE4E4E0),
    pin: Color(0xFFF2B705),
    danger: Color(0xFFE53935),
    guideInk: Color(0xFF3A3A3C),
    // 2026-08-16 브랜드 하늘색으로 통일. 계산값:
    //   선택 블럭 #3FB2F0 40%+흰 배경 = #B2E0F9 → 검정 글자 14.9:1
    //   손잡이 #1A5FCB on 흰 배경 5.9:1 (조작점 기준 3:1)
    //   태그 글자 #1A5FCB on #E1F4FF 5.2:1
    selBg: Color(0x663FB2F0),
    selHandle: Color(0xFF1A5FCB),
    glass: Color(0xCCFFFFFF),
    glassLine: Color(0x1F000000),
    tagBg: Color(0xFFE1F4FF),
    tagInk: Color(0xFF1A5FCB),
    tagLine: Color(0xFFB8E2FA),
  );

  static const dark = AppC(
    bg: Color(0xFF000000),
    panel: Color(0xFF1C1C1E),
    line: Color(0xFF38383A),
    sub: Color(0xFF98989E),
    // 다크 강조는 하늘색을 밝힌 톤 — 어두운 바탕에 쨍한 원색은 눈을
    // 찌른다(소유자: 밤에 눈부시지 않게). on #1C1C1E 8.8:1, on 검정 10.9:1
    accent: Color(0xFF6FC4F4),
    field: Color(0xFF1C1C1E),
    toolbar: Color(0xFF1C1C1E),
    toolbarLine: Color(0xFF38383A),
    infoBg: Color(0xFF0B2740), // 딥 네이비(#08205A 계열) 정보 카드
    warnBg: Color(0xFF2A2318),
    warnInk: Color(0xFFE0B96A),
    codeBg: Color(0xFF141416),
    codeLine: Color(0xFF2C2C2E),
    pin: Color(0xFFF2B705),
    danger: Color(0xFFFF453A),
    guideInk: Color(0xFFE5E5EA),
    // 선택 블럭 #3FB2F0 48%+검정 = #1E5573 → 흰 글자 8.1:1
    // 손잡이는 기존 검증값 유지(#4FC3F7 on 검정 10.5:1)
    selBg: Color(0x7A3FB2F0),
    selHandle: Color(0xFF4FC3F7),
    glass: Color(0xC61C1C1E),
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

class SimpleTextApp extends StatelessWidget {
  /// 스토어 스크린샷 촬영용 강제 로케일. 평상시엔 null이라 기기 설정을 따른다.
  /// (integration_test/screenshots_test.dart에서 언어별로 지정한다 —
  ///  노하우 6절: 현지화 스크린샷이 없으면 기본 언어 것이 그대로 나간다)
  final Locale? locale;
  const SimpleTextApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
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
        if (!isDesktopPlatform) return child!;
        final mq = MediaQuery.of(ctx);
        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(0.8)),
          child: child!,
        );
      },
      // 애플 메모장과 같이 기기 설정(라이트/다크)을 그대로 따른다
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
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
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(seedColor: _sky, brightness: b),
      scaffoldBackgroundColor: c.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
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
  String lastReport;

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
    this.lastReport = '',
  })  : tags = tags ?? [],
        history = history ?? [];

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
        'lastReport': lastReport,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        originalBody: (j['originalBody'] ?? '') as String,
        pinned: (j['pinned'] ?? false) as bool,
        source: (j['source'] ?? '') as String,
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
  static const int settingsRev = 1;

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

  /// 정리 결과를 먼저 보여 줄지. 미리보기 화면에서 '앞으로 생략'을 켜면 꺼지고,
  /// 설정에서 다시 켤 수 있다(2026-08-14 소유자 요청).
  bool previewBeforeApply = true;

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
        'bodyFontSize': bodyFontSize,
        'aiKey': aiKey,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'aiModels': aiModels,
        'adFreeDate': adFreeDate,
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
    if (((j['rev'] ?? 0) as int) < settingsRev && s.emphStyle == 'quoteSingle') {
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
    s.bodyFontSize = ((j['bodyFontSize'] ?? s.bodyFontSize) as num).toDouble();
    s.aiKey = (j['aiKey'] ?? s.aiKey) as String;
    s.aiProvider = (j['aiProvider'] ?? s.aiProvider) as String;
    s.aiModel = (j['aiModel'] ?? s.aiModel) as String;
    s.aiModels = List<String>.from((j['aiModels'] ?? const []) as List);
    s.adFreeDate = (j['adFreeDate'] ?? s.adFreeDate) as String;
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
    loaded = true;
    notifyListeners();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _notesKey, jsonEncode({'v': 2, 'notes': notes.map((n) => n.toJson()).toList(), 'tombstones': tombstones}));
    notifyListeners();
  }

  Future<void> persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  void deleteNote(String id) {
    tombstones.add({'id': id, 'deletedAt': DateTime.now().millisecondsSinceEpoch});
    notes.removeWhere((n) => n.id == id);
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = Store.instance;
  String query = '';

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
    store.load();
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _pasteAndTidy() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (mounted) _toast(context, L10n.of(context).clipboardEmpty);
      return;
    }
    final note = Note.fresh(body: text);
    store.notes.insert(0, note);
    await store.persist();
    if (!mounted) return;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: note.id, autoTidy: true)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final q = query.trim().toLowerCase();
    final filtered = store.notes.where((n) {
      if (q.isEmpty) return true;
      final hay = '${n.title} ${n.body} ${n.tags.join(' ')} ${n.source}'.toLowerCase();
      return hay.contains(q);
    }).toList();
    final pinned = filtered.where((n) => n.pinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final rest = filtered.where((n) => !n.pinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          // 2026-08-16 소유자 요청: 큰 '메모' 타이틀을 없애고 검색을 설정
          // 톱니 왼쪽으로. 그 위 최상단은 배너 자리다(광고 없는 날은 0px).
          : SafeArea(
              bottom: false,
              child: Column(children: [
                const TopBannerBar(),
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: CustomScrollView(
              slivers: [
                // 유리 머리 높이만큼 비워서 목록이 그 밑으로 흘러 들어간다.
                const SliverToBoxAdapter(child: SizedBox(height: kHomeHeaderH)),
                if (pinned.isEmpty && rest.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l.emptyList, textAlign: TextAlign.center)),
                  ),
                if (pinned.isNotEmpty) _groupLabel(l.pinnedLabel),
                if (pinned.isNotEmpty) _groupCard(pinned),
                if (rest.isNotEmpty) _groupLabel(l.notesLabel),
                if (rest.isNotEmpty) _groupCard(rest),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
                              IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: l.settingsTooltip,
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SettingsScreen())),
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: note.id)));
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

  Widget _groupLabel(String label) => SliverToBoxAdapter(
        child: Padding(
          // 애플 메모의 '고정된 메모' 헤더 실측: 글자높이 52px, 좌측 135px(45pt).
          // 제목 46px=17pt 비율로 환산하면 19.2pt → 애플 .title3(20pt) 굵게.
          // 색도 회색이 아니라 본문색이다.
          padding: const EdgeInsets.fromLTRB(kListRowInset + 16, 18, 16, 8),
          child: Text(label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
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

  Widget _noteTile(Note n) {
    final l = L10n.of(context);
    final firstLine = n.body.split('\n').firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
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
        final ok = await showAdaptiveDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog.adaptive(
            title: Text(L10n.of(ctx).deleteConfirmTitle),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.of(ctx).cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(L10n.of(ctx).delete)),
            ],
          ),
        );
        if (ok == true) store.deleteNote(n.id);
        return ok == true;
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
        color: context.c.panel,
        child: InkWell(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: n.id))),
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
  const EditorScreen({super.key, required this.noteId, this.autoTidy = false});

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

  void _moveCursor(int delta) {
    final sel = bodyCtl.selection;
    if (!sel.isValid) return;
    final pos = (sel.baseOffset + delta).clamp(0, bodyCtl.text.length);
    bodyCtl.selection = TextSelection.collapsed(offset: pos);
  }

  void _moveToLineEdge(bool start) {
    final sel = bodyCtl.selection;
    if (!sel.isValid) return;
    final text = bodyCtl.text;
    int pos = sel.baseOffset.clamp(0, text.length);
    if (start) {
      final idx = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
      pos = idx < 0 ? 0 : idx + 1;
    } else {
      final idx = text.indexOf('\n', pos);
      pos = idx < 0 ? text.length : idx;
    }
    bodyCtl.selection = TextSelection.collapsed(offset: pos);
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
  Widget _barBtn(IconData icon, String label, VoidCallback? onTap, {bool primary = false}) {
    final on = onTap != null;
    final color = !on
        ? context.c.sub.withValues(alpha: 0.5)
        : (primary ? context.c.accent : context.c.accent);
    return Expanded(
      child: TextButton(
        onPressed: onTap,
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
                _kbBtn(icon: Icons.undo, tip: l.undoTip, onTap: () => _undoCtl.undo()),
                _kbBtn(icon: Icons.redo, tip: l.redoTip, onTap: () => _undoCtl.redo()),
                _kbBtn(glyph: '( )', onTap: () => _insertText('(', ')')),
                _kbBtn(glyph: '[ ]', onTap: () => _insertText('[', ']')),
                _kbBtn(glyph: '" "', onTap: () => _insertText('"', '"')),
                _kbBtn(glyph: "' '", onTap: () => _insertText("'", "'")),
                _kbBtn(glyph: '·', onTap: () => _insertText('· ')),
                _kbBtn(glyph: '-', onTap: () => _insertText('- ')),
                _kbBtn(glyph: '@', onTap: () => _insertText('@')),
                _kbBtn(glyph: '%', onTap: () => _insertText('%')),
                _kbBtn(glyph: '/', onTap: () => _insertText('/')),
                _kbBtn(icon: Icons.keyboard_arrow_left, tip: l.moveLeftTip, onTap: () => _moveCursor(-1)),
                _kbBtn(icon: Icons.keyboard_arrow_right, tip: l.moveRightTip, onTap: () => _moveCursor(1)),
                _kbBtn(icon: Icons.keyboard_double_arrow_left, tip: l.lineStartTip, onTap: () => _moveToLineEdge(true)),
                _kbBtn(icon: Icons.keyboard_double_arrow_right, tip: l.lineEndTip, onTap: () => _moveToLineEdge(false)),
                _kbBtn(icon: Icons.format_indent_increase, tip: l.indentTip, onTap: () => _insertText('  ')),
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
    // 태그의 진짜 값은 note.tags 하나뿐이다. 이 입력칸은 '새로 칠 것'만 담는다.
    // (전에는 입력칸의 글자가 곧 태그였다 — 그러면 블럭을 지우는 조작을 만들 수 없다)
    tagsCtl = TextEditingController();
    for (final f in [_titleFocus, _bodyFocus, _tagsFocus]) {
      f.addListener(() => setState(() {}));
    }
    if (widget.autoTidy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTidyWithPreset(buildPresets().first));
    }
  }

  @override
  void dispose() {
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
    if (!mounted) return;
    setState(() => _tagAiBusy = false);
    if (got.isEmpty) {
      _toast(context, l.tagAiNone);
      return;
    }
    await _commitTags(got.join(','), clear: false);
    if (mounted && !byAi) _toast(context, l.tagAiLocalNote);
  }

  Future<void> _save() async {
    note.title = titleCtl.text;
    note.body = bodyCtl.text;
    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await store.persist();
  }

  /// 본문에서 뽑은 제목 — 비어 있지 않은 맨 윗줄, 최대 40자.
  static String _titleFrom(String body) {
    final first = body.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return first.length > 40 ? first.substring(0, 40) : first;
  }

  Future<void> _runTidyWithPreset(Preset preset) async {
    await _save();
    final r = tidy(note.body, store.effOpts(preset));
    if (!mounted) return;
    final l = L10n.of(context);
    // 미리보기를 끈 사람은 바로 적용된다. 되돌리기가 있으니 안전하다
    // (2026-08-14 소유자 요청 — 매번 미리보기를 거치는 게 번거롭다).
    final apply = store.settings.previewBeforeApply
        ? await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => PreviewScreen(
                    presetName: l.presetName(preset.id, preset.name),
                    before: note.body,
                    result: r)),
          )
        : true;
    if (apply == true) {
      note.history.add(note.body);
      if (note.history.length > 30) note.history.removeAt(0);
      if (note.originalBody.isEmpty) note.originalBody = note.body;
      // 제목은 "본문 맨 위 한 줄"이다(소유자 확정 2026-08-14).
      // 정리하면서 맨 윗줄이 바뀔 수 있으므로(출력 시각 줄 제거 등) 다시 뽑는다.
      // 단 사용자가 손으로 쓴 제목은 건드리지 않는다 — 정리 전 첫 줄과 같을 때만
      // "자동으로 붙은 제목"으로 보고 갱신한다.
      final wasAuto = note.title.isEmpty || note.title == _titleFrom(note.body);
      note.body = r.text;
      note.lastReport = r.summary;
      if (wasAuto) {
        note.title = _titleFrom(r.text);
        titleCtl.text = note.title;
      }
      bodyCtl.text = note.body;
      await _save();
      if (mounted) {
        setState(() {});
        _toast(context, L10n.of(context).appliedDone(r.summary));
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

  /// 오류 본문에서 사람이 읽을 한 줄을 뽑는다. 전에는 'API 400'만 던져서
  /// 무엇이 문제인지(키가 틀렸는지, 모델이 없는지) 알 수 없었다.
  static String _apiErr(int code, List<int> bodyBytes) {
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

  Future<String> _aiCallOnce(
      String provider, String model, String sys, String instruction, String body) async {
    final s = store.settings;
    final user = '[지시]\n$instruction\n\n[본문]\n$body';
    if (provider == 'google') {
      final res = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeComponent(s.aiKey)}'),
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
          'x-api-key': s.aiKey,
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
        'authorization': 'Bearer ${s.aiKey}',
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

  Future<void> _showWizardDialog() async {
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
                            if (note.history.length > 30) note.history.removeAt(0);
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
                    if (note.history.length > 30) note.history.removeAt(0);
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
                  if (note.history.length > 30) note.history.removeAt(0);
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
    // 설정을 바꾸면 다음 build에서 바로 반영된다(컨트롤러가 매번 이 값을 본다).
    bodyCtl.monoEnabled = store.settings.monoEditor;
    bodyCtl.bodyFontSize = store.settings.bodyFontSize;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        backgroundColor: context.c.panel,
        // 2026-08-16 소유자 지시 — 배너는 상단바(뒤로가기 줄)보다도 위,
        // 화면 진짜 꼭대기다. 원래 화면 전체(상단바 포함)를 안쪽
        // Scaffold로 감싸 배너 아래로 넣는다.
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            const TopBannerBar(),
            Expanded(
              child: Scaffold(
        backgroundColor: context.c.panel,
        appBar: AppBar(
          backgroundColor: context.c.panel,
          title: const SizedBox.shrink(),
          actions: [
            if (_editing)
              TextButton(
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Text(l.done, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            // 붙여넣고 바로 누르는 버튼 — 'AI 답변 정리'를 한 번에 돌린다
            // (2026-08-14 소유자 요청). 아래 도구 막대의 '정리'와 같은 동작이지만
            // 손이 위에 있을 때 바로 누를 수 있어야 한다.
            if (!_editing)
              TextButton(
                onPressed: () => _runTidyWithPreset(buildPresets().first),
                child: Text(l.autoTidy, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
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
                await store.persist();
                setState(() {});
              },
            ),
            // 2026-08-16 소유자 요청 — 애플 메모장처럼 '...' 메뉴.
            // 이 메모에 대한 설정이 앞으로 여기에 쌓인다. 지금은 삭제 하나.
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              tooltip: l.moreTooltip,
              onSelected: (v) async {
                if (v != 'delete') return;
                final ok = await showAdaptiveDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog.adaptive(
                    title: Text(L10n.of(ctx).deleteConfirmTitle),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.of(ctx).cancel)),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true), child: Text(L10n.of(ctx).delete)),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  store.deleteNote(note.id);
                  Navigator.pop(context);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 20, color: ctx.c.danger),
                    const SizedBox(width: 10),
                    Text(L10n.of(ctx).delete, style: TextStyle(color: ctx.c.danger)),
                  ]),
                ),
              ],
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
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => EditorScreen(noteId: fresh.id)));
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
            if (_isDesktop) _accessoryBar(atTop: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextField(
                controller: titleCtl,
                focusNode: _titleFocus,
                decoration: InputDecoration(
                    hintText: l.titleHint, border: InputBorder.none, isDense: true),
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                onChanged: (_) => _save(),
              ),
            ),
            if (_showMeta)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
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
                      await _save();
                      setState(() {});
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
                            onSubmitted: (v) => _commitTags(v, clear: true),
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
                child: TextField(
                  controller: bodyCtl,
                  focusNode: _bodyFocus,
                  undoController: _undoCtl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  // 선택 돋보기는 TextField가 기본으로 켜 준다(따로 지정할 필요 없음).
                  // 2026-08-14에 명시적으로 넣으려다 이름을 틀려 빌드가 깨졌고,
                  // 확인해 보니 어차피 기본값이었다. 즉 선택 조작감 문제의 원인은
                  // 돋보기가 아니다 — 기기에서 직접 만져 보며 찾아야 한다.
                  //
                  // 튕기는 스크롤은 선택 중에 문서가 더 크게 흔들려 보이게 한다.
                  scrollPhysics: const ClampingScrollPhysics(),
                  decoration: InputDecoration(hintText: l.bodyHint, border: InputBorder.none),
                  // 줄글은 기기 기본 글꼴 그대로 두고, 표·코드 구간만 등폭으로
                  // 바꿔 그린다(2026-08-14 소유자 요청). 어디가 표인지는
                  // core/mono_spans.dart가, 실제로 글꼴을 입히는 일은
                  // core/mono_controller.dart가 한다.
                  // 표에 등폭이 필요한 이유: 공백으로 맞춘 칸은 글자 폭이 일정해야
                  // 줄이 맞는다. 비례 글꼴에서는 원리적으로 맞출 수 없다.
                  style: TextStyle(
                      fontSize: store.settings.bodyFontSize,
                      height: MonoTextController.bodyHeight),
                  onChanged: (_) => _save(),
                ),
              ),
            ),
            if (note.lastReport.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(note.lastReport,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.c.accent, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: (_bodyFocus.hasFocus && !_isDesktop)
                ? _accessoryBar()
                : Glass(
                    hairlineTop: true,
                    child: Row(
                    children: [
                      _barBtn(CupertinoIcons.wand_stars, l.tidyAction, _showPresetSheet,
                          primary: true),
                      _barBtn(CupertinoIcons.sparkles, l.wizardAction, _showWizardDialog),
                      _barBtn(CupertinoIcons.table, l.tableAction, _showTables),
                      _barBtn(CupertinoIcons.search, l.replaceAction, _showReplaceDialog),
                      _barBtn(CupertinoIcons.doc_on_doc, l.copyAction, _showCopyMenu),
                      _barBtn(
                        CupertinoIcons.arrow_uturn_left,
                        l.undoAction,
                        note.history.isEmpty
                            ? null
                            : () async {
                                note.body = note.history.removeLast();
                                note.lastReport = '';
                                bodyCtl.text = note.body;
                                await _save();
                                setState(() {});
                                if (mounted) _toast(context, L10n.of(context).revertedToast);
                              },
                      ),
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
  const PreviewScreen({super.key, required this.presetName, required this.before, required this.result});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final store = Store.instance;
  bool _skipNext = false;

  String get presetName => widget.presetName;
  String get before => widget.before;
  TidyResult get result => widget.result;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.previewTitle(presetName))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.c.infoBg, borderRadius: BorderRadius.circular(10)),
            child: Text(result.summary,
                style: TextStyle(color: context.c.accent, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          for (final w in result.warnings)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.c.warnBg, borderRadius: BorderRadius.circular(10)),
              child: Text(l.warningPrefix(w),
                  style: TextStyle(color: context.c.warnInk, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 14),
          Text(l.tidyResultLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.c.sub)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: context.c.codeBg,
                border: Border.all(color: context.c.codeLine),
                borderRadius: BorderRadius.circular(10)),
            child: SelectableText(result.text, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
          const SizedBox(height: 14),
          Text(l.originalLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.c.sub)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: context.c.codeBg,
                border: Border.all(color: context.c.codeLine),
                borderRadius: BorderRadius.circular(10)),
            child: SelectableText(before, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 버튼 바로 위 — 여기서 켜면 다음부터 이 화면을 건너뛴다.
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
          const SizedBox(height: 10),
          Text(l.premiumBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.55, color: context.c.guideInk)),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _toast(context, l.premiumComingSoon),
            child: Text(l.premiumLifetime,
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

/// ---------------- 정리 규칙 설정 ----------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final store = Store.instance;
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
      setState(() {
        _aiChecking = false;
        _aiMsg = L10n.of(context).aiModelsFound(filterChatModels(p, ids).length);
      });
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

  /// 글자 크기 — 쓰던 앱과 눈으로 맞출 수 있게 견본을 같이 보여 준다.
  /// 숫자를 코드에 박아 두면 맞출 때마다 설치 왕복이 생긴다(2026-08-14).
  /// 견본 문장은 소유자 지정: 자국어와 영어가 섞인 세 줄짜리 문장이다.
  /// 한쪽 글자만 보고 맞추면 다른 쪽이 어긋나기 때문이다.
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          // 2026-08-16 소유자 요청 — 설정 맨 위에 프리미엄(결제) 유도 배너.
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
                            Text(l.premiumPitchSub,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: context.c.guideInk)),
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
          _secHeader(l.settingsSecView),
          _card([
            _fontSizeBlock(l, s),
            _sep(),
            _switchRow(l.monoEditorTitle, l.monoEditorSub, s.monoEditor,
                (v) => s.monoEditor = v),
          ]),
          _secHeader(l.settingsSecTidy),
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
          _secHeader(l.settingsSecWhen),
          _card([
            // 미리보기 화면에서 '앞으로 생략'을 켜면 여기로 돌아와 다시 켤 수 있다.
            _switchRow(l.previewTitle2, l.previewSub2, s.previewBeforeApply,
                (v) => s.previewBeforeApply = v),
          ]),
          _secHeader(l.aiSectionTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 6),
            child: Text(l.aiSectionDesc,
                style: TextStyle(fontSize: 17, height: 1.35, color: context.c.guideInk)),
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
                  TextButton(
                    onPressed: () => setState(() => _aiAdvOpen = !_aiAdvOpen),
                    child: Text(l.aiAdvancedLabel),
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
          _secHeader(l.rulesSectionTitle),
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
          const SizedBox(height: 24),
        ],
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
