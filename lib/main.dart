/// 심플텍스트 (SimpleText) — Flutter MVP
/// AI 답변을 붙여넣으면, 바로 쓸 수 있는 글이 됩니다.
///
/// 2026-08-12 i18n: UI 문자열은 전부 lib/l10n/으로 분리했다 (한/영/일/중간·번체/스/포/독/프).
/// 엔진(tidy_engine)·마법사(wizard)가 만드는 리포트 문구는 JS 엔진과의 대칭 규칙 때문에
/// 이번 범위에서 제외 — 로드맵의 후속 항목이다. 프리셋 이름은 Preset.id를 UI 층에서 매핑한다.
import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/tidy_engine.dart';
import 'core/wizard.dart';
import 'l10n/l10n.dart';
import 'version.dart';

void main() {
  runApp(const SimpleTextApp());
}

const _accent = Color(0xFF2F5FE0);

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
    infoBg: Color(0xFFEEF2FD),
    warnBg: Color(0xFFFDF3E7),
    warnInk: Color(0xFF9A6A1F),
    codeBg: Color(0xFFF6F6F4),
    codeLine: Color(0xFFE4E4E0),
    pin: Color(0xFFF2B705),
    danger: Color(0xFFE53935),
  );

  static const dark = AppC(
    bg: Color(0xFF000000),
    panel: Color(0xFF1C1C1E),
    line: Color(0xFF38383A),
    sub: Color(0xFF98989E),
    accent: Color(0xFF6E9BFF),
    field: Color(0xFF1C1C1E),
    toolbar: Color(0xFF1C1C1E),
    toolbarLine: Color(0xFF38383A),
    infoBg: Color(0xFF13203A),
    warnBg: Color(0xFF2A2318),
    warnInk: Color(0xFFE0B96A),
    codeBg: Color(0xFF141416),
    codeLine: Color(0xFF2C2C2E),
    pin: Color(0xFFF2B705),
    danger: Color(0xFFFF453A),
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
      // 애플 메모장과 같이 기기 설정(라이트/다크)을 그대로 따른다
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }

  static ThemeData _theme(Brightness b, AppC c) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: b),
        scaffoldBackgroundColor: c.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        extensions: [c],
      );
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
  String emphStyle = 'quoteSingle';
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
  String aiKey = '';
  String aiModel = 'gemini-2.5-flash-lite';
  List<CustomRule> customRules = [];

  Map<String, dynamic> toJson() => {
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
        'aiKey': aiKey,
        'aiModel': aiModel,
        'customRules': customRules
            .map((r) => {'find': r.find, 'replace': r.replace, 'regex': r.regex})
            .toList(),
      };

  static AppSettings fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    s.emphStyle = (j['emphStyle'] ?? s.emphStyle) as String;
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
    s.aiKey = (j['aiKey'] ?? s.aiKey) as String;
    s.aiModel = (j['aiModel'] ?? s.aiModel) as String;
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
          : CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(l.homeTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  backgroundColor: context.c.bg,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: l.settingsTooltip,
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: context.c.field,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'new',
            tooltip: l.newNoteTooltip,
            onPressed: () async {
              final note = Note.fresh();
              store.notes.insert(0, note);
              await store.persist();
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: note.id)));
            },
            child: const Icon(Icons.add),
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
          padding: const EdgeInsets.fromLTRB(28, 12, 16, 6),
          child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.c.sub)),
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
                      Divider(height: 1, indent: 16, color: context.c.line),
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
      child: ListTile(
        tileColor: context.c.panel,
        title: Text(
          n.title.isNotEmpty ? n.title : (firstLine.isNotEmpty ? firstLine : l.untitled),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(_listDate(l, n.updatedAt), style: TextStyle(fontSize: 13, color: context.c.sub)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(firstLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.c.sub)),
            ),
          ],
        ),
        trailing: n.pinned ? Icon(Icons.push_pin, size: 15, color: context.c.pin) : null,
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: n.id))),
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
  late TextEditingController bodyCtl;
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

  Widget _accessoryBar() {
    final l = L10n.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.c.toolbar,
        border: Border(top: BorderSide(color: context.c.toolbarLine)),
      ),
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
          Container(width: 1, height: 26, color: context.c.toolbarLine),
          _kbBtn(
            icon: Icons.keyboard_hide_outlined,
            tip: l.hideKeyboardTip,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ],
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
    bodyCtl = TextEditingController(text: note.body);
    tagsCtl = TextEditingController(text: note.tags.join(', '));
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

  Future<void> _save() async {
    note.title = titleCtl.text;
    note.body = bodyCtl.text;
    note.tags = tagsCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await store.persist();
  }

  Future<void> _runTidyWithPreset(Preset preset) async {
    await _save();
    final r = tidy(note.body, store.effOpts(preset));
    if (!mounted) return;
    final l = L10n.of(context);
    final apply = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PreviewScreen(
              presetName: l.presetName(preset.id, preset.name), before: note.body, result: r)),
    );
    if (apply == true) {
      note.history.add(note.body);
      if (note.history.length > 30) note.history.removeAt(0);
      if (note.originalBody.isEmpty) note.originalBody = note.body;
      note.body = r.text;
      note.lastReport = r.summary;
      if (note.title.isEmpty) {
        note.title = r.text.split('\n').firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
        if (note.title.length > 40) note.title = note.title.substring(0, 40);
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

  Future<void> _showTables() async {
    await _save();
    final r = extractTables(note.body);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: r.tables.isEmpty
            ? Padding(padding: const EdgeInsets.all(30), child: Text(L10n.of(ctx).noTablesFound))
            : ListView(
                shrinkWrap: true,
                children: [
                  for (int i = 0; i < r.tables.length; i++)
                    ListTile(
                      title: Text(L10n.of(ctx)
                          .tableInfo(i + 1, r.tables[i].header.length, r.tables[i].rows.length)),
                      subtitle: Wrap(spacing: 8, children: [
                        FilledButton.tonal(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToTSV(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, L10n.of(context).copiedSpreadsheet);
                          },
                          child: Text(L10n.of(ctx).forSpreadsheet),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToCSV(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, L10n.of(context).copiedCsv);
                          },
                          child: const Text('CSV'),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToMarkdown(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, L10n.of(context).copiedMarkdown);
                          },
                          child: const Text('Markdown'),
                        ),
                      ]),
                    ),
                ],
              ),
      ),
    );
  }

  static const _aiSys =
      '너는 텍스트 편집 도구다. 사용자의 지시대로만 본문을 편집한다. 규칙: 숫자·날짜·통화·퍼센트·고유명사·URL은 절대 바꾸지 않는다. 요청하지 않은 사실을 추가하지 않고, 요청하지 않은 내용을 삭제하지 않는다. 입력 언어를 유지한다. 결과 본문만 출력하고 설명·인사·코드펜스는 붙이지 않는다.';

  Future<String> _aiEditCall(String instruction, String body) async {
    final s = store.settings;
    final user = '[지시]\n$instruction\n\n[본문]\n$body';
    if (s.aiModel.startsWith('gemini')) {
      final res = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/${s.aiModel}:generateContent?key=${Uri.encodeComponent(s.aiKey)}'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {'parts': [{'text': _aiSys}]},
          'contents': [{'role': 'user', 'parts': [{'text': user}]}],
        }),
      );
      if (res.statusCode != 200) throw Exception('API ${res.statusCode}');
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final cands = (j['candidates'] ?? []) as List;
      if (cands.isEmpty) return '';
      final parts = ((cands[0]['content'] ?? {})['parts'] ?? []) as List;
      return parts.map((p) => (p['text'] ?? '') as String).join();
    }
    if (s.aiModel.startsWith('claude')) {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'content-type': 'application/json',
          'x-api-key': s.aiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': s.aiModel,
          'max_tokens': 8000,
          'system': _aiSys,
          'messages': [{'role': 'user', 'content': user}],
        }),
      );
      if (res.statusCode != 200) throw Exception('API ${res.statusCode}');
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = (j['content'] ?? []) as List;
      return content.isEmpty ? '' : ((content[0]['text'] ?? '') as String);
    }
    // OpenAI(ChatGPT)와 xAI(Grok)는 동일한 chat/completions 형식
    final base = s.aiModel.startsWith('grok') ? 'https://api.x.ai' : 'https://api.openai.com';
    final res = await http.post(
      Uri.parse('$base/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${s.aiKey}',
      },
      body: jsonEncode({
        'model': s.aiModel,
        'messages': [
          {'role': 'system', 'content': _aiSys},
          {'role': 'user', 'content': user},
        ],
      }),
    );
    if (res.statusCode != 200) throw Exception('API ${res.statusCode}');
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
    await showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final l = L10n.of(ctx);
          return AlertDialog.adaptive(
            title: Text(l.wizardTitle),
            content: SizedBox(
              width: 480,
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
              FilledButton(
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
                  setD(() {
                    applied = r.applied;
                    unknown = r.unknown;
                    aiResult = null;
                  });
                  if (mounted) setState(() {});
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
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
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.deleteTooltip,
              onPressed: () async {
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
            ),
          ],
        ),
        body: Column(
          children: [
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: tagsCtl,
                      focusNode: _tagsFocus,
                      decoration: InputDecoration(hintText: l.tagsHint, isDense: true),
                      onChanged: (_) => _save(),
                    ),
                  ),
                ],
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
                  decoration: InputDecoration(hintText: l.bodyHint, border: InputBorder.none),
                  // 등폭을 켜면 표의 칸이 정확히 맞는다 (CotEditor와 같은 방식).
                  // 비례 글꼴에서는 공백 정렬이 원리적으로 맞을 수 없다.
                  style: store.settings.monoEditor
                      ? const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          fontFamily: 'Menlo',
                          fontFamilyFallback: ['SF Mono', 'Consolas', 'monospace'])
                      : const TextStyle(fontSize: 16, height: 1.6),
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
            child: _bodyFocus.hasFocus
                ? _accessoryBar()
                : Row(
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
                  ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- 정리 미리보기 ----------------
class PreviewScreen extends StatelessWidget {
  final String presetName;
  final String before;
  final TidyResult result;
  const PreviewScreen({super.key, required this.presetName, required this.before, required this.result});

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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l.apply, style: const TextStyle(fontWeight: FontWeight.w700))),
              ),
            ],
          ),
        ),
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

  Widget _dropRow<T>(String label, String? sub, T value, List<(T, String)> options, ValueChanged<T> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12)) : null,
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

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = store.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _dropRow(l.emphTitle, l.emphSub, s.emphStyle, [
            ('quoteSingle', l.emphQuoteSingle),
            ('quoteDouble', l.emphQuoteDouble),
            ('remove', l.removeLabel),
            ('keep', l.keepLabel),
          ], (v) => s.emphStyle = v),
          _dropRow(l.hrTitle, null, s.hrMode, [
            ('keep', l.keepLabel),
            ('remove', l.removeLabel),
          ], (v) => s.hrMode = v),
          _dropRow(l.headingTitle, null, s.headingMode, [
            ('strip', l.headingStrip),
            ('keep', l.headingKeep),
            ('prefix', l.headingPrefix),
            ('bracket', l.headingBracket),
          ], (v) => s.headingMode = v),
          _dropRow(l.bulletTitle, null, s.bulletChar, [
            ('-', l.bulletHyphen),
            ('·', l.bulletMiddot),
            ('•', l.bulletDot),
            ('◦', l.bulletWhite),
            ('keep', l.bulletKeep),
          ], (v) => s.bulletChar = v),
          _dropRow(l.bulletIndentTitle, null, s.bulletIndent, [
            (2, l.indent2),
            (4, l.indent4),
            (0, l.indentNone),
          ], (v) => s.bulletIndent = v),
          SwitchListTile.adaptive(
            title: Text(l.headingPadTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(l.headingPadSub, style: const TextStyle(fontSize: 12)),
            value: s.headingPad,
            onChanged: (v) {
              s.headingPad = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            title: Text(l.monoEditorTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(l.monoEditorSub, style: const TextStyle(fontSize: 12)),
            value: s.monoEditor,
            onChanged: (v) {
              s.monoEditor = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            title: Text(l.citationsTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(l.citationsSub, style: const TextStyle(fontSize: 12)),
            value: s.removeCitations,
            onChanged: (v) {
              s.removeCitations = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            title: Text(l.dashListTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(l.dashListSub, style: const TextStyle(fontSize: 12)),
            value: s.smartDashList,
            onChanged: (v) {
              s.smartDashList = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            title: Text(l.fillerHeadingTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(l.fillerHeadingSub, style: const TextStyle(fontSize: 12)),
            value: s.smartFillerHeading,
            onChanged: (v) {
              s.smartFillerHeading = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(l.aiSectionTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.aiSectionDesc, style: TextStyle(fontSize: 12, color: context.c.sub)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
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
                DropdownButton<String>(
                  value: s.aiModel,
                  items: const [
                    DropdownMenuItem(value: 'gemini-2.5-flash-lite', child: Text('Gemini Flash-Lite')),
                    DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('Gemini Flash')),
                    DropdownMenuItem(value: 'claude-haiku-4-5-20251001', child: Text('Claude Haiku')),
                    DropdownMenuItem(value: 'claude-sonnet-5', child: Text('Claude Sonnet')),
                    DropdownMenuItem(value: 'gpt-5-mini', child: Text('ChatGPT (GPT-5 Mini)')),
                    DropdownMenuItem(value: 'gpt-5-nano', child: Text('ChatGPT (GPT-5 Nano)')),
                    DropdownMenuItem(value: 'grok-4.1-fast', child: Text('Grok (4.1 Fast)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      s.aiModel = v;
                      store.persistSettings();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(l.rulesSectionTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.rulesSectionDesc, style: TextStyle(fontSize: 12, color: context.c.sub)),
          ),
          for (int i = 0; i < s.customRules.length; i++) _ruleRow(i),
          Padding(
            padding: const EdgeInsets.all(16),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(l.settingsFooter, style: TextStyle(fontSize: 12, color: context.c.sub)),
          ),
          // 버전은 여기서 눈으로 확인한다. 업데이트가 실제로 반영됐는지
          // 이 숫자 하나로 알 수 있어야 한다(소유자 요청 2026-08-12).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: Text(appVersionLabel,
                style: TextStyle(fontSize: 12, color: context.c.sub)),
          ),
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
          Text(l.regexLabel, style: const TextStyle(fontSize: 11)),
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
