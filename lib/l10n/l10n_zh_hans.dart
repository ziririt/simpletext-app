import 'l10n.dart';

/// 简体中文
class L10nZhHans extends L10n {
  const L10nZhHans();

  @override
  String get localeTag => 'zh-Hans';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => '版本';

  @override
  String get homeTitle => '备忘录';
  @override
  String get settingsTooltip => '整理规则设置';
  @override
  String get searchHint => '搜索';
  @override
  String get emptyList => '暂无备忘录。\n从"粘贴并整理"开始吧。';
  @override
  String get pinnedLabel => '已置顶';
  @override
  String get notesLabel => '备忘录';
  @override
  String get newNoteTooltip => '新建备忘录';
  @override
  String get pasteAndTidy => '新建并粘贴整理';
  @override
  String get clipboardEmpty => '剪贴板为空。请先复制一段 AI 回答。';
  @override
  String get yesterday => '昨天';
  @override
  String get untitled => '无标题';
  @override
  String get deleteConfirmTitle => '要删除这条备忘录吗？';
  @override
  String get cancel => '取消';
  @override
  String get delete => '删除';

  @override
  String dateShort(int y, int m, int d) => '$y/$m/$d';

  @override
  String get seedTitle => '欢迎使用 Skyblue Note';
  @override
  String get seedTag => '使用方法';
  @override
  String get seedBody => [
        'Skyblue Note 使用方法',
        '',
        '1. 复制 ChatGPT 或 Claude 的回答，然后点"粘贴并整理"。',
        '2. 在预览中对比原文和结果，点"应用"即可。',
        '3. 含表格的备忘录可用"表格"按钮复制为电子表格格式(TSV)。',
        '4. 每次整理都可以通过一次撤销恢复。',
        '',
        '下面是一张故意弄坏的表格。点"整理"看看修复效果。',
        '',
        '| 股票 | 代码 | 收益率 | 占比',
        '|------|------|--------|',
        '| 苹果 | AAPL | +14.2% | 12% |',
        '| 微软 | MSFT | +21.5%',
        '| 英伟达 | NVDA | +48.9% | 22% |',
        '|特斯拉|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '完成';

  @override
  String get bodyFontSizeTitle => '正文字号';

  @override
  String get bodyFontSizeSample =>
      '遇见一个把脑中纷杂思绪整理得 Simplicity 而 Smart 的工作空间。粘贴后点一次"整理"，一切都变得 Clean。';

  @override
  String get wizardNothingToDo => '没有需要更改的内容';

  @override
  String wizardAppliedToast(int count) => '已应用 $count 条指令';

  @override
  String get skipPreviewCheck => '以后跳过预览';

  @override
  String get previewTitle2 => '应用前预览';

  @override
  String get previewSub2 => '先显示整理结果，再询问是否应用';
  @override
  String get metaTooltip => '来源·标签';
  @override
  String get pinTooltip => '置顶';
  @override
  String get unpinTooltip => '取消置顶';
  @override
  String get deleteTooltip => '删除';
  @override
  String get titleHint => '标题（自动）';
  @override
  String get sourceNone => '无来源';
  @override
  String get sourceOther => '其他';
  @override
  String get tagsHint => '标签（逗号分隔）';
  @override
  String get tagAiButton => 'AI 自动填标签';
  @override
  String get tagAiWorking => '正在提取标签…';
  @override
  String get tagAiNone => '未找到关键词';
  @override
  String get tagAiLocalNote => '没有 AI 密钥，已在本机提取';
  @override
  String get tagsBoxHint => '输入标签后加逗号';
  @override
  String get tagRemoveTip => '删除标签';
  @override
  String get bodyHint => '在此粘贴或输入';
  @override
  String get noteNotFound => '找不到该备忘录';
  @override
  String get revertedToast => '已恢复到上一版本';
  @override
  String appliedDone(String summary) => '已应用 — $summary';

  @override
  String get undoTip => '撤销';
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
  String get indentTip => '缩进';
  @override
  String get hideKeyboardTip => '收起键盘';

  @override
  String get tidyAction => '整理';
  @override
  String get wizardAction => 'AI编辑';
  @override
  String get tableAction => '表格';
  @override
  String get replaceAction => '替换';
  @override
  String get copyAction => '复制';
  @override
  String get undoAction => '撤销';

  @override
  String get noTablesFound => '这条备忘录中没有找到表格';
  @override
  String tableInfo(int n, int cols, int rows) => '表格$n — $cols列 × $rows行';
  @override
  String get forSpreadsheet => '电子表格格式';
  @override
  String get copiedSpreadsheet => '已复制 — 粘贴到 Google 表格或 Excel 单元格即可';
  @override
  String get copiedCsv => '已复制为 CSV';
  @override
  String get copiedMarkdown => '已复制为 Markdown 表格';

  @override
  String get wizardTitle => 'AI 编辑';
  @override
  String get wizardHint => '用自然语言下指令。例如：\n小标题上方空2行，下方空1行\n把微软替换成 Microsoft';
  @override
  String get favSaveButton => '存为常用指令';
  @override
  String get favListTitle => '常用指令';
  @override
  String get favUse => '选用';
  @override
  String get favEmpty => '还没有保存的指令';
  @override
  String get favRemove => '删除';
  @override
  String get favSavedToast => '已保存';
  @override
  String appliedPrefix(String what) => '已应用 · $what';
  @override
  String unknownPrefix(String what) => '无法解析为规则 · $what';
  @override
  String get aiKeyPromo => '在设置中填入 AI API 密钥后，这类自由编辑指令也能处理。';
  @override
  String get aiRunUnknown => '用 AI 执行无法解析的指令';
  @override
  String get aiBusyLabel => 'AI 编辑中…';
  @override
  String get aiEmptyResponse => '空响应';
  @override
  String aiCallFailed(String error) => 'AI 调用失败: $error';
  @override
  String get aiApplyResult => '应用 AI 结果';
  @override
  String get aiAppliedToast => '已应用 AI 编辑 — 可通过撤销恢复';
  @override
  String get close => '关闭';
  @override
  String get interpretApply => '解析并应用';

  @override
  String get replaceTitle => '替换';
  @override
  String get findLabel => '查找';
  @override
  String get replaceWithLabel => '替换为 (\\n=换行)';
  @override
  String get regexLabel => '正则表达式';
  @override
  String get saveAsRule => '保存为自动替换规则';
  @override
  String get saveAsRuleSub => '此后每次"整理"时始终应用';
  @override
  String get invalidRegex => '正则表达式不正确';
  @override
  String get noMatches => '没有匹配的内容';
  @override
  String replacedCount(int count) => '已替换 $count 处';
  @override
  String get savedRuleSuffix => ' · 已保存为自动替换规则';
  @override
  String get replaceAllAction => '全部替换';

  @override
  String get copyAll => '复制全部';
  @override
  String get copiedAll => '已复制全文';
  @override
  String get tidyCopy => '整理后复制';
  @override
  String get tidyCopySub => '备忘录保持不变，仅复制整理后的结果';
  @override
  String tidyCopied(String summary) => '已整理并复制 — $summary';
  @override
  String get copyTableSpreadsheet => '将表格复制为电子表格格式';
  @override
  String get copiedTableSpreadsheet => '已将表格复制为电子表格格式';

  @override
  String previewTitle(String preset) => '$preset — 预览';
  @override
  String warningPrefix(String warning) => '注意: $warning';
  @override
  String get tidyResultLabel => '整理结果';
  @override
  String get originalLabel => '原文';
  @override
  String get apply => '应用';

  @override
  String get presetAiName =>
      '标准整理';
  @override
  String get presetAiDesc =>
      '把粘贴的 AI 回答变得可读。多数情况够用';
  @override
  String get presetStripName =>
      '清除所有符号';
  @override
  String get presetStripDesc =>
      '发到聊天、短信等没有格式的地方时';
  @override
  String get presetMinimalName =>
      '只去杂质';
  @override
  String get presetMinimalDesc =>
      '保留结构，只清除看不见的杂质';
  @override
  String get presetTablesName =>
      '只取表格';
  @override
  String get presetTablesDesc =>
      '直接粘贴到 Excel 或 Google 表格';
  @override
  String get presetBlogName =>
      '博客用';
  @override
  String get presetBlogDesc =>
      '保留链接地址，去掉符号';

  @override
  String get settingsTitle => '设置';

  @override
  String get menuAppSettings => '应用设置';

  @override
  String get menuAiKey => 'AI API 密钥';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => '已开启 — iPhone、iPad 和 Mac 上是同一份备忘';

  @override
  String get syncStateOff => '已关闭 — 请在设备设置中开启 iCloud 云盘';

  @override
  String get syncStateSyncing => '同步中…';

  @override
  String get aiKeyNotSynced => '备忘会通过 iCloud 同步到您的所有设备，但 API 密钥不会同步 — 请在每台设备上单独输入。';

  @override
  String get syncStateSignedOut => '尚未登录 iCloud — 点按查看方法';

  @override
  String get syncHelpTitle => '如何开启 iCloud';

  @override
  String get syncHelpSteps =>
      '1. 打开「设置」› 顶部的你的姓名 › iCloud\n2. 确认 iCloud 云盘已开启 — 若关闭，任何 App 都不会同步\n3. 锁屏后解锁，回到本 App 点按「重新检查」\n\n请在「文件」App 中确认，而非「设置」。若在「文件」› iCloud 云盘中看到 Skyblue Note 文件夹，即已就绪。';

  @override
  String get syncOpenSettings => '打开设置';

  @override
  String get syncRecheck => '重新检查';

  @override
  String get syncHelpNote =>
      '刚安装完成时可能需要一两分钟准备。稍后点按重新检查即可。';

  @override
  String get sortFilterTooltip => '排序和筛选';

  @override
  String get sortFilterTitle => '排序与筛选';

  @override
  String get sortLabel => '排序';

  @override
  String get sortUpdated => '最近修改';

  @override
  String get sortCreated => '创建时间';

  @override
  String get sortByTitle => '标题';

  @override
  String get filterSourceLabel => '来源';

  @override
  String get filterTagLabel => '标签';

  @override
  String get filterAll => '全部';

  @override
  String get filterReset => '重置';

  @override
  String get trashTitle => '废纸篓';

  @override
  String get trashSubtitle => '删除的备忘会保留 30 天';

  @override
  String get trashEmpty => '废纸篓是空的';

  @override
  String get trashRestore => '恢复';

  @override
  String get trashDeleteNow => '立即删除';

  @override
  String get trashEmptyAll => '清空';

  @override
  String get trashEmptyConfirm => '清空后无法恢复，确定继续吗？';

  @override
  String get trashRestored => '已恢复';

  @override
  String trashDaysLeftLabel(int days) => '$days 天后彻底删除';

  @override
  String get exportSectionTitle =>
      '导入与导出';

  @override
  String get exportSubtitle =>
      '备忘随时可以带走。Markdown 可导入苹果备忘录、Obsidian、Notion 等。';

  @override
  String get exportNote =>
      '导出此备忘';

  @override
  String get exportAllMd =>
      '导出全部备忘';

  @override
  String get exportAllMdSub =>
      '所有备忘的 Markdown 打包为一个 ZIP';

  @override
  String get exportBackup =>
      '保存备份文件';

  @override
  String get exportBackupSub =>
      '可完整还原到本 App 的单个文件（不含 API 密钥）';

  @override
  String get exportFailed =>
      '导出失败';

  @override
  String get exportEmpty =>
      '没有可导出的备忘';

  @override
  String get choosePreset => '选择整理方式';

  @override
  String get importFiles =>
      '从文件导入';

  @override
  String get importFilesSub =>
      'Markdown 和文本文件变成备忘。备份文件也在这里还原';

  @override
  String get importAppend =>
      '追加文件内容';

  @override
  String get importNone =>
      '没有导入任何文件';

  @override
  String importDone(int n) => '已导入 $n 条备忘';

  @override
  String get sourceGuessSuffix => '（推测）';

  @override
  String get splitEmpty => '请在左侧选择一条备忘';

  @override
  String get historyTitle =>
      '版本历史';

  @override
  String get historySub =>
      '可以回到整理或替换之前的文字';

  @override
  String get historyEmpty =>
      '还没有可回退的版本';

  @override
  String get historyRestore =>
      '恢复';

  @override
  String get historyOriginal =>
      '粘贴时的原文';

  @override
  String historyUnknownTime(int n) => '早前版本 $n';

  @override
  String get selUnitSentence => '句';

  @override
  String get selUnitLine => '行';

  @override
  String get selUnitPara => '段';

  @override
  String get selUnitAll => '全部';

  @override
  String get selStartLeft => '起点左移';

  @override
  String get selStartRight => '起点右移';

  @override
  String get selEndLeft => '终点左移';

  @override
  String get selEndRight => '终点右移';

  @override
  String get selClear => '取消选择';

  @override
  String get paperTitle => '编辑页纸张';

  @override
  String get paperSub => '背景与格线成套选择。行距自动跟随字号。';

  @override
  String get paperNone => '默认';

  @override
  String get paperMoleskine => '摩斯奇诺';

  @override
  String get paperSepia => '棕褐';

  @override
  String get paperManuscript => '稿纸';

  @override
  String get paperGrid => '方格';

  @override
  String get lockSectionTitle => '锁定';

  @override
  String get lockTitle => '应用锁';

  @override
  String get lockSub => '使用面容 ID、触控 ID 或设备密码打开应用。';

  @override
  String get lockNote => '此锁定用于防止他人拿到设备后打开应用，并不会加密设备中的文件本身。';

  @override
  String get lockDelayTitle => '锁定时机';

  @override
  String get lockDelayNow => '立即';

  @override
  String get lockDelay1m => '1 分钟后';

  @override
  String get lockDelay5m => '5 分钟后';

  @override
  String get lockUnlock => '解锁';

  @override
  String get lockLocked => '已锁定';

  @override
  String get lockUnavailable => '此设备无法使用面容 ID、触控 ID 或设备密码。';

  @override
  String get lockReasonOpen => '打开备忘录需要验证';

  @override
  String get lockReasonOn => '开启锁定需要验证';

  @override
  String get lockReasonOff => '关闭锁定需要验证';

  @override
  String get syncDiagSignedOut => '此设备未登录 iCloud。请先登录。';

  @override
  String get syncDiagNoContainer => '已登录，但此应用还没有 iCloud 空间。请按下方步骤开启。';

  @override
  String get syncDiagPreparing => '空间已就位，正在等待准备完成。';

  @override
  String get syncRecheckWhat => '重新向设备查询 iCloud 状态。';

  @override
  String get syncRecheckOk => 'iCloud 已开启';

  @override
  String get syncRecheckStill => '尚未开启。请在设置中开启后再次点按。若刚刚开启，请一两分钟后再试一次。';

  @override
  String get syncOpenFailed => '无法打开设置。请从主屏幕直接打开。';

  @override
  String get syncOpenManual => '请直接打开「设置」：主屏幕 › 设置 › 顶部的你的姓名 › iCloud。';

  @override
  String get menuFile => '文件';

  @override
  String get menuClose => '关闭';

  @override
  String get menuPrefs => '设置…';

  @override
  String get appliedTitle => '已整理得干干净净';

  @override
  String pastedFrom(String src, String date) =>
      '$date 来自 $src';

  @override
  String pastedOn(String date) => '$date 粘贴';

  @override
  String staleWarn(int days) =>
      '这个回答已过去 $days 天，其间模型可能已更新。';
  @override
  String get settingsSecView => '显示';
  @override
  String get settingsSecTidy => '整理规则';
  @override
  String get settingsSecWhen => '整理时';
  @override
  String get settingsSecInfo => '关于';
  @override
  String get emphTitle => '加粗强调 (**文本**)';
  @override
  String get emphSub => '超过40字的整句强调始终仅去除标记';
  @override
  String get emphQuoteSingle => "单引号 '强调'";
  @override
  String get emphQuoteDouble => '双引号 "强调"';
  @override
  String get removeLabel => '去除';
  @override
  String get keepLabel => '保留';
  @override
  String get hrTitle => '分隔线 (---)';
  @override
  String get headingTitle => '标题 (#, ##)';
  @override
  String get headingStrip => '仅保留文本';
  @override
  String get headingKeep => '原样保留';
  @override
  String get headingPrefix => '加 ■ 符号';
  @override
  String get headingBracket => '[方括号]';
  @override
  String get bulletTitle => '项目符号 (-, *)';
  @override
  String get bulletHyphen => '连字符 -';
  @override
  String get bulletMiddot => '间隔号 ·';
  @override
  String get bulletDot => '实心圆点 •';
  @override
  String get bulletWhite => '空心圆点 ◦';
  @override
  String get bulletKeep => '保留原符号';
  @override
  String get bulletIndentTitle => '项目符号缩进';
  @override
  String get indent2 => '2格';
  @override
  String get indent4 => '4格';
  @override
  String get indentNone => '无';
  @override
  String get headingPadTitle => '小标题留白';
  @override
  String get headingPadSub => '上2行·下1行 — 使用不可见字符(ㅤ)，在聊天软件和博客中也不会丢失';
  @override
  String get citationsTitle => '去除引用链接';
  @override
  String get citationsSub => '删除正文中的脚注编号和文末的“来源”列表';
  @override
  String get monoEditorTitle => '表格使用等宽字体';
  @override
  String get monoEditorSub => '表格与代码各列精确对齐。正文仍使用设备默认字体';
  @override
  String get dashListTitle => '破折号连排转列表';
  @override
  String get dashListSub => '将"– a – b – c"式的单行连排拆分为逐行列表';
  @override
  String get fillerHeadingTitle => '整理不可见字符小标题';
  @override
  String get fillerHeadingSub => '对被ㅤ包裹的类小标题应用留白和标题规则';
  @override
  String get aiSectionTitle => 'AI 编辑连接';
  @override
  String get aiSectionDesc =>
      '填入 API 密钥后，AI 可处理"写得更简洁"这类自由指令。整理使用设备内规则，无需密钥；只有 AI 编辑需要。';
  @override
  String get aiKeyHint => 'API 密钥（Gemini · Claude · ChatGPT · Grok）';
  @override
  String get adClose => '关闭广告';
  @override
  String get sponsorTitle => '一条广告，成就下一次更新';
  @override
  String get sponsorBody => '您的支持让更新不断。每天观看一条全屏广告，当天即可无横幅使用；升级高级版，广告将永久消失。';
  @override
  String get sponsorWatch => '看广告支持我们';
  @override
  String get sponsorSkip => '跳过';
  @override
  String get sponsorLoading => '正在加载广告…';
  @override
  String get sponsorFailed => '广告加载失败，请稍后重试。';
  @override
  String get moreTooltip => '更多';
  @override
  String get sponsorGoPremium => '升级高级版，无广告';
  @override
  String get premiumTitle => '高级版';
  @override
  String get premiumPitch => '无广告，全设备通用';
  @override
  String get premiumPitchSub => '买断 US\$29.99 或每月 US\$1.99 · iPhone、iPad、Mac 一次搞定';
  @override
  String get premiumBody => '高级版将移除所有广告，并可在 iPhone、iPad 和 Mac 上不受限制地使用。一次购买，三端通用。您的支持成就下一次更新。';
  @override
  String get premiumLifetime => '买断 · US\$29.99';
  @override
  String get premiumMonthly => '订阅 · US\$2.99/月';
  @override
  String get premiumComingSoon => '购买将在 App Store 正式版中开放，敬请期待。';
  @override
  String get limitTitle => '今天的免费次数已用完';
  @override
  String limitTidyBody(int n) => '免费版每天可整理 $n 次，明天恢复。高级版不限次数。';
  @override
  String limitWizardBody(int n) =>
      '免费版每天可使用 $n 次 AI 编辑，明天恢复 — 高级版没有限制。';
  @override
  String get limitSeePremium => '查看高级版';
  @override
  String get premiumYearly => '年付 · US\$14.99/年';
  @override
  String get premiumLifetimeNote => '上市纪念价 · 原价 US\$39.99';

  @override
  String trialBadge(int days) => '无限体验 · 剩余$days天';

  @override
  String get trialEndedTitle => '无限体验已结束';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      '体验期间您整理了 $tidy 次，使用 AI 编辑 $wiz 次。从现在起免费版每天可整理 $tidyLimit 次、AI 编辑 $wizLimit 次。升级高级版即可解除限制。';
  @override
  String get themeTitle => '外观模式';
  @override
  String get themeSystem => '跟随设备';
  @override
  String get themeLight => '浅色';
  @override
  String get themeDark => '深色';
  @override
  String get aiKeyVerify => '验证密钥';
  @override
  String get aiKeyChecking => '验证中…';
  @override
  String get aiKeyUnknownFormat => '无法识别密钥格式。请在高级选项中手动指定模型。';
  @override
  String get aiAdvancedLabel => '高级 — 手动选择模型';
  @override
  String get aiManualModelHint => '输入模型名称（例如 gemini-2.5-flash-lite）';
  @override
  String aiAutoLabel(String provider, String model) => '自动选择：$provider · $model';
  @override
  String aiModelsFound(int n) => '已确认 $n 个可用模型。';
  @override
  String aiListFailed(String error) => '无法获取模型列表（$error）。将使用内置备用列表。';
  @override
  String aiModelSwitched(String model) => '原模型无响应，已切换到 $model。';
  @override
  String get rulesSectionTitle => '自动替换规则';
  @override
  String get rulesSectionDesc => '自上而下依次应用。替换内容中的 \\n 表示换行。代码块内不会改动。';
  @override
  String get addRule => '添加规则';
  @override
  String get settingsFooter => '设置保存后立即生效，从下一次"整理"开始应用。已整理过的备忘录不会被追溯修改。';
}
