import 'l10n.dart';

/// English — also the fallback for unsupported system languages.
class L10nEn extends L10n {
  const L10nEn();

  @override
  String get localeTag => 'en';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => 'Version';

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
  String get pasteAndTidy => 'New note from clipboard';
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
  String get seedTitle => 'Welcome to Skyblue Note';
  @override
  String get seedTag => 'How to use';
  @override
  String get seedBody => [
        'Sure! 🙂 Here is everything you asked for, laid out below.',
        '',
        '---',
        '',
        '## How to use Skyblue Note',
        '',
        '**1. Paste & Tidy** — copy an answer from ChatGPT or Claude, then tap "Paste & Tidy".',
        '* Asterisks (**), hash marks (##), emoji 🎉 and throat-clearing intros come off **in one go**.',
        '* Broken tables get repaired at the same time.',
        '',
        '### 2. Working with tables',
        '',
        '> For notes with tables, the "Table" button copies them for spreadsheets (TSV).',
        '',
        '**3. Undo** — every tidy-up can be [reverted](https://example.com/undo) with a single Undo. ✅',
        '',
        '---',
        '',
        'Below is a deliberately broken table. Tap "Tidy" to see it repaired.',
        '',
        '| Stock | Ticker | Return | Weight',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '| NVIDIA | NVDA | +48.9% | 22% |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'Done';

  @override
  String get bodyFontSizeTitle => 'Body text size';

  @override
  String get bodyFontSizeSample =>
      'Meet a Smart workspace that turns the many thoughts in your head into pure Simplicity. Paste it, tap Tidy once, and everything comes out Clean.';

  @override
  String get wizardNothingToDo => 'Nothing to change';

  @override
  String wizardAppliedToast(int count) => 'Applied $count instruction(s)';

  @override
  String get skipPreviewCheck => 'Skip preview from now on';

  @override
  String get previewTitle2 => 'Preview before applying';

  @override
  String get previewSub2 => 'Shows the result first and asks before applying';
  @override
  String get metaTooltip => 'Source & tags';
  @override
  String get pinTooltip => 'Pin to top';
  @override
  String get unpinTooltip => 'Unpin';
  @override
  String get deleteTooltip => 'Delete';
  @override
  String get titleHint => 'Title (auto)';
  @override
  String get sourceNone => 'No source';
  @override
  String get sourceOther => 'Other';
  @override
  String get tagsHint => 'Tags (comma separated)';
  @override
  String get tagAiButton => 'AI tags';
  @override
  String get tagAiWorking => 'Finding tags…';
  @override
  String get tagAiNone => 'No keywords found';
  @override
  String get tagAiLocalNote => 'No AI key — picked on this device';
  @override
  String get tagsBoxHint => 'Type a tag, then comma';
  @override
  String get tagRemoveTip => 'Remove tag';
  @override
  String get bodyHint => 'Paste or type here';
  @override
  String get noteNotFound => 'Note not found';
  @override
  String get revertedToast => 'Back to the original. The previous text is in Version history.';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => 'Restore original';

  @override
  String get revertConfirmTitle => 'Go back to the original?';

  @override
  String get revertConfirmBody =>
      'This returns the note to the text you first pasted. Every tidy-up and every edit you made after that will be gone.\n\nThe text you have now is kept in Version history, so you can bring it back.';

  @override
  String get revertConfirmOk => 'Restore';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => 'Bullet list';

  @override
  String get listDashAction => 'Dash list';

  @override
  String get listNumberAction => 'Numbered list';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => 'Source';

  @override
  String sourceSaved(String name) => 'Source saved: $name';

  @override
  String sourceDetected(String name) => 'Source detected: $name';

  @override
  String get sourceCleared => 'Source cleared';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'Folder';

  @override
  String get folderNone => 'No folder';

  @override
  String get folderNew => 'New folder';

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get folderCleared => 'Removed from folder';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => 'Checking whether it can actually be used…';

  @override
  String get aiPingOk => 'Editing works. You are ready to go.';

  @override
  String aiPingFailed(String err) => 'The list came back, but the edit call was refused — $err';

  @override
  String get aiAdvancedNote => 'You usually do not need this. The key alone is enough.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => 'Plain';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWalnut => 'Walnut';

  @override
  String get paperNight => 'Night';

  @override
  String get paperSky => 'Sky';

  @override
  String get themeSystemNote =>
      'Follow the device and the app turns dark when your device does.';

  @override
  String folderMoved(String name) => 'Moved to $name';
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
  String get wizardAction => 'AI edit';
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
  String get wizardTitle => 'AI edit';
  @override
  String get wizardHint =>
      'Tell it what to do. e.g.\nMake it 2 blank lines above headings, 1 below\nReplace MS with Microsoft';
  @override
  String get favSaveButton => 'Save as a favorite';
  @override
  String get favListTitle => 'Favorite instructions';
  @override
  String get favUse => 'Use';
  @override
  String get favEmpty => 'No saved instructions yet';
  @override
  String get favRemove => 'Remove';
  @override
  String get favSavedToast => 'Saved';
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
  String get presetAiName =>
      'Standard tidy';
  @override
  String get presetAiDesc =>
      'Makes a pasted AI answer readable. This is enough most of the time';
  @override
  String get presetStripName =>
      'Strip all marks';
  @override
  String get presetStripDesc =>
      'For places without formatting, like chat and SMS';
  @override
  String get presetMinimalName =>
      'Lint only';
  @override
  String get presetMinimalDesc =>
      'Keeps the structure, removes only invisible junk';
  @override
  String get presetTablesName =>
      'Tables only';
  @override
  String get presetTablesDesc =>
      'To paste straight into Excel or Google Sheets';
  @override
  String get presetBlogName =>
      'For blogs';
  @override
  String get presetBlogDesc =>
      'Keeps link addresses, drops the marks';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get menuAppSettings => 'App settings';

  @override
  String get menuAiKey => 'AI API key';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'The same notes on iPhone, iPad and Mac';

  @override
  String get syncStateOff => 'Turn on iCloud Drive in your device settings';

  @override
  String get syncStateSyncing => 'Connecting to iCloud… this takes a few seconds to a minute';

  @override
  String get aiKeyNotSynced => 'Your notes sync to all your devices through iCloud. Your API key does not — enter it separately on each device.';

  @override
  String get syncStateSignedOut => 'Tap to see how';

  @override
  String get syncHelpTitle => 'How to turn on iCloud';

  @override
  String get syncHelpSteps =>
      '1. Settings › your name at the top › iCloud\n2. Check that iCloud Drive is on — if it is off, no app syncs\n3. Lock and unlock your phone, come back here and tap Check again\n\nCheck in the Files app, not Settings. If you see a Skyblue Note folder in Files › iCloud Drive, it is ready.';

  @override
  String get syncOpenSettings => 'Open Settings';

  @override
  String get syncRecheck => 'Check again';

  @override
  String get syncHelpNote =>
      'If you just installed the app, it can take a minute or two to get ready. Just tap Check again.';

  @override
  String get sortFilterTooltip => 'Sort & filter';

  @override
  String get sortFilterTitle => 'Sort and filter';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortUpdated => 'Last edited';

  @override
  String get sortCreated => 'Date created';

  @override
  String get sortByTitle => 'Title';

  @override
  String get filterSourceLabel => 'Source';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterAll => 'All';

  @override
  String get filterReset => 'Reset';

  @override
  String get trashTitle => 'Trash';

  @override
  String get trashSubtitle => 'Deleted notes are kept for 30 days';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashRestore => 'Restore';

  @override
  String get trashDeleteNow => 'Delete now';

  @override
  String get trashEmptyAll => 'Empty';

  @override
  String get trashEmptyConfirm => 'Emptying the trash cannot be undone. Continue?';

  @override
  String get trashRestored => 'Restored';

  @override
  String trashDaysLeftLabel(int days) => 'Deleted permanently in $days days';

  @override
  String get exportSectionTitle =>
      'Import & export';

  @override
  String get exportSubtitle =>
      'Your notes can leave any time. Markdown opens in Apple Notes, Obsidian, Notion and the rest.';

  @override
  String get exportNote =>
      'Export this note';

  @override
  String get exportAllMd =>
      'Export all notes';

  @override
  String get exportAllMdSub =>
      'Every note as Markdown, in one zip';

  @override
  String get exportBackup =>
      'Save a backup file';

  @override
  String get exportBackupSub =>
      'One file that restores everything here (your API key is left out)';

  @override
  String get exportFailed =>
      'Export failed';

  @override
  String get exportEmpty =>
      'There are no notes to export';

  @override
  String get choosePreset => 'Choose how to tidy';

  @override
  String get importFiles =>
      'Import from files';

  @override
  String get importFilesSub =>
      'Markdown and text files become notes. Backup files restore here too';

  @override
  String get importAppend =>
      'Load a file and append it';

  @override
  String get importNone =>
      'Nothing was imported';

  @override
  String importDone(int n) => 'Imported $n notes';

  @override
  String get sourceGuessSuffix => '(guess)';

  @override
  String get splitEmpty => 'Pick a note on the left';

  @override
  String get historyTitle =>
      'Version history';

  @override
  String get historySub =>
      'Go back to the text before a tidy or replace';

  @override
  String get historyEmpty =>
      'Nothing to go back to yet';

  @override
  String get historyRestore =>
      'Restore';

  @override
  String get historyOriginal =>
      'As pasted';

  @override
  String historyUnknownTime(int n) => 'Earlier version $n';

  @override
  String get selUnitSentence => 'Sentence';

  @override
  String get selUnitLine => 'Line';

  @override
  String get selUnitPara => 'Paragraph';

  @override
  String get selUnitAll => 'All';

  @override
  String get selStartLeft => 'Start left';

  @override
  String get selStartRight => 'Start right';

  @override
  String get selEndLeft => 'End left';

  @override
  String get selEndRight => 'End right';

  @override
  String get selClear => 'Clear selection';

  @override
  String get paperTitle => 'Editor background';

  @override
  String get paperSub => 'Background and ruling as a set. Line spacing follows your text size automatically.';

  @override
  String get paperNone => 'Plain';

  @override
  String get paperMoleskine => 'Moleskine';

  @override
  String get paperSepia => 'Sepia';

  @override
  String get paperManuscript => 'Manuscript';

  @override
  String get paperGrid => 'Grid';

  @override
  String get lockSectionTitle => 'Lock';

  @override
  String get lockTitle => 'App lock';

  @override
  String get lockSub => 'Open the app with Face ID, Touch ID, or your device passcode.';

  @override
  String get lockNote => 'This lock keeps someone who picks up your device from opening the app. It does not encrypt the files stored on the device.';

  @override
  String get lockDelayTitle => 'Lock after';

  @override
  String get lockDelayNow => 'Immediately';

  @override
  String get lockDelay1m => 'After 1 minute';

  @override
  String get lockDelay5m => 'After 5 minutes';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockLocked => 'Locked';

  @override
  String get lockUnavailable => 'Face ID, Touch ID, and device passcode are unavailable on this device.';

  @override
  String get lockReasonOpen => 'Verify to open your notes';

  @override
  String get lockReasonOn => 'Verify to turn on the lock';

  @override
  String get lockReasonOff => 'Verify to turn off the lock';

  @override
  String get syncDiagSignedOut => 'This device is not signed in to iCloud. Please sign in first.';

  @override
  String get syncDiagNoContainer => 'You are signed in, but this app does not have its iCloud space yet. Turn it on with the steps below.';

  @override
  String get syncDiagPreparing => 'The space is there. Waiting for it to finish getting ready.';

  @override
  String get syncRecheckWhat => 'Asks the device about iCloud again, from scratch.';

  @override
  String get syncRecheckOk => 'iCloud is on';

  @override
  String get syncRecheckStill => 'Not on yet. Turn it on in Settings, then tap again. If you just turned it on, try once more in a minute or two.';

  @override
  String get syncOpenFailed => 'Could not open Settings. Please open it from the Home Screen.';

  @override
  String get syncOpenManual => 'Please open Settings yourself: Home Screen › Settings › your name at the top › iCloud.';

  @override
  String get menuFile => 'File';

  @override
  String get menuClose => 'Close';

  @override
  String get menuPrefs => 'Settings…';

  @override
  String get appliedTitle => 'All tidied up';

  @override
  String get tidyRulesTitle => 'Tidy-up rules';

  @override
  String get tidyRulesSub => 'Decides how your text changes when you tap Tidy.';

  @override
  String get syncOnTitle => 'On';

  @override
  String get syncOffTitle => 'Off';

  @override
  String get syncSignedOutTitle => 'Sign in needed';

  @override
  String pastedFrom(String src, String date) =>
      'from $src on $date';

  @override
  String pastedOn(String date) => 'pasted on $date';

  @override
  String staleWarn(int days) =>
      'This answer is $days days old. The model may have changed since.';
  @override
  String get settingsSecView => 'Display';
  @override
  String get settingsSecTidy => 'Tidy rules';
  @override
  String get settingsSecWhen => 'When tidying';
  @override
  String get settingsSecInfo => 'About';
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
  String get citationsSub => 'Removes in-text footnote numbers and the “Sources” list at the end';
  @override
  String get monoEditorTitle => 'Monospaced tables';
  @override
  String get monoEditorSub => 'Aligns table and code columns exactly. Prose keeps your device font';
  @override
  String get dashListTitle => 'Split dash runs into lists';
  @override
  String get dashListSub => 'Splits one-line runs like "– a – b – c" into a line list';
  @override
  String get fillerHeadingTitle => 'Tidy invisible-char headings';
  @override
  String get fillerHeadingSub => 'Applies spacing and heading rules to ㅤ-wrapped pseudo-headings';
  @override
  String get aiSectionTitle => 'AI edit setup';
  @override
  String get aiSectionDesc =>
      'With an API key, AI handles free-form instructions like "make this shorter". Tidy runs on device rules and needs no key — only AI edit does.';
  @override
  String get aiKeyHint => 'API key (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get menuTidyPreview => 'Preview the tidy';
  @override
  String get adClose => 'Close ads';
  @override
  String get noteDuplicate => 'Duplicate';
  @override
  String get noteDuplicated => 'Duplicated';
  @override
  String get adSponsored => 'Sponsored';
  @override
  String get sponsorTitle => 'One ad funds the next update';
  @override
  String get sponsorBody => 'Your support keeps the updates coming. Watch one full-screen ad a day to use the app banner-free for the day — or go Premium and the ads are gone for good.';
  @override
  String get sponsorWatch => 'Watch an ad to support';
  @override
  String get sponsorSkip => 'Skip';
  @override
  String get sponsorLoading => 'Loading ad…';
  @override
  String get sponsorFailed => "Couldn't load the ad. Please try again in a moment.";
  @override
  String get moreTooltip => 'More';
  @override
  String get sponsorGoPremium => 'Go Premium — no ads';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'No ads, on every device';
  @override
  String get premiumPitchSub => 'US\$29.99 once or US\$1.99/month · iPhone, iPad and Mac together';
  @override
  String get premiumBody => 'Premium removes all ads and unlocks Skyblue Note on iPhone, iPad and Mac. One purchase covers all three. Your support builds the next update.';
  @override
  String get premiumLifetime => 'Lifetime · US\$29.99';
  @override
  String get premiumMonthly => 'Monthly · US\$2.99/mo';
  @override
  String get premiumComingSoon => 'Purchases will be enabled in the App Store release. Almost there.';
  @override
  String get limitTitle => 'You have used up today\'s free runs';
  @override
  String limitTidyBody(int n) => 'The free plan includes $n cleanups a day. It resets tomorrow — Premium removes the limit.';
  @override
  String limitWizardBody(int n) =>
      'The free plan includes $n AI edits a day. It resets tomorrow — Premium removes the limit.';
  @override
  String get limitSeePremium => 'See Premium';
  @override
  String get premiumYearly => 'Yearly · US\$14.99/yr';
  @override
  String get premiumLifetimeNote => 'Launch price · regularly US\$39.99';

  @override
  String trialBadge(int days) => 'Unlimited trial · $days days left';

  @override
  String get trialEndedTitle => 'Your unlimited trial has ended';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      'During the trial you ran $tidy tidy-ups and $wiz AI edits. From now on the free plan gives you $tidyLimit tidy-ups and $wizLimit AI edits a day. Premium removes the limit.';
  @override
  String get themeTitle => 'Appearance';
  @override
  String get themeSystem => 'Follow device';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get aiKeyVerify => 'Verify key';
  @override
  String get aiKeyChecking => 'Checking…';
  @override
  String get aiKeyUnknownFormat => 'Unrecognized key format. Set the model manually under Advanced.';
  @override
  String get aiAdvancedLabel => 'Advanced — choose the model yourself';
  @override
  String get aiManualModelHint => 'Type a model name (e.g. gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => 'Auto: $provider · $model';
  @override
  String aiModelsFound(int n) => '$n models available.';
  @override
  String aiListFailed(String error) => "Couldn't fetch the model list ($error). Using the built-in fallback list.";
  @override
  String aiModelSwitched(String model) => 'Switched to $model because the previous model stopped responding.';
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
