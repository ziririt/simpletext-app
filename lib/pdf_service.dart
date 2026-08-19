/// 종이로 나가는 쪽 — PDF 한 장을 만들고, 인쇄 화면에 넘긴다.
///
/// 2026-08-19 소유자 지시로 넷 중 첫째. 왜 이게 첫째냐면, 이 앱이 하는 일이
/// **"AI가 뱉은 덩어리를 사람이 읽을 수 있는 글로 만드는 것"** 이기 때문이다.
/// 그 결과를 남에게 건네는 가장 흔한 모양이 아직도 종이와 PDF다.
///
/// ## 왜 화면을 찍지 않고 다시 그리나
///
/// 화면을 그대로 이미지로 떠서 넣는 길이 있다. 반나절이면 된다. 그런데
/// 그렇게 만든 PDF는 글자를 긁어 갈 수 없고, 찾기가 안 되고, 확대하면
/// 뭉갠다. 종이에 옮기는 일의 값어치가 거기서 절반 넘게 날아간다.
/// 그래서 덩어리를 다시 세어(core/print_blocks.dart) 종이 위에 새로 앉힌다.
///
/// ## 글꼴을 앱 안에 넣는 까닭
///
/// PDF는 화면과 달리 기기의 글꼴을 빌려 쓰지 못한다. 파일 안에 글자 모양이
/// 없으면 받는 쪽에서 네모(두부)로 나온다. 그래서 본문용 비례 글꼴을
/// 넣는다(Noto Sans KR, OFL). 한자·가나는 이미 들어 있는 D2Coding 으로
/// 받친다 — 그 둘까지 비례 글꼴에 담으면 앱이 12MB 무거워지는데, 한국어
/// 메모에서 한자가 나오는 빈도를 생각하면 값이 맞지 않는다.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'core/export_md.dart' show safeFileName;
import 'core/print_blocks.dart';
import 'main.dart' show Note;

/// 종이 위의 색. 화면 테마를 따라가지 않는다 — 종이는 늘 흰색이고,
/// 다크 모드로 인쇄하면 잉크만 먹는다.
class _Ink {
  static const body = PdfColor.fromInt(0xFF1C1C1E);
  static const head = PdfColor.fromInt(0xFF000000);
  static const sub = PdfColor.fromInt(0xFF8A8A8E);
  static const line = PdfColor.fromInt(0xFFE1E1E6);
  static const accent = PdfColor.fromInt(0xFF0070BE);
  static const codeBg = PdfColor.fromInt(0xFFF5F5F7);
  static const headBg = PdfColor.fromInt(0xFFF7F9FB);
}

class PdfService {
  static pw.Font? _reg;
  static pw.Font? _bold;
  static pw.Font? _mono;

  /// 글꼴은 한 번만 읽는다. 6MB짜리를 메모 열 때마다 파싱하면 눈에 띄게 늦다.
  static Future<void> _loadFonts() async {
    if (_reg != null) return;
    _reg = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf'));
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf'));
    _mono = pw.Font.ttf(await rootBundle.load('assets/fonts/D2Coding.ttf'));
  }

  static String fileNameOf(Note n) =>
      '${safeFileName(n.title.trim().isNotEmpty ? n.title : n.body)}.pdf';

  /// 인쇄 화면을 연다. 애플·안드로이드·윈도우·맥 모두 여기서 'PDF로 저장'이
  /// 같이 나온다 — 우리가 저장 화면을 따로 만들면 그중 하나만 되는 더 나쁜
  /// 물건이 된다(export_service.dart와 같은 판단).
  static Future<bool> printNote(Note n, {required String dateLabel}) async {
    try {
      final bytes = await build(n, dateLabel: dateLabel);
      // 돌아오는 값을 안 본다. 사용자가 인쇄 화면에서 취소해도 false가
      // 오는데, 그건 실패가 아니라 마음이 바뀐 것이다. 거기에 '실패했습니다'를
      // 띄우면 앱이 고장 난 것처럼 보인다.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileNameOf(n),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// PDF 파일 한 장을 만들어 시스템 공유 시트로 넘긴다.
  static Future<bool> sharePdf(Note n, {required String dateLabel}) async {
    try {
      final bytes = await build(n, dateLabel: dateLabel);
      await Printing.sharePdf(bytes: bytes, filename: fileNameOf(n));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 만들어진 PDF의 날바이트. 시험과 미리보기가 여기를 쓴다.
  static Future<Uint8List> build(Note n, {required String dateLabel}) async {
    await _loadFonts();
    final blocks = printBlocks(n.body);
    final title = n.title.trim();

    final doc = pw.Document(
      title: title.isEmpty ? 'Skyblue Note' : title,
      theme: pw.ThemeData.withFont(
        base: _reg!,
        bold: _bold!,
        italic: _reg!,
        boldItalic: _bold!,
        fontFallback: [_mono!],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(52, 54, 52, 46),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            '${ctx.pageNumber}',
            style: pw.TextStyle(fontSize: 8.5, color: _Ink.sub, font: _reg),
          ),
        ),
        build: (ctx) => [
          ..._titleBlock(title, dateLabel, n),
          ...blocks.map(_paint).whereType<pw.Widget>(),
        ],
      ),
    );

    return doc.save();
  }

  // ── 머리 ─────────────────────────────────────────────────────────

  static List<pw.Widget> _titleBlock(String title, String dateLabel, Note n) {
    final meta = <String>[
      if (dateLabel.isNotEmpty) dateLabel,
      if (n.source.trim().isNotEmpty) n.source.trim(),
      if (n.tags.isNotEmpty) n.tags.map((t) => '#$t').join(' '),
    ];
    return [
      if (title.isNotEmpty)
        pw.Text(title,
            style: pw.TextStyle(
                font: _bold,
                fontSize: 19,
                height: 1.32,
                color: _Ink.head,
                letterSpacing: -0.3)),
      if (meta.isNotEmpty)
        pw.Padding(
          padding: pw.EdgeInsets.only(top: title.isEmpty ? 0 : 7),
          child: pw.Text(meta.join('   ·   '),
              style: pw.TextStyle(font: _reg, fontSize: 8.5, color: _Ink.sub)),
        ),
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 11, bottom: 16),
        height: 0.7,
        color: _Ink.line,
      ),
    ];
  }

  // ── 덩어리 하나를 종이 위젯으로 ──────────────────────────────────

  static pw.Widget? _paint(PBlock b) {
    switch (b.kind) {
      case PKind.blank:
        return pw.SizedBox(height: 7);

      case PKind.hr:
        return pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 11),
            height: 0.7,
            color: _Ink.line);

      case PKind.h1:
        return _head(b, 15.5, 17);
      case PKind.h2:
        return _head(b, 13, 14);
      case PKind.h3:
        return _head(b, 11.5, 12);

      case PKind.para:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.5),
          child: pw.RichText(text: _spanOf(b.spans, 10)),
        );

      case PKind.quote:
        return pw.Container(
          margin: const pw.EdgeInsets.fromLTRB(2, 4, 0, 6),
          padding: const pw.EdgeInsets.fromLTRB(11, 2, 0, 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                left: pw.BorderSide(color: _Ink.accent, width: 2.2)),
          ),
          child: pw.RichText(
              text: _spanOf(b.spans, 10, color: PdfColor.fromInt(0xFF4A4A4E))),
        );

      case PKind.bullet:
        return _listRow(b, _dot(b.indent), 10.5, bulletColor: _Ink.accent);

      case PKind.numbered:
        return _listRow(b, b.marker, 10);

      case PKind.task:
        return _taskRow(b);

      case PKind.code:
        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.symmetric(vertical: 7),
          padding: const pw.EdgeInsets.fromLTRB(11, 9, 11, 9),
          decoration: pw.BoxDecoration(
            color: _Ink.codeBg,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _Ink.line, width: 0.6),
          ),
          child: pw.Text(b.text,
              style: pw.TextStyle(
                  font: _mono, fontSize: 8.6, height: 1.45, color: _Ink.body)),
        );

      case PKind.table:
        return _table(b);
    }
  }

  static pw.Widget _head(PBlock b, double size, double top) => pw.Padding(
        padding: pw.EdgeInsets.only(top: top, bottom: 5),
        child: pw.RichText(
            text: _spanOf(b.spans, size,
                bold: true, color: _Ink.head, height: 1.34)),
      );

  /// 단마다 모양을 바꾼다. 같은 점이 세 단 이어지면 단이 안 보인다.
  static String _dot(int indent) =>
      indent <= 0 ? '•' : (indent == 1 ? '◦' : '–');

  static pw.Widget _listRow(PBlock b, String mark, double markSize,
      {PdfColor? bulletColor}) {
    return pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(b.indent * 15.0, 1.5, 0, 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            padding: const pw.EdgeInsets.only(top: 0.5),
            child: pw.Text(mark,
                style: pw.TextStyle(
                    font: _reg,
                    fontSize: markSize,
                    height: 1.62,
                    color: bulletColor ?? _Ink.sub)),
          ),
          pw.Expanded(child: pw.RichText(text: _spanOf(b.spans, 10))),
        ],
      ),
    );
  }

  /// 할 일의 네모는 **글자가 아니라 그림**이다. ☐ ☑ 는 글꼴에 따라 있고
  /// 없고가 갈려서, 없으면 그 자리에 두부가 뜬다. 선으로 그리면 어디서나 같다.
  ///
  /// 폭을 정해 둔 칸에 넣지 않고 여백으로 띄운다. 칸에 넣으면 네모가 그
  /// 칸을 꽉 채우려 들어서 정사각형이 아니라 알약이 된다(첫 판의 잘못).
  static pw.Widget _taskRow(PBlock b) {
    return pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(b.indent * 15.0, 2, 0, 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3.6, right: 7.4),
            child: pw.SizedBox(
              width: 8.6,
              height: 8.6,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  // 끝낸 일은 네모를 하늘색으로 채운다. 안쪽에 체크 표시를
                  // 그려 넣어 봤는데, 8pt 짜리 네모 안에서는 그냥 얼룩이었다.
                  color: b.checked ? _Ink.accent : null,
                  borderRadius: pw.BorderRadius.circular(2),
                  border: pw.Border.all(
                      color: b.checked ? _Ink.accent : _Ink.sub, width: 0.9),
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: _spanOf(b.spans, 10,
                  color: b.checked ? _Ink.sub : null,
                  lineThrough: b.checked),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _table(PBlock b) {
    if (b.rows.isEmpty) return pw.SizedBox();
    final head = b.rows.first;
    final body = b.rows.skip(1).toList();
    pw.Widget cell(String s, {required bool bold}) => pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(7, 5.5, 7, 5.5),
          child: pw.RichText(
            text: _spanOf(inlineSpans(s), 8.8,
                bold: bold, color: bold ? _Ink.head : _Ink.body, height: 1.4),
          ),
        );
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Table(
        border: pw.TableBorder.all(color: _Ink.line, width: 0.6),
        // 칸 너비를 고르게 나눈다. 속살에 맞춰 늘리면 긴 칸 하나가 종이
        // 밖으로 나가고, 그때는 그 줄이 통째로 안 그려진다.
        defaultColumnWidth: const pw.FlexColumnWidth(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _Ink.headBg),
            children: head.map((c) => cell(c, bold: true)).toList(),
          ),
          for (final r in body)
            pw.TableRow(children: r.map((c) => cell(c, bold: false)).toList()),
        ],
      ),
    );
  }

  // ── 토막 ─────────────────────────────────────────────────────────

  static pw.TextSpan _spanOf(
    List<PSpan> spans,
    double size, {
    bool bold = false,
    PdfColor? color,
    double height = 1.62,
    bool lineThrough = false,
  }) {
    final base = pw.TextStyle(
      font: bold ? _bold : _reg,
      fontSize: size,
      height: height,
      color: color ?? _Ink.body,
      decoration:
          lineThrough ? pw.TextDecoration.lineThrough : pw.TextDecoration.none,
      decorationColor: _Ink.sub,
    );
    if (spans.isEmpty) return pw.TextSpan(text: '', style: base);
    return pw.TextSpan(
      style: base,
      children: spans.map((s) {
        if (s.code) {
          return pw.TextSpan(
            text: s.text,
            style: base.copyWith(
                font: _mono,
                fontSize: size * 0.9,
                color: PdfColor.fromInt(0xFFB5266B)),
          );
        }
        return pw.TextSpan(
          text: s.text,
          style: base.copyWith(
            font: (bold || s.bold) ? _bold : _reg,
            // 기울임꼴을 따로 안 넣었다. 한글 글꼴에는 대개 기울임 판이
            // 없고, 기계로 기울이면 획이 뭉개진다. 대신 옅은 색으로 구분한다.
            color: s.italic
                ? PdfColor.fromInt(0xFF55555A)
                : (color ?? _Ink.body),
            decoration: (lineThrough || s.strike)
                ? pw.TextDecoration.lineThrough
                : pw.TextDecoration.none,
          ),
        );
      }).toList(),
    );
  }
}
