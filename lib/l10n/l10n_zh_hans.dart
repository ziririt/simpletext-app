import 'l10n.dart';

/// 简体中文
class L10nZhHans extends L10n {
  const L10nZhHans();

  @override
  String get localeTag => 'zh-Hans';

  @override
  String get appTitle => '简文本';

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
  String get seedTitle => '欢迎使用简文本';
  @override
  String get seedTag => '使用方法';
  @override
  String get seedBody => [
        '简文本使用方法',
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
        '| 英伟达 | NVDA | +48.9% | 22% | 多余单元格 |',
        '|特斯拉|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '完成';

  @override
  String get autoTidy => '自动整理';

  @override
  String get bodyFontSizeTitle => '正文字号';

  @override
  String get bodyFontSizeSample =>
      '遇见一个把脑中纷杂思绪整理得 Simplicity 而 Smart 的工作空间。粘贴后点一次"整理"，一切都变得 Clean。';

  @override
  String get wizardNothingToDo => '没有需要更改的内容';

  @override
  String wizardAppliedToast(int count) => '已应用 \$count 条指令';

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
  String get wizardAction => '向导';
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
  String get wizardTitle => '向导';
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
  String get presetAiName => '整理 AI 回答';
  @override
  String get presetAiDesc => '去除 Markdown 标记、表情符号、AI 开场白，修复表格';
  @override
  String get presetStripName => '完全去除 Markdown';
  @override
  String get presetStripDesc => '最大限度去除 Markdown 语法，表格转为 TSV';
  @override
  String get presetMinimalName => '最小整理';
  @override
  String get presetMinimalDesc => '保留结构，仅去除杂质（空格、零宽字符等）';
  @override
  String get presetTablesName => '仅提取表格';
  @override
  String get presetTablesDesc => '从文档中提取表格并转为 TSV';
  @override
  String get presetBlogName => '博客粘贴';
  @override
  String get presetBlogDesc => '去除标记，链接保留网址，修复表格';

  @override
  String get settingsTitle => '整理规则设置';
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
  String get aiSectionTitle => 'AI 向导连接（自由编辑）';
  @override
  String get aiSectionDesc => '填入 API 密钥后，向导可处理"写得更简洁些"这类自由编辑指令。密钥仅保存在本设备上。';
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
  String limitTidyBody(int n) => '免费版每天可整理 \$n 次，明天恢复。高级版不限次数。';
  @override
  String limitWizardBody(int n) => '免费版每天可使用向导 \$n 次，明天恢复。高级版不限次数。';
  @override
  String get limitSeePremium => '查看高级版';
  @override
  String get premiumYearly => '年付 · US\$14.99/年';
  @override
  String get premiumLifetimeNote => '上市纪念价 · 原价 US\$39.99';
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
