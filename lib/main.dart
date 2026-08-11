/// 심플텍스트 (SimpleText) — Flutter MVP
/// AI 답변을 붙여넣으면, 바로 쓸 수 있는 글이 됩니다.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/tidy_engine.dart';

void main() {
  runApp(const SimpleTextApp());
}

const _accent = Color(0xFF2F5FE0);

class SimpleTextApp extends StatelessWidget {
  const SimpleTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '심플텍스트',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _accent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
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
  String emphStyle = 'quoteSingle';
  String hrMode = 'keep';
  String headingMode = 'strip';
  String headingSymbol = '■';
  String bulletChar = '-';
  bool smartDashList = true;
  bool smartFillerHeading = true;
  bool headingPad = true;
  int bulletIndent = 2;
  bool removeCitations = true;
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
        'bulletIndent': bulletIndent,
        'removeCitations': removeCitations,
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
    s.bulletIndent = (j['bulletIndent'] ?? s.bulletIndent) as int;
    s.removeCitations = (j['removeCitations'] ?? s.removeCitations) as bool;
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
    if (o.stripHeadings || o.smartFillerHeading) o.headingPad = s.headingPad;
    if (o.bulletsToDot) o.bulletIndent = s.bulletIndent;
    if (o.removeCitations) o.removeCitations = s.removeCitations;
    return o;
  }

  static Note _seedNote() {
    final body = [
      '심플텍스트 사용법',
      '',
      '1. ChatGPT나 클로드 답변을 복사한 뒤, "붙여넣고 정리"를 누르세요.',
      '2. 정리 미리보기에서 원본과 결과를 비교하고 "적용"을 누르면 끝.',
      '3. 표가 있는 메모는 "표" 버튼으로 스프레드시트용(TSV) 복사가 가능합니다.',
      '4. 모든 정리는 되돌리기 한 번으로 복구됩니다.',
      '',
      '아래는 일부러 깨뜨린 표입니다. "정리"를 눌러 복구를 확인해 보세요.',
      '',
      '| 종목 | 티커 | 수익률 | 비중',
      '|------|------|--------|',
      '| 애플 | AAPL | +14.2% | 12% |',
      '| 마이크로소프트 | MSFT | +21.5%',
      '| 엔비디아 | NVDA | +48.9% | 22% | 추가셀 |',
      '|테슬라|TSLA|-8.3%|8%|',
    ].join('\n');
    final now = DateTime.now().millisecondsSinceEpoch;
    return Note(
      id: 'seed-$now',
      title: '심플텍스트에 오신 것을 환영합니다',
      body: body,
      originalBody: body,
      pinned: true,
      tags: ['사용법'],
      createdAt: now,
      updatedAt: now,
    );
  }
}

String _fmtDate(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String p(int x) => x.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
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
      if (mounted) _toast(context, '클립보드가 비어 있습니다. AI 답변을 먼저 복사해 주세요.');
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
      appBar: AppBar(
        title: const Text('심플텍스트', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '정리 규칙 설정',
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '메모 검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: (pinned.isEmpty && rest.isEmpty)
                      ? const Center(child: Text('메모가 없습니다.\n"붙여넣고 정리"로 시작해 보세요.', textAlign: TextAlign.center))
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            if (pinned.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                                child: Text('고정됨', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                              ),
                            ...pinned.map(_noteTile),
                            if (rest.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                                child: Text('메모', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                              ),
                            ...rest.map(_noteTile),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'new',
            tooltip: '새 메모',
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
            label: const Text('붙여넣고 정리', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _noteTile(Note n) {
    final firstLine = n.body.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    final meta = <String>[
      if (n.source.isNotEmpty) n.source,
      if (n.tags.isNotEmpty) n.tags.map((t) => '#$t').join(' '),
      _fmtDate(n.updatedAt),
    ].join(' · ');
    return ListTile(
      title: Text(
        n.title.isNotEmpty ? n.title : (firstLine.isNotEmpty ? firstLine : '제목 없음'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(firstLine, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(meta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: n.pinned ? const Icon(Icons.push_pin, size: 16, color: _accent) : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(noteId: n.id))),
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
    if (widget.autoTidy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTidyWithPreset(buildPresets().first));
    }
  }

  @override
  void dispose() {
    titleCtl.dispose();
    bodyCtl.dispose();
    tagsCtl.dispose();
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
    final apply = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PreviewScreen(presetName: preset.name, before: note.body, result: r)),
    );
    if (apply == true) {
      note.history.add(note.body);
      if (note.history.length > 30) note.history.removeAt(0);
      if (note.originalBody.isEmpty) note.originalBody = note.body;
      note.body = r.text;
      note.lastReport = r.summary;
      if (note.title.isEmpty) {
        note.title = r.text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
        if (note.title.length > 40) note.title = note.title.substring(0, 40);
        titleCtl.text = note.title;
      }
      bodyCtl.text = note.body;
      await _save();
      if (mounted) {
        setState(() {});
        _toast(context, '적용 완료 — ${r.summary}');
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
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.desc, style: const TextStyle(fontSize: 12)),
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
            ? const Padding(padding: EdgeInsets.all(30), child: Text('이 메모에서 표를 찾지 못했습니다.'))
            : ListView(
                shrinkWrap: true,
                children: [
                  for (int i = 0; i < r.tables.length; i++)
                    ListTile(
                      title: Text('표 ${i + 1} — ${r.tables[i].header.length}열 × ${r.tables[i].rows.length}행'),
                      subtitle: Wrap(spacing: 8, children: [
                        FilledButton.tonal(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToTSV(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, '복사 완료 — 구글 시트나 엑셀 셀에 붙여넣으세요');
                          },
                          child: const Text('스프레드시트용'),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToCSV(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, 'CSV로 복사했습니다');
                          },
                          child: const Text('CSV'),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: tableToMarkdown(r.tables[i])));
                            Navigator.pop(ctx);
                            _toast(context, 'Markdown 표로 복사했습니다');
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

  void _showCopyMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('전체 복사'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: bodyCtl.text));
                Navigator.pop(ctx);
                _toast(context, '전체 텍스트를 복사했습니다');
              },
            ),
            ListTile(
              title: const Text('정리해서 복사'),
              subtitle: const Text('메모는 그대로 두고, 정리된 결과만 복사', style: TextStyle(fontSize: 12)),
              onTap: () {
                final r = tidy(bodyCtl.text, store.effOpts(buildPresets().first));
                Clipboard.setData(ClipboardData(text: r.text));
                Navigator.pop(ctx);
                _toast(context, '정리해서 복사했습니다 — ${r.summary}');
              },
            ),
            ListTile(
              title: const Text('표를 스프레드시트용으로 복사'),
              onTap: () {
                final r = extractTables(bodyCtl.text);
                Navigator.pop(ctx);
                if (r.tables.isEmpty) {
                  _toast(context, '이 메모에서 표를 찾지 못했습니다');
                } else {
                  Clipboard.setData(ClipboardData(text: r.tables.map(tableToTSV).join('\n\n')));
                  _toast(context, '표를 스프레드시트용으로 복사했습니다');
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
    if (!_found) {
      return const Scaffold(body: Center(child: Text('메모를 찾을 수 없습니다')));
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: titleCtl,
            decoration: const InputDecoration(hintText: '제목', border: InputBorder.none),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            onChanged: (_) => _save(),
          ),
          actions: [
            IconButton(
              icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: note.pinned ? '상단 고정 해제' : '리스트 상단 고정',
              onPressed: () async {
                note.pinned = !note.pinned;
                await store.persist();
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('이 메모를 삭제할까요?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: note.source.isEmpty ? '' : note.source,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('출처 없음')),
                      DropdownMenuItem(value: 'ChatGPT', child: Text('ChatGPT')),
                      DropdownMenuItem(value: 'Claude', child: Text('Claude')),
                      DropdownMenuItem(value: 'Gemini', child: Text('Gemini')),
                      DropdownMenuItem(value: 'Grok', child: Text('Grok')),
                      DropdownMenuItem(value: 'Perplexity', child: Text('Perplexity')),
                      DropdownMenuItem(value: '기타', child: Text('기타')),
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
                      decoration: const InputDecoration(hintText: '태그 (쉼표로 구분)', isDense: true),
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
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(hintText: '여기에 붙여넣거나 입력하세요', border: InputBorder.none),
                  style: const TextStyle(fontSize: 16, height: 1.6),
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
                      style: const TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _showPresetSheet,
                  child: const Text('정리', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              Expanded(child: TextButton(onPressed: _showTables, child: const Text('표'))),
              Expanded(child: TextButton(onPressed: _showCopyMenu, child: const Text('복사'))),
              Expanded(
                child: TextButton(
                  onPressed: note.history.isEmpty
                      ? null
                      : () async {
                          note.body = note.history.removeLast();
                          note.lastReport = '';
                          bodyCtl.text = note.body;
                          await _save();
                          setState(() {});
                          if (mounted) _toast(context, '이전 버전으로 되돌렸습니다');
                        },
                  child: const Text('되돌리기'),
                ),
              ),
            ],
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
    return Scaffold(
      appBar: AppBar(title: Text('$presetName — 미리보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FD), borderRadius: BorderRadius.circular(10)),
            child: Text(result.summary,
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          for (final w in result.warnings)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFDF3E7), borderRadius: BorderRadius.circular(10)),
              child: Text('주의: $w',
                  style: const TextStyle(color: Color(0xFF9A6A1F), fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 14),
          const Text('정리 결과', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF6F6F4),
                border: Border.all(color: const Color(0xFFE4E4E0)),
                borderRadius: BorderRadius.circular(10)),
            child: SelectableText(result.text, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
          const SizedBox(height: 14),
          const Text('원본', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF6F6F4),
                border: Border.all(color: const Color(0xFFE4E4E0)),
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
                    onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('적용', style: TextStyle(fontWeight: FontWeight.w700))),
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
    final s = store.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('정리 규칙 설정')),
      body: ListView(
        children: [
          _dropRow('굵은 강조 (**텍스트**)', '40자 초과 문장 전체 강조는 항상 마커만 제거', s.emphStyle, const [
            ('quoteSingle', "작은따옴표 '강조'"),
            ('quoteDouble', '큰따옴표 "강조"'),
            ('remove', '제거'),
            ('keep', '유지'),
          ], (v) => s.emphStyle = v),
          _dropRow('구분선 (---)', null, s.hrMode, const [
            ('keep', '유지'),
            ('remove', '제거'),
          ], (v) => s.hrMode = v),
          _dropRow('제목 (#, ##)', null, s.headingMode, const [
            ('strip', '텍스트만 남기기'),
            ('keep', '그대로 유지'),
            ('prefix', '■ 기호 붙이기'),
            ('bracket', '[대괄호]'),
          ], (v) => s.headingMode = v),
          _dropRow('글머리 기호 (-, *)', null, s.bulletChar, const [
            ('-', '하이픈 -'),
            ('·', '가운뎃점 ·'),
            ('•', '불릿 •'),
            ('◦', '흰 불릿 ◦'),
            ('keep', '원래 기호 유지'),
          ], (v) => s.bulletChar = v),
          _dropRow('글머리 들여쓰기', null, s.bulletIndent, const [
            (2, '2칸'),
            (4, '4칸'),
            (0, '없음'),
          ], (v) => s.bulletIndent = v),
          SwitchListTile(
            title: const Text('소제목 여백', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('위 2줄·아래 1줄, 투명 문자(ㅤ)라 카톡·블로그에서도 유지', style: TextStyle(fontSize: 12)),
            value: s.headingPad,
            onChanged: (v) {
              s.headingPad = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('출처 링크 제거', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('[1]: URL 출처 블록과 본문 [1] 표시 제거', style: TextStyle(fontSize: 12)),
            value: s.removeCitations,
            onChanged: (v) {
              s.removeCitations = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('대시 나열 목록화', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('"– a – b – c" 한 줄 나열을 줄 목록으로 분리', style: TextStyle(fontSize: 12)),
            value: s.smartDashList,
            onChanged: (v) {
              s.smartDashList = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('투명 문자 소제목 정리', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('ㅤ로 감싼 유사 소제목에 여백·제목 규칙 적용', style: TextStyle(fontSize: 12)),
            value: s.smartFillerHeading,
            onChanged: (v) {
              s.smartFillerHeading = v;
              store.persistSettings();
              setState(() {});
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text('사용자 치환 규칙', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('위에서부터 순서대로 적용. 바꾸기에 \\n을 쓰면 줄바꿈. 코드블록 안은 건드리지 않습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              label: const Text('규칙 추가'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: Text('설정은 저장 즉시 반영되며, 이후 "정리"를 실행할 때부터 적용됩니다. 이미 정리해 둔 메모는 소급해서 바뀌지 않습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(int i) {
    final s = store.settings;
    final r = s.customRules[i];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: r.find,
              decoration: const InputDecoration(hintText: '찾기', isDense: true),
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
              decoration: const InputDecoration(hintText: '바꾸기', isDense: true),
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
          const Text('정규식', style: TextStyle(fontSize: 11)),
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
