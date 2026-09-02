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
  String get shareAppTitle => 'Share the app';
  @override
  String get rateAppTitle => 'Rate us';
  @override
  String get shareAppMsg =>
      'Skyblue Note — a light, fast notes app that syncs across all your devices.';
  @override
  String get seedBody => [
        'Hello! 😊 Here is the summary you asked for[1][2].',
        '',
        '# Skyblue Note',
        '',
        'The table is out of line. Tap the **wand** at the bottom left. 🎉',
        '',
        '| Company | Ticker | Return | Weight',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '|Nvidia|NVDA|+48.9%|22%|',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '|Tesla|TSLA|-8.3%|8%|',
        '',
        '> Tidy lines it up. The \'Table\' menu pastes it straight into a spreadsheet.',
        '',
        '## What gets swept away',
        '',
        '- [ ] Filler greetings and emoji 🙂',
        '- [ ] Footnotes stuck to a sentence[3][4]',
        '- [ ] A stray asterisk pair at the end of a line**',
        '- [x] A broken table gets rebuilt',
        '',
        '## What stays',
        '',
        'Headings, **bold** and quotes stay. On screen they read as meaning; paste them into Notes or a forum and the marks are gone.',
        '',
        '---',
        '',
        '\t•\tBullets wrapped in tabs — this is how Grok and ChatGPT paste',
        '\t•\tDoubled   spaces and tabs',
        '\t•\tThese scattered lines find their place too',
        '',
        '> Not happy with it? [Restore original](https://ezlong.com/skybluenote) puts it back.',
      ].join('\n');

  @override
  String get done => 'Done';

  @override
  String get bodyFontSizeTitle => 'Body text size';

  @override
  String get bodyLineHeightTitle => 'Body line spacing';

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
  String get metaTooltip => 'Title & tags';
  @override
  String get pinTooltip => 'Pin to top';
  @override
  String get unpinTooltip => 'Unpin';

  @override
  String get unpinConfirmTitle => 'Unpin this note?';

  @override
  String get unpinConfirmBody =>
      'Long-press a note in the list to pin it again.';
  @override
  String get deleteTooltip => 'Delete';
  @override
  String get titleHint => 'Title (auto)';
  @override
  String get titleTapHint => 'Add a title';
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
      'This returns the note to the text you first pasted. Every tidy-up and every edit you made after that will be gone.\n\nYou can still get back to your earlier edits — the menu → Version history keeps the text you have now as its top entry.';

  @override
  String get revertConfirmOk => 'Restore';

  @override
  String get okAction =>
      'OK';

  @override
  String get revertDoneTitle =>
      'Reverted to the original';

  @override
  String get revertDoneBody =>
      'The text you were working on is not gone.\n\nOpen the menu → Version history: the top entry is the text from just before the revert. Tap it to bring it back at any time.';

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

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => 'Manage folders';

  @override
  String get folderRename => 'Rename';

  @override
  String get folderDelete => 'Delete folder';

  @override
  String get folderReorderHint => 'Drag to reorder';

  @override
  String get folderManageEmpty => 'No folders yet';

  @override
  String get folderDupName => 'A folder with that name already exists';

  @override
  String get folderDeleted => 'Folder deleted';

  @override
  String get folderRenamed => 'Renamed';

  @override
  String folderDeleteBody(String name, int count) =>
      'The $count notes in \'$name\' will still be in All notes. Notes are not deleted.';

  @override
  String folderNoteCount(int count) => '$count notes';

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
  String get todoAction => 'To-do';
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
  String unknownPrefix(String what) => 'The AI will handle this · $what';
  @override
  String get aiKeyPromo => 'Add an AI API key in Settings to handle free-form edits like this.';
  @override
  String get aiBusyLabel => 'AI editing…';
  @override
  String get aiKeyInviteTitle => 'Your own AI key makes this much stronger';
  @override
  String get aiKeyInviteBody => 'Right now only fixed rules are understood. With your own AI key, free-form instructions like "make this more concise" or "rewrite it politely" work too, and tags are pulled by AI.';
  @override
  String get aiKeyCta => 'Add AI key';
  @override
  String get aiKeyPasteBtn => 'Paste';
  @override
  String get aiKeyCost => 'This app simply calls the AI service you already use. Put in the key from whichever you have — Gemini, ChatGPT, Claude or Grok.';
  @override
  String get aiKeySafe => 'The key stays on this device. It is never sent to this app’s servers.';
  @override
  String get aiKeyWhere => 'Where to get a key';
  @override
  String get aiKeyStart => 'Get started';
  @override
  String get recentPromptsTitle => 'Recently used';
  @override
  String get recentEmpty => 'Nothing yet. What you run shows up here';
  @override
  String get favAdd => 'Save as favorite';
  @override
  String get tableFixTitle => 'Tidy tables';
  @override
  String get tableFixSub => 'Rebuilds broken tables and aligns the columns';
  @override
  String get wideTableTitle => 'Wide tables';
  @override
  String get wideTableAuto => 'Auto';
  @override
  String get wideTableAligned => 'Align columns';
  @override
  String get wideTableRecords => 'Write out as text';
  @override
  String get headingBigTitle => 'Subheads as Heading 2';
  @override
  String get headingBigSub => 'Makes detected subheads large and bold (Heading 2)';
  @override
  String get aiWorking => 'The AI is editing as you asked. This can take a little while…';
  @override
  String get aiEmptyResponse => 'Empty response';
  @override
  String aiCallFailed(String error) => 'AI call failed: $error';
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
  String get ruleScopeAll => 'Apply to all notes';
  @override
  String get ruleScopeNote => 'Apply to this note only';
  @override
  String get noteRules => 'Rules for this note';
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
  String get copyPlainSub =>
      'Plain text — markdown marks removed';

  @override
  String get copyRaw => 'Copy as markdown';

  @override
  String get copyRawSub =>
      'For Notion, Slack, GitHub and other markdown-aware apps';
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
  String get apply => 'Apply tidy now';

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
      'For chat and SMS. Every mark and emoji goes; tables become aligned text';
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
  String get tidySample => [
        '## Today\'s summary 😊',
        '',
        'The **key** points are three[1][2].',
        '',
        '- First item',
        '- Second item',
        '',
        '> A quoted line',
        '',
        'More on the [blog](https://ezlong.com)',
        '',
        '| Item | Value |',
        '|---|---|',
        '|Sales|120|',
      ].join('\n');

  @override
  String get settingsTitle => 'Settings';

  @override
  String get menuAppSettings => 'App settings';

  @override
  String get menuAiKey => 'AI API key';

  @override
  String get syncTitle => 'Sync';
  @override
  String get syncAppleOnly => 'Apple only';

  @override
  String get syncScopeTitle =>
      'Sync scope';

  @override
  String get syncScopeShared =>
      'Synced across your devices: notes, tidy rules, custom replace rules, folders, saved AI prompts';

  @override
  String get syncStateOffGdrive => 'Please sign in to your Google account again';
  @override
  String get syncStateExpiredGdrive => 'Your account is still connected, but permission to use Drive has expired. Tap once to renew it.';

  @override
  String get syncScopePlatformGdrive =>
      'The Google Drive store is shared by every device running this app. Install this app and sign in with the same Google account';

  @override
  String get syncScopeDevice =>
      'Per device: text size, line spacing, paper, appearance, sort order';

  @override
  String get syncScopePlatform =>
      'Automatic sync currently works between Apple devices only (iPhone, iPad, Mac). Elsewhere, use Export backup and Import from the menu';

  @override
  String get typographyTitle => 'Text & spacing';

  @override
  String get syncScopeNever =>
      'Your AI API key is never uploaded to any cloud, so enter it on each device';
  @override
  String get syncWhereTitle =>
      'Where to keep it';
  @override
  String get syncBackendNone =>
      'Don\'t sync';
  @override
  String get syncBackendNoneSub =>
      'Keep everything on this device only';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      'Between iPhone, iPad and Mac';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      'Other devices and the web too';
  @override
  String get syncSoon =>
      'Coming soon';

  @override
  String get driveSignInFailed => 'Could not connect your Google account';

  @override
  String get driveNeedsSignIn => 'Connect a Google account first';

  @override
  String get driveSignedInAs => 'Connected';
  @override
  String get syncSectionState =>
      'Right now';
  @override
  String get syncNowAction =>
      'Sync now';
  @override
  String get syncNowBusy => 'Syncing…';

  @override
  String get syncLastNever =>
      'Not synced yet';
  @override
  String get headingTip => 'Heading';
  @override
  String get quoteTip => 'Quote';
  @override
  String get boldTip => 'Bold';
  @override
  String get codeTip => 'Code';
  @override
  String get linkTip => 'Link';
  @override
  String get outdentTip => 'Outdent';
  @override
  String get cursorLeftTip => 'Left';
  @override
  String get cursorRightTip => 'Right';
  @override
  String get clearFormatTip => 'Clear formatting';

  @override
  String get blockFormatTip => 'Paragraph format';

  @override
  String get syncStalledTitle => 'Sync is stopped';

  @override
  String get wipeAction => 'Before and after';

  @override
  String get travelAction => 'Time travel';

  @override
  String get skyAction => 'Constellation';

  @override
  String get timePasted => 'Pasted';

  @override
  String get exportShort => 'Export';
  @override
  String get exportPdfShort => 'PDF';
  @override
  String get printShort => 'Print';
  @override
  String timeEdited(String when) => 'edited $when';
  @override
  String get skyTitle => 'Constellation';
  @override
  String skyCounts(int stars, int links) => '$stars stars · $links links';
  @override
  String skyEmpty(int more) => '$more more notes and your constellation appears here. Similar notes are joined by threads.';
  @override
  String get travelTitle => 'Time travel';
  @override
  String get travelNow => 'Now';
  @override
  String get travelOlder => 'Earlier';
  @override
  String get travelRestore => 'Restore this';
  @override
  String travelShrank(int n) => '$n characters shorter';
  @override
  String travelGrew(int n) => '$n characters longer';
  @override
  String get wipeTitle => 'Before · After';
  @override
  String get wipeBefore => 'Before';
  @override
  String get wipeAfter => 'After';
  @override
  String wipeCounts(int before, int after) => '$before → $after characters';
  @override
  String get syncStalledSub => 'Google access has lapsed. Your notes are safe on this device.';
  @override
  String get syncStalledFix => 'Reconnect';
  @override
  String get blockBody => 'Body';
  @override
  String get blockH1 => 'Heading 1';
  @override
  String get blockH2 => 'Heading 2';
  @override
  String get blockH3 => 'Heading 3';
  @override
  String get blockQuote => 'Quote';
  @override
  String get blockCode => 'Code';
  @override
  String get bodyFontTitle => 'Body font';
  @override
  String get bodyFontSystem => 'System';
  @override
  String get bodyFontNoto => 'Noto';
  @override
  String get bodyFontMono => 'Mono';
  @override
  String get moreTools => 'More';
  @override
  String get findTitle => 'Find';
  @override
  String get findAction => 'Find';
  @override
  String get showReplaceLabel => 'Replace';
  @override
  String get replaceOneAction => 'Replace';
  @override
  String get findNone => 'No matches';
  @override
  String get syncFirstTitle => 'Syncing…';
  @override
  String get syncFirstSub => 'Fetching notes from your other devices. This can take a moment if you have many.';
  @override
  String get syncLogTitle => 'Sync history';
  @override
  String get syncLogNote => 'Only what moved and when. No note content is stored here.';
  @override
  String get syncLogEmpty => 'Nothing has moved yet';
  @override
  String get syncLogNever => 'Not yet';
  @override
  String get syncLogUp => 'Sent';
  @override
  String get syncLogDown => 'Received';
  @override
  String get syncLogFailed => 'Failed';
  @override
  String syncUpdatedAt(String when) => 'Updated ' + when;
  @override
  String findHits(int n) => n.toString() + ' found';
  @override
  String syncLogLastUp(String when) => 'Last sent · ' + when;
  @override
  String syncLogLastDown(String when) => 'Last received · ' + when;
  @override
  String get syncTroubleTitle =>
      'If something goes wrong';
  @override
  String get syncTroubleNote =>
      'Syncing is not a backup. Delete on one device and it goes everywhere. Export a file now and then for the notes that matter.';
  @override
  String syncLastAt(String when) => 'Last synced $when';

  @override
  String syncStateOn(String where) => 'Kept in $where — the same notes on every device with this app';

  @override
  String get syncStateOff => 'Turn on iCloud Drive in your device settings';

  @override
  String syncStateSyncing(String where) => 'Syncing with $where… this takes a few seconds to a minute';

  @override
  String get aiKeyNotSynced => 'Your notes sync to all your devices through the store you chose. Your API key does not — enter it separately on each device.';
  @override
  String get aiKeySyncTitle => 'Sync the API key too';
  @override
  String get aiKeySyncSubApple => 'It travels through the iCloud Keychain — a different road from your notes. Only your devices hold the key, so not even Apple can read it.';
  @override
  String get aiKeySyncSubGdrive => 'Once it is on Google Drive, keeping the API key safe is your own responsibility.';

  @override
  String get autoTagTitle => 'Tag notes automatically';

  @override
  String get autoTagSub =>
      'After you edit and pause, AI refreshes the tags. Notes whose tags you edited yourself are left alone';

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
  String get selectWord => 'Select';

  @override
  String get tagAiNeedKey => 'Enter an API key in Settings to use AI auto-tagging.';

  @override
  String get toggleListTooltip => 'Hide or show the list';

  @override
  String get aiDetecting => 'Checking which provider this key belongs to…';

  @override
  String get aiErrNoCredits => 'The key is fine, but the account has no balance. Add a payment method or credits on the provider\'s site. To avoid paying, try a Google Gemini key (starts with AIza…) — it has a free tier.';

  @override
  String get aiErrBadKey => 'The key was rejected. Check for stray spaces or quotes, then issue a new key on the provider\'s site.';

  @override
  String get aiErrRateLimit => 'The provider is busy right now. Nothing is wrong with the app — try again in a moment.';

  @override
  String get aiErrNoModel => 'That model is not available on this account. Pick another one under \'Advanced — choose a model\'.';

  @override
  String get aiErrNetwork => 'Could not reach the internet. Check your connection and try again.';

  @override
  String get multiSelectStart => 'Delete several notes';

  @override
  String get selectAllTooltip => 'Select all / none';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get deleteSelectedDone => 'Done';

  @override
  String get deleteSelectedConfirm => 'Delete the selected notes?';

  @override
  String deleteSelectedBody(int n) => n == 1
          ? '1 note will move to the Trash. You can restore it within 30 days.'
          : '$n notes will move to the Trash. You can restore them within 30 days.';

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
  String get printAction =>
      'Print';

  @override
  String get exportPdf =>
      'Export as PDF';

  @override
  String get pdfFailed =>
      'Could not create the PDF';

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
  String get historyWhyTidy => 'Before tidy';

  @override
  String get historyWhyAi => 'Before AI edit';

  @override
  String get historyWhyReplace => 'Before replace';

  @override
  String get historyWhyRevert => 'Before reverting to original';

  @override
  String get historyWhyRestore => 'Before restoring';

  @override
  String get widgetEmpty => 'No notes yet';

  @override
  String get widgetAllLocked => 'Locked notes don\'t appear in the widget';

  @override
  String get attachTitle => 'Attachments';

  @override
  String get attachAdd => 'Attach a file';

  @override
  String get attachRemove => 'Remove attachment';

  @override
  String get attachRemoveBody => 'The file will be deleted from this device. This cannot be undone.';

  @override
  String get attachFailed => 'Could not attach the file';

  @override
  String get attachNotHere => 'This file lives on another device';

  @override
  String attachAndMore(int n) => 'and ${n} more';

  @override
  String attachOther(String device, String what) => 'Attachment: ${what} is attached on your ${device} (viewable on that device only)';

  @override
  String deviceName(String kind) {
    switch (kind) {
      case 'iphone':
        return 'iPhone';
      case 'ipad':
        return 'iPad';
      case 'mac':
        return 'Mac';
      case 'android':
        return 'Android phone';
      case 'windows':
        return 'Windows PC';
      case 'web':
        return 'web';
      default:
        return 'other device';
    }
  }

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
  String get paperFrost => 'Frost';

  @override
  String get lockSectionTitle => 'Lock';

  @override
  String get lockTitle => 'App lock';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? 'Open the app with your fingerprint, your face, or the screen lock.'
      : vendor == 'windows'
          ? 'Open the app with Windows Hello or your device PIN.'
          : 'Open the app with Face ID, Touch ID, or your device passcode.';

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
  String lockUnavailable(String vendor) => vendor == 'android'
      ? 'Fingerprint, face unlock, and screen lock are unavailable on this device.'
      : vendor == 'windows'
          ? 'Windows Hello and device PIN are unavailable on this device.'
          : 'Face ID, Touch ID, and device passcode are unavailable on this device.';

  @override
  String get lockReasonOpen => 'Verify to open your notes';

  @override
  String get lockReasonOn => 'Verify to turn on the lock';

  @override
  String get lockReasonOff => 'Verify to turn off the lock';

  @override
  String get noteLock => 'Lock this note';

  @override
  String get noteUnlock => 'Unlock this note';

  @override
  String get noteLocked => 'Locked note';

  @override
  String get lockReasonNote => 'Open the locked note';

  @override
  String get noteLockDone => 'This note is locked';

  @override
  String get noteUnlockDone => 'This note is unlocked';

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
  String get tidyRulesSub =>
      'Decides what Tidy does to your text. What you pick here applies to the basic tidy only — the other ways do exactly what their names say.';

  @override
  String get syncOnTitle => 'On';

  @override
  String get syncOffTitle => 'Off';

  @override
  String get syncSignedOutTitle => 'Sign in needed';
  @override
  String get syncHelpTitleGdrive => 'Reconnect Google Drive';
  @override
  String get syncHelpStepsGdrive => '1. Tap the button below and choose your Google account\n2. Allow access to Drive\n3. Syncing starts right away';
  @override
  String get syncHelpNoteGdrive => 'Your notes are still on Drive. They come back once you sign in.';
  @override
  String get syncDiagSignedOutGdrive => 'This device is not signed in to a Google account.';
  @override
  String get syncSignInGoogle => 'Sign in with Google';
  @override
  String get syncAllowDrive => 'Allow access to Drive';
  @override
  String get syncDiagPreparingGdrive =>
      "Signed in. Fetching your notes from Drive. No need to keep watching — you can switch to another app; fetching pauses and picks up where it left off when you return.";
  @override
  String get syncRecheckStillGdrive => 'Not everything is here yet. The first sync takes a moment when you have many notes \u2014 it keeps going after you close this.';

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
  String get quoteTitle => 'Block quotes (> text)';
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
  String get dividerTip => 'Divider';
  @override
  String get syncScroll => 'Scroll together';
  @override
  String get pasteTipTitle => 'Stop the paste prompt';
  @override
  String get pasteTipSub => 'Turn off the alert iPhone shows on every paste';
  @override
  String get pasteTipBody =>
      'iPhone asks for permission each time an app reads the clipboard. This app starts with a paste, so you see that alert a lot.\n\nChange it once and it never asks again.\n\n1. Tap \'Open Settings\' below\n2. Tap \'Paste from Other Apps\'\n3. Choose \'Allow\'\n\nEven when allowed, this app reads the clipboard only at the moment you tap Paste. It never looks on its own.';
  @override
  String get pasteTipLater => 'Later';
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
  String get sponsorBody =>
      'Better features and steady updates need your support. Watch one ad to the end and this app shows no ads for the rest of today.';
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
  String get premiumPlanBase => 'Standard';
  @override
  String get premiumPlanAll => 'All Devices';
  @override
  String get premiumBestValue => 'Best value';
  @override
  String get premiumPerks => 'No ads · Unlimited tidying · Unlimited AI editing';
  @override
  String get premiumScopeBase => 'Bought on Apple, it opens on iPhone, iPad and Mac. Bought on Google Play, on your Android devices. Either way the web app is included.';
  @override
  String get premiumScopeAll => 'One purchase opens everything, even if you use iPhone and Android side by side. Devices added later are included too.';
  @override
  String get premiumAutoRenew => 'Subscriptions renew automatically unless canceled at least 24 hours before the period ends. You can cancel any time in your account settings.';
  @override
  String get premiumRestore => 'Restore purchases';
  @override
  String get premiumTerms => 'Terms of Use';
  @override
  String get premiumPrivacy => 'Privacy Policy';
  @override
  String get premiumThanks => 'Thank you. Premium is on.';
  @override
  String get premiumNoStore => 'You can’t purchase on this device. Once purchased, it applies here as soon as you sign in with the same account.';
  @override
  String get premiumUpgradeHere => 'Upgrade to All Devices to use it here too. The store credits your remaining time.';
  @override
  String get premiumHave => 'Your plan';
  @override
  String get premiumLoading => 'Getting prices from the store';

  @override
  String get premiumPerkNoAds => 'No ads — the top banner and the close-notice too';

  @override
  String get premiumGroupPerks => 'What you get';

  @override
  String get premiumHeadline => 'No limits. No ads.';

  @override
  String get onbTitle1 => 'Paste, and it is tidy';

  @override
  String get onbBody1 => 'Paste an AI answer as it came. Asterisks, hashes and filler greetings come off in one press.';

  @override
  String get onbTitle2 => 'Broken tables stand again';

  @override
  String get onbBody2 => 'Misaligned tables are rebuilt, and one tap copies them straight into Excel or Google Sheets.';

  @override
  String get onbTitle3 => 'The same notes everywhere';

  @override
  String get onbBody3 => 'What you write on iPhone is on your Mac and in the browser too. No charge for that.';

  @override
  String get onbTitle4 => 'Everything is open';

  @override
  String onbBody4(int days) => 'Use it without limits for $days days. Decide later, if it turns out to be worth keeping. Nothing to pay now.';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbSeePremium => 'See Premium';

  @override
  String get premiumSubhead => 'For people who work with AI answers every day. Press tidy as often as you like — nobody is counting.';

  @override
  String get premiumPerkNew => 'New features first — the moment they are built';

  @override
  String get premiumTrustTitle => 'Still being built';

  @override
  String get premiumCancelAnytime => 'Cancel anytime';

  @override
  String get premiumPerMonth => 'mo';

  @override
  String get premiumPerYear => 'yr';

  @override
  String get premiumPerLifetime => 'Lifetime';

  @override
  String premiumCta(String period, String price) => 'Get it for $price / $period';

  @override
  String premiumChargeNote(String period, String price) => 'You will be charged $price per $period.';

  @override
  String premiumTrialThen(int days) => '$days days free, then';

  @override
  String premiumSave(int pct) => 'Save $pct%';

  @override
  String premiumTrustBody(String version) => 'You are on $version. Requests usually ship the same week, and you can see what changed inside the app.';




  @override
  String get premiumPerkWeb => 'The web app too — no ads in the browser';






  @override
  String premiumPerkTidy(int n) => 'Unlimited tidying — no $n-a-day cap';

  @override
  String premiumPerkWizard(int n) => 'Unlimited AI editing — no $n-a-day cap';



  @override
  String get sponsorPremiumNote => 'Buy once and neither the banner nor this notice comes back.';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'No ads. No limits.';
  @override
  String get premiumLifetime => 'Lifetime';
  @override
  String get premiumMonthly => 'Monthly';
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
  String limitLeftTidy(int n) => '$n free tidy left today.';

  @override
  String limitLeftWizard(int n) => '$n free AI edit left today.';
  @override
  String get premiumYearly => 'Yearly';
  @override
  String get premiumLifetimeNote => 'One payment, no renewal';

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
  String get aiKeyUnknownFormat => 'Could not identify the provider. All four were asked and none accepted this key. Please copy and paste the key again.';
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
  String get rulesSectionTitle => 'My auto-replace rules';
  @override
  String get rulesSectionDesc =>
      'Applied top to bottom. Use \\n in Replace for a line break. Code blocks are left untouched.';
  @override
  String get addRule => 'Add rule';
  @override
  String get settingsFooter =>
      'Settings take effect immediately and apply from the next "Tidy". Notes you have already tidied are not changed retroactively.';
}
