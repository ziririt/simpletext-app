import 'l10n.dart';

/// 繁體中文（台灣·香港·澳門）
class L10nZhHant extends L10n {
  const L10nZhHant();

  @override
  String get localeTag => 'zh-Hant';

  @override
  String get appTitle => '簡文本';

  @override
  String get versionLabel => '版本';

  @override
  String get homeTitle => '備忘錄';
  @override
  String get settingsTooltip => '整理規則設定';
  @override
  String get searchHint => '搜尋';
  @override
  String get emptyList => '尚無備忘錄。\n從「貼上並整理」開始吧。';
  @override
  String get pinnedLabel => '已置頂';
  @override
  String get notesLabel => '備忘錄';
  @override
  String get newNoteTooltip => '新增備忘錄';
  @override
  String get pasteAndTidy => '新增並貼上整理';
  @override
  String get clipboardEmpty => '剪貼簿是空的。請先複製一段 AI 回答。';
  @override
  String get yesterday => '昨天';
  @override
  String get untitled => '無標題';
  @override
  String get deleteConfirmTitle => '要刪除這則備忘錄嗎？';
  @override
  String get cancel => '取消';
  @override
  String get delete => '刪除';

  @override
  String dateShort(int y, int m, int d) => '$y/$m/$d';

  @override
  String get seedTitle => '歡迎使用簡文本';
  @override
  String get seedTag => '使用方式';
  @override
  String get seedBody => [
        '簡文本使用方式',
        '',
        '1. 複製 ChatGPT 或 Claude 的回答，然後點「貼上並整理」。',
        '2. 在預覽中比較原文與結果，點「套用」即可。',
        '3. 含表格的備忘錄可用「表格」按鈕複製為試算表格式(TSV)。',
        '4. 每次整理都能用一次復原來還原。',
        '',
        '下面是一張故意弄壞的表格。點「整理」看看修復效果。',
        '',
        '| 股票 | 代號 | 報酬率 | 佔比',
        '|------|------|--------|',
        '| 蘋果 | AAPL | +14.2% | 12% |',
        '| 微軟 | MSFT | +21.5%',
        '| 輝達 | NVDA | +48.9% | 22% | 多餘儲存格 |',
        '|特斯拉|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '完成';

  @override
  String get autoTidy => '自動整理';

  @override
  String get bodyFontSizeTitle => '內文字級';

  @override
  String get bodyFontSizeSample =>
      '遇見一個把腦中紛雜思緒整理得 Simplicity 而 Smart 的工作空間。貼上後點一次「整理」，一切都變得 Clean。';

  @override
  String get wizardNothingToDo => '沒有需要變更的內容';

  @override
  String wizardAppliedToast(int count) => '已套用 \$count 條指令';

  @override
  String get skipPreviewCheck => '以後略過預覽';

  @override
  String get previewTitle2 => '套用前預覽';

  @override
  String get previewSub2 => '先顯示整理結果，再詢問是否套用';
  @override
  String get metaTooltip => '來源·標籤';
  @override
  String get pinTooltip => '置頂';
  @override
  String get unpinTooltip => '取消置頂';
  @override
  String get deleteTooltip => '刪除';
  @override
  String get titleHint => '標題（自動）';
  @override
  String get sourceNone => '無來源';
  @override
  String get sourceOther => '其他';
  @override
  String get tagsHint => '標籤（以逗號分隔）';
  @override
  String get tagAiButton => 'AI 自動填標籤';
  @override
  String get tagAiWorking => '正在擷取標籤…';
  @override
  String get tagAiNone => '找不到關鍵字';
  @override
  String get tagAiLocalNote => '沒有 AI 金鑰，已在本機擷取';
  @override
  String get tagsBoxHint => '輸入標籤後加逗號';
  @override
  String get tagRemoveTip => '刪除標籤';
  @override
  String get bodyHint => '在此貼上或輸入';
  @override
  String get noteNotFound => '找不到這則備忘錄';
  @override
  String get revertedToast => '已還原到上一個版本';
  @override
  String appliedDone(String summary) => '已套用 — $summary';

  @override
  String get undoTip => '復原';
  @override
  String get redoTip => '重做';
  @override
  String get moveLeftTip => '向左';
  @override
  String get moveRightTip => '向右';
  @override
  String get lineStartTip => '行首';
  @override
  String get lineEndTip => '行尾';
  @override
  String get indentTip => '縮排';
  @override
  String get hideKeyboardTip => '收起鍵盤';

  @override
  String get tidyAction => '整理';
  @override
  String get wizardAction => '精靈';
  @override
  String get tableAction => '表格';
  @override
  String get replaceAction => '取代';
  @override
  String get copyAction => '複製';
  @override
  String get undoAction => '復原';

  @override
  String get noTablesFound => '這則備忘錄中找不到表格';
  @override
  String tableInfo(int n, int cols, int rows) => '表格$n — $cols欄 × $rows列';
  @override
  String get forSpreadsheet => '試算表格式';
  @override
  String get copiedSpreadsheet => '已複製 — 貼到 Google 試算表或 Excel 儲存格即可';
  @override
  String get copiedCsv => '已複製為 CSV';
  @override
  String get copiedMarkdown => '已複製為 Markdown 表格';

  @override
  String get wizardTitle => '精靈';
  @override
  String get wizardHint => '用自然語言下指令。例如：\n小標題上方空2行，下方空1行\n把微軟取代成 Microsoft';
  @override
  String get favSaveButton => '存為常用指令';
  @override
  String get favListTitle => '常用指令';
  @override
  String get favUse => '選用';
  @override
  String get favEmpty => '還沒有儲存的指令';
  @override
  String get favRemove => '刪除';
  @override
  String get favSavedToast => '已儲存';
  @override
  String appliedPrefix(String what) => '已套用 · $what';
  @override
  String unknownPrefix(String what) => '無法解析為規則 · $what';
  @override
  String get aiKeyPromo => '在設定中填入 AI API 金鑰後，這類自由編輯指令也能處理。';
  @override
  String get aiRunUnknown => '用 AI 執行無法解析的指令';
  @override
  String get aiBusyLabel => 'AI 編輯中…';
  @override
  String get aiEmptyResponse => '空回應';
  @override
  String aiCallFailed(String error) => 'AI 呼叫失敗: $error';
  @override
  String get aiApplyResult => '套用 AI 結果';
  @override
  String get aiAppliedToast => '已套用 AI 編輯 — 可用復原還原';
  @override
  String get close => '關閉';
  @override
  String get interpretApply => '解析並套用';

  @override
  String get replaceTitle => '取代';
  @override
  String get findLabel => '尋找';
  @override
  String get replaceWithLabel => '取代為 (\\n=換行)';
  @override
  String get regexLabel => '正規表示式';
  @override
  String get saveAsRule => '儲存為自動取代規則';
  @override
  String get saveAsRuleSub => '之後每次「整理」時皆會套用';
  @override
  String get invalidRegex => '正規表示式不正確';
  @override
  String get noMatches => '沒有相符的內容';
  @override
  String replacedCount(int count) => '已取代 $count 處';
  @override
  String get savedRuleSuffix => ' · 已儲存為自動取代規則';
  @override
  String get replaceAllAction => '全部取代';

  @override
  String get copyAll => '複製全部';
  @override
  String get copiedAll => '已複製全文';
  @override
  String get tidyCopy => '整理後複製';
  @override
  String get tidyCopySub => '備忘錄保持原樣，只複製整理後的結果';
  @override
  String tidyCopied(String summary) => '已整理並複製 — $summary';
  @override
  String get copyTableSpreadsheet => '將表格複製為試算表格式';
  @override
  String get copiedTableSpreadsheet => '已將表格複製為試算表格式';

  @override
  String previewTitle(String preset) => '$preset — 預覽';
  @override
  String warningPrefix(String warning) => '注意: $warning';
  @override
  String get tidyResultLabel => '整理結果';
  @override
  String get originalLabel => '原文';
  @override
  String get apply => '套用';

  @override
  String get presetAiName => '整理 AI 回答';
  @override
  String get presetAiDesc => '移除 Markdown 標記、表情符號、AI 開場白，修復表格';
  @override
  String get presetStripName => '完全移除 Markdown';
  @override
  String get presetStripDesc => '盡可能移除 Markdown 語法，表格轉為 TSV';
  @override
  String get presetMinimalName => '最小整理';
  @override
  String get presetMinimalDesc => '保留結構，只移除雜訊（空白、零寬字元等）';
  @override
  String get presetTablesName => '只取表格';
  @override
  String get presetTablesDesc => '從文件中擷取表格並轉為 TSV';
  @override
  String get presetBlogName => '部落格貼上';
  @override
  String get presetBlogDesc => '移除標記，連結保留網址，修復表格';

  @override
  String get settingsTitle => '設定';

  @override
  String get menuAppSettings => '應用程式設定';

  @override
  String get menuAiKey => 'AI API 金鑰';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => '已開啟 — iPhone、iPad 和 Mac 上是同一份備忘';

  @override
  String get syncStateOff => '已關閉 — 請在裝置設定中開啟 iCloud 雲碟';

  @override
  String get syncStateSyncing => '同步中…';

  @override
  String get aiKeyNotSynced => '備忘會透過 iCloud 同步到您的所有裝置，但 API 金鑰不會同步 — 請在每台裝置上分別輸入。';
  @override
  String get settingsSecView => '顯示';
  @override
  String get settingsSecTidy => '整理規則';
  @override
  String get settingsSecWhen => '整理時';
  @override
  String get settingsSecInfo => '關於';
  @override
  String get emphTitle => '粗體強調 (**文字**)';
  @override
  String get emphSub => '超過40字的整句強調一律只移除標記';
  @override
  String get emphQuoteSingle => "單引號 '強調'";
  @override
  String get emphQuoteDouble => '雙引號 "強調"';
  @override
  String get removeLabel => '移除';
  @override
  String get keepLabel => '保留';
  @override
  String get hrTitle => '分隔線 (---)';
  @override
  String get headingTitle => '標題 (#, ##)';
  @override
  String get headingStrip => '只留文字';
  @override
  String get headingKeep => '原樣保留';
  @override
  String get headingPrefix => '加 ■ 符號';
  @override
  String get headingBracket => '[方括號]';
  @override
  String get bulletTitle => '項目符號 (-, *)';
  @override
  String get bulletHyphen => '連字號 -';
  @override
  String get bulletMiddot => '間隔號 ·';
  @override
  String get bulletDot => '實心圓點 •';
  @override
  String get bulletWhite => '空心圓點 ◦';
  @override
  String get bulletKeep => '保留原符號';
  @override
  String get bulletIndentTitle => '項目符號縮排';
  @override
  String get indent2 => '2格';
  @override
  String get indent4 => '4格';
  @override
  String get indentNone => '無';
  @override
  String get headingPadTitle => '小標題留白';
  @override
  String get headingPadSub => '上2行·下1行 — 使用隱形字元(ㅤ)，在通訊軟體和部落格也不會消失';
  @override
  String get citationsTitle => '移除引用連結';
  @override
  String get citationsSub => '刪除內文的註腳編號與文末的「來源」清單';
  @override
  String get monoEditorTitle => '表格使用等寬字型';
  @override
  String get monoEditorSub => '表格與程式碼各欄精確對齊。內文仍使用裝置預設字型';
  @override
  String get dashListTitle => '破折號連排轉列表';
  @override
  String get dashListSub => '將「– a – b – c」式的單行連排拆成逐行列表';
  @override
  String get fillerHeadingTitle => '整理隱形字元小標題';
  @override
  String get fillerHeadingSub => '對被ㅤ包住的類小標題套用留白與標題規則';
  @override
  String get aiSectionTitle => 'AI 精靈連接（自由編輯）';
  @override
  String get aiSectionDesc => '填入 API 金鑰後，精靈可處理「寫得更簡潔些」這類自由編輯指令。金鑰只儲存在這部裝置上。';
  @override
  String get aiKeyHint => 'API 金鑰（Gemini · Claude · ChatGPT · Grok）';
  @override
  String get adClose => '關閉廣告';
  @override
  String get sponsorTitle => '一則廣告，成就下一次更新';
  @override
  String get sponsorBody => '您的支持讓更新不斷。每天觀看一則全螢幕廣告，當天即可無橫幅使用；升級進階版，廣告將永久消失。';
  @override
  String get sponsorWatch => '看廣告支持我們';
  @override
  String get sponsorSkip => '略過';
  @override
  String get sponsorLoading => '正在載入廣告…';
  @override
  String get sponsorFailed => '廣告載入失敗，請稍後再試。';
  @override
  String get moreTooltip => '更多';
  @override
  String get sponsorGoPremium => '升級進階版，無廣告';
  @override
  String get premiumTitle => '進階版';
  @override
  String get premiumPitch => '無廣告，全裝置通用';
  @override
  String get premiumPitchSub => '買斷 US\$29.99 或每月 US\$1.99 · iPhone、iPad、Mac 一次搞定';
  @override
  String get premiumBody => '進階版將移除所有廣告，並可在 iPhone、iPad 和 Mac 上不受限制地使用。一次購買，三端通用。您的支持成就下一次更新。';
  @override
  String get premiumLifetime => '買斷 · US\$29.99';
  @override
  String get premiumMonthly => '訂閱 · US\$2.99/月';
  @override
  String get premiumComingSoon => '購買將在 App Store 正式版中開放，敬請期待。';
  @override
  String get limitTitle => '今天的免費次數已用完';
  @override
  String limitTidyBody(int n) => '免費版每天可整理 \$n 次，明天恢復。進階版不限次數。';
  @override
  String limitWizardBody(int n) => '免費版每天可使用精靈 \$n 次，明天恢復。進階版不限次數。';
  @override
  String get limitSeePremium => '查看進階版';
  @override
  String get premiumYearly => '年付 · US\$14.99/年';
  @override
  String get premiumLifetimeNote => '上市紀念價 · 原價 US\$39.99';

  @override
  String trialBadge(int days) => '無限體驗 · 剩餘$days天';

  @override
  String get trialEndedTitle => '無限體驗已結束';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      '體驗期間您整理了$tidy次，使用精靈$wiz次。從現在起免費版每天可整理$tidyLimit次、使用精靈$wizLimit次。升級進階版即可解除限制。';
  @override
  String get themeTitle => '外觀模式';
  @override
  String get themeSystem => '跟隨裝置';
  @override
  String get themeLight => '淺色';
  @override
  String get themeDark => '深色';
  @override
  String get aiKeyVerify => '驗證金鑰';
  @override
  String get aiKeyChecking => '驗證中…';
  @override
  String get aiKeyUnknownFormat => '無法識別金鑰格式。請在進階選項中手動指定模型。';
  @override
  String get aiAdvancedLabel => '進階 — 手動選擇模型';
  @override
  String get aiManualModelHint => '輸入模型名稱（例如 gemini-2.5-flash-lite）';
  @override
  String aiAutoLabel(String provider, String model) => '自動選擇：$provider · $model';
  @override
  String aiModelsFound(int n) => '已確認 $n 個可用模型。';
  @override
  String aiListFailed(String error) => '無法取得模型清單（$error）。將使用內建備用清單。';
  @override
  String aiModelSwitched(String model) => '原模型無回應，已切換至 $model。';
  @override
  String get rulesSectionTitle => '自動取代規則';
  @override
  String get rulesSectionDesc => '由上而下依序套用。取代內容中的 \\n 表示換行。程式碼區塊內不會更動。';
  @override
  String get addRule => '新增規則';
  @override
  String get settingsFooter => '設定儲存後立即生效，從下一次「整理」開始套用。已整理過的備忘錄不會被回溯修改。';
}
