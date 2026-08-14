import 'l10n.dart';

/// 日本語
class L10nJa extends L10n {
  const L10nJa();

  @override
  String get localeTag => 'ja';

  @override
  String get appTitle => 'シンプルテキスト';

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
  String get seedTitle => 'シンプルテキストへようこそ';
  @override
  String get seedTag => '使い方';
  @override
  String get seedBody => [
        'シンプルテキストの使い方',
        '',
        '1. ChatGPTやClaudeの回答をコピーして、「貼り付けて整理」を押します。',
        '2. プレビューで原文と結果を見比べて、「適用」を押せば完了。',
        '3. 表があるメモは「表」ボタンでスプレッドシート用(TSV)にコピーできます。',
        '4. どの整理もひとつの「元に戻す」で復元できます。',
        '',
        '下はわざと崩した表です。「整理」を押して復元を確かめてみてください。',
        '',
        '| 銘柄 | ティッカー | リターン | 比率',
        '|------|------|--------|',
        '| アップル | AAPL | +14.2% | 12% |',
        '| マイクロソフト | MSFT | +21.5%',
        '| エヌビディア | NVDA | +48.9% | 22% | 余分なセル |',
        '|テスラ|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '完了';

  @override
  String get autoTidy => '自動整理';

  @override
  String get bodyFontSizeTitle => '本文の文字サイズ';

  @override
  String get bodyFontSizeSample => 'いつものメモアプリと並べて、この文が同じに見えるまで合わせてください。';

  @override
  String get wizardNothingToDo => '変更するものがありません';

  @override
  String wizardAppliedToast(int count) => '指示 \$count 件を適用しました';

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
  String get revertedToast => '前のバージョンに戻しました';
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
  String get wizardAction => 'ウィザード';
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
  String get wizardTitle => 'ウィザード';
  @override
  String get wizardHint => '言葉で指示してください。例：\n小見出しの上の空白は2行、下は1行にして\nマイクロソフトをMSに置換して';
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
  String get presetAiName => 'AI回答の整理';
  @override
  String get presetAiDesc => 'マークダウン記号・絵文字・AIの前置きを除去、表を復元';
  @override
  String get presetStripName => 'Markdown完全除去';
  @override
  String get presetStripDesc => 'マークダウン記法を最大限除去、表はTSVに';
  @override
  String get presetMinimalName => '最小限の整理';
  @override
  String get presetMinimalDesc => '構造は保持し、ノイズ（空白・ゼロ幅文字など）だけ除去';
  @override
  String get presetTablesName => '表だけ抽出';
  @override
  String get presetTablesDesc => '文書から表を抽出してTSVに';
  @override
  String get presetBlogName => 'ブログ貼り付け用';
  @override
  String get presetBlogDesc => '記号を除去、リンクはURLを保持、表を復元';

  @override
  String get settingsTitle => '整理ルール設定';
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
  String get aiSectionTitle => 'AIウィザード連携（自由編集）';
  @override
  String get aiSectionDesc =>
      'APIキーを入れると「もっと簡潔にして」のような自由編集の指示をウィザードが処理します。キーはこの端末にのみ保存されます。';
  @override
  String get aiKeyHint => 'APIキー（Google AI または Anthropic）';
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
