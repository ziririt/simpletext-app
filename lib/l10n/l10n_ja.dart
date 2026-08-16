import 'l10n.dart';

/// 日本語
class L10nJa extends L10n {
  const L10nJa();

  @override
  String get localeTag => 'ja';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get homeTitle => 'メモ';
  @override
  String get settingsTooltip => '整理ルール設定';
  @override
  String get searchHint => '検索';
  @override
  String get emptyList => 'メモがありません。\n「貼り付けて整理」から始めましょう。';
  @override
  String get pinnedLabel => 'ピン固定';
  @override
  String get notesLabel => 'メモ';
  @override
  String get newNoteTooltip => '新規メモ';
  @override
  String get pasteAndTidy => '貼り付けて整理（新規メモ）';
  @override
  String get clipboardEmpty => 'クリップボードが空です。先にAIの回答をコピーしてください。';
  @override
  String get yesterday => '昨日';
  @override
  String get untitled => '無題';
  @override
  String get deleteConfirmTitle => 'このメモを削除しますか？';
  @override
  String get cancel => 'キャンセル';
  @override
  String get delete => '削除';

  @override
  String dateShort(int y, int m, int d) => '$y/$m/$d';

  @override
  String get seedTitle => 'Skyblue Note へようこそ';
  @override
  String get seedTag => '使い方';
  @override
  String get seedBody => [
        'Skyblue Note の使い方',
        '',
        '1. ChatGPTやClaudeの回答をコピーして、「貼り付けて整理」を押します。',
        '2. アスタリスクや見出し記号、余計な前置きが一度に取れます。',
        '3. 表があるメモは「表」ボタンでスプレッドシート用(TSV)にコピーできます。',
        '4. どの整理もひとつの「元に戻す」で復元できます。',
        '',
        '下はわざと崩した表です。「整理」を押して復元を確かめてみてください。',
        '',
        '| 銘柄 | ティッカー | リターン | 比率',
        '|------|------|--------|',
        '| アップル | AAPL | +14.2% | 12% |',
        '| マイクロソフト | MSFT | +21.5% | 18% |',
        '| エヌビディア | NVDA | +48.9% | 22% |',
        '|テスラ|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '完了';

  @override
  String get bodyFontSizeTitle => '本文の文字サイズ';

  @override
  String get bodyFontSizeSample =>
      '頭の中のたくさんの考えを Simplicity に整えてくれる Smart なワークスペース。貼り付けて「整理」を一度押すだけで Clean に片づきます。';

  @override
  String get wizardNothingToDo => '変更するものがありません';

  @override
  String wizardAppliedToast(int count) => '指示 $count 件を適用しました';

  @override
  String get skipPreviewCheck => '今後プレビューを省略';

  @override
  String get previewTitle2 => '適用前にプレビュー';

  @override
  String get previewSub2 => '結果を先に表示して適用するか確認します';
  @override
  String get metaTooltip => '出典・タグ';
  @override
  String get pinTooltip => 'リスト上部に固定';
  @override
  String get unpinTooltip => '固定を解除';
  @override
  String get deleteTooltip => '削除';
  @override
  String get titleHint => 'タイトル（自動）';
  @override
  String get sourceNone => '出典なし';
  @override
  String get sourceOther => 'その他';
  @override
  String get tagsHint => 'タグ（カンマ区切り）';
  @override
  String get tagAiButton => 'タグをAIで自動入力';
  @override
  String get tagAiWorking => 'タグを抽出中…';
  @override
  String get tagAiNone => 'キーワードが見つかりませんでした';
  @override
  String get tagAiLocalNote => 'AIキーがないため端末で抽出しました';
  @override
  String get tagsBoxHint => 'タグを入力してカンマ';
  @override
  String get tagRemoveTip => 'タグを削除';
  @override
  String get bodyHint => 'ここに貼り付けるか入力';
  @override
  String get noteNotFound => 'メモが見つかりません';
  @override
  String get revertedToast => '原文に戻しました。直前の文章は変更履歴にあります';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => '原文に戻す';

  @override
  String get revertConfirmTitle => '原文に戻しますか？';

  @override
  String get revertConfirmBody =>
      '最初に貼り付けた文章に戻ります。そのあとの整形と手直しはすべて消えます。\n\n今の文章は変更履歴に残るので、いつでも取り出せます。';

  @override
  String get revertConfirmOk => '戻す';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => '中黒リスト';

  @override
  String get listDashAction => 'ダッシュリスト';

  @override
  String get listNumberAction => '番号リスト';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => '出典';

  @override
  String sourceSaved(String name) => '出典を保存しました · $name';

  @override
  String sourceDetected(String name) => '出典を判別しました · $name';

  @override
  String get sourceCleared => '出典を消しました';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'フォルダ';

  @override
  String get folderNone => 'フォルダなし';

  @override
  String get folderNew => '新規フォルダ';

  @override
  String get folderNameHint => 'フォルダ名';

  @override
  String get folderCleared => 'フォルダから外しました';

  @override
  String folderMoved(String name) => '$name に移しました';
  @override
  String appliedDone(String summary) => '適用しました — $summary';

  @override
  String get undoTip => '取り消す';
  @override
  String get redoTip => 'やり直す';
  @override
  String get moveLeftTip => '左へ';
  @override
  String get moveRightTip => '右へ';
  @override
  String get lineStartTip => '行頭へ';
  @override
  String get lineEndTip => '行末へ';
  @override
  String get indentTip => 'インデント';
  @override
  String get hideKeyboardTip => 'キーボードを閉じる';

  @override
  String get tidyAction => '整理';
  @override
  String get wizardAction => 'AI編集';
  @override
  String get tableAction => '表';
  @override
  String get replaceAction => '置換';
  @override
  String get copyAction => 'コピー';
  @override
  String get undoAction => '元に戻す';

  @override
  String get noTablesFound => 'このメモに表は見つかりませんでした';
  @override
  String tableInfo(int n, int cols, int rows) => '表$n — $cols列 × $rows行';
  @override
  String get forSpreadsheet => 'スプレッドシート用';
  @override
  String get copiedSpreadsheet => 'コピーしました — GoogleスプレッドシートやExcelのセルに貼り付けてください';
  @override
  String get copiedCsv => 'CSVとしてコピーしました';
  @override
  String get copiedMarkdown => 'Markdownの表としてコピーしました';

  @override
  String get wizardTitle => 'AI編集';
  @override
  String get wizardHint => '言葉で指示してください。例：\n小見出しの上の空白は2行、下は1行にして\nマイクロソフトをMSに置換して';
  @override
  String get favSaveButton => 'よく使う指示として登録';
  @override
  String get favListTitle => 'よく使う指示';
  @override
  String get favUse => '選択';
  @override
  String get favEmpty => '登録した指示はまだありません';
  @override
  String get favRemove => '削除';
  @override
  String get favSavedToast => '登録しました';
  @override
  String appliedPrefix(String what) => '適用済み · $what';
  @override
  String unknownPrefix(String what) => 'ルールとして解釈できません · $what';
  @override
  String get aiKeyPromo => '設定にAI APIキーを入れると、このような自由編集の指示も処理できます。';
  @override
  String get aiRunUnknown => '解釈できない指示をAIで実行';
  @override
  String get aiBusyLabel => 'AI編集中…';
  @override
  String get aiEmptyResponse => '空の応答';
  @override
  String aiCallFailed(String error) => 'AI呼び出しに失敗: $error';
  @override
  String get aiApplyResult => 'AIの結果を適用';
  @override
  String get aiAppliedToast => 'AI編集を適用しました — 「元に戻す」で復元できます';
  @override
  String get close => '閉じる';
  @override
  String get interpretApply => '解釈して適用';

  @override
  String get replaceTitle => '置換';
  @override
  String get findLabel => '検索';
  @override
  String get replaceWithLabel => '置換後 (\\n=改行)';
  @override
  String get regexLabel => '正規表現';
  @override
  String get saveAsRule => '自動置換ルールとして保存';
  @override
  String get saveAsRuleSub => '以後「整理」のたびに常に適用';
  @override
  String get invalidRegex => '正規表現が正しくありません';
  @override
  String get noMatches => '一致する内容がありません';
  @override
  String replacedCount(int count) => '$count箇所を置換しました';
  @override
  String get savedRuleSuffix => ' · 自動置換ルールとして保存済み';
  @override
  String get replaceAllAction => 'すべて置換';

  @override
  String get copyAll => 'すべてコピー';
  @override
  String get copiedAll => '全文をコピーしました';
  @override
  String get tidyCopy => '整理してコピー';
  @override
  String get tidyCopySub => 'メモはそのままに、整理した結果だけをコピー';
  @override
  String tidyCopied(String summary) => '整理してコピーしました — $summary';
  @override
  String get copyTableSpreadsheet => '表をスプレッドシート用にコピー';
  @override
  String get copiedTableSpreadsheet => '表をスプレッドシート用にコピーしました';

  @override
  String previewTitle(String preset) => '$preset — プレビュー';
  @override
  String warningPrefix(String warning) => '注意: $warning';
  @override
  String get tidyResultLabel => '整理結果';
  @override
  String get originalLabel => '原文';
  @override
  String get apply => '適用';

  @override
  String get presetAiName =>
      '標準の整理';
  @override
  String get presetAiDesc =>
      '貼り付けたAIの回答をそのまま読める形に。ほとんどはこれで十分です';
  @override
  String get presetStripName =>
      '記号をすべて削除';
  @override
  String get presetStripDesc =>
      'LINEやSMSなど書式が使えない場所へ送るとき';
  @override
  String get presetMinimalName =>
      '汚れだけ落とす';
  @override
  String get presetMinimalDesc =>
      '構造はそのまま、見えないゴミだけ';
  @override
  String get presetTablesName =>
      '表だけ取り出す';
  @override
  String get presetTablesDesc =>
      'ExcelやGoogleスプレッドシートに直接貼るため';
  @override
  String get presetBlogName =>
      'ブログ用';
  @override
  String get presetBlogDesc =>
      'リンクのアドレスは残し、記号だけ外す';

  @override
  String get settingsTitle => '設定';

  @override
  String get menuAppSettings => 'アプリ設定';

  @override
  String get menuAiKey => 'AI APIキー';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'iPhone・iPad・Mac で同じメモを見られます';

  @override
  String get syncStateOff => '端末の設定で iCloud Drive をオンにしてください';

  @override
  String get syncStateSyncing => '同期中…';

  @override
  String get aiKeyNotSynced => 'メモは iCloud で全ての端末に同期されます。ただし API キーは同期されません — 端末ごとに入力してください。';

  @override
  String get syncStateSignedOut => 'タップして方法を見る';

  @override
  String get syncHelpTitle => 'iCloudをオンにする方法';

  @override
  String get syncHelpSteps =>
      '1. 設定 › 一番上の自分の名前 › iCloud を開きます\n2. iCloud Drive がオンか確認します — オフだとどのアプリも同期しません\n3. iPhone をロックして解除し、このアプリに戻って「再確認」を押します\n\n確認は設定ではなくファイルアプリで。ファイル › iCloud Drive に Skyblue Note フォルダが見えれば準備完了です。';

  @override
  String get syncOpenSettings => '設定を開く';

  @override
  String get syncRecheck => '再確認';

  @override
  String get syncHelpNote =>
      'インストール直後は準備に1〜2分かかることがあります。その場合は再確認を押してください。';

  @override
  String get sortFilterTooltip => '並べ替え・絞り込み';

  @override
  String get sortFilterTitle => '並べ替えと絞り込み';

  @override
  String get sortLabel => '並べ替え';

  @override
  String get sortUpdated => '最近の変更順';

  @override
  String get sortCreated => '作成順';

  @override
  String get sortByTitle => 'タイトル順';

  @override
  String get filterSourceLabel => '出典';

  @override
  String get filterTagLabel => 'タグ';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterReset => 'リセット';

  @override
  String get trashTitle => 'ゴミ箱';

  @override
  String get trashSubtitle => '削除したメモは30日間保管されます';

  @override
  String get trashEmpty => 'ゴミ箱は空です';

  @override
  String get trashRestore => '復元';

  @override
  String get trashDeleteNow => '完全に削除';

  @override
  String get trashEmptyAll => '空にする';

  @override
  String get trashEmptyConfirm => 'ゴミ箱を空にすると元に戻せません。続けますか？';

  @override
  String get trashRestored => '復元しました';

  @override
  String trashDaysLeftLabel(int days) => '$days日後に完全に削除されます';

  @override
  String get exportSectionTitle =>
      '読み込みと書き出し';

  @override
  String get exportSubtitle =>
      'メモはいつでも取り出せます。Markdownならアップルのメモ・Obsidian・Notionのどれにも入ります。';

  @override
  String get exportNote =>
      'このメモを書き出す';

  @override
  String get exportAllMd =>
      'すべてのメモを書き出す';

  @override
  String get exportAllMdSub =>
      'Markdownをまとめて1つのZIPに';

  @override
  String get exportBackup =>
      'バックアップを保存';

  @override
  String get exportBackupSub =>
      'このアプリにそのまま戻せる1ファイル（APIキーは除きます）';

  @override
  String get exportFailed =>
      '書き出しに失敗しました';

  @override
  String get exportEmpty =>
      '書き出すメモがありません';

  @override
  String get choosePreset => '整理の方法を選ぶ';

  @override
  String get importFiles =>
      'ファイルから読み込む';

  @override
  String get importFilesSub =>
      'Markdownやテキストをメモに。バックアップの復元もここです';

  @override
  String get importAppend =>
      'ファイルを追記';

  @override
  String get importNone =>
      '読み込んだファイルがありません';

  @override
  String importDone(int n) => 'メモを$n件読み込みました';

  @override
  String get sourceGuessSuffix => '（推定）';

  @override
  String get splitEmpty => '左からメモを選んでください';

  @override
  String get historyTitle =>
      'バージョン履歴';

  @override
  String get historySub =>
      '整理や置換の前の文に戻せます';

  @override
  String get historyEmpty =>
      'まだ戻せる版がありません';

  @override
  String get historyRestore =>
      '戻す';

  @override
  String get historyOriginal =>
      '貼り付けた原文';

  @override
  String historyUnknownTime(int n) => '以前の版 $n';

  @override
  String get selUnitSentence => '文';

  @override
  String get selUnitLine => '行';

  @override
  String get selUnitPara => '段落';

  @override
  String get selUnitAll => '全体';

  @override
  String get selStartLeft => '始点を左へ';

  @override
  String get selStartRight => '始点を右へ';

  @override
  String get selEndLeft => '終点を左へ';

  @override
  String get selEndRight => '終点を右へ';

  @override
  String get selClear => '選択解除';

  @override
  String get paperTitle => '編集画面の紙';

  @override
  String get paperSub => '背景と罫線をセットで選びます。行間は文字サイズに自動で合います。';

  @override
  String get paperNone => '標準';

  @override
  String get paperMoleskine => 'モレスキン';

  @override
  String get paperSepia => 'セピア';

  @override
  String get paperManuscript => '原稿用紙';

  @override
  String get paperGrid => '方眼';

  @override
  String get lockSectionTitle => 'ロック';

  @override
  String get lockTitle => 'アプリのロック';

  @override
  String get lockSub => 'Face ID・Touch ID、またはデバイスのパスコードでアプリを開きます。';

  @override
  String get lockNote => 'このロックは、他人が端末を手にしたときに画面を開けなくするものです。端末内のファイル自体を暗号化するわけではありません。';

  @override
  String get lockDelayTitle => 'ロックするまで';

  @override
  String get lockDelayNow => 'すぐに';

  @override
  String get lockDelay1m => '1分後';

  @override
  String get lockDelay5m => '5分後';

  @override
  String get lockUnlock => 'ロック解除';

  @override
  String get lockLocked => 'ロック中';

  @override
  String get lockUnavailable => 'この端末では Face ID・Touch ID・パスコードを利用できません。';

  @override
  String get lockReasonOpen => 'メモを開くには確認が必要です';

  @override
  String get lockReasonOn => 'ロックを有効にするには確認が必要です';

  @override
  String get lockReasonOff => 'ロックを解除するには確認が必要です';

  @override
  String get syncDiagSignedOut => 'この端末は iCloud にサインインしていません。まずサインインしてください。';

  @override
  String get syncDiagNoContainer => 'サインインは済んでいますが、このアプリの iCloud 領域がまだありません。下の手順でオンにしてください。';

  @override
  String get syncDiagPreparing => '領域は確保できました。準備が終わるのを待っています。';

  @override
  String get syncRecheckWhat => 'iCloud の状態を端末に最初から問い合わせます。';

  @override
  String get syncRecheckOk => 'iCloud がオンになりました';

  @override
  String get syncRecheckStill => 'まだオンになっていません。設定でオンにしてからもう一度押してください。今オンにした場合は 1〜2 分後にもう一度お試しください。';

  @override
  String get syncOpenFailed => '設定アプリを開けませんでした。ホーム画面から直接開いてください。';

  @override
  String get syncOpenManual => '設定アプリを直接開いてください。ホーム画面 › 設定 › 一番上の自分の名前 › iCloud です。';

  @override
  String get menuFile => 'ファイル';

  @override
  String get menuClose => '閉じる';

  @override
  String get menuPrefs => '設定…';

  @override
  String get appliedTitle => 'すっきり整いました';

  @override
  String get tidyRulesTitle => '整える規則';

  @override
  String get tidyRulesSub => '「整える」を押したとき文章がどう変わるかを決めます。';

  @override
  String get syncOnTitle => 'オン';

  @override
  String get syncOffTitle => 'オフ';

  @override
  String get syncSignedOutTitle => 'サインインが必要';

  @override
  String pastedFrom(String src, String date) =>
      '$date に $src から';

  @override
  String pastedOn(String date) => '$date に貼り付け';

  @override
  String staleWarn(int days) =>
      '受け取ってから$days日たった回答です。その間にモデルが変わっている可能性があります。';
  @override
  String get settingsSecView => '表示';
  @override
  String get settingsSecTidy => '整理ルール';
  @override
  String get settingsSecWhen => '整理するとき';
  @override
  String get settingsSecInfo => '情報';
  @override
  String get emphTitle => '太字強調 (**テキスト**)';
  @override
  String get emphSub => '40字を超える文全体の強調は常に記号のみ除去';
  @override
  String get emphQuoteSingle => "シングルクォート '強調'";
  @override
  String get emphQuoteDouble => 'ダブルクォート "強調"';
  @override
  String get removeLabel => '除去';
  @override
  String get keepLabel => '保持';
  @override
  String get hrTitle => '区切り線 (---)';
  @override
  String get headingTitle => '見出し (#, ##)';
  @override
  String get headingStrip => 'テキストのみ残す';
  @override
  String get headingKeep => 'そのまま保持';
  @override
  String get headingPrefix => '■ 記号を付ける';
  @override
  String get headingBracket => '[角かっこ]';
  @override
  String get bulletTitle => '箇条書き記号 (-, *)';
  @override
  String get bulletHyphen => 'ハイフン -';
  @override
  String get bulletMiddot => '中黒 ·';
  @override
  String get bulletDot => 'ビュレット •';
  @override
  String get bulletWhite => '白丸 ◦';
  @override
  String get bulletKeep => '元の記号を保持';
  @override
  String get bulletIndentTitle => '箇条書きのインデント';
  @override
  String get indent2 => '2文字';
  @override
  String get indent4 => '4文字';
  @override
  String get indentNone => 'なし';
  @override
  String get headingPadTitle => '小見出しの余白';
  @override
  String get headingPadSub => '上2行・下1行 — 不可視文字(ㅤ)なのでメッセージアプリやブログでも保たれます';
  @override
  String get citationsTitle => '出典リンクの除去';
  @override
  String get citationsSub => '本文の脚注番号と末尾の「出典」一覧をまとめて削除します';
  @override
  String get monoEditorTitle => '表を等幅フォントで';
  @override
  String get monoEditorSub => '表とコードの桁がぴったり揃います。本文は端末の標準フォントのままです';
  @override
  String get dashListTitle => 'ダッシュ列挙のリスト化';
  @override
  String get dashListSub => '「– a – b – c」の一行列挙を行リストに分割';
  @override
  String get fillerHeadingTitle => '不可視文字見出しの整理';
  @override
  String get fillerHeadingSub => 'ㅤで囲まれた擬似見出しに余白・見出しルールを適用';
  @override
  String get aiSectionTitle => 'AI編集の接続';
  @override
  String get aiSectionDesc =>
      'APIキーを入れると「もっと簡潔に」のような指示をAIが処理します。整理は端末内のルールなのでキー不要で、AI編集だけがキーを使います。';
  @override
  String get aiKeyHint => 'APIキー (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get adClose => '広告を閉じる';
  @override
  String get sponsorTitle => '広告1本が次のアップデートを作ります';
  @override
  String get sponsorBody => '応援が次のアップデートを支えます。全画面広告を1日1本ご覧いただくと、その日はバナーなしで。プレミアムなら広告は永久になくなります。';
  @override
  String get sponsorWatch => '広告を見て応援する';
  @override
  String get sponsorSkip => 'スキップ';
  @override
  String get sponsorLoading => '広告を読み込み中…';
  @override
  String get sponsorFailed => '広告を読み込めませんでした。しばらくしてからもう一度お試しください。';
  @override
  String get moreTooltip => 'その他';
  @override
  String get sponsorGoPremium => 'プレミアムで広告なしに';
  @override
  String get premiumTitle => 'プレミアム';
  @override
  String get premiumPitch => '広告なしで、すべてのデバイスで';
  @override
  String get premiumPitchSub => '買い切りUS\$29.99または月額US\$1.99 · iPhone・iPad・Macまとめて';
  @override
  String get premiumBody => 'プレミアムはすべての広告をなくし、iPhone・iPad・Macで制限なく使えるようにします。1回の購入で3つのデバイスすべてに適用されます。皆さまの応援が次のアップデートを作ります。';
  @override
  String get premiumLifetime => '買い切り · US\$29.99';
  @override
  String get premiumMonthly => '月額 · US\$2.99/月';
  @override
  String get premiumComingSoon => '購入はApp Store公開版で有効になります。もうしばらくお待ちください。';
  @override
  String get limitTitle => '本日の無料利用を使い切りました';
  @override
  String limitTidyBody(int n) => '無料では1日$n回まで整理できます。明日また使えます。プレミアムなら制限はありません。';
  @override
  String limitWizardBody(int n) =>
      '無料プランでは1日に$n回までAI編集を使えます。明日また開きます — プレミアムなら制限がありません。';
  @override
  String get limitSeePremium => 'プレミアムを見る';
  @override
  String get premiumYearly => '年間 · 年US\$14.99';
  @override
  String get premiumLifetimeNote => '発売記念価格 · 通常US\$39.99';

  @override
  String trialBadge(int days) => '無制限体験 · 残り$days日';

  @override
  String get trialEndedTitle => '無制限体験が終了しました';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      '体験中に整理を$tidy回、AI編集を$wiz回お使いになりました。これからは無料プランで1日に整理$tidyLimit回、AI編集$wizLimit回です。プレミアムなら制限がありません。';
  @override
  String get themeTitle => '画面モード';
  @override
  String get themeSystem => '端末の設定に従う';
  @override
  String get themeLight => 'ライト';
  @override
  String get themeDark => 'ダーク';
  @override
  String get aiKeyVerify => 'キーを確認';
  @override
  String get aiKeyChecking => '確認中…';
  @override
  String get aiKeyUnknownFormat => 'キー形式を認識できませんでした。詳細設定でモデルを直接指定してください。';
  @override
  String get aiAdvancedLabel => '詳細 — モデルを直接選択';
  @override
  String get aiManualModelHint => 'モデル名を入力（例: gemini-2.5-flash-lite）';
  @override
  String aiAutoLabel(String provider, String model) => '自動選択: $provider · $model';
  @override
  String aiModelsFound(int n) => '利用可能なモデルを$n件確認しました。';
  @override
  String aiListFailed(String error) => 'モデル一覧を取得できませんでした（$error）。内蔵の予備リストで動作します。';
  @override
  String aiModelSwitched(String model) => '以前のモデルが応答しないため、$model に切り替えました。';
  @override
  String get rulesSectionTitle => '自動置換ルール';
  @override
  String get rulesSectionDesc => '上から順に適用。置換後に \\n を使うと改行。コードブロック内は変更しません。';
  @override
  String get addRule => 'ルールを追加';
  @override
  String get settingsFooter =>
      '設定は保存と同時に反映され、次に「整理」を実行したときから適用されます。すでに整理済みのメモは遡って変わりません。';
}
