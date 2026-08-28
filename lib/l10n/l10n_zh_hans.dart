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
  String get shareAppTitle => '分享应用';
  @override
  String get rateAppTitle => '给我们评分';
  @override
  String get shareAppMsg =>
      'Skyblue Note — 轻快的笔记应用，在所有设备间同步。';
  @override
  String get seedBody => [
        '您好！😊 以下是您要的整理结果[1][2]。',
        '',
        '# Skyblue Note',
        '',
        '表格错位了吧。点一下左下角的**魔法棒**。🎉',
        '',
        '| 公司 | 代码 | 涨跌幅 | 比重',
        '|------|------|--------|',
        '| 苹果 | AAPL | +14.2% | 12% |',
        '|英伟达|NVDA|+48.9%|22%|',
        '| 微软 | MSFT | +21.5% | 18% |',
        '|特斯拉|TSLA|-8.3%|8%|',
        '',
        '> 整理后各列对齐。菜单里的"表格"可直接粘进电子表格。',
        '',
        '## 会被清掉的',
        '',
        '- [ ] 客套开场白和表情符号 🙂',
        '- [ ] 黏在句尾的脚注[3][4]',
        '- [ ] 行尾落单的星号**',
        '- [x] 错位的表格会重新排好',
        '',
        '## 会保留的',
        '',
        '标题、**加粗**和引用都保留。屏幕上显示为格式，复制到记事本或论坛时符号会自动去掉。',
        '',
        '---',
        '',
        '\t•\t用制表符包住的项目符号 — Grok 和 ChatGPT 就是这样粘出来的',
        '\t•\t重复的   空格和制表符',
        '\t•\t散开的这几行也会归位',
        '',
        '> 不满意就用菜单里的[恢复原文](https://ezlong.com/skybluenote)还原。',
      ].join('\n');

  @override
  String get done => '完成';

  @override
  String get bodyFontSizeTitle => '正文字号';

  @override
  String get bodyLineHeightTitle => '正文行距';

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
  String get metaTooltip => '标题·标签';
  @override
  String get pinTooltip => '置顶';
  @override
  String get unpinTooltip => '取消置顶';

  @override
  String get unpinConfirmTitle => '取消置顶这条笔记？';

  @override
  String get unpinConfirmBody =>
      '在列表中长按笔记即可重新置顶。';
  @override
  String get deleteTooltip => '删除';
  @override
  String get titleHint => '标题（自动）';
  @override
  String get titleTapHint => '输入标题';
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
  String get revertedToast => '已还原到原文，之前的文字在版本记录里';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => '还原到原文';

  @override
  String get revertConfirmTitle => '还原到原文？';

  @override
  String get revertConfirmBody =>
      '笔记将回到你最初粘贴的文本，之后的整理和手动修改都会消失。\n\n恢复后仍可回到之前的编辑 — 菜单 → 版本历史的第一条就是现在这段内容。';

  @override
  String get revertConfirmOk => '还原';

  @override
  String get okAction =>
      '确定';

  @override
  String get revertDoneTitle =>
      '已恢复为原文';

  @override
  String get revertDoneBody =>
      '刚才的内容并没有消失。\n\n打开菜单 → 版本历史，最上面的一条就是恢复前的内容，随时可以点击还原。';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => '圆点列表';

  @override
  String get listDashAction => '短横列表';

  @override
  String get listNumberAction => '编号列表';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => '来源';

  @override
  String sourceSaved(String name) => '已保存来源 · $name';

  @override
  String sourceDetected(String name) => '已识别来源 · $name';

  @override
  String get sourceCleared => '已清除来源';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => '文件夹';

  @override
  String get folderNone => '不放入文件夹';

  @override
  String get folderNew => '新建文件夹';

  @override
  String get folderNameHint => '文件夹名称';

  @override
  String get folderCleared => '已移出文件夹';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => '管理文件夹';

  @override
  String get folderRename => '重命名';

  @override
  String get folderDelete => '删除文件夹';

  @override
  String get folderReorderHint => '拖动以排序';

  @override
  String get folderManageEmpty => '还没有文件夹';

  @override
  String get folderDupName => '已存在同名文件夹';

  @override
  String get folderDeleted => '已删除文件夹';

  @override
  String get folderRenamed => '已重命名';

  @override
  String folderDeleteBody(String name, int count) =>
      '“$name”中的 $count 条笔记仍可在全部笔记中查看。笔记不会被删除。';

  @override
  String folderNoteCount(int count) => '$count 条笔记';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => '正在确认是否真的可用…';

  @override
  String get aiPingOk => '编辑也能用，可以开始了。';

  @override
  String aiPingFailed(String err) => '能取到列表，但编辑调用被拒绝 — $err';

  @override
  String get aiAdvancedNote => '通常不用管这里。填了密钥就会自动选。';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => '纸';

  @override
  String get paperKraft => '牛皮纸';

  @override
  String get paperWalnut => '胡桃';

  @override
  String get paperNight => '夜';

  @override
  String get paperSky => '天空';

  @override
  String get themeSystemNote =>
      '跟随设备时，设备切到深色的时间，应用也会一起切换。';

  @override
  String folderMoved(String name) => '已移到 $name';
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
  String get todoAction => '待办';
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
  String unknownPrefix(String what) => '交给 AI 处理 · $what';
  @override
  String get aiKeyPromo => '在设置中填入 AI API 密钥后，这类自由编辑指令也能处理。';
  @override
  String get aiBusyLabel => 'AI 编辑中…';
  @override
  String get aiWorking => 'AI 正在按你的指示编辑。这需要一点时间…';
  @override
  String get aiEmptyResponse => '空响应';
  @override
  String aiCallFailed(String error) => 'AI 调用失败: $error';
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
  String get ruleScopeAll => '应用于所有笔记';
  @override
  String get ruleScopeNote => '仅应用于此笔记';
  @override
  String get noteRules => '此笔记的规则';
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
  String get copyPlainSub =>
      '纯文本 — 去掉 #、** 等符号';

  @override
  String get copyRaw => '按 Markdown 复制';

  @override
  String get copyRawSub =>
      '用于 Notion、Slack、GitHub 等支持 Markdown 的地方';
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
  String get apply => '立即应用整理';

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
      '发到微信·短信时。符号和表情全部清掉，表格排成对齐的文字表';
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
  String get tidySample => [
        '## 今日小结 😊',
        '',
        '**要点**有三条[1][2]。',
        '',
        '- 第一条',
        '- 第二条',
        '',
        '> 引用一行',
        '',
        '详见[博客](https://ezlong.com)',
        '',
        '| 项目 | 值 |',
        '|---|---|',
        '|营收|120|',
      ].join('\n');

  @override
  String get settingsTitle => '设置';

  @override
  String get menuAppSettings => '应用设置';

  @override
  String get menuAiKey => 'AI API 密钥';

  @override
  String get syncTitle => '同步';
  @override
  String get syncAppleOnly => '仅限苹果设备';

  @override
  String get syncScopeTitle =>
      '同步范围';

  @override
  String get syncScopeShared =>
      '设备间同步：备忘录、整理规则、手动添加的替换规则、文件夹、常用 AI 编辑指令';

  @override
  String get syncStateOffGdrive => '请重新登录你的 Google 账号';
  @override
  String get syncStateExpiredGdrive => '账号仍已连接，但云端硬盘的使用授权已过期。点一次即可重新授权';

  @override
  String get syncScopePlatformGdrive =>
      'Google 云端硬盘的存放处由使用本应用的所有设备共用。装上本应用并用同一个 Google 账号登录即可';

  @override
  String get syncScopeDevice =>
      '每台设备单独：字号、行距、背景、外观、排序';

  @override
  String get syncScopePlatform =>
      '目前自动同步仅在 Apple 设备（iPhone、iPad、Mac）之间进行。其他设备请使用菜单中的导出备份与导入';

  @override
  String get typographyTitle => '字体与行距';

  @override
  String get syncScopeNever =>
      'AI API 密钥不会上传到任何云端，需要在每台设备上分别输入';
  @override
  String get syncWhereTitle =>
      '放在哪里';
  @override
  String get syncBackendNone =>
      '不同步';
  @override
  String get syncBackendNoneSub =>
      '只保存在这台设备';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      '在 iPhone·iPad·Mac 之间';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      '还包括其他设备与网页';
  @override
  String get syncSoon =>
      '准备中';

  @override
  String get driveSignInFailed => '无法连接你的 Google 账号';

  @override
  String get driveNeedsSignIn => '需要先连接 Google 账号';

  @override
  String get driveSignedInAs => '已连接';
  @override
  String get syncSectionState =>
      '当前状态';
  @override
  String get syncNowAction =>
      '立即同步';
  @override
  String get syncNowBusy => '正在同步…';

  @override
  String get syncLastNever =>
      '还没有同步过';
  @override
  String get headingTip => '标题';
  @override
  String get quoteTip => '引用';
  @override
  String get boldTip => '粗体';
  @override
  String get codeTip => '代码';
  @override
  String get linkTip => '链接';
  @override
  String get outdentTip => '减少缩进';
  @override
  String get cursorLeftTip => '向左';
  @override
  String get cursorRightTip => '向右';
  @override
  String get clearFormatTip => '清除格式';

  @override
  String get blockFormatTip => '段落格式';

  @override
  String get syncStalledTitle => '同步已停止';

  @override
  String get wipeAction => '整理前后对比';

  @override
  String get travelAction => '时间旅行';

  @override
  String get skyAction => 'AI 星座';
  @override
  String get skyTitle => 'AI 星座';
  @override
  String skyCounts(int stars, int links) => '$stars 颗星 · $links 条线';
  @override
  String skyEmpty(int more) => '再写 $more 篇，这里就会出现星座。相似的笔记会被线连起来。';
  @override
  String get travelTitle => '时间旅行';
  @override
  String get travelNow => '现在';
  @override
  String get travelOlder => '早前版本';
  @override
  String get travelRestore => '恢复此版本';
  @override
  String travelShrank(int n) => '少了 $n 字';
  @override
  String travelGrew(int n) => '多了 $n 字';
  @override
  String get wipeTitle => '整理前 · 整理后';
  @override
  String get wipeBefore => '整理前';
  @override
  String get wipeAfter => '整理后';
  @override
  String wipeCounts(int before, int after) => '$before 字 → $after 字';
  @override
  String get syncStalledSub => 'Google 授权已失效。笔记仍安全保存在本设备。';
  @override
  String get syncStalledFix => '重新连接';
  @override
  String get blockBody => '正文';
  @override
  String get blockH1 => '标题1';
  @override
  String get blockH2 => '标题2';
  @override
  String get blockH3 => '标题3';
  @override
  String get blockQuote => '引用';
  @override
  String get blockCode => '代码';
  @override
  String get bodyFontTitle => '正文字体';
  @override
  String get bodyFontSystem => '系统';
  @override
  String get bodyFontNoto => 'Noto';
  @override
  String get bodyFontMono => '等宽';
  @override
  String get moreTools => '更多';
  @override
  String get findTitle => '查找';
  @override
  String get findAction => '查找';
  @override
  String get showReplaceLabel => '替换';
  @override
  String get replaceOneAction => '替换';
  @override
  String get findNone => '没有匹配项';
  @override
  String get syncFirstTitle => '正在同步';
  @override
  String get syncFirstSub => '正在获取其他设备上的笔记。笔记较多时可能需要一点时间。';
  @override
  String get syncLogTitle => '同步记录';
  @override
  String get syncLogNote => '只记录什么在何时同步过，不保存笔记内容。';
  @override
  String get syncLogEmpty => '还没有同步过任何内容';
  @override
  String get syncLogNever => '尚无';
  @override
  String get syncLogUp => '上传';
  @override
  String get syncLogDown => '下载';
  @override
  String get syncLogFailed => '失败';
  @override
  String syncUpdatedAt(String when) => '最近更新 ' + when;
  @override
  String findHits(int n) => '找到 ' + n.toString() + ' 个';
  @override
  String syncLogLastUp(String when) => '最近一次上传 · ' + when;
  @override
  String syncLogLastDown(String when) => '最近一次下载 · ' + when;
  @override
  String get syncTroubleTitle =>
      '出问题时';
  @override
  String get syncTroubleNote =>
      '同步不是备份。在一台设备上删掉，别处也会消失。重要的笔记请偶尔导出成文件。';
  @override
  String syncLastAt(String when) => '上次同步 $when';

  @override
  String syncStateOn(String where) => '存放在 $where，装有本应用的设备都看到同样的备忘录';

  @override
  String get syncStateOff => '请在设备设置中开启 iCloud 云盘';

  @override
  String syncStateSyncing(String where) => '正在与 $where 同步… 需要几秒到几十秒';

  @override
  String get aiKeyNotSynced => '备忘会通过所选的存放处同步到您的所有设备，但 API 密钥不会同步 — 请在每台设备上单独输入。';
  @override
  String get aiKeySyncTitle => 'API 密钥也同步';
  @override
  String get aiKeySyncSubApple => '通过 iCloud 钥匙串传输，与备忘的通道不同。只有您的设备持有密钥，因此连 Apple 也无法读取。';
  @override
  String get aiKeySyncSubGdrive => '存放在 Google 云端硬盘上的 API 密钥，安全由各自负责。';

  @override
  String get autoTagTitle => '自动添加标签';

  @override
  String get autoTagSub =>
      '编辑后稍作停顿，AI 会重新提取标签。你手动改过标签的笔记不会被改动';

  @override
  String get syncStateSignedOut => '点按查看方法';

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
  String get selectWord => '选择';

  @override
  String get tagAiNeedKey => '在设置中输入 API 密钥后即可使用 AI 自动标签。';

  @override
  String get toggleListTooltip => '隐藏或显示列表';

  @override
  String get aiDetecting => '正在确认这是哪家服务商的密钥…';

  @override
  String get aiErrNoCredits => '密钥没问题，但该账户没有余额。请在服务商网站添加付款方式或充值。若不想付费，可以试试 Google Gemini 密钥（以 AIza… 开头）——它有免费额度。';

  @override
  String get aiErrBadKey => '密钥被拒绝。请检查前后是否有空格或引号，仍然不行就到服务商网站重新申请。';

  @override
  String get aiErrRateLimit => '当前请求过于集中。这不是应用的问题，请稍后再试。';

  @override
  String get aiErrNoModel => '该账户无法使用这个模型。请在下方“高级 — 直接选择模型”中换一个。';

  @override
  String get aiErrNetwork => '无法连接互联网。请检查网络后重试。';

  @override
  String get multiSelectStart => '选择多条删除';

  @override
  String get selectAllTooltip => '全选 / 取消全选';

  @override
  String get deleteSelected => '删除所选';

  @override
  String get deleteSelectedDone => '完成';

  @override
  String get deleteSelectedConfirm => '确定删除所选备忘录吗？';

  @override
  String deleteSelectedBody(int n) => '将有 $n 条备忘录移入回收站，30 天内可以恢复。';

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
  String get printAction =>
      '打印';

  @override
  String get exportPdf =>
      '导出为 PDF';

  @override
  String get pdfFailed =>
      '无法生成 PDF';

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
      '载入文件并追加到正文';

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
  String get historyWhyTidy => '整理前';

  @override
  String get historyWhyAi => 'AI 编辑前';

  @override
  String get historyWhyReplace => '替换前';

  @override
  String get historyWhyRevert => '恢复原文前';

  @override
  String get historyWhyRestore => '还原前';

  @override
  String get widgetEmpty => '还没有笔记';

  @override
  String get widgetAllLocked => '已锁定的笔记不会显示在小组件中';

  @override
  String get attachTitle => '附件';

  @override
  String get attachAdd => '添加附件';

  @override
  String get attachRemove => '删除附件';

  @override
  String get attachRemoveBody => '文件将从此设备删除，且无法恢复。';

  @override
  String get attachFailed => '无法添加附件';

  @override
  String get attachNotHere => '该文件在另一台设备上';

  @override
  String attachAndMore(int n) => '等 ${n} 个';

  @override
  String attachOther(String device, String what) => '附件：${device} 上的笔记附有 ${what}（仅可在该设备上查看）';

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
        return '安卓手机';
      case 'windows':
        return 'Windows 电脑';
      case 'web':
        return '网页';
      default:
        return '其他设备';
    }
  }

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
  String get paperTitle => '编辑页背景';

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
  String get paperFrost => '霜白';

  @override
  String get lockSectionTitle => '锁定';

  @override
  String get lockTitle => '应用锁';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? '使用指纹、人脸识别或屏幕锁打开应用。'
      : vendor == 'windows'
          ? '使用 Windows Hello 或设备 PIN 打开应用。'
          : '使用面容 ID、触控 ID 或设备密码打开应用。';

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
  String lockUnavailable(String vendor) => vendor == 'android'
      ? '此设备无法使用指纹、人脸识别或屏幕锁。'
      : vendor == 'windows'
          ? '此设备无法使用 Windows Hello 或设备 PIN。'
          : '此设备无法使用面容 ID、触控 ID 或设备密码。';

  @override
  String get lockReasonOpen => '打开备忘录需要验证';

  @override
  String get lockReasonOn => '开启锁定需要验证';

  @override
  String get lockReasonOff => '关闭锁定需要验证';

  @override
  String get noteLock => '锁定此笔记';

  @override
  String get noteUnlock => '解锁此笔记';

  @override
  String get noteLocked => '已锁定的笔记';

  @override
  String get lockReasonNote => '打开已锁定的笔记';

  @override
  String get noteLockDone => '已锁定此笔记';

  @override
  String get noteUnlockDone => '已解锁此笔记';

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
  String get tidyRulesTitle => '整理规则';

  @override
  String get tidyRulesSub =>
      '决定按下"整理"后文字如何变化。这里选的只对"基本整理"生效 — 其他方式按名字所说的做。';

  @override
  String get syncOnTitle => '已开启';

  @override
  String get syncOffTitle => '已关闭';

  @override
  String get syncSignedOutTitle => '需要登录';
  @override
  String get syncHelpTitleGdrive => '重新连接 Google 云端硬盘';
  @override
  String get syncHelpStepsGdrive => '1. 点击下方按钮，选择您的 Google 账号\n2. 允许访问云端硬盘\n3. 随即开始同步';
  @override
  String get syncHelpNoteGdrive => '备忘仍在云端硬盘中。重新登录后就会回来。';
  @override
  String get syncDiagSignedOutGdrive => '此设备尚未登录 Google 账号。';
  @override
  String get syncSignInGoogle => '使用 Google 账号登录';
  @override
  String get syncAllowDrive => '允许访问云端硬盘';
  @override
  String get syncDiagPreparingGdrive =>
      "已登录，正在从云端硬盘接收笔记。无需一直盯着屏幕 — 切到其他应用也没关系，接收会暂停，回来后从中断处继续。";
  @override
  String get syncRecheckStillGdrive => '还没全部取回。备忘较多时首次同步需要一点时间 \u2014 关闭此窗口后仍会继续。';

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
  String get quoteTitle => '引用 (> 文本)';
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
  String get menuTidyPreview => '整理预览';
  @override
  String get dividerTip => '分隔线';
  @override
  String get syncScroll => '同步滚动';
  @override
  String get pasteTipTitle => '不再每次询问粘贴';
  @override
  String get pasteTipSub => '一次关掉 iPhone 每次粘贴都弹出的询问';
  @override
  String get pasteTipBody =>
      'iPhone 在应用每次读取剪贴板时都会请求许可。这个应用从粘贴开始，所以那个询问会频繁出现。\n\n改一次就不会再问了。\n\n1. 点下面的“打开设置”\n2. 点“从其他 App 粘贴”\n3. 选“允许”\n\n即使允许，这个应用也只在您点粘贴的那一刻读取剪贴板，不会私自查看。';
  @override
  String get pasteTipLater => '以后再说';
  @override
  String get adClose => '关闭广告';
  @override
  String get noteDuplicate => '复制';
  @override
  String get noteDuplicated => '已复制';
  @override
  String get adSponsored => '赞助';
  @override
  String get sponsorTitle => '一条广告，成就下一次更新';
  @override
  String get sponsorBody =>
      '更好的功能和持续的更新需要您的支持。完整看完一支广告，今天这个应用就不再显示广告。';
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
  String get premiumPlanBase => '基础版';
  @override
  String get premiumPlanAll => '全设备';
  @override
  String get premiumBestValue => '最划算';
  @override
  String get premiumPerks => '无广告 · 整理无限 · AI 向导无限';
  @override
  String get premiumScopeBase => '在购买所在商店的设备和网页版上可用。';
  @override
  String get premiumScopeAll => '在你使用的任何设备上都可用。';
  @override
  String get premiumAutoRenew => '订阅将在到期前 24 小时未取消时自动续期并按同额计费。您可随时在账户设置中取消。';
  @override
  String get premiumRestore => '恢复购买';
  @override
  String get premiumTerms => '使用条款';
  @override
  String get premiumPrivacy => '隐私政策';
  @override
  String get premiumThanks => '谢谢，高级版已开启。';
  @override
  String get premiumNoStore => '此设备无法购买。购买后用同一账号登录这里即可生效。';
  @override
  String get premiumUpgradeHere => '要在此设备使用，请升级到「全设备」。剩余时间由商店折算。';
  @override
  String get premiumHave => '当前方案';
  @override
  String get premiumLoading => '正在从商店获取价格';
  @override
  String get premiumTitle => '高级版';
  @override
  String get premiumPitch => '无广告，不设限';
  @override
  String get premiumPitchSub => '无广告、不限量 · 从月付到买断';
  @override
  String get premiumBody => '高级版去除广告，并解锁无限整理与 AI 向导。两种方案 —「基础版」适用于购买所在商店的设备和网页版；「全设备」适用于你使用的任何设备。您的支持成就下一次更新。';
  @override
  String get premiumLifetime => '买断';
  @override
  String get premiumMonthly => '月付';
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
  String get premiumYearly => '年付';
  @override
  String get premiumLifetimeNote => '一次付款，不再续费';

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
  String get aiKeyUnknownFormat => '无法识别服务商。已向四家全部询问，均未接受此密钥。请重新复制并粘贴密钥。';
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
