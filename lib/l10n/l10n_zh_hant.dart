import 'l10n.dart';

/// 繁體中文（台灣·香港·澳門）
class L10nZhHant extends L10n {
  const L10nZhHant();

  @override
  String get localeTag => 'zh-Hant';

  @override
  String get appTitle => 'Skyblue Note';

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
  String get seedTitle => '歡迎使用 Skyblue Note';
  @override
  String get seedTag => '使用方式';
  @override
  String get seedBody => [
        '您好！😊 以下是您要的整理結果[1][2]。',
        '',
        '# Skyblue Note',
        '',
        '表格錯位了吧。點一下左下角的**魔法棒**。🎉',
        '',
        '| 公司 | 代碼 | 漲跌幅 | 比重',
        '|------|------|--------|',
        '| 蘋果 | AAPL | +14.2% | 12% |',
        '|輝達|NVDA|+48.9%|22%|',
        '| 微軟 | MSFT | +21.5% | 18% |',
        '|特斯拉|TSLA|-8.3%|8%|',
        '',
        '> 整理後各欄對齊。選單裡的「表格」可直接貼進試算表。',
        '',
        '## 會被清掉的',
        '',
        '- [ ] 客套開場白和表情符號 🙂',
        '- [ ] 黏在句尾的註腳[3][4]',
        '- [ ] 行尾落單的星號**',
        '- [x] 錯位的表格會重新排好',
        '',
        '## 會保留的',
        '',
        '標題、**粗體**和引用都保留。螢幕上顯示為格式，複製到記事本或論壇時符號會自動去掉。',
        '',
        '---',
        '',
        '\t•\t用定位字元包住的項目符號 — Grok 和 ChatGPT 就是這樣貼出來的',
        '\t•\t重複的   空格和定位字元',
        '\t•\t散開的這幾行也會歸位',
        '',
        '> 不滿意就用選單裡的[還原原文](https://ezlong.com/skybluenote)還原。',
      ].join('\n');

  @override
  String get done => '完成';

  @override
  String get bodyFontSizeTitle => '內文字級';

  @override
  String get bodyLineHeightTitle => '正文行距';

  @override
  String get bodyFontSizeSample =>
      '遇見一個把腦中紛雜思緒整理得 Simplicity 而 Smart 的工作空間。貼上後點一次「整理」，一切都變得 Clean。';

  @override
  String get wizardNothingToDo => '沒有需要變更的內容';

  @override
  String wizardAppliedToast(int count) => '已套用 $count 條指令';

  @override
  String get skipPreviewCheck => '以後略過預覽';

  @override
  String get previewTitle2 => '套用前預覽';

  @override
  String get previewSub2 => '先顯示整理結果，再詢問是否套用';
  @override
  String get metaTooltip => '標題·標籤';
  @override
  String get pinTooltip => '置頂';
  @override
  String get unpinTooltip => '取消置頂';

  @override
  String get unpinConfirmTitle => '取消置頂這則筆記？';

  @override
  String get unpinConfirmBody =>
      '在清單中長按筆記即可重新置頂。';
  @override
  String get deleteTooltip => '刪除';
  @override
  String get titleHint => '標題（自動）';
  @override
  String get titleTapHint => '輸入標題';
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
  String get revertedToast => '已還原成原文，之前的文字在版本記錄裡';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => '還原成原文';

  @override
  String get revertConfirmTitle => '還原成原文？';

  @override
  String get revertConfirmBody =>
      '將回到你最初貼上的文字。之後的整理和手動修改都會消失。\n\n現在的文字會留在版本記錄裡，隨時可以取回。';

  @override
  String get revertConfirmOk => '還原';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => '圓點清單';

  @override
  String get listDashAction => '短橫清單';

  @override
  String get listNumberAction => '編號清單';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => '來源';

  @override
  String sourceSaved(String name) => '已儲存來源 · $name';

  @override
  String sourceDetected(String name) => '已辨識來源 · $name';

  @override
  String get sourceCleared => '已清除來源';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => '資料夾';

  @override
  String get folderNone => '不放入資料夾';

  @override
  String get folderNew => '新增資料夾';

  @override
  String get folderNameHint => '資料夾名稱';

  @override
  String get folderCleared => '已移出資料夾';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => '管理資料夾';

  @override
  String get folderRename => '重新命名';

  @override
  String get folderDelete => '刪除資料夾';

  @override
  String get folderReorderHint => '拖曳以排序';

  @override
  String get folderManageEmpty => '還沒有資料夾';

  @override
  String get folderDupName => '已存在同名資料夾';

  @override
  String get folderDeleted => '已刪除資料夾';

  @override
  String get folderRenamed => '已重新命名';

  @override
  String folderDeleteBody(String name, int count) =>
      '「$name」中的 $count 則筆記仍可在全部筆記中查看。筆記不會被刪除。';

  @override
  String folderNoteCount(int count) => '$count 則筆記';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => '正在確認是否真的可用…';

  @override
  String get aiPingOk => '編輯也能用，可以開始了。';

  @override
  String aiPingFailed(String err) => '能取到清單，但編輯呼叫被拒絕 — $err';

  @override
  String get aiAdvancedNote => '通常不用管這裡。填了金鑰就會自動選。';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => '紙';

  @override
  String get paperKraft => '牛皮紙';

  @override
  String get paperWalnut => '胡桃';

  @override
  String get paperNight => '夜';

  @override
  String get paperSky => '天空';

  @override
  String get themeSystemNote =>
      '跟隨裝置時，裝置切到深色的時間，App 也會一起切換。';

  @override
  String folderMoved(String name) => '已移到 $name';
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
  String get todoAction => '待辦';
  @override
  String get hideKeyboardTip => '收起鍵盤';

  @override
  String get tidyAction => '整理';
  @override
  String get wizardAction => 'AI編輯';
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
  String get wizardTitle => 'AI 編輯';
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
  String unknownPrefix(String what) => '交給 AI 處理 · $what';
  @override
  String get aiKeyPromo => '在設定中填入 AI API 金鑰後，這類自由編輯指令也能處理。';
  @override
  String get aiBusyLabel => 'AI 編輯中…';
  @override
  String get aiWorking => 'AI 正在讀取指示並編輯…';
  @override
  String get aiEmptyResponse => '空回應';
  @override
  String aiCallFailed(String error) => 'AI 呼叫失敗: $error';
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
  String get copyPlainSub =>
      '純文字 — 去掉 #、** 等符號';

  @override
  String get copyRaw => '依 Markdown 複製';

  @override
  String get copyRawSub =>
      '用於 Notion、Slack、GitHub 等支援 Markdown 的地方';
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
  String get apply => '立即套用整理';

  @override
  String get presetAiName =>
      '標準整理';
  @override
  String get presetAiDesc =>
      '把貼上的 AI 回答變得可讀。多數情況夠用';
  @override
  String get presetStripName =>
      '清除所有符號';
  @override
  String get presetStripDesc =>
      '傳到 LINE·簡訊時。符號和表情全部清掉，表格排成對齊的文字表';
  @override
  String get presetMinimalName =>
      '只去雜質';
  @override
  String get presetMinimalDesc =>
      '保留結構，只清除看不見的雜質';
  @override
  String get presetTablesName =>
      '只取表格';
  @override
  String get presetTablesDesc =>
      '直接貼到 Excel 或 Google 試算表';
  @override
  String get presetBlogName =>
      '部落格用';
  @override
  String get presetBlogDesc =>
      '保留連結網址，去掉符號';

  @override
  String get tidySample => [
        '## 今日小結 😊',
        '',
        '**要點**有三條[1][2]。',
        '',
        '- 第一條',
        '- 第二條',
        '',
        '> 引用一行',
        '',
        '詳見[部落格](https://ezlong.com)',
        '',
        '| 項目 | 值 |',
        '|---|---|',
        '|營收|120|',
      ].join('\n');

  @override
  String get settingsTitle => '設定';

  @override
  String get menuAppSettings => '應用程式設定';

  @override
  String get menuAiKey => 'AI API 金鑰';

  @override
  String get syncTitle => '同步';
  @override
  String get syncAppleOnly => '僅限 Apple 裝置';

  @override
  String get syncScopeTitle =>
      '同步範圍';

  @override
  String get syncScopeShared =>
      'Apple 裝置間同步：備忘錄、整理規則、手動新增的取代規則、資料夾、常用 AI 編輯指令';

  @override
  String get syncScopeDevice =>
      '每台裝置各自：字級、行距、背景、外觀、排序';

  @override
  String get syncScopePlatform =>
      '目前自動同步僅在 Apple 裝置（iPhone、iPad、Mac）之間進行。Android 與 Windows 請使用選單中的匯出備份與匯入';

  @override
  String get typographyTitle => '字體與行距';

  @override
  String get syncScopeNever =>
      'AI API 金鑰不會上傳到 iCloud，需要在每台裝置分別輸入';
  @override
  String get syncWhereTitle =>
      '放在哪裡';
  @override
  String get syncBackendNone =>
      '不同步';
  @override
  String get syncBackendNoneSub =>
      '只保存在這台裝置';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      '在 iPhone·iPad·Mac 之間';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      '還包括 Android·Windows·網頁';
  @override
  String get syncSoon =>
      '準備中';
  @override
  String get syncSectionState =>
      '目前狀態';
  @override
  String get syncNowAction =>
      '立即同步';
  @override
  String get syncLastNever =>
      '還沒有同步過';
  @override
  String get syncTroubleTitle =>
      '出問題時';
  @override
  String get syncTroubleNote =>
      '同步不是備份。在一台裝置上刪掉，別處也會消失。重要的筆記請偶爾匯出成檔案。';
  @override
  String syncLastAt(String when) => '上次同步 $when';

  @override
  String get syncStateOn => '在 iPhone、iPad 和 Mac 上看到相同的備忘錄';

  @override
  String get syncStateOff => '請在裝置設定中開啟 iCloud 雲碟';

  @override
  String get syncStateSyncing => '正在連接 iCloud… 需要幾秒到幾十秒';

  @override
  String get aiKeyNotSynced => '備忘會透過 iCloud 同步到您的所有裝置，但 API 金鑰不會同步 — 請在每台裝置上分別輸入。';

  @override
  String get autoTagTitle => '自動加入標籤';

  @override
  String get autoTagSub =>
      '編輯後稍作停頓，AI 會重新擷取標籤。你手動改過標籤的筆記不會被更動';

  @override
  String get syncStateSignedOut => '點按查看方法';

  @override
  String get syncHelpTitle => '如何開啟 iCloud';

  @override
  String get syncHelpSteps =>
      '1. 開啟「設定」› 頂端的你的名稱 › iCloud\n2. 確認 iCloud 雲碟已開啟 — 若關閉，任何 App 都不會同步\n3. 鎖定後解鎖，回到本 App 點按「重新檢查」\n\n請在「檔案」App 中確認，而非「設定」。若在「檔案」› iCloud 雲碟中看到 Skyblue Note 資料夾，即已就緒。';

  @override
  String get syncOpenSettings => '打開設定';

  @override
  String get syncRecheck => '重新檢查';

  @override
  String get syncHelpNote =>
      '剛安裝完成時可能需要一兩分鐘準備。稍後點一下重新檢查即可。';

  @override
  String get sortFilterTooltip => '排序和篩選';

  @override
  String get sortFilterTitle => '排序與篩選';

  @override
  String get sortLabel => '排序';

  @override
  String get sortUpdated => '最近修改';

  @override
  String get sortCreated => '建立時間';

  @override
  String get sortByTitle => '標題';

  @override
  String get filterSourceLabel => '來源';

  @override
  String get filterTagLabel => '標籤';

  @override
  String get filterAll => '全部';

  @override
  String get filterReset => '重設';

  @override
  String get selectWord => '選取';

  @override
  String get tagAiNeedKey => '在設定中輸入 API 金鑰後即可使用 AI 自動標籤。';

  @override
  String get toggleListTooltip => '隱藏或顯示清單';

  @override
  String get aiDetecting => '正在確認這是哪家服務商的金鑰…';

  @override
  String get aiErrNoCredits => '金鑰沒問題，但該帳戶沒有餘額。請在服務商網站新增付款方式或儲值。若不想付費，可以試試 Google Gemini 金鑰（以 AIza… 開頭）——它有免費額度。';

  @override
  String get aiErrBadKey => '金鑰被拒絕。請檢查前後是否有空格或引號，仍然不行就到服務商網站重新申請。';

  @override
  String get aiErrRateLimit => '目前請求過於集中。這不是應用程式的問題，請稍後再試。';

  @override
  String get aiErrNoModel => '該帳戶無法使用這個模型。請在下方「進階 — 直接選擇模型」中換一個。';

  @override
  String get aiErrNetwork => '無法連線到網際網路。請檢查網路後重試。';

  @override
  String get multiSelectStart => '選擇多筆刪除';

  @override
  String get selectAllTooltip => '全選 / 取消全選';

  @override
  String get deleteSelected => '刪除所選';

  @override
  String get deleteSelectedDone => '完成';

  @override
  String get deleteSelectedConfirm => '確定刪除所選備忘錄嗎？';

  @override
  String deleteSelectedBody(int n) => '將有 $n 筆備忘錄移至垃圾桶，30 天內可以還原。';

  @override
  String get trashTitle => '垃圾桶';

  @override
  String get trashSubtitle => '刪除的備忘會保留 30 天';

  @override
  String get trashEmpty => '垃圾桶是空的';

  @override
  String get trashRestore => '回復';

  @override
  String get trashDeleteNow => '立即刪除';

  @override
  String get trashEmptyAll => '清空';

  @override
  String get trashEmptyConfirm => '清空後無法復原，確定要繼續嗎？';

  @override
  String get trashRestored => '已回復';

  @override
  String trashDaysLeftLabel(int days) => '$days 天後徹底刪除';

  @override
  String get exportSectionTitle =>
      '匯入與輸出';

  @override
  String get exportSubtitle =>
      '備忘隨時可以帶走。Markdown 可匯入蘋果備忘錄、Obsidian、Notion 等。';

  @override
  String get exportNote =>
      '輸出此備忘';

  @override
  String get exportAllMd =>
      '輸出全部備忘';

  @override
  String get exportAllMdSub =>
      '所有備忘的 Markdown 打包為一個 ZIP';

  @override
  String get exportBackup =>
      '儲存備份檔案';

  @override
  String get exportBackupSub =>
      '可完整還原到本 App 的單一檔案（不含 API 金鑰）';

  @override
  String get exportFailed =>
      '輸出失敗';

  @override
  String get exportEmpty =>
      '沒有可輸出的備忘';

  @override
  String get choosePreset => '選擇整理方式';

  @override
  String get importFiles =>
      '從檔案匯入';

  @override
  String get importFilesSub =>
      'Markdown 和文字檔會變成備忘。備份檔也在這裡還原';

  @override
  String get importAppend =>
      '載入檔案並附加到內文';

  @override
  String get importNone =>
      '沒有匯入任何檔案';

  @override
  String importDone(int n) => '已匯入 $n 則備忘';

  @override
  String get sourceGuessSuffix => '（推測）';

  @override
  String get splitEmpty => '請在左側選擇一則備忘';

  @override
  String get historyTitle =>
      '版本紀錄';

  @override
  String get historySub =>
      '可以回到整理或取代之前的文字';

  @override
  String get historyEmpty =>
      '還沒有可回復的版本';

  @override
  String get historyRestore =>
      '回復';

  @override
  String get historyOriginal =>
      '貼上時的原文';

  @override
  String historyUnknownTime(int n) => '先前版本 $n';

  @override
  String get selUnitSentence => '句';

  @override
  String get selUnitLine => '行';

  @override
  String get selUnitPara => '段';

  @override
  String get selUnitAll => '全部';

  @override
  String get selStartLeft => '起點左移';

  @override
  String get selStartRight => '起點右移';

  @override
  String get selEndLeft => '終點左移';

  @override
  String get selEndRight => '終點右移';

  @override
  String get selClear => '取消選取';

  @override
  String get paperTitle => '編輯頁背景';

  @override
  String get paperSub => '背景與格線成套選擇。行距自動跟隨字級。';

  @override
  String get paperNone => '預設';

  @override
  String get paperMoleskine => '摩斯奇諾';

  @override
  String get paperSepia => '棕褐';

  @override
  String get paperManuscript => '稿紙';

  @override
  String get paperFrost => '霜白';

  @override
  String get lockSectionTitle => '鎖定';

  @override
  String get lockTitle => '應用程式鎖';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? '使用指紋、臉部辨識或螢幕鎖定開啟 App。'
      : vendor == 'windows'
          ? '使用 Windows Hello 或裝置 PIN 開啟 App。'
          : '使用 Face ID、Touch ID 或裝置密碼開啟 App。';

  @override
  String get lockNote => '此鎖定用於防止他人拿到裝置後開啟 App，並不會加密裝置中的檔案本身。';

  @override
  String get lockDelayTitle => '鎖定時機';

  @override
  String get lockDelayNow => '立即';

  @override
  String get lockDelay1m => '1 分鐘後';

  @override
  String get lockDelay5m => '5 分鐘後';

  @override
  String get lockUnlock => '解鎖';

  @override
  String get lockLocked => '已鎖定';

  @override
  String lockUnavailable(String vendor) => vendor == 'android'
      ? '此裝置無法使用指紋、臉部辨識或螢幕鎖定。'
      : vendor == 'windows'
          ? '此裝置無法使用 Windows Hello 或裝置 PIN。'
          : '此裝置無法使用 Face ID、Touch ID 或裝置密碼。';

  @override
  String get lockReasonOpen => '開啟備忘錄需要驗證';

  @override
  String get lockReasonOn => '開啟鎖定需要驗證';

  @override
  String get lockReasonOff => '關閉鎖定需要驗證';

  @override
  String get syncDiagSignedOut => '此裝置未登入 iCloud。請先登入。';

  @override
  String get syncDiagNoContainer => '已登入，但此 App 還沒有 iCloud 空間。請依下方步驟開啟。';

  @override
  String get syncDiagPreparing => '空間已就緒，正在等待準備完成。';

  @override
  String get syncRecheckWhat => '重新向裝置查詢 iCloud 狀態。';

  @override
  String get syncRecheckOk => 'iCloud 已開啟';

  @override
  String get syncRecheckStill => '尚未開啟。請在設定中開啟後再次點按。若剛剛才開啟，請一兩分鐘後再試一次。';

  @override
  String get syncOpenFailed => '無法開啟設定。請從主畫面直接開啟。';

  @override
  String get syncOpenManual => '請直接開啟「設定」：主畫面 › 設定 › 頂端的你的名稱 › iCloud。';

  @override
  String get menuFile => '檔案';

  @override
  String get menuClose => '關閉';

  @override
  String get menuPrefs => '設定…';

  @override
  String get appliedTitle => '已整理得乾乾淨淨';

  @override
  String get tidyRulesTitle => '整理規則';

  @override
  String get tidyRulesSub =>
      '決定按下「整理」後文字如何變化。這裡選的只對「基本整理」生效 — 其他方式按名字所說的做。';

  @override
  String get syncOnTitle => '已開啟';

  @override
  String get syncOffTitle => '已關閉';

  @override
  String get syncSignedOutTitle => '需要登入';

  @override
  String pastedFrom(String src, String date) =>
      '$date 來自 $src';

  @override
  String pastedOn(String date) => '$date 貼上';

  @override
  String staleWarn(int days) =>
      '這個回答已過去 $days 天，其間模型可能已更新。';
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
  String get quoteTitle => '引用 (> 文字)';
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
  String get aiSectionTitle => 'AI 編輯連線';
  @override
  String get aiSectionDesc =>
      '填入 API 金鑰後，AI 可處理「寫得更簡潔」這類自由指令。整理使用裝置內規則，不需金鑰；只有 AI 編輯需要。';
  @override
  String get aiKeyHint => 'API 金鑰（Gemini · Claude · ChatGPT · Grok）';
  @override
  String get menuTidyPreview => '整理預覽';
  @override
  String get dividerTip => '分隔線';
  @override
  String get syncScroll => '同步捲動';
  @override
  String get pasteTipTitle => '不再每次詢問貼上';
  @override
  String get pasteTipSub => '一次關掉 iPhone 每次貼上都跳出的詢問';
  @override
  String get pasteTipBody =>
      'iPhone 在 App 每次讀取剪貼簿時都會請求許可。這個 App 從貼上開始，所以那個詢問會頻繁出現。\n\n改一次就不會再問了。\n\n1. 點下面的「打開設定」\n2. 點「從其他 App 貼上」\n3. 選「允許」\n\n即使允許，這個 App 也只在您點貼上的那一刻讀取剪貼簿，不會私自查看。';
  @override
  String get pasteTipLater => '稍後';
  @override
  String get adClose => '關閉廣告';
  @override
  String get noteDuplicate => '複製';
  @override
  String get noteDuplicated => '已複製';
  @override
  String get adSponsored => '贊助';
  @override
  String get sponsorTitle => '一則廣告，成就下一次更新';
  @override
  String get sponsorBody =>
      '更好的功能和持續的更新需要您的支持。完整看完一支廣告，今天這個 App 就不再顯示廣告。';
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
  String limitTidyBody(int n) => '免費版每天可整理 $n 次，明天恢復。進階版不限次數。';
  @override
  String limitWizardBody(int n) =>
      '免費版每天可使用 $n 次 AI 編輯，明天恢復 — 進階版沒有限制。';
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
      '體驗期間您整理了 $tidy 次，使用 AI 編輯 $wiz 次。從現在起免費版每天可整理 $tidyLimit 次、AI 編輯 $wizLimit 次。升級進階版即可解除限制。';
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
  String get aiKeyUnknownFormat => '無法識別服務商。已向四家全部詢問，均未接受此金鑰。請重新複製並貼上金鑰。';
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
