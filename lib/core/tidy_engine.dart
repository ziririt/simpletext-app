/// =====================================================================
/// 심플텍스트 (SimpleText) — Tidy Engine + Table Engine (Dart)
/// 웹 프로토타입 engine.js에서 이식. 동일한 테스트 스위트로 검증됨.
/// Pure Dart. 플랫폼 API 호출 없음. (기획서 39절 원칙)
/// =====================================================================
library tidy_engine;

class CustomRule {
  final String find;
  final String replace;
  final bool regex;
  const CustomRule({required this.find, this.replace = '', this.regex = false});
}

class TidyOptions {
  bool stripHeadings;
  bool stripEmphasis;
  bool bulletsToDot;
  bool stripQuotes;
  bool removeHr;
  bool removeEmoji;
  bool removePreamble;
  bool repairTables;
  bool tablesToTSV;
  bool tablesOnly;
  bool detectRecords; // 풀어쓴 표도 표로 인식 (표 도구 전용 — 본문 오탐 방지)
  String wideTables; // auto | aligned | records
  String linkMode; // keep | text | textUrl
  bool stripHtml;
  bool unescape;
  bool smartPunct;
  bool removeOuterFence;
  bool normalizeWhitespace;
  String emphStyle; // remove | quoteSingle | quoteDouble | keep
  String hrMode; // '' | keep | remove
  String headingMode; // '' | strip | keep | prefix | bracket
  String headingSymbol;
  String bulletChar; // '·' | '•' | '◦' | '-' | 'keep'
  bool smartDashList;
  bool smartFillerHeading;
  List<CustomRule>? customRules;
  bool headingPad;
  int headingPadAbove;
  int headingPadBelow;
  String headingPadChar;
  int bulletIndent;
  bool removeCitations;
  bool inlineCites = false; // 내부용: 출처 정의 존재 시 본문 [n] 제거

  TidyOptions({
    this.stripHeadings = false,
    this.stripEmphasis = false,
    this.bulletsToDot = false,
    this.stripQuotes = false,
    this.removeHr = false,
    this.removeEmoji = false,
    this.removePreamble = false,
    this.repairTables = false,
    this.tablesToTSV = false,
    this.tablesOnly = false,
    this.detectRecords = false,
    this.wideTables = 'auto',
    this.linkMode = 'keep',
    this.stripHtml = false,
    this.unescape = false,
    this.smartPunct = false,
    this.removeOuterFence = false,
    this.normalizeWhitespace = true,
    this.emphStyle = 'remove',
    this.hrMode = '',
    this.headingMode = '',
    this.headingSymbol = '■',
    this.bulletChar = '·',
    this.smartDashList = false,
    this.smartFillerHeading = false,
    this.customRules,
    this.headingPad = false,
    this.headingPadAbove = 2,
    this.headingPadBelow = 1,
    this.headingPadChar = 'ㅤ',
    this.bulletIndent = 0,
    this.removeCitations = false,
  });

  TidyOptions copyWith({
    bool? stripHeadings,
    bool? stripEmphasis,
    bool? bulletsToDot,
    bool? stripQuotes,
    bool? removeHr,
    bool? removeEmoji,
    bool? removePreamble,
    bool? repairTables,
    bool? tablesToTSV,
    bool? tablesOnly,
    bool? detectRecords,
    String? wideTables,
    String? linkMode,
    bool? stripHtml,
    bool? unescape,
    bool? smartPunct,
    bool? removeOuterFence,
    bool? normalizeWhitespace,
    String? emphStyle,
    String? hrMode,
    String? headingMode,
    String? headingSymbol,
    String? bulletChar,
    bool? smartDashList,
    bool? smartFillerHeading,
    List<CustomRule>? customRules,
    bool? headingPad,
    int? headingPadAbove,
    int? headingPadBelow,
    String? headingPadChar,
    int? bulletIndent,
    bool? removeCitations,
  }) {
    return TidyOptions(
      stripHeadings: stripHeadings ?? this.stripHeadings,
      stripEmphasis: stripEmphasis ?? this.stripEmphasis,
      bulletsToDot: bulletsToDot ?? this.bulletsToDot,
      stripQuotes: stripQuotes ?? this.stripQuotes,
      removeHr: removeHr ?? this.removeHr,
      removeEmoji: removeEmoji ?? this.removeEmoji,
      removePreamble: removePreamble ?? this.removePreamble,
      repairTables: repairTables ?? this.repairTables,
      tablesToTSV: tablesToTSV ?? this.tablesToTSV,
      tablesOnly: tablesOnly ?? this.tablesOnly,
      detectRecords: detectRecords ?? this.detectRecords,
      wideTables: wideTables ?? this.wideTables,
      linkMode: linkMode ?? this.linkMode,
      stripHtml: stripHtml ?? this.stripHtml,
      unescape: unescape ?? this.unescape,
      smartPunct: smartPunct ?? this.smartPunct,
      removeOuterFence: removeOuterFence ?? this.removeOuterFence,
      normalizeWhitespace: normalizeWhitespace ?? this.normalizeWhitespace,
      emphStyle: emphStyle ?? this.emphStyle,
      hrMode: hrMode ?? this.hrMode,
      headingMode: headingMode ?? this.headingMode,
      headingSymbol: headingSymbol ?? this.headingSymbol,
      bulletChar: bulletChar ?? this.bulletChar,
      smartDashList: smartDashList ?? this.smartDashList,
      smartFillerHeading: smartFillerHeading ?? this.smartFillerHeading,
      customRules: customRules ?? this.customRules,
      headingPad: headingPad ?? this.headingPad,
      headingPadAbove: headingPadAbove ?? this.headingPadAbove,
      headingPadBelow: headingPadBelow ?? this.headingPadBelow,
      headingPadChar: headingPadChar ?? this.headingPadChar,
      bulletIndent: bulletIndent ?? this.bulletIndent,
      removeCitations: removeCitations ?? this.removeCitations,
    );
  }
}

class Preset {
  final String id;
  final String name;
  final String desc;
  final TidyOptions opts;
  const Preset({required this.id, required this.name, required this.desc, required this.opts});
}

class TableGrid {
  final List<String> header;
  final List<String> aligns; // left | center | right
  final List<List<String>> rows;
  final bool repaired;
  const TableGrid({required this.header, required this.aligns, required this.rows, required this.repaired});
}

class TidyReport {
  int markers = 0;
  int headings = 0;
  int emoji = 0;
  int tablesRepaired = 0;
  int preamble = 0;
  int citations = 0;
}

class TidyResult {
  final String text;
  final String summary;
  final List<String> warnings;
  final List<TableGrid> tables;
  final TidyReport report;
  const TidyResult({required this.text, required this.summary, required this.warnings, required this.tables, required this.report});
}

/// ---------------- 프리셋 5종 (기획서 22절) ----------------
List<Preset> buildPresets() => [
      Preset(id: 'ai', name: 'AI 답변 정리', desc: '마크다운 마커·이모지·AI 서두 제거, 표 복구', opts: TidyOptions(
        stripHeadings: true, stripEmphasis: true, bulletsToDot: true, stripQuotes: true,
        removeHr: true, removeEmoji: true, removePreamble: true, repairTables: true,
        linkMode: 'text', stripHtml: true, unescape: true, removeOuterFence: true,
        smartDashList: true, smartFillerHeading: true, removeCitations: true)),
      Preset(id: 'strip', name: 'Markdown 완전 제거', desc: '마크다운 문법 최대 제거, 표는 TSV로', opts: TidyOptions(
        stripHeadings: true, stripEmphasis: true, bulletsToDot: true, stripQuotes: true,
        removeHr: true, repairTables: true, tablesToTSV: true,
        linkMode: 'text', stripHtml: true, unescape: true, removeOuterFence: true,
        smartDashList: true, smartFillerHeading: true, removeCitations: true)),
      Preset(id: 'minimal', name: '최소 정리', desc: '구조 보존, 잡티(공백·제로폭 문자 등)만 제거', opts: TidyOptions(
        removeOuterFence: true)),
      Preset(id: 'tables', name: '표만 뽑기', desc: '문서에서 표를 추출해 TSV로', opts: TidyOptions(
        tablesOnly: true, repairTables: true, removeOuterFence: true)),
      Preset(id: 'blog', name: '블로그 붙여넣기', desc: '마커 제거, 링크는 주소 유지, 표 복구', opts: TidyOptions(
        stripHeadings: true, stripEmphasis: true, bulletsToDot: true, stripQuotes: true,
        removeHr: true, removePreamble: true, repairTables: true,
        linkMode: 'textUrl', stripHtml: true, unescape: true, removeOuterFence: true,
        smartDashList: true, smartFillerHeading: true, removeCitations: true)),
    ];

/// ================= 유틸 =================
final RegExp _emojiRe = RegExp(
    r'(\p{Regional_Indicator}{2}|\p{Extended_Pictographic}(?:[\u{1F3FB}-\u{1F3FF}])?(?:\uFE0F)?(?:\u200D\p{Extended_Pictographic}(?:\uFE0F)?)*|[\u2600-\u27BF]\uFE0F?|[0-9#*]\uFE0F?\u20E3)',
    unicode: true);
final RegExp _zwWithZwj = RegExp('[\u200B\u200C\u200D\u200E\u200F\u2060\uFEFF]');
final RegExp _zwNoZwj = RegExp('[\u200B\u200C\u200E\u200F\u2060\uFEFF]');

T _mode<T extends Comparable>(List<T> arr) {
  final m = <T, int>{};
  T best = arr[0];
  int bestN = 0;
  for (final v in arr) {
    final n = (m[v] ?? 0) + 1;
    m[v] = n;
    if (n > bestN || (n == bestN && v.compareTo(best) < 0)) {
      best = v;
      bestN = n;
    }
  }
  return best;
}

String _grp(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// ============ 03. Outer Fence Detection ============
({String text, bool removed}) _stripOuterFence(String text) {
  final lines = text.split('\n');
  int s = 0, e = lines.length - 1;
  while (s <= e && lines[s].trim().isEmpty) s++;
  while (e >= s && lines[e].trim().isEmpty) e--;
  if (e - s < 1) return (text: text, removed: false);
  final first = lines[s].trim(), last = lines[e].trim();
  final mOpen = RegExp(r'^(`{3,}|~{3,})\s*([A-Za-z0-9_-]*)\s*$').firstMatch(first);
  if (mOpen == null || !RegExp(r'^(`{3,}|~{3,})$').hasMatch(last)) {
    return (text: text, removed: false);
  }
  final lang = (mOpen.group(2) ?? '').toLowerCase();
  final fenceCount = lines.sublist(s, e + 1).where((l) => RegExp(r'^\s*(```|~~~)').hasMatch(l)).length;
  const wrapperLangs = ['markdown', 'md', 'text', 'txt', 'plaintext', ''];
  if (!wrapperLangs.contains(lang)) return (text: text, removed: false);
  if (lang == '' && fenceCount > 2) return (text: text, removed: false);
  if ((fenceCount - 2) % 2 != 0) return (text: text, removed: false);
  return (text: lines.sublist(s + 1, e).join('\n'), removed: true);
}

/// ============ 04. Protected Segment Split (FenceSplitter) ============
class _Segment {
  final String type; // 'code' | 'text'
  List<String> lines;
  _Segment(this.type, this.lines);
}

List<_Segment> _splitSegments(String text) {
  final lines = text.split('\n');
  final segs = <_Segment>[];
  var buf = <String>[];
  bool inCode = false;
  String fenceMark = '';
  void push(String type) {
    if (buf.isNotEmpty) {
      segs.add(_Segment(type, buf));
      buf = <String>[];
    }
  }

  for (final line in lines) {
    final m = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
    if (!inCode && m != null) {
      push('text');
      inCode = true;
      fenceMark = m.group(1)![0] * 3;
      buf.add(line);
    } else if (inCode && m != null && line.trim().startsWith(fenceMark)) {
      buf.add(line);
      push('code');
      inCode = false;
    } else {
      buf.add(line);
    }
  }
  push(inCode ? 'code' : 'text');
  return segs;
}

/// ============ 05. AI Preamble Detection (보수적) ============
final RegExp _preambleStart = RegExp(
    r"^(네[,.!\s]|넵[,.!\s]|물론(입니다|이죠|이에요)|알겠(습니다|어요)|안녕하세요|좋(습니다|아요)[,.!\s]|요청하신|말씀하신|아래는|다음은|정리해\s?드리|설명해\s?드리|도와드리|Sure[,.!\s]|Of course[,.!\s]|Certainly[,.!\s]|Absolutely[,.!\s]|Here('s| is| are)\b|Below (is|are)\b|I('|’)?ve\b|I('|’)?d be happy\b|Great question)",
    caseSensitive: false);
final RegExp _preambleEnd = RegExp(r'(:|：|(습니다|입니다|드릴게요|드리겠습니다|볼게요|할게요|겠습니다)[.!]?|[.!?:])\s*$');

int _detectPreamble(List<String> lines) {
  int idx = 0;
  while (idx < lines.length && lines[idx].trim().isEmpty) idx++;
  if (idx >= lines.length) return -1;
  final line = lines[idx].trim();
  if (line.isEmpty || line.length > 90) return -1;
  if (!_preambleStart.hasMatch(line)) return -1;
  if (!_preambleEnd.hasMatch(line)) return -1;
  int j = idx + 1;
  while (j < lines.length && lines[j].trim().isEmpty) j++;
  if (j >= lines.length) return -1;
  final next = lines[j].trim();
  final structured = RegExp(r'^(#{1,6}\s|[-*+]\s|\d+[.)]\s|\||>|\*\*|`|=|—|-{3,})').hasMatch(next) ||
      (idx + 1 < lines.length && lines[idx + 1].isEmpty) ||
      line.endsWith(':') ||
      line.endsWith('：');
  if (!structured) return -1;
  return idx;
}

/// ================= Table Engine =================
bool _hasUnescapedPipe(String line) => RegExp(r'(?<!\\)\|').hasMatch(line);

List<String> _splitCells(String line) {
  var s = line.trim();
  if (s.startsWith('|')) s = s.substring(1);
  if (RegExp(r'(?<!\\)\|$').hasMatch(s)) {
    s = s.replaceFirst(RegExp(r'(?<!\\)\|$'), '');
  }
  return s.split(RegExp(r'(?<!\\)\|')).map((c) => c.trim().replaceAll(r'\|', '|')).toList();
}

bool _isSeparatorCells(List<String> cells) =>
    cells.isNotEmpty &&
    cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c) && c.replaceAll(':', '').isNotEmpty);

class _Block {
  final int start;
  final int end;
  final String kind; // 'pipe' | 'aligned' | 'record'
  final List<_RecordGroup> records = []; // kind == 'record'일 때만 채워진다
  _Block(this.start, this.end, [this.kind = 'pipe']);
}

/// --------- 탭으로 구분된 표 (ChatGPT·클로드 앱에서 복사하면 이렇게 온다) ---------
/// 2026-08-12 — 실제 사용 중 발견. 앱에서 렌더된 표를 복사하면 마크다운 파이프가
/// 아니라 탭으로 넘어온다. 탐지가 '|'와 '─'만 보고 있어서 표를 통째로 놓쳤고,
/// 사용자 화면에서 표가 줄글로 뭉개졌다. 붙여넣기의 가장 흔한 경로라 반드시 잡아야 한다.
List<String> _splitTsvCells(String line) =>
    line.split('\t').map((c) => c.trim()).toList();

List<_Block> _detectTsvBlocks(List<String> lines) {
  final blocks = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    final cells = lines[i].contains('\t') ? _splitTsvCells(lines[i]) : <String>[];
    if (cells.where((c) => c.isNotEmpty).length >= 2) {
      var j = i;
      while (j + 1 < lines.length &&
          lines[j + 1].contains('\t') &&
          lines[j + 1].trim().isNotEmpty) {
        j++;
      }
      // 한 줄짜리는 표로 보지 않는다(들여쓰기용 탭 한 줄 등 오탐 방지)
      if (j > i) blocks.add(_Block(i, j, 'tsv'));
      i = j + 1;
    } else {
      i++;
    }
  }
  return blocks;
}

TableGrid _parseTsvTable(List<String> lines, String Function(String)? cellClean) {
  String clean(String c) => cellClean != null ? cellClean(c) : c;
  final rows = lines.map(_splitTsvCells).toList();
  var colCount = 0;
  for (final r in rows) {
    if (r.length > colCount) colCount = r.length;
  }
  List<String> fit(List<String> r) {
    final c = r.take(colCount).toList();
    while (c.length < colCount) {
      c.add('');
    }
    return c.map(clean).toList();
  }

  return TableGrid(
    header: fit(rows.first),
    aligns: List<String>.filled(colCount, 'left'),
    rows: rows.skip(1).map(fit).toList(),
    repaired: false,
  );
}

/// --------- 정렬 텍스트 표 되읽기 (round-trip) ---------
/// 2026-08-12 — tableToAligned가 만든 공백 정렬 표를 다시 표로 인식한다.
/// 이게 없으면 "정리" 직후 표 도구가 표를 못 찾아 스프레드시트 복사가 끊긴다
/// (실제로 그 상태로 웹이 한 번 배포됐다). 엔진이 만든 형식은 엔진이 되읽을 수 있어야 한다.
/// 셀 안에는 연속 공백이 없도록 생성하므로(_alignCell), 2칸 이상 공백 = 열 구분자.
bool _isAlignedRule(String line) => RegExp(r'^─{3,}$').hasMatch(line.trim());

List<String> _splitAlignedCells(String line) =>
    line.trim().split(RegExp(r' {2,}')).map((c) => c.trim()).toList();

List<_Block> _detectAlignedBlocks(List<String> lines) {
  final blocks = <_Block>[];
  for (int i = 1; i < lines.length; i++) {
    if (!_isAlignedRule(lines[i])) continue;
    final header = lines[i - 1];
    if (header.trim().isEmpty || _splitAlignedCells(header).length < 2) continue;
    int j = i + 1;
    while (j < lines.length && lines[j].trim().isNotEmpty) {
      j++;
    }
    if (j - (i + 1) < 1) continue;
    // 데이터 줄 중 하나 이상이 2열 이상이어야 표로 본다(─ 장식선 오탐 방지)
    int multi = 0;
    for (int k = i + 1; k < j; k++) {
      if (_splitAlignedCells(lines[k]).length >= 2) multi++;
    }
    if (multi < 1) continue;
    blocks.add(_Block(i - 1, j - 1, 'aligned'));
    i = j;
  }
  return blocks;
}

TableGrid _parseAlignedTable(List<String> lines, String Function(String)? cellClean) {
  String clean(String c) => cellClean != null ? cellClean(c) : c;
  final header = _splitAlignedCells(lines[0]);
  final colCount = header.length;
  final rows = <List<String>>[];
  for (int k = 2; k < lines.length; k++) {
    if (lines[k].trim().isEmpty) continue;
    var cells = _splitAlignedCells(lines[k]);
    if (cells.length > colCount) {
      cells = [...cells.take(colCount - 1), cells.skip(colCount - 1).join(' ')];
    }
    while (cells.length < colCount) {
      cells.add('');
    }
    rows.add(cells.map(clean).toList());
  }
  return TableGrid(
    header: header.map(clean).toList(),
    aligns: List<String>.filled(colCount, 'left'),
    rows: rows,
    repaired: false,
  );
}

List<_Block> _detectTableBlocks(List<String> lines, bool withRecords) {
  final blocks = <_Block>[];
  int i = 0;
  while (i < lines.length) {
    if (_hasUnescapedPipe(lines[i]) && _splitCells(lines[i]).length >= 2) {
      int j = i;
      while (j + 1 < lines.length && _hasUnescapedPipe(lines[j + 1]) && lines[j + 1].trim().isNotEmpty) {
        j++;
      }
      final rowCount = j - i + 1;
      if (rowCount >= 2) {
        int multi = 0;
        for (int k = i; k <= j; k++) {
          if (_splitCells(lines[k]).length >= 2) multi++;
        }
        final threshold = (rowCount * 0.6).ceil();
        if (multi >= (threshold > 2 ? threshold : 2)) blocks.add(_Block(i, j));
      }
      i = j + 1;
    } else {
      i++;
    }
  }
  // 정렬 텍스트 표도 함께 인식 (파이프 블록과 겹치지 않는 구간만)
  final taken = <int>{};
  for (final b in blocks) {
    for (int k = b.start; k <= b.end; k++) {
      taken.add(k);
    }
  }
  void addIfFree(_Block b) {
    for (int k = b.start; k <= b.end; k++) {
      if (taken.contains(k)) return;
    }
    for (int k = b.start; k <= b.end; k++) {
      taken.add(k);
    }
    blocks.add(b);
  }

  for (final b in _detectAlignedBlocks(lines)) {
    addIfFree(b);
  }
  for (final b in _detectTsvBlocks(lines)) {
    addIfFree(b);
  }
  if (withRecords) {
    for (final b in _detectRecordBlocks(lines)) {
      addIfFree(b);
    }
  }
  blocks.sort((a, b) => a.start.compareTo(b.start));
  return blocks;
}

TableGrid _parseTable(List<String> lines, List<String> warnings, String Function(String)? cellClean) {
  bool repaired = false;
  final rawRows = lines.map(_splitCells).toList();
  int sepIdx = -1;
  for (int k = 0; k < rawRows.length; k++) {
    if (_isSeparatorCells(rawRows[k])) {
      sepIdx = k;
      break;
    }
  }
  List<String> header;
  List<List<String>> dataRows;
  List<String>? sepCells;
  if (sepIdx > 0) {
    header = rawRows[sepIdx - 1];
    sepCells = rawRows[sepIdx];
    dataRows = [...rawRows.sublist(0, sepIdx - 1), ...rawRows.sublist(sepIdx + 1)];
  } else {
    header = rawRows[0];
    dataRows = rawRows.sublist(1);
    repaired = true;
    warnings.add('구분선 1개 생성');
  }
  dataRows = dataRows.where((r) => !(r.length == 1 && r[0].isEmpty)).toList();
  final counts = <int>[header.length, ...dataRows.map((r) => r.length)];
  int colCount = _mode(counts);
  if (header.length > colCount) colCount = header.length;
  if (sepCells != null && sepCells.length != colCount) repaired = true;
  final aligns = List<String>.filled(colCount, 'left');
  if (sepCells != null) {
    for (int ci = 0; ci < colCount && ci < sepCells.length; ci++) {
      final c = sepCells[ci];
      final l = c.startsWith(':'), r = c.endsWith(':');
      aligns[ci] = l && r ? 'center' : (r ? 'right' : 'left');
    }
  }
  List<String> fix(List<String> row) {
    if (row.length < colCount) {
      repaired = true;
      return [...row, ...List.filled(colCount - row.length, '')];
    }
    if (row.length > colCount) {
      repaired = true;
      final extra = row.length - colCount;
      final merged = [...row.sublist(0, colCount - 1), row.sublist(colCount - 1).join(' ')];
      final label = row[0].trim().isEmpty ? '행' : row[0].trim();
      warnings.add('$label 행에서 초과 셀 $extra개 병합');
      return merged;
    }
    return row;
  }

  if (header.length != colCount) header = fix(header);
  int padded = 0;
  dataRows = dataRows.map((r) {
    final before = r.length;
    final f = fix(r);
    if (before < colCount) padded++;
    return f;
  }).toList();
  if (padded > 0) warnings.add('행 $padded개 보정');
  String clean(String c) => cellClean != null ? cellClean(c) : c;
  return TableGrid(
    header: header.map(clean).toList(),
    aligns: aligns,
    rows: dataRows.map((r) => r.map(clean).toList()).toList(),
    repaired: repaired,
  );
}

/// --------- Table Export (Aligned / Markdown / TSV / CSV / HTML) ---------
String _rowToMd(List<String> cells) =>
    '|' + cells.map((c) => c.isEmpty ? ' ' : ' $c ').join('|') + '|';

String tableToMarkdown(TableGrid t) {
  final sep = t.aligns.map((a) => a == 'center' ? ':---:' : (a == 'right' ? '---:' : '---')).toList();
  return [_rowToMd(t.header), _rowToMd(sep), ...t.rows.map(_rowToMd)].join('\n');
}

String _flat(String c) => c.replaceAll(RegExp(r'[\t\n\r]+'), ' ');

/// 표시폭: 한글·CJK·전각·이모지는 2칸, 그 외는 1칸.
/// 등폭 글꼴에서 열을 맞추려면 문자 수가 아니라 이 폭으로 패딩해야 한다
/// (한글 '종목'은 2글자지만 등폭에서 4칸을 차지한다).
int dispWidth(String s) {
  var w = 0;
  for (final c in s.runes) {
    final wide = c >= 0x1100 &&
        (c <= 0x115F || // 한글 자모
            c == 0x2329 ||
            c == 0x232A ||
            (c >= 0x2E80 && c <= 0xA4CF && c != 0x303F) || // CJK 부수~이체자
            (c >= 0xAC00 && c <= 0xD7A3) || // 한글 음절
            (c >= 0xF900 && c <= 0xFAFF) || // CJK 호환 한자
            (c >= 0xFE30 && c <= 0xFE4F) || // CJK 호환 형식
            (c >= 0xFF00 && c <= 0xFF60) || // 전각 형식
            (c >= 0xFFE0 && c <= 0xFFE6) ||
            (c >= 0x1F300 && c <= 0x1FAFF) || // 이모지
            (c >= 0x20000 && c <= 0x3FFFD)); // CJK 확장 B+
    w += wide ? 2 : 1;
  }
  return w;
}

String _padDisp(String s, int width) {
  final pad = width - dispWidth(s);
  return pad > 0 ? s + ' ' * pad : s;
}

/// 세로 구분자 없이 공백만으로 각 열을 좌측 정렬하고,
/// 헤더 아래에 가로 구분선(─────)을 넣은 정렬 텍스트 표.
///
/// 2026-08-12 — 표 복구의 기본 출력이 파이프 마크다운(| a | b |)이었는데,
/// 일반 사용자에게는 그 구분줄(| --- |)이 "고장 난 표"로 보였다. 그래서
/// 세로선을 없애고 공백 정렬로 바꿨다. 웹(index.html)에 먼저 넣고 동일 적용한 것이며,
/// 엔진 수정은 JS·Dart 양쪽 대칭 유지가 제1규칙이다(HANDOVER 5절).
/// 되돌리기 전에: 이 형식은 사용자가 화면을 보고 확정한 것이다.
String tableToAligned(TableGrid t) {
  const gap = '  '; // 열 사이 간격(공백 2칸)
  // 셀 안의 연속 공백은 1칸으로 줄인다 — 그래야 "2칸 이상 = 열 구분자"가 성립해
  // 되읽기(_parseAlignedTable)가 셀 내용과 구분자를 헷갈리지 않는다.
  String alignCell(String c) => _flat(c).replaceAll(RegExp(r' {2,}'), ' ');
  final header = t.header.map(alignCell).toList();
  final dataRows = t.rows.map((r) => r.map(alignCell).toList()).toList();
  final cols = t.header.length;
  final widths = List<int>.filled(cols, 0);
  for (final r in [header, ...dataRows]) {
    for (var i = 0; i < cols; i++) {
      final w = dispWidth(i < r.length ? r[i] : '');
      if (w > widths[i]) widths[i] = w;
    }
  }
  String fmtRow(List<String> r) {
    final cells = <String>[];
    for (var i = 0; i < cols; i++) {
      cells.add(_padDisp(i < r.length ? r[i] : '', widths[i]));
    }
    // 좌측 정렬 + 마지막 열 뒤 공백 제거
    return cells.join(gap).replaceAll(RegExp(r'\s+$'), '');
  }

  final total = widths.fold<int>(0, (a, b) => a + b) + gap.length * (cols - 1);
  // '─'(U+2500)는 D2Coding에서 정확히 한 칸으로 그려진다(2026-08-14 측정).
  // 한때 두 칸으로 오해해 절반만 찍었다가 선이 짧아졌다. 표 폭만큼 그대로 찍는다.
  final rule = '─' * total;
  return [fmtRow(header), rule, ...dataRows.map(fmtRow)].join('\n');
}

/// --------- 넓은 표: 행 단위 풀어쓰기 (record view) ---------
/// 칸 맞추기는 셀에 문장이 들어가는 순간 화면 밖으로 나가 줄이 접히고, 접히면 정렬이
/// 통째로 깨진다. 그래서 넓은 표는 한 행을 한 덩어리로 눕힌다.
/// (DB 도구의 세로 출력 — MySQL \G, psql \x — 과 같은 해법)
/// 첫 칸은 제목 줄, 나머지 칸은 "이름 : 값" 글머리. 사용자 확정 형식(2026-08-12).
const int kWideTotal = 42; // 폰 화면에서 등폭으로 무리 없이 읽히는 한계
const int kWideCell = 25; // 한 칸에 문장이 들어왔다고 볼 기준

List<int> _alignedWidths(TableGrid t) {
  final cells = [t.header, ...t.rows];
  final cols = t.header.length;
  final widths = List<int>.filled(cols, 0);
  for (final r in cells) {
    for (var i = 0; i < cols; i++) {
      final raw = i < r.length ? r[i] : '';
      final w = dispWidth(_flat(raw).replaceAll(RegExp(r' {2,}'), ' '));
      if (w > widths[i]) widths[i] = w;
    }
  }
  return widths;
}

bool tableIsWide(TableGrid t) {
  final widths = _alignedWidths(t);
  final total = widths.fold<int>(0, (a, b) => a + b) + 2 * (widths.length - 1);
  return total > kWideTotal || widths.any((w) => w > kWideCell);
}

String tableToRecords(TableGrid t, TidyOptions o) {
  final mark = (o.bulletChar.isNotEmpty && o.bulletChar != 'keep') ? o.bulletChar : '-';
  // 들여쓰기는 사용자 글머리 설정을 그대로 따른다. 여기서 임의로 최소값을 강제하면
  // 재정리 때 글머리 규칙이 다시 들여쓰기를 바꿔 결과가 계속 달라진다(멱등성 깨짐).
  final pad = ' ' * o.bulletIndent;
  final names = t.header.map((c) => _flat(c).trim()).toList();
  final blocks = <String>[];
  for (final r in t.rows) {
    final key = _flat(r.isNotEmpty ? r[0] : '').trim();
    final lines = <String>[key.isEmpty ? '-' : key];
    for (var i = 1; i < names.length; i++) {
      final v = _flat(i < r.length ? r[i] : '').trim();
      if (v.isEmpty) continue; // 빈 칸은 줄을 만들지 않는다
      lines.add('$pad$mark ${names[i]} : $v');
    }
    blocks.add(lines.join('\n'));
  }
  return blocks.join('\n\n');
}

/// 풀어쓴 표를 다시 표로 되읽기 — 스프레드시트 변환용.
/// 오탐이 본문을 망치지 않도록 표 도구(extractTables)에서만 켠다(o.detectRecords).
class _RecordField {
  final String name;
  final String value;
  _RecordField(this.name, this.value);
}

class _RecordGroup {
  final int start;
  final int end;
  final String key;
  final List<_RecordField> fields;
  _RecordGroup(this.start, this.end, this.key, this.fields);
}

_RecordField? _recordFieldOf(String line) {
  final m = RegExp(r'^\s*[-*·•◦]\s+(.+?)\s+:\s+(.+)$').firstMatch(line);
  return m == null ? null : _RecordField(m.group(1)!.trim(), m.group(2)!.trim());
}

List<_Block> _detectRecordBlocks(List<String> lines) {
  final groups = <_RecordGroup>[];
  var i = 0;
  while (i < lines.length) {
    final head = lines[i];
    if (head.trim().isEmpty || RegExp(r'^\s').hasMatch(head) || _recordFieldOf(head) != null) {
      i++;
      continue;
    }
    var j = i + 1;
    final fields = <_RecordField>[];
    while (j < lines.length) {
      final f = _recordFieldOf(lines[j]);
      if (f == null) break;
      fields.add(f);
      j++;
    }
    if (fields.isNotEmpty) {
      groups.add(_RecordGroup(i, j - 1, head.trim(), fields));
      i = j;
    } else {
      i++;
    }
  }
  // 같은 항목 이름을 가진 덩어리가 2개 이상 이어질 때만 표로 본다
  final blocks = <_Block>[];
  var s = 0;
  while (s < groups.length) {
    final sig = groups[s].fields.map((f) => f.name).join();
    var e = s;
    while (e + 1 < groups.length && groups[e + 1].fields.map((f) => f.name).join() == sig) {
      e++;
    }
    if (e > s) {
      blocks.add(_Block(groups[s].start, groups[e].end, 'record')
        ..records.addAll(groups.sublist(s, e + 1)));
    }
    s = e + 1;
  }
  return blocks;
}

TableGrid _recordBlockToTable(_Block b, String Function(String)? cellClean) {
  String clean(String c) => cellClean != null ? cellClean(c) : c;
  final names = b.records.first.fields.map((f) => f.name).toList();
  // 첫 칸 이름은 풀어쓰기에 남지 않는다(사용자 확정 [A]) — 빈 제목으로 둔다
  final header = ['', ...names];
  final rows = b.records.map((g) {
    return [
      g.key,
      ...names.map((n) {
        final f = g.fields.where((x) => x.name == n);
        return f.isEmpty ? '' : f.first.value;
      })
    ].map(clean).toList();
  }).toList();
  return TableGrid(
    header: header.map(clean).toList(),
    aligns: List<String>.filled(header.length, 'left'),
    rows: rows,
    repaired: false,
  );
}

String tableToTSV(TableGrid t) =>
    [t.header, ...t.rows].map((r) => r.map(_flat).join('\t')).join('\n');

String _csvCell(String c) =>
    RegExp(r'[",\n\r]').hasMatch(c) ? '"${c.replaceAll('"', '""')}"' : c;

String tableToCSV(TableGrid t) =>
    [t.header, ...t.rows].map((r) => r.map(_csvCell).join(',')).join('\r\n');

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String tableToHTML(TableGrid t) {
  String al(String a) => a != 'left' ? ' style="text-align:$a"' : '';
  final head = '<tr>' +
      List.generate(t.header.length, (i) => '<th${al(t.aligns[i])}>${_esc(t.header[i])}</th>').join('') +
      '</tr>';
  final body = t.rows
      .map((r) =>
          '<tr>' + List.generate(r.length, (i) => '<td${al(t.aligns[i])}>${_esc(r[i])}</td>').join('') + '</tr>')
      .join('\n');
  return '<table>\n<thead>\n$head\n</thead>\n<tbody>\n$body\n</tbody>\n</table>';
}

/// ============ 출처(citation) 블록 제거 ============
bool isCitationLine(String line) {
  var c = line.trim();
  if (c.startsWith('|')) {
    c = c.replaceFirst(RegExp(r'^\|+'), '').replaceFirst(RegExp(r'\|+$'), '').trim();
  }
  return RegExp(r'^\[\^?\d+\]:\s*(https?://|www\.)\S+').hasMatch(c);
}

List<String> _stripCitations(List<String> lines, TidyReport rep) {
  final cite = lines.map(isCitationLine).toList();
  if (!cite.contains(true)) return lines;
  final out = <String>[];
  for (int i = 0; i < lines.length; i++) {
    if (cite[i]) {
      rep.citations++;
      continue;
    }
    final t = lines[i].trim();
    final sepOnly = t.contains('|') && RegExp(r'^[|\s:-]+$').hasMatch(t) && RegExp(r'-{2,}').hasMatch(t);
    if (sepOnly && ((i > 0 && cite[i - 1]) || (i + 1 < lines.length && cite[i + 1]))) continue;
    out.add(lines[i]);
  }
  return out;
}

/// ============ 구조 규칙: "– a – b – c" 나열 문장 → 줄 목록 ============
List<String> _expandDashLists(List<String> lines, TidyOptions o, TidyReport rep) {
  if (!o.smartDashList) return lines;
  final out = <String>[];
  for (final line in lines) {
    final t = line.trim();
    final dashCount = RegExp(r'(^|\s)[–—]\s+').allMatches(t).length;
    if (dashCount >= 2 && !_hasUnescapedPipe(t) && !RegExp(r'^(```|~~~)').hasMatch(t)) {
      final startsWithDash = RegExp(r'^[–—]\s').hasMatch(t);
      final bodyText = startsWithDash ? t.replaceFirst(RegExp(r'^[–—]\s+'), '') : t;
      final pieces = bodyText.split(RegExp(r'\s+[–—]\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      for (int i = 0; i < pieces.length; i++) {
        if (i == 0 && !startsWithDash) {
          out.add(pieces[i]); // 라벨 줄 유지
        } else {
          out.add('- ${pieces[i]}');
        }
      }
      rep.markers += dashCount;
    } else {
      out.add(line);
    }
  }
  return out;
}

String _headingOut(String inner, TidyOptions o, TidyReport rep) {
  final hm = o.headingMode.isNotEmpty ? o.headingMode : (o.stripHeadings ? 'strip' : 'keep');
  rep.headings++;
  if (hm == 'prefix') return '${o.headingSymbol} $inner';
  if (hm == 'bracket') return '[$inner]';
  return inner;
}

/// ================= Inline Cleaner =================
String _inlineClean(String s, TidyOptions o, TidyReport rep) {
  var t = s;
  int count(RegExp re) => re.allMatches(t).length;

  if (o.stripHtml) {
    rep.markers += count(RegExp(r'<[^>\n]+>'));
    t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ').replaceAll(RegExp(r'<[^>\n]+>'), '');
    t = t
        .replaceAll(RegExp('&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp('&amp;', caseSensitive: false), '&')
        .replaceAll(RegExp('&lt;', caseSensitive: false), '<')
        .replaceAll(RegExp('&gt;', caseSensitive: false), '>')
        .replaceAll(RegExp('&quot;', caseSensitive: false), '"')
        .replaceAll(RegExp('&#39;', caseSensitive: false), "'");
  }
  // 본문 인라인 출처 마커 [1][2] — 출처 정의 블록이 있을 때만
  if (o.inlineCites) {
    t = t.replaceAllMapped(RegExp(r'\[\^?\d{1,2}\](?=[\s.,;:!?)\]]|\[|$)'), (m) {
      rep.citations++;
      return '';
    });
  }
  // 이미지 → alt
  t = t.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\(([^)]*)\)'), (m) {
    rep.markers++;
    return m.group(1)!;
  });
  // 링크
  if (o.linkMode == 'text') {
    t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]*)\)'), (m) {
      rep.markers++;
      return m.group(1)!;
    });
  } else if (o.linkMode == 'textUrl') {
    t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)\s]*)[^)]*\)'), (m) {
      rep.markers++;
      final tx = m.group(1)!, url = m.group(2)!;
      return url.isNotEmpty ? '$tx ($url)' : tx;
    });
  }
  if (o.stripEmphasis) {
    rep.markers += count(RegExp(r'`[^`\n]*`'));
    t = t.replaceAllMapped(RegExp(r'`([^`\n]*)`'), (m) => m.group(1)!);
    rep.markers += count(RegExp(r'~~[^~\n]+~~'));
    t = t.replaceAllMapped(RegExp(r'~~([^~\n]+)~~'), (m) => m.group(1)!);
    final emph = o.emphStyle;
    if (emph != 'keep') {
      String wrap(String inner) {
        final s2 = inner.trim();
        if (emph == 'quoteSingle' && s2.length <= 40) return "'$s2'";
        if (emph == 'quoteDouble' && s2.length <= 40) return '"$s2"';
        return inner;
      }

      t = t.replaceAllMapped(RegExp(r'\*\*([^*\n]+)\*\*'), (m) {
        rep.markers++;
        return wrap(m.group(1)!);
      });
      t = t.replaceAllMapped(RegExp(r'__([^_\n]+)__'), (m) {
        rep.markers++;
        return wrap(m.group(1)!);
      });
      rep.markers += count(RegExp(r'\*[^*\s][^*\n]*\*'));
      t = t.replaceAllMapped(RegExp(r'\*([^*\s][^*\n]*?)\*'), (m) => m.group(1)!);
      t = t.replaceAllMapped(RegExp('(^|[\\s([{"\'])_([^_\\n]+)_(?=\$|[\\s)\\]}.,!?:;"\'])'), (m) {
        rep.markers++;
        return m.group(1)! + m.group(2)!;
      });
    }
  }
  if (o.removeEmoji) {
    final em = _emojiRe.allMatches(t).length;
    rep.emoji += em;
    t = t.replaceAll(_emojiRe, '');
    t = t.replaceAll(_zwWithZwj, '');
  } else {
    t = t.replaceAll(_zwNoZwj, '');
  }
  t = t.replaceAll('\u00A0', ' ');
  if (o.smartPunct) {
    t = t
        .replaceAll(RegExp('[\u201C\u201D]'), '"')
        .replaceAll(RegExp('[\u2018\u2019]'), "'")
        .replaceAll(RegExp('[\u2013\u2014]'), '-')
        .replaceAll('\u2026', '...');
  }
  if (o.removeEmoji) t = t.replaceAll(RegExp(' {2,}'), ' ');
  return t;
}

/// ================= Block 처리 =================
List<String> _processTextSegment(
    List<String> linesIn, TidyOptions o, TidyReport rep, List<String> warnings, List<TableGrid> tablesOut) {
  var input = linesIn;
  if (o.removeCitations) input = _stripCitations(input, rep);
  final lines = _expandDashLists(input, o, rep);
  final out = <String>[];
  bool skipBlanks = false;
  // 빈 줄 또는 투명 문자(ㅤ)로만 이루어진 여백 줄 판정
  bool isSpacer(String l) => l.replaceAll(RegExp('[ㅤ\\s]'), '').isEmpty;

  void emitHeading(String formatted) {
    if (o.headingPad) {
      final ch = o.headingPadChar.isNotEmpty ? o.headingPadChar : 'ㅤ';
      // 원본에 이미 있던 소제목 주변 여백 줄은 흡수해 두 배가 되지 않게 한다
      while (out.isNotEmpty && isSpacer(out.last)) out.removeLast();
      if (out.isNotEmpty) {
        for (int k = 0; k < o.headingPadAbove; k++) out.add(ch);
      }
      out.add(formatted);
      for (int k = 0; k < o.headingPadBelow; k++) out.add(ch);
      skipBlanks = true;
    } else {
      out.add('');
      out.add(formatted);
      out.add('');
    }
  }

  final tableBlocks = _detectTableBlocks(lines, o.detectRecords);
  final inTable = <int, int>{};
  for (int bi = 0; bi < tableBlocks.length; bi++) {
    for (int k = tableBlocks[bi].start; k <= tableBlocks[bi].end; k++) {
      inTable[k] = bi;
    }
  }
  String cellClean(String c) => _inlineClean(c, o, rep);
  final doneTables = <int>{};

  for (int i = 0; i < lines.length; i++) {
    if (inTable.containsKey(i)) {
      final bi = inTable[i]!;
      if (doneTables.contains(bi)) continue;
      doneTables.add(bi);
      final b = tableBlocks[bi];
      if (o.repairTables || o.tablesOnly || o.tablesToTSV) {
        final w = <String>[];
        final blockLines = lines.sublist(b.start, b.end + 1);
        final t = b.kind == 'record'
            ? _recordBlockToTable(b, cellClean)
            : b.kind == 'tsv'
                ? _parseTsvTable(blockLines, cellClean)
                : b.kind == 'aligned'
                    ? _parseAlignedTable(blockLines, cellClean)
                    : _parseTable(blockLines, w, cellClean);
        warnings.addAll(w);
        if (t.repaired || w.isNotEmpty) rep.tablesRepaired++;
        tablesOut.add(t);
        if (o.tablesOnly) {
          // 본문 출력 안 함
        } else if (o.tablesToTSV) {
          out.add(tableToTSV(t));
        } else if (o.wideTables != 'aligned' && (o.wideTables == 'records' || tableIsWide(t))) {
          // 좁은 표는 칸 맞추기, 넓거나 문장이 든 표는 행 단위 풀어쓰기 (자동 판단)
          out.add(tableToRecords(t, o));
        } else {
          out.add(tableToAligned(t));
        }
      } else {
        for (int k = b.start; k <= b.end; k++) {
          out.add(lines[k]);
        }
      }
      i = b.end;
      continue;
    }
    if (o.tablesOnly) continue;
    if (skipBlanks) {
      if (isSpacer(lines[i])) continue;
      skipBlanks = false;
    }
    final line = lines[i];
    RegExpMatch? m;
    // ㅤ(U+3164)로 감싼 유사 소제목
    if (o.smartFillerHeading && line.contains('ㅤ') && !_hasUnescapedPipe(line)) {
      final innerT =
          _inlineClean(line.replaceAll(RegExp('[ㅤ]+'), ' '), o, rep).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (innerT.isNotEmpty && innerT.length <= 30) {
        emitHeading(_headingOut(innerT, o, rep));
        continue;
      }
    }
    if ((m = RegExp(r'^\s*(#{1,6})\s+(.*)$').firstMatch(line)) != null) {
      final hm = o.headingMode.isNotEmpty ? o.headingMode : (o.stripHeadings ? 'strip' : 'keep');
      String formatted;
      if (hm == 'keep') {
        formatted = (o.stripHeadings || o.headingMode.isNotEmpty)
            ? '${m!.group(1)!} ${_inlineClean(m.group(2)!, o, rep).trim()}'
            : line;
      } else {
        formatted = _headingOut(_inlineClean(m!.group(2)!, o, rep).trim(), o, rep);
      }
      if (o.headingPad) {
        emitHeading(formatted);
      } else {
        out.add(formatted);
      }
    } else if (RegExp(r'^\s*([-*_])\s*(\1\s*){2,}$').hasMatch(line)) {
      final hrm = o.hrMode.isNotEmpty ? o.hrMode : (o.removeHr ? 'remove' : 'keep');
      if (hrm == 'remove') {
        rep.markers++;
      } else {
        out.add(line.trim());
      }
    } else if (o.stripQuotes && (m = RegExp(r'^(\s*)>\s?(.*)$').firstMatch(line)) != null) {
      rep.markers++;
      out.add(m!.group(1)! + _inlineClean(m.group(2)!.replaceFirst(RegExp(r'^(>\s?)+'), ''), o, rep));
    } else if (o.bulletsToDot && (m = RegExp(r'^(\s*)([-*+–—])\s+(?:\[[ xX]\]\s+)?(.*)$').firstMatch(line)) != null) {
      final bc = o.bulletChar;
      final ind = ' ' * o.bulletIndent;
      if (bc == 'keep') {
        out.add(ind + m!.group(1)! + m.group(2)! + ' ' + _inlineClean(m.group(3)!, o, rep));
      } else {
        // 변환 시 원본 들여쓰기는 버리고 설정 들여쓰기만 적용 (누적 방지)
        rep.markers++;
        out.add(ind + bc + ' ' + _inlineClean(m!.group(3)!, o, rep));
      }
    } else if ((m = RegExp(r'^(\s*)(\d+)([.)])\s+(.*)$').firstMatch(line)) != null) {
      out.add('${m!.group(1)!}${m.group(2)!}. ${_inlineClean(m.group(4)!, o, rep)}');
    } else {
      out.add(_inlineClean(line, o, rep));
    }
  }
  return out;
}

/// ================= 메인 파이프라인 =================
TidyResult tidy(String raw, TidyOptions optsIn) {
  final o = optsIn;
  o.inlineCites = false;
  final rep = TidyReport();
  final warnings = <String>[];
  final tables = <TableGrid>[];
  final originalLen = raw.length;

  // 01 Line Ending Normalization
  var text = raw.replaceAll(RegExp(r'\r\n?'), '\n');

  // 02 Literal Newline Detection
  final litN = RegExp(r'\\n').allMatches(text).length;
  final realN = '\n'.allMatches(text).length;
  if (litN >= 2 && realN <= 1) text = text.replaceAll(r'\n', '\n');

  // 03 Outer Fence Detection
  if (o.removeOuterFence) {
    final r = _stripOuterFence(text);
    if (r.removed) {
      text = r.text;
      rep.markers += 2;
    }
  }

  // 04 Protected Segment Split
  final segs = _splitSegments(text);

  // 05 AI Preamble Detection (첫 text segment에만)
  if (o.removePreamble) {
    for (final s in segs) {
      if (s.type != 'text') continue;
      final idx = _detectPreamble(s.lines);
      if (idx >= 0) {
        s.lines.removeAt(idx);
        if (idx < s.lines.length && s.lines[idx].isEmpty) s.lines.removeAt(idx);
        rep.preamble = 1;
      }
      break;
    }
  }

  // 06 Escape Normalization (pipe 제외 — 표 파서에서 처리)
  if (o.unescape) {
    for (final s in segs) {
      if (s.type != 'text') continue;
      s.lines = s.lines
          .map((l) => l.replaceAllMapped(RegExp(r'\\([*_#>\[\]()`~.!+-])'), (m) => m.group(1)!))
          .toList();
    }
  }

  // 06.5 사용자 치환 규칙 (코드블록 제외, 순서대로 적용)
  final rules = o.customRules;
  if (rules != null && rules.isNotEmpty) {
    for (final s in segs) {
      if (s.type != 'text') continue;
      var joined = s.lines.join('\n');
      for (final rule in rules) {
        if (rule.find.isEmpty) continue;
        final repl = rule.replace.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
        try {
          if (rule.regex) {
            joined = joined.replaceAllMapped(RegExp(rule.find), (m) {
              var r2 = repl;
              for (int g = 1; g <= m.groupCount; g++) {
                r2 = r2.replaceAll('\$$g', m.group(g) ?? '');
              }
              return r2;
            });
          } else {
            joined = joined.split(rule.find).join(repl);
          }
        } catch (_) {/* 잘못된 정규식은 건너뜀 */}
      }
      s.lines = joined.split('\n');
    }
  }

  // 06.7 출처 정의 블록 존재 여부 사전 스캔
  if (o.removeCitations) {
    o.inlineCites = segs.any((s) => s.type == 'text' && s.lines.any(isCitationLine));
  }

  // 07~09 Block Parsing + Inline Cleaning + Table Engine
  final outParts = <String>[];
  for (final s in segs) {
    if (s.type == 'code') {
      if (!o.tablesOnly) outParts.add(s.lines.join('\n'));
    } else {
      outParts.add(_processTextSegment(s.lines, o, rep, warnings, tables).join('\n'));
    }
  }
  var result = outParts.join('\n');

  // 표만 뽑기 모드
  if (o.tablesOnly) {
    result = tables.isNotEmpty ? tables.map(tableToTSV).join('\n\n') : '';
    if (tables.isEmpty) warnings.add('문서에서 표를 찾지 못했습니다');
  }

  // 10 Whitespace Normalization
  if (o.normalizeWhitespace) {
    result = result.split('\n').map((l) => l.replaceFirst(RegExp(r'[ \t]+$'), '')).join('\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.replaceFirst(RegExp(r'^\n+'), '').replaceFirst(RegExp(r'\n+$'), '');
  }

  // 11 TidyReport
  final delta = originalLen - result.length;
  final parts = <String>[];
  if (rep.markers > 0) parts.add('마커 ${rep.markers}개 제거');
  if (rep.headings > 0) parts.add('제목 ${rep.headings}개 정리');
  if (rep.emoji > 0) parts.add('이모지 ${rep.emoji}개 제거');
  if (rep.preamble > 0) parts.add('AI 서두 ${rep.preamble}개 제거');
  if (rep.citations > 0) parts.add('출처 ${rep.citations}개 제거');
  if (rep.tablesRepaired > 0) parts.add('표 ${rep.tablesRepaired}개 복구');
  if (delta > 0) {
    parts.add('${_grp(delta)}자 감소');
  } else if (delta < 0) {
    parts.add('${_grp(-delta)}자 증가');
  }
  final summary = parts.isNotEmpty ? parts.join(' · ') : '변경 사항 없음';

  return TidyResult(text: result, summary: summary, warnings: warnings, tables: tables, report: rep);
}

/// 문서에서 표만 추출 (표 도구용)
({List<TableGrid> tables, List<String> warnings}) extractTables(String raw) {
  // detectRecords: 풀어쓴 표도 스프레드시트로 되돌릴 수 있도록 표 도구에서만 인식
  final r = tidy(raw,
      TidyOptions(tablesOnly: true, repairTables: true, removeOuterFence: true, detectRecords: true));
  return (tables: r.tables, warnings: r.warnings);
}
