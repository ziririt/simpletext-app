/// 시간 여행 — 손잡이 하나로 글의 과거를 훑는다.
///
/// 2026-08-29. 왜 이 기능인지는 core/time_travel.dart 머리말에 있다.
/// 여기는 그 정거장들을 화면으로 옮긴 것뿐이다.
///
/// ## 목록이 아니라 길이다
///
/// 버전 기록 화면은 이미 있고, 정확하다. 다만 목록이라 **아무 감흥이
/// 없다.** 줄을 하나씩 눌러 미리보기를 열고 닫는 동안, 글이 어떻게
/// 자라났는지는 머릿속에서 이어 붙여야 한다.
///
/// 손잡이로 훑으면 그 이음질을 눈이 대신한다. 같은 자료, 다른 감각이다.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/time_travel.dart';
import 'rich_note_text.dart';

class TimeTravelView extends StatefulWidget {
  const TimeTravelView({
    super.key,
    required this.stops,
    required this.fontSize,
    required this.lineHeight,
    required this.nowLabel,
    required this.whyLabel,
    required this.whenLabel,
    required this.growLabel,
    required this.restoreLabel,
    required this.onRestore,
    this.fontFamily,
  });

  final List<Stop> stops;
  final double fontSize;
  final double lineHeight;
  final String? fontFamily;

  /// '지금'
  final String nowLabel;

  /// 부호를 사람 말로. ('tidy' → '정리함')
  final String Function(String why) whyLabel;

  /// 시각을 사람 말로. 0이면 '언제인지 모름'.
  final String Function(int at) whenLabel;

  /// '132자 줄었습니다' 같은 한 줄. 0이면 빈 글자를 준다.
  final String Function(int delta) growLabel;

  final String restoreLabel;

  /// 이 판으로 되돌린다. 지금 판에서는 안 불린다.
  final void Function(Stop stop) onRestore;

  @override
  State<TimeTravelView> createState() => _TimeTravelViewState();
}

class _TimeTravelViewState extends State<TimeTravelView> {
  late int _i = widget.stops.length - 1; // 늘 지금에서 출발한다
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _go(int i) {
    final n = widget.stops.length;
    final k = i < 0 ? 0 : (i >= n ? n - 1 : i);
    if (k == _i) return;
    setState(() => _i = k);
    // 정거장을 지날 때마다 한 번씩. 눈으로만 훑으면 몇 정거장을
    // 지났는지 모른다 — 손끝이 세어 준다.
    HapticFeedback.selectionClick();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final s = stops[_i];
    final theme = Theme.of(context);
    final ink = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final mark = ink.withValues(alpha: 0.45);
    final accent = theme.colorScheme.primary;
    final delta = growth(stops, _i);
    final grow = widget.growLabel(delta);

    return Column(
      children: [
        // ── 지금 어느 정거장인가 ──────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: s.now ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.now ? widget.nowLabel : widget.whyLabel(s.why),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.whenLabel(s.at),
                        style: TextStyle(fontSize: 13, color: mark)),
                  ),
                  Text('${_i + 1} / ${stops.length}',
                      style: TextStyle(fontSize: 12.5, color: mark)),
                ],
              ),
              if (grow.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(grow,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: delta < 0 ? accent : mark,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        // ── 그때의 글 ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: RichNoteText(
              text: s.text,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              ink: ink,
              mark: mark,
              fontFamily: widget.fontFamily,
            ),
          ),
        ),
        // ── 길 ──────────────────────────────────────────────
        //
        // 정거장이 하나뿐이면 손잡이를 아예 안 그린다. 밀 데가 없는
        // 손잡이는 고장으로 읽힌다.
        if (stops.length > 1)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.22),
                        thumbColor: accent,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        tickMarkShape:
                            const RoundSliderTickMarkShape(tickMarkRadius: 2.5),
                        activeTickMarkColor: Colors.white,
                        inactiveTickMarkColor: accent.withValues(alpha: 0.45),
                      ),
                      child: Slider(
                        value: _i.toDouble(),
                        min: 0,
                        max: (stops.length - 1).toDouble(),
                        divisions: stops.length - 1,
                        onChanged: (v) => _go(v.round()),
                      ),
                    ),
                  ),
                  if (!s.now)
                    TextButton(
                      onPressed: () => widget.onRestore(s),
                      child: Text(widget.restoreLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
