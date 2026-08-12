import 'l10n.dart';

/// English — also the fallback for unsupported system languages.
class L10nEn extends L10n {
  const L10nEn();

  @override
  String get localeTag => 'en';

  @override
  String get appTitle => 'SimpleText';

  @override
  String get homeTitle => 'Notes';
  @override
  String get settingsTooltip => 'Tidy rules';
  @override
  String get searchHint => 'Search';
  @override
  String get emptyList => 'No notes yet.\nStart with "Paste & Tidy".';
  @override
  String get pinnedLabel => 'Pinned';
  @override
  String get notesLabel => 'Notes';
  @override
  String get newNoteTooltip => 'New note';
  @override
  String get pasteAndTidy => 'Paste & Tidy';
  @override
  String get clipboardEmpty => 'Clipboard is empty. Copy an AI answer first.';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get untitled => 'Untitled';
  @override
  String get deleteConfirmTitle => 'Delete this note?';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';

  @override
  String dateShort(int y, int m, int d) => '$m/$d/$y';

  @override
  String get seedTitle => 'Welcome to SimpleText';
  @override
  String get seedTag => 'How to use';
  @override
  String get seedBody => [
        'How to use SimpleText',
        '',
        '1. Copy an answer from ChatGPT or Claude, then tap "Paste & Tidy".',
        '2. Compare the original and the result in the preview, tap "Apply" — done.',
        '3. For notes with tables, the "Table" button copies them for spreadsheets (TSV).',
        '4. Every tidy-up can be reverted with a single Undo.',
        '',
        'Below is a deliberately broken table. Tap "Tidy" to see it repaired.',
        '',
        '| Stock | Ticker | Return | Weight',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5%',
        '| Nvidia | NVDA | +48.9% | 22% | extra cell |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'Done';
  @override
  String get metaTooltip => 'Source & tags';
  @override
  String get pinTooltip => 'Pin to top';
  @override
  String get unpinTooltip => 'Unpin';
  @override
  String get deleteTooltip => 'Delete';
  @override
  String get titleHint => 'Title';
  @override
  String get sourceNone => 'No source';
  @override
  String get sourceOther => 'Other';
  @override
  String get tagsHint => 'Tags (comma separated)';
  @override
  String get bodyHint => 'Paste or type here';
  @override
  String get noteNotFound => 'Note not found';
  @override
  String get revertedToast => 'Reverted to the previous version';
  @override
  String appliedDone(String summary) => 'Applied — $summary';

  @override
  String get undoTip => 'Undo';
  @override
  String get redoTip => 'Redo';
  @override
  String get moveLeftTip => 'Move left';
  @override
  String get moveRightTip => 'Move right';
  @override
  String get lineStartTip => 'Line start';
  @override
  String get lineEndTip => 'Line end';
  @override
  String get indentTip => 'Indent';
  @override
  String get hideKeyboardTip => 'Hide keyboard';

  @override
  String get tidyAction => 'Tidy';
  @override
  String get wizardAction => 'Wizard';
  @override
  String get tableAction => 'Table';
  @override
  String get replaceAction => 'Replace';
  @override
  String get copyAction => 'Copy';
  @override
  String get undoAction => 'Undo';

  @override
  String get noTablesFound => 'No tables found in this note';
  @override
  String tableInfo(int n, int cols, int rows) => 'Table $n — $cols cols × $rows rows';
  @override
  String get forSpreadsheet => 'For spreadsheets';
  @override
  String get copiedSpreadsheet => 'Copied — paste into a Google Sheets or Excel cell';
  @override
  String get copiedCsv => 'Copied as CSV';
  @override
  String get copiedMarkdown => 'Copied as a Markdown table';

  @override
  String get wizardTitle => 'Wizard';
  @override
  String get wizardHint =>
      'Tell it what to do. e.g.\nMake it 2 blank lines above headings, 1 below\nReplace MS with Microsoft';
  @override
  String appliedPrefix(String what) => 'Applied · $what';
  @override
  String unknownPrefix(String what) => 'Not a recognized rule · $what';
  @override
  String get aiKeyPromo => 'Add an AI API key in Settings to handle free-form edits like this.';
  @override
  String get aiRunUnknown => 'Run unrecognized commands with AI';
  @override
  String get aiBusyLabel => 'AI editing…';
  @override
  String get aiEmptyResponse => 'Empty response';
  @override
  String aiCallFailed(String error) => 'AI call failed: $error';
  @override
  String get aiApplyResult => 'Apply AI result';
  @override
  String get aiAppliedToast => 'AI edit applied — recoverable with Undo';
  @override
  String get close => 'Close';
  @override
  String get interpretApply => 'Interpret & apply';

  @override
  String get replaceTitle => 'Replace';
  @override
  String get findLabel => 'Find';
  @override
  String get replaceWithLabel => 'Replace with (\\n = line break)';
  @override
  String get regexLabel => 'Regex';
  @override
  String get saveAsRule => 'Save as auto-replace rule';
  @override
  String get saveAsRuleSub => 'Always applied on every future "Tidy"';
  @override
  String get invalidRegex => 'Invalid regular expression';
  @override
  String get noMatches => 'No matches found';
  @override
  String replacedCount(int count) => 'Replaced in $count places';
  @override
  String get savedRuleSuffix => ' · saved as an auto-replace rule';
  @override
  String get replaceAllAction => 'Replace all';

  @override
  String get copyAll => 'Copy all';
  @override
  String get copiedAll => 'Copied the full text';
  @override
  String get tidyCopy => 'Tidy & copy';
  @override
  String get tidyCopySub => 'Keeps the note as is, copies only the tidied result';
  @override
  String tidyCopied(String summary) => 'Tidied and copied — $summary';
  @override
  String get copyTableSpreadsheet => 'Copy tables for spreadsheets';
  @override
  String get copiedTableSpreadsheet => 'Copied tables for spreadsheets';

  @override
  String previewTitle(String preset) => '$preset — Preview';
  @override
  String warningPrefix(String warning) => 'Note: $warning';
  @override
  String get tidyResultLabel => 'Tidied result';
  @override
  String get originalLabel => 'Original';
  @override
  String get apply => 'Apply';

  @override
  String get presetAiName => 'Tidy AI answer';
  @override
  String get presetAiDesc => 'Strips markdown markers, emoji, AI preamble; repairs tables';
  @override
  String get presetStripName => 'Strip all Markdown';
  @override
  String get presetStripDesc => 'Removes as much markdown syntax as possible; tables become TSV';
  @override
  String get presetMinimalName => 'Minimal tidy';
  @override
  String get presetMinimalDesc => 'Keeps structure; removes only noise (spaces, zero-width chars)';
  @override
  String get presetTablesName => 'Tables only';
  @override
  String get presetTablesDesc => 'Extracts tables from the document as TSV';
  @override
  String get presetBlogName => 'Paste to blog';
  @override
  String get presetBlogDesc => 'Strips markers, keeps link URLs, repairs tables';

  @override
  String get settingsTitle => 'Tidy rules';
  @override
  String get emphTitle => 'Bold emphasis (**text**)';
  @override
  String get emphSub => 'Whole sentences over 40 chars always get markers removed only';
  @override
  String get emphQuoteSingle => "Single quotes 'emphasis'";
  @override
  String get emphQuoteDouble => 'Double quotes "emphasis"';
  @override
  String get removeLabel => 'Remove';
  @override
  String get keepLabel => 'Keep';
  @override
  String get hrTitle => 'Dividers (---)';
  @override
  String get headingTitle => 'Headings (#, ##)';
  @override
  String get headingStrip => 'Keep text only';
  @override
  String get headingKeep => 'Keep as is';
  @override
  String get headingPrefix => 'Prefix with ■';
  @override
  String get headingBracket => '[Brackets]';
  @override
  String get bulletTitle => 'Bullets (-, *)';
  @override
  String get bulletHyphen => 'Hyphen -';
  @override
  String get bulletMiddot => 'Middle dot ·';
  @override
  String get bulletDot => 'Bullet •';
  @override
  String get bulletWhite => 'White bullet ◦';
  @override
  String get bulletKeep => 'Keep original symbol';
  @override
  String get bulletIndentTitle => 'Bullet indent';
  @override
  String get indent2 => '2 spaces';
  @override
  String get indent4 => '4 spaces';
  @override
  String get indentNone => 'None';
  @override
  String get headingPadTitle => 'Heading spacing';
  @override
  String get headingPadSub =>
      '2 lines above, 1 below — an invisible character (ㅤ) keeps it in chat apps and blogs';
  @override
  String get citationsTitle => 'Remove citation links';
  @override
  String get citationsSub => 'Removes [1]: URL citation blocks and in-text [1] marks';
  @override
  String get monoEditorTitle => 'Monospaced editor font';
  @override
  String get monoEditorSub => 'Aligns table columns exactly. Applies to the whole editor';
  @override
  String get dashListTitle => 'Split dash runs into lists';
  @override
  String get dashListSub => 'Splits one-line runs like "– a – b – c" into a line list';
  @override
  String get fillerHeadingTitle => 'Tidy invisible-char headings';
  @override
  String get fillerHeadingSub => 'Applies spacing and heading rules to ㅤ-wrapped pseudo-headings';
  @override
  String get aiSectionTitle => 'AI Wizard connection (free-form edits)';
  @override
  String get aiSectionDesc =>
      'With an API key, the Wizard handles free-form commands like "make this more concise". The key is stored only on this device.';
  @override
  String get aiKeyHint => 'API key (Google AI or Anthropic)';
  @override
  String get rulesSectionTitle => 'Auto-replace rules';
  @override
  String get rulesSectionDesc =>
      'Applied top to bottom. Use \\n in Replace for a line break. Code blocks are left untouched.';
  @override
  String get addRule => 'Add rule';
  @override
  String get settingsFooter =>
      'Settings take effect immediately and apply from the next "Tidy". Notes you have already tidied are not changed retroactively.';
}
