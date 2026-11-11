// 본문 속 가로로 미는 표 카드 (2026-11-11 소유자 지시 — 제미나이처럼
// "표가 깨지지 않고 가로로 스크롤되는 표").
//
// 높이를 먼저 재고(measureTableCard) 그 값 그대로 그린다(TableCard).
// 본문 글상자는 이 높이만큼 빈 줄을 비워 두고(mono_controller.dart), 화면은
// 그 자리에 이 카드를 얹는다. **재는 셈과 그리는 셈이 같아야** 카드가 빈
// 자리에 꼭 맞는다 — 그래서 둘 다 아래 숫자만 쓴다.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'core/tidy_engine.dart';

const double kCellPadV = 11; // 칸 위아래 여백
const double kCellGap = 18; // 열 사이(가로줄이 여기서 끊긴다 — 제미나이 모양)
const double kMinCol = 64;
const double kMaxCol = 196; // 이보다 긴 글은 칸 안에서 줄을 바꾼다
const double kScrollBarSpace = 12; // 아래 굴림 막대 자리
const double kCardVPad = 6;
const double kFitGap = 12; // 화면 폭 표는 칸 사이를 조금 좁힌다

class TableCardLayout {
  final List<double> colWidths;
  final List<double> rowHeights; // 0번이 머리줄
  const TableCardLayout(
    this.colWidths,
    this.rowHeights, {
    this.fit = false,
    this.scale = 1.0,
    this.image = false,
  });
  final bool fit;

  /// 그림 표(image): 제 폭으로 그린 것을 이만큼 줄여 놓는다.
  final double scale;
  final bool image;

  double get gridW =>
      colWidths.fold<double>(0, (a, b) => a + b) + gap * (colWidths.length - 1);
  double get gridH => rowHeights.fold<double>(0, (a, b) => a + b);

  double get gap => fit ? kFitGap : kCellGap;

  double get height => image
      ? (gridH * scale).ceilToDouble() + kCardVPad * 2
      : gridH + (fit ? 0 : kScrollBarSpace) + kCardVPad * 2;
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
  bool fit = false,
  bool fill = true,
  bool image = false,
}) {
  if (image) {
    // 제 폭으로 재고(채우지 않는다) 화면 폭에 맞게 줄인다. 키울 일은 없다.
    final nat = measureTableCard(
      t,
      fontSize: fontSize,
      maxWidth: 0,
      scaler: scaler,
      family: family,
      fill: false,
    );
    final n = TableCardLayout(nat.colWidths, nat.rowHeights, fit: true);
    final sc = n.gridW <= 0 ? 1.0 : math.min(1.0, maxWidth / n.gridW);
    return TableCardLayout(
      nat.colWidths,
      nat.rowHeights,
      fit: true,
      scale: sc,
      image: true,
    );
  }
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
  if (fit && cols > 0) {
    // 화면 폭에 꼭 맞춘다. 글이 긴 칸이 더 넓게 — 다만 긴 칸이 판을 다
    // 가져가지 않게 지수 0.6 으로 누그러뜨린다(짧은 칸도 숨은 쉬게).
    final avail = maxWidth - kFitGap * (cols - 1);
    final nat = [for (final w in widths) w];
    final weight = [for (final w in nat) math.pow(w, 0.6).toDouble()];
    final sum = weight.fold<double>(0, (a, b) => a + b);
    for (var c = 0; c < cols; c++) {
      widths[c] = avail * weight[c] / sum;
    }
    // 짧은 칸이 제 글보다 넓게 받았으면 남는 몫을 긴 칸에 돌려준다.
    for (var round = 0; round < 3; round++) {
      var spare = 0.0;
      final room = <int>[];
      for (var c = 0; c < cols; c++) {
        if (widths[c] > nat[c] + 4) {
          spare += widths[c] - (nat[c] + 4);
          widths[c] = nat[c] + 4;
        } else {
          room.add(c);
        }
      }
      if (spare < 1 || room.isEmpty) break;
      final rs = room.fold<double>(0, (a, c) => a + weight[c]);
      for (final c in room) {
        widths[c] += spare * weight[c] / rs;
      }
    }
    for (var c = 0; c < cols; c++) {
      widths[c] = widths[c].floorToDouble();
    }
  } else {
    for (var c = 0; c < cols; c++) {
      widths[c] = widths[c].clamp(kMinCol, kMaxCol);
    }
  }
  // 화면보다 좁으면 남는 폭을 열마다 고르게 나눠 판을 채운다.
  final used = widths.fold<double>(0, (a, b) => a + b) + kCellGap * (cols - 1);
  if (!fit && fill && used < maxWidth && cols > 0) {
    final add = (maxWidth - used) / cols;
    for (var c = 0; c < cols; c++) {
      widths[c] = (widths[c] + add).floorToDouble();
    }
  }
  for (var c = 0; c < cols; c++) {
    if (widths[c] < 24) widths[c] = 24;
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
  return TableCardLayout(widths, heights, fit: fit);
}

class TableCard extends StatefulWidget {
  const TableCard({
    super.key,
    required this.grid,
    required this.layout,
    required this.fontSize,
    required this.ink,
    required this.line,
    this.onCopy,
    this.onEdit,
    this.panel,
    this.family,
  });

  final TableGrid grid;
  final TableCardLayout layout;
  final double fontSize;
  final Color ink;
  final Color line;

  /// 카드 오른쪽 아래 떠 있는 작은 단추 둘(2026-11-11 소유자 지시 — 챗GPT
  /// 표처럼). 둘 다 null 이면 단추를 안 띄운다(표 편집 창의 미리보기·그림).
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final Color? panel;
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

  Widget _grid() {
    final t = widget.grid;
    final l = widget.layout;
    final rows = [t.header, ...t.rows];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < l.colWidths.length; c++) ...[
                if (c > 0) SizedBox(width: l.gap),
                Container(
                  width: l.colWidths[c],
                  height: l.rowHeights[r],
                  padding: const EdgeInsets.symmetric(vertical: kCellPadV),
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
    );
  }

  Widget _btn(IconData ic, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Icon(ic, size: 17, color: widget.ink.withValues(alpha: 0.75)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = widget.layout;
    final body = l.image
        ? Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: l.gridW * l.scale,
              height: l.gridH * l.scale,
              child: FittedBox(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: l.gridW,
                  height: l.gridH,
                  child: _grid(),
                ),
              ),
            ),
          )
        : l.fit
        ? _grid()
        : Scrollbar(
            controller: _sc,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: kScrollBarSpace),
              child: _grid(),
            ),
          );
    final hasBtns = widget.onCopy != null || widget.onEdit != null;
    return SizedBox(
      height: l.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kCardVPad),
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (hasBtns)
              Positioned(
                right: 2,
                bottom: (l.fit ? 0 : kScrollBarSpace) + 4,
                child: Material(
                  color: (widget.panel ?? Colors.white).withValues(alpha: 0.94),
                  elevation: 1.5,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: widget.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onCopy != null)
                        _btn(CupertinoIcons.doc_on_doc, widget.onCopy!),
                      if (widget.onCopy != null && widget.onEdit != null)
                        Container(width: 1, height: 18, color: widget.line),
                      if (widget.onEdit != null)
                        _btn(CupertinoIcons.slider_horizontal_3, widget.onEdit!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
