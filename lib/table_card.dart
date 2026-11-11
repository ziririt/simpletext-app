// 본문 속 가로로 미는 표 카드 (2026-11-11 소유자 지시 — 제미나이처럼
// "표가 깨지지 않고 가로로 스크롤되는 표").
//
// 높이를 먼저 재고(measureTableCard) 그 값 그대로 그린다(TableCard).
// 본문 글상자는 이 높이만큼 빈 줄을 비워 두고(mono_controller.dart), 화면은
// 그 자리에 이 카드를 얹는다. **재는 셈과 그리는 셈이 같아야** 카드가 빈
// 자리에 꼭 맞는다 — 그래서 둘 다 아래 숫자만 쓴다.

import 'package:flutter/material.dart';

import 'core/tidy_engine.dart';

const double kCellPadV = 11; // 칸 위아래 여백
const double kCellGap = 18; // 열 사이(가로줄이 여기서 끊긴다 — 제미나이 모양)
const double kMinCol = 64;
const double kMaxCol = 196; // 이보다 긴 글은 칸 안에서 줄을 바꾼다
const double kScrollBarSpace = 12; // 아래 굴림 막대 자리
const double kCardVPad = 6;

class TableCardLayout {
  final List<double> colWidths;
  final List<double> rowHeights; // 0번이 머리줄
  const TableCardLayout(this.colWidths, this.rowHeights);

  double get height =>
      rowHeights.fold<double>(0, (a, b) => a + b) +
      kScrollBarSpace +
      kCardVPad * 2;
}

TextStyle tableCellStyle(double fontSize, {bool head = false, String? family}) =>
    TextStyle(
      fontSize: fontSize,
      height: 1.35,
      letterSpacing: 0,
      fontFamily: family,
      fontWeight: head ? FontWeight.w700 : FontWeight.w400,
    );

String _cell(List<String> r, int i) => i < r.length ? r[i].trim() : '';

TableCardLayout measureTableCard(
  TableGrid t, {
  required double fontSize,
  required double maxWidth,
  required TextScaler scaler,
  String? family,
}) {
  final cols = t.header.length;
  final all = [t.header, ...t.rows];
  double w(String s, TextStyle st) {
    final p = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return p.width;
  }

  final widths = List<double>.filled(cols, kMinCol);
  for (var r = 0; r < all.length; r++) {
    final st = tableCellStyle(fontSize, head: r == 0, family: family);
    for (var c = 0; c < cols; c++) {
      final v = w(_cell(all[r], c), st).ceilToDouble() + 2;
      if (v > widths[c]) widths[c] = v;
    }
  }
  for (var c = 0; c < cols; c++) {
    widths[c] = widths[c].clamp(kMinCol, kMaxCol);
  }
  // 화면보다 좁으면 남는 폭을 열마다 고르게 나눠 판을 채운다.
  final used = widths.fold<double>(0, (a, b) => a + b) + kCellGap * (cols - 1);
  if (used < maxWidth && cols > 0) {
    final add = (maxWidth - used) / cols;
    for (var c = 0; c < cols; c++) {
      widths[c] = (widths[c] + add).floorToDouble();
    }
  }
  final heights = <double>[];
  for (var r = 0; r < all.length; r++) {
    final st = tableCellStyle(fontSize, head: r == 0, family: family);
    var h = 0.0;
    for (var c = 0; c < cols; c++) {
      final p = TextPainter(
        text: TextSpan(text: _cell(all[r], c), style: st),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: widths[c]);
      if (p.height > h) h = p.height;
    }
    heights.add((h + kCellPadV * 2 + 2).ceilToDouble()); // +2: 아래 가름선 몫
  }
  return TableCardLayout(widths, heights);
}

class TableCard extends StatefulWidget {
  const TableCard({
    super.key,
    required this.grid,
    required this.layout,
    required this.fontSize,
    required this.ink,
    required this.line,
    required this.onTap,
    this.family,
  });

  final TableGrid grid;
  final TableCardLayout layout;
  final double fontSize;
  final Color ink;
  final Color line;
  final VoidCallback onTap;
  final String? family;

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final _sc = ScrollController();

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.grid;
    final l = widget.layout;
    final rows = [t.header, ...t.rows];
    return SizedBox(
      height: l.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kCardVPad),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Scrollbar(
            controller: _sc,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: kScrollBarSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var r = 0; r < rows.length; r++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < l.colWidths.length; c++) ...[
                          if (c > 0) const SizedBox(width: kCellGap),
                          Container(
                            width: l.colWidths[c],
                            height: l.rowHeights[r],
                            padding: const EdgeInsets.symmetric(
                              vertical: kCellPadV,
                            ),
                            decoration: r == rows.length - 1
                                ? null
                                : BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: widget.line,
                                        width: r == 0 ? 1.2 : 0.8,
                                      ),
                                    ),
                                  ),
                            child: Text(
                              _cell(rows[r], c),
                              style: tableCellStyle(
                                widget.fontSize,
                                head: r == 0,
                                family: widget.family,
                              ).copyWith(color: widget.ink),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
