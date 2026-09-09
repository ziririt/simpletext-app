/// 보기 설정 — 전자책 뷰어의 그 판.
///
/// 2026-09-09 소유자 지시 — "편집화면에서 바로 '보기 설정'을 하고 싶다.
/// 전자책 뷰어 앱과 다를 이유가 없다. (…) '이 노트에만 적용'을 두고, 그걸
/// 체크하면 이 노트에만 이 값이 저장되고, 기본은 전체 노트에 적용되는
/// 것이다. (…) '앱설정'에서의 편집 화면 배경을 별도로 두지 말고 이 안에
/// 넣어라."
///
/// ## 판이 하나다
///
/// 같은 [ViewSettingsPanel] 을 두 자리에서 쓴다.
///   - 편집 화면의 시트 — `noteId` 가 있다. '이 노트에만 적용' 줄이 뜬다.
///   - 앱 설정의 화면 — `noteId` 가 null. 그 줄만 없다.
/// **다른 것은 그 한 줄뿐이다.** 두 벌로 만들면 반드시 한쪽만 고쳐지고,
/// 그러면 같은 이름의 설정이 자리마다 다르게 동작한다.
///
/// ## '이 노트에만 적용'을 끄면 무슨 일이 일어나는가
///
/// **지금 화면의 값이 그대로 전체 설정이 되고, 이 노트의 덮어쓰기는
/// 지워진다.** "끄면 모든 노트에 적용됩니다"라는 말 그대로다. 이 노트에서
/// 맞춰 본 값을 마음에 들어 전체에 퍼뜨리는 길이 이것이다.
///
/// 반대로 켤 때는 아무것도 안 벌어진다. 켠 그 순간의 값은 전체값과 같아서
/// 덮어쓸 것이 없기 때문이다(ViewPrefs.diff). 무언가를 바꾸는 순간부터
/// 그 칸만 이 노트에 적힌다.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/body_font.dart';
import 'core/mono_controller.dart';
import 'core/paper.dart';
import 'core/view_prefs.dart';
import 'l10n/l10n.dart';
import 'main.dart'
    show AppColorsX, AppSettings, PaperPainter, SplitShell, Store, scrollPad;
import 'web_font.dart' show kWebFontFamily;

/// 편집 화면에서 여는 시트.
Future<void> showViewSettings(BuildContext context, {String? noteId}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) =>
          ViewSettingsPanel(noteId: noteId, scrollController: controller),
    ),
  );
}

/// 앱 설정에서 여는 화면.
class ViewSettingsScreen extends StatelessWidget {
  const ViewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(L10n.of(context).viewSettingsTitle)),
    body: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: SplitShell.readWidth(context)),
        child: const ViewSettingsPanel(),
      ),
    ),
  );
}

class ViewSettingsPanel extends StatefulWidget {
  const ViewSettingsPanel({super.key, this.noteId, this.scrollController});

  /// 어느 노트에서 열었나. null 이면 앱 전체 설정이다.
  final String? noteId;
  final ScrollController? scrollController;

  @override
  State<ViewSettingsPanel> createState() => _ViewSettingsPanelState();
}

class _ViewSettingsPanelState extends State<ViewSettingsPanel> {
  final store = Store.instance;
  late ViewSpec _spec;
  late bool _only;

  @override
  void initState() {
    super.initState();
    _spec = store.viewFor(widget.noteId);
    // 이미 이 노트에만 걸린 값이 있으면 켜진 채로 연다.
    _only = store.noteView(widget.noteId).isNotEmpty;
  }

  bool get _perNote => widget.noteId != null;

  /// 지금 값을 어디에 적을지 정하고, 적는다.
  void _commit() {
    final id = widget.noteId;
    if (_perNote && _only) {
      // 전체값과 다른 칸만 적는다. 같은 값을 통째로 베껴 두면 나중에 전체
      // 설정을 바꿔도 이 노트만 옛 값에 갇힌다(ViewPrefs.diff 주석).
      store.setNoteView(id!, ViewPrefs.diff(_spec, store.globalView));
      store.notifyView();
      return;
    }
    final s = store.settings;
    s.bodyFont = _spec.font;
    s.bodyFontSize = _spec.fontSize;
    s.bodyLineHeight = _spec.lineHeight;
    s.bodyBold = _spec.bold;
    s.bodyMargin = _spec.margin;
    s.bodyAlign = _spec.align;
    s.paraGap = _spec.paraGap;
    s.paperMode = _spec.paper;
    if (id != null) s.noteViews.remove(id);
    store.persistSettings();
    store.notifyView();
  }

  void _set(ViewSpec next) {
    setState(() => _spec = next);
    _commit();
  }

  void _tick(ViewSpec next) {
    HapticFeedback.selectionClick();
    _set(next);
  }

  void _reset() {
    final d = AppSettings();
    _tick(
      ViewSpec(
        font: d.bodyFont,
        fontSize: d.bodyFontSize,
        lineHeight: d.bodyLineHeight,
        bold: d.bodyBold,
        margin: d.bodyMargin,
        align: d.bodyAlign,
        paraGap: d.paraGap,
        paper: d.paperMode,
      ),
    );
  }

  /// 줄 쳐진 종이인가. 문단 간격을 잠그는 까닭은 mono_controller 주석에 있다.
  bool get _ruled => drawsHorizontal(paperById(_spec.paper).ruling);

  // ── 조각들 ────────────────────────────────────────────────

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  );

  /// − 값 + 한 줄. 전자책 뷰어의 그 모양이다.
  Widget _step(
    String title,
    String value, {
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
    bool enabled = true,
  }) {
    final c = context.c;
    Widget btn(IconData ic, VoidCallback? on) => InkResponse(
      onTap: enabled ? on : null,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Icon(
          ic,
          size: 18,
          color: (enabled && on != null)
              ? c.guideInk
              : c.sub.withValues(alpha: 0.4),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: enabled ? null : c.sub,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                btn(Icons.remove, onMinus),
                SizedBox(
                  width: 46,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : c.sub,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                btn(Icons.add, onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg<T>(
    String title,
    List<(T, String, TextStyle?)> items,
    T now,
    void Function(T) pick,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final it in items)
                ButtonSegment<T>(
                  value: it.$1,
                  label: Text(
                    it.$2,
                    style: (it.$3 ?? const TextStyle()).copyWith(fontSize: 13),
                  ),
                ),
            ],
            selected: {now},
            onSelectionChanged: (v) => pick(v.first),
          ),
        ),
      ],
    ),
  );

  Widget _papers(L10n l) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = context.c;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.paperTitle),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kPapers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = kPapers[i];
              final on = _spec.paper == p.id;
              final isNone = p.id == kPaperNone;
              return GestureDetector(
                onTap: () => _tick(_spec.copyWith(paper: p.id)),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 68,
                      decoration: BoxDecoration(
                        color: isNone ? c.panel : Color(p.bgOf(dark)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: on ? c.accent : c.line,
                          width: on ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isNone
                          ? Icon(Icons.block, size: 18, color: c.sub)
                          : CustomPaint(
                              painter: PaperPainter(
                                ruling: p.ruling,
                                color: Color(p.ruleOf(dark)),
                                lineHeight: 10,
                                colWidth: 10,
                                scroll: 0,
                                headPad: 0,
                              ),
                            ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 62,
                      child: Text(
                        nameOf(p.id),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: on ? c.accent : c.sub,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sample(L10n l) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = paperById(_spec.paper);
    final onPaper = p.id != kPaperNone;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: _spec.margin, vertical: 14),
      decoration: BoxDecoration(
        color: onPaper ? Color(p.bgOf(dark)) : context.c.codeBg,
        border: Border.all(color: context.c.codeLine),
        borderRadius: BorderRadius.circular(10),
      ),
      // 견본은 고른 값 그대로 보여 준다. 견본이 다른 값이면 견본이 아니다.
      child: Text(
        l.bodyFontSizeSample,
        textAlign: _spec.align == kAlignJustify
            ? TextAlign.justify
            : TextAlign.start,
        style: TextStyle(
          fontSize: _spec.fontSize,
          height: _spec.lineHeight,
          fontWeight: _spec.bold ? FontWeight.w600 : FontWeight.w400,
          color: onPaper ? Color(p.inkOf(dark)) : null,
          fontFamily: bodyFontFamily(
            _spec.font,
            webDefault: kIsWeb ? kWebFontFamily : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = context.c;
    return ListView(
      controller: widget.scrollController,
      padding: widget.scrollController != null
          ? const EdgeInsets.fromLTRB(18, 0, 18, 28)
          : scrollPad(
              context,
              top: 8,
            ).add(const EdgeInsets.symmetric(horizontal: 18)),
      children: [
        if (_perNote) ...[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.viewOnlyThisNote,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              l.viewOnlyThisNoteSub,
              style: TextStyle(fontSize: 13.5, color: c.guideInk),
            ),
            value: _only,
            onChanged: (v) {
              setState(() => _only = v);
              // 끄면 지금 값이 그대로 전체가 된다(머리말 참고).
              _commit();
            },
          ),
          Divider(color: c.line, height: 18),
        ],
        _seg<String>(
          l.bodyFontTitle,
          [
            (kBodyFontSystem, l.bodyFontSystem, null),
            (
              kBodyFontNoto,
              l.bodyFontNoto,
              const TextStyle(fontFamily: 'NotoSansKR'),
            ),
            (
              kBodyFontMono,
              l.bodyFontMono,
              const TextStyle(fontFamily: 'D2Coding'),
            ),
          ],
          _spec.font,
          (v) => _tick(_spec.copyWith(font: v)),
        ),
        _step(
          l.bodyFontSizeTitle,
          '${_spec.fontSize.round()}',
          onMinus: _spec.fontSize > MonoTextController.minBodyFontSize
              ? () => _tick(_spec.copyWith(fontSize: _spec.fontSize - 1))
              : null,
          onPlus: _spec.fontSize < MonoTextController.maxBodyFontSize
              ? () => _tick(_spec.copyWith(fontSize: _spec.fontSize + 1))
              : null,
        ),
        _seg<bool>(
          l.viewBoldTitle,
          [(false, l.viewBoldOff, null), (true, l.viewBoldOn, null)],
          _spec.bold,
          (v) => _tick(_spec.copyWith(bold: v)),
        ),
        _step(
          l.bodyLineHeightTitle,
          _spec.lineHeight.toStringAsFixed(1),
          onMinus: _spec.lineHeight > MonoTextController.minBodyHeight + 0.001
              ? () => _tick(
                  _spec.copyWith(
                    lineHeight:
                        ((_spec.lineHeight - 0.1) * 10).roundToDouble() / 10,
                  ),
                )
              : null,
          onPlus: _spec.lineHeight < MonoTextController.maxBodyHeight - 0.001
              ? () => _tick(
                  _spec.copyWith(
                    lineHeight:
                        ((_spec.lineHeight + 0.1) * 10).roundToDouble() / 10,
                  ),
                )
              : null,
        ),
        _step(
          l.viewMarginTitle,
          '${_spec.margin.round()}',
          onMinus: _spec.margin > kMarginMin
              ? () => _tick(
                  _spec.copyWith(
                    margin: clampMargin(_spec.margin - kMarginStep),
                  ),
                )
              : null,
          onPlus: _spec.margin < kMarginMax
              ? () => _tick(
                  _spec.copyWith(
                    margin: clampMargin(_spec.margin + kMarginStep),
                  ),
                )
              : null,
        ),
        _seg<String>(
          l.viewAlignTitle,
          [
            (kAlignStart, l.viewAlignStart, null),
            (kAlignJustify, l.viewAlignJustify, null),
          ],
          _spec.align,
          (v) => _tick(_spec.copyWith(align: v)),
        ),
        _step(
          l.viewParaGapTitle,
          _spec.paraGap.toStringAsFixed(2),
          enabled: !_ruled,
          onMinus: _spec.paraGap > kParaGapMin
              ? () => _tick(
                  _spec.copyWith(
                    paraGap: clampParaGap(_spec.paraGap - kParaGapStep),
                  ),
                )
              : null,
          onPlus: _spec.paraGap < kParaGapMax
              ? () => _tick(
                  _spec.copyWith(
                    paraGap: clampParaGap(_spec.paraGap + kParaGapStep),
                  ),
                )
              : null,
        ),
        if (_ruled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.viewParaGapLocked,
              style: TextStyle(fontSize: 13, height: 1.35, color: c.guideInk),
            ),
          ),
        const SizedBox(height: 6),
        _papers(l),
        const SizedBox(height: 14),
        _sample(l),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 17),
            label: Text(l.viewReset),
          ),
        ),
      ],
    );
  }
}
