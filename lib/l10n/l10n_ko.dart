import 'l10n.dart';

/// 한국어 — 원문(소스 오브 트루스). 다른 언어는 이 파일 기준으로 번역한다.
class L10nKo extends L10n {
  const L10nKo();

  @override
  String get localeTag => 'ko';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => '버전';

  @override
  String get homeTitle => '메모';
  @override
  String get settingsTooltip => '정리 규칙 설정';
  @override
  String get searchHint => '검색';
  @override
  String get emptyList => '메모가 없습니다.\n"붙여넣고 정리"로 시작해 보세요.';
  @override
  String get pinnedLabel => '고정됨';
  @override
  String get notesLabel => '노트';
  @override
  String get newNoteTooltip => '새 문서 만들기';
  @override
  String get pasteAndTidy => '새 문서 만들어 붙여넣고 정리';
  @override
  String get clipboardEmpty => '클립보드가 비어 있습니다. AI 답변을 먼저 복사해 주세요.';
  @override
  String get yesterday => '어제';
  @override
  String get untitled => '제목 없음';
  @override
  String get deleteConfirmTitle => '이 메모를 삭제할까요?';
  @override
  String get cancel => '취소';
  @override
  String get delete => '삭제';

  @override
  String dateShort(int y, int m, int d) => '$y. $m. $d.';

  @override
  String get seedTitle => 'Skyblue Note에 오신 것을 환영합니다';
  @override
  String get seedTag => '사용법';
  @override
  String get seedBody => [
        '안녕하세요! 😊 요청하신 내용을 아래와 같이 정리해 드렸습니다[1][2].',
        '',
        '# Skyblue Note',
        '',
        '표가 어긋나 있죠. 왼쪽 아래 **마법봉**을 눌러 보세요. 🎉',
        '',
        '| 종목 | 티커 | 수익률 | 비중',
        '|------|------|--------|',
        '| 애플 | AAPL | +14.2% | 12% |',
        '|엔비디아|NVDA|+48.9%|22%|',
        '| 마이크로소프트 | MSFT | +21.5% | 18% |',
        '|테슬라|TSLA|-8.3%|8%|',
        '',
        '> 정리하면 줄이 맞습니다. 메뉴의 \'표\'를 누르면 엑셀에 그대로 붙습니다.',
        '',
        '## 걷히는 것',
        '',
        '- [ ] 군더더기 인사말과 이모지 🙂',
        '- [ ] 문장 끝에 붙은 각주[3][4]',
        '- [ ] 줄 끝에 홀로 남은 별표**',
        '- [x] 어긋난 표는 다시 세웁니다',
        '',
        '## 남는 것',
        '',
        '제목과 **굵게**와 인용은 그대로 둡니다. 화면에서는 뜻으로 보이고, 복사해서 메모장이나 게시판에 붙이면 표시는 빠집니다.',
        '',
        '---',
        '',
        '\t•\t탭으로 감싼 글머리표 — 그록·챗지피티가 이렇게 냅니다',
        '\t•\t겹친   공백과 탭',
        '\t•\t흩어진 이 줄들도 제자리를 찾습니다',
        '',
        '> 마음에 안 들면 메뉴의 [원본 복귀](https://ezlong.com/skybluenote) 한 번으로 되돌립니다.',
      ].join('\n');

  @override
  String get done => '완료';

  @override
  String get bodyFontSizeTitle => '본문 글자 크기';

  @override
  String get bodyLineHeightTitle => '본문 줄 간격';

  @override
  String get bodyFontSizeSample =>
      '머릿속의 수많은 생각을 Simplicity하게 깔끔히 정돈해 주는 Smart한 작업 공간을 만나보세요. 붙여넣고 정리 한 번이면 Clean하게 끝납니다.';

  @override
  String get wizardNothingToDo => '바꿀 것이 없습니다';

  @override
  String wizardAppliedToast(int count) => '지시 $count개를 적용했습니다';

  @override
  String get skipPreviewCheck => '앞으로 미리보기 생략';

  @override
  String get previewTitle2 => '정리 전 미리보기';

  @override
  String get previewSub2 => '정리 결과를 먼저 보여 주고 적용할지 묻습니다';
  @override
  String get metaTooltip => '제목·태그';
  @override
  String get pinTooltip => '리스트 상단 고정';
  @override
  String get unpinTooltip => '상단 고정 해제';

  @override
  String get unpinConfirmTitle => '상단 고정을 해제할까요?';

  @override
  String get unpinConfirmBody =>
      '목록에서 노트를 길게 누르면 다시 고정할 수 있습니다.';
  @override
  String get deleteTooltip => '삭제';
  @override
  String get titleHint => '제목(자동)';
  @override
  String get titleTapHint => '제목 입력';
  @override
  String get sourceNone => '출처 없음';
  @override
  String get sourceOther => '기타';
  @override
  String get tagsHint => '태그 (쉼표로 구분)';
  @override
  String get tagAiButton => '태그 AI 자동입력';
  @override
  String get tagAiWorking => '태그를 뽑는 중…';
  @override
  String get tagAiNone => '뽑을 만한 키워드를 찾지 못했습니다';
  @override
  String get tagAiLocalNote => 'AI 키가 없어 앱이 직접 골랐습니다';
  @override
  String get tagsBoxHint => '태그 입력 후 쉼표';
  @override
  String get tagRemoveTip => '태그 삭제';
  @override
  String get bodyHint => '여기에 붙여넣거나 입력하세요';
  @override
  String get noteNotFound => '메모를 찾을 수 없습니다';
  @override
  String get revertedToast => '원본으로 되돌렸습니다 · 직전 글은 버전기록에 있습니다';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => '원본복귀';

  @override
  String get revertConfirmTitle => '원본으로 되돌릴까요?';

  @override
  String get revertConfirmBody =>
      '처음 붙여넣은 글로 돌아갑니다. 그 뒤에 정리한 것과 손으로 고친 것이 모두 사라집니다.\n\n되돌린 뒤에도 이전 편집 내역으로 갈 수 있습니다 — 삼선 메뉴 → 버전 기록의 맨 위 항목이 지금 이 글입니다.';

  @override
  String get revertConfirmOk => '원본으로';

  @override
  String get okAction =>
      '확인';

  @override
  String get revertDoneTitle =>
      '원본으로 되돌렸습니다';

  @override
  String get revertDoneBody =>
      '방금까지 쓰던 글은 사라지지 않았습니다.\n\n삼선 메뉴 → 버전 기록을 열면 맨 위 항목이 원복 직전의 글입니다. 눌러서 언제든 되살릴 수 있습니다.';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => '구분점 목록';

  @override
  String get listDashAction => '대시 목록';

  @override
  String get listNumberAction => '번호 목록';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => '출처';

  @override
  String sourceSaved(String name) => '출처를 저장했습니다 · $name';

  @override
  String sourceDetected(String name) => '출처를 알아냈습니다 · $name';

  @override
  String get sourceCleared => '출처를 지웠습니다';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => '폴더';

  @override
  String get folderNone => '폴더 없음';

  @override
  String get folderNew => '새 폴더';

  @override
  String get folderNameHint => '폴더 이름';

  @override
  String get folderCleared => '폴더에서 뺐습니다';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => '폴더 설정';

  @override
  String get folderRename => '이름 바꾸기';

  @override
  String get folderDelete => '폴더 삭제';

  @override
  String get folderReorderHint => '끌어서 차례를 바꿉니다';

  @override
  String get folderManageEmpty => '아직 폴더가 없습니다';

  @override
  String get folderDupName => '같은 이름의 폴더가 이미 있습니다';

  @override
  String get folderDeleted => '폴더를 지웠습니다';

  @override
  String get folderRenamed => '이름을 바꿨습니다';

  @override
  String folderDeleteBody(String name, int count) =>
      "'$name' 폴더 안의 노트 $count개는 전체 목록에서 볼 수 있습니다. 노트는 지워지지 않습니다.";

  @override
  String folderNoteCount(int count) => '노트 $count개';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => '실제로 쓸 수 있는지 확인하는 중…';

  @override
  String get aiPingOk => '편집까지 됩니다. 이제 쓰셔도 됩니다.';

  @override
  String aiPingFailed(String err) => '목록은 받았지만 편집 호출이 거절당했습니다 — $err';

  @override
  String get aiAdvancedNote => '보통은 안 건드려도 됩니다. 키만 넣으면 알아서 고릅니다.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => '종이';

  @override
  String get paperKraft => '크라프트';

  @override
  String get paperWalnut => '월넛';

  @override
  String get paperNight => '나이트';

  @override
  String get paperSky => '하늘';

  @override
  String get themeSystemNote =>
      '기기 설정을 따르면, 기기가 어두운 모드로 바뀌는 시간에 앱도 같이 바뀝니다.';

  @override
  String folderMoved(String name) => '폴더로 옮겼습니다 · $name';
  @override
  String appliedDone(String summary) => '적용 완료 — $summary';

  @override
  String get undoTip => '실행 취소';
  @override
  String get redoTip => '다시 실행';
  @override
  String get moveLeftTip => '왼쪽으로';
  @override
  String get moveRightTip => '오른쪽으로';
  @override
  String get lineStartTip => '줄 처음';
  @override
  String get lineEndTip => '줄 끝';
  @override
  String get indentTip => '들여쓰기';

  @override
  String get todoAction => '할 일';
  @override
  String get hideKeyboardTip => '키보드 내리기';

  @override
  String get tidyAction => '정리';
  @override
  String get wizardAction => 'AI 편집';
  @override
  String get tableAction => '표';
  @override
  String get replaceAction => '바꾸기';
  @override
  String get copyAction => '복사';
  @override
  String get undoAction => '되돌리기';

  @override
  String get noTablesFound => '이 메모에서 표를 찾지 못했습니다';
  @override
  String tableInfo(int n, int cols, int rows) => '표 $n — $cols열 × $rows행';
  @override
  String get forSpreadsheet => '스프레드시트용';
  @override
  String get copiedSpreadsheet => '복사 완료 — 구글 시트나 엑셀 셀에 붙여넣으세요';
  @override
  String get copiedCsv => 'CSV로 복사했습니다';
  @override
  String get copiedMarkdown => 'Markdown 표로 복사했습니다';

  @override
  String get wizardTitle => 'AI 편집';
  @override
  String get wizardHint => '말로 지시하세요. 예:\n소제목 위 공백은 2줄, 아래는 1줄로 해줘\n마소를 마이크로소프트로 바꿔줘';
  @override
  String get favSaveButton => '자주 쓰는 지시문으로 등록';
  @override
  String get favListTitle => '자주 쓰는 지시문';
  @override
  String get favUse => '선택';
  @override
  String get favEmpty => '아직 등록한 지시문이 없습니다';
  @override
  String get favRemove => '지우기';
  @override
  String get favSavedToast => '등록했습니다';
  @override
  String appliedPrefix(String what) => '적용됨 · $what';
  @override
  String unknownPrefix(String what) => 'AI가 맡을 부분 · $what';
  @override
  String get aiKeyPromo => '설정에 AI API 키를 넣으면 이런 자유 편집 명령도 처리됩니다.';
  @override
  String get aiBusyLabel => 'AI 편집 중…';
  @override
  String get aiWorking => 'AI가 지시대로 편집하고 있습니다. 편집에 시간이 좀 걸립니다…';
  @override
  String get aiEmptyResponse => '빈 응답';
  @override
  String aiCallFailed(String error) => 'AI 호출 실패: $error';
  @override
  String get aiAppliedToast => 'AI 편집을 적용했습니다 — 되돌리기로 복구 가능';
  @override
  String get close => '닫기';
  @override
  String get interpretApply => '해석하고 적용';

  @override
  String get replaceTitle => '바꾸기';
  @override
  String get findLabel => '찾기';
  @override
  String get replaceWithLabel => '바꾸기 (\\n=줄바꿈)';
  @override
  String get regexLabel => '정규식';
  @override
  String get saveAsRule => '자동 바꾸기 규칙으로 저장';
  @override
  String get saveAsRuleSub => '이후 "정리"할 때마다 항상 적용';
  @override
  String get invalidRegex => '정규식이 올바르지 않습니다';
  @override
  String get noMatches => '일치하는 내용이 없습니다';
  @override
  String replacedCount(int count) => '$count곳을 바꿨습니다';
  @override
  String get savedRuleSuffix => ' · 자동 바꾸기 규칙으로 저장됨';
  @override
  String get replaceAllAction => '모두 바꾸기';

  @override
  String get copyAll => '전체 복사';

  @override
  String get copyPlainSub =>
      '#, ** 같은 표시를 빼고 맨 글자로';

  @override
  String get copyRaw => '마크다운 그대로 복사';

  @override
  String get copyRawSub =>
      '노션·슬랙·깃허브처럼 마크다운을 아는 곳에';
  @override
  String get copiedAll => '전체 텍스트를 복사했습니다';
  @override
  String get tidyCopy => '정리해서 복사';
  @override
  String get tidyCopySub => '메모는 그대로 두고, 정리된 결과만 복사';
  @override
  String tidyCopied(String summary) => '정리해서 복사했습니다 — $summary';
  @override
  String get copyTableSpreadsheet => '표를 스프레드시트용으로 복사';
  @override
  String get copiedTableSpreadsheet => '표를 스프레드시트용으로 복사했습니다';

  @override
  String previewTitle(String preset) => '$preset — 미리보기';
  @override
  String warningPrefix(String warning) => '주의: $warning';
  @override
  String get tidyResultLabel => '정리 결과';
  @override
  String get originalLabel => '원본';
  @override
  String get apply => '정리 바로적용';

  @override
  String get presetAiName =>
      '기본 정리';
  @override
  String get presetAiDesc =>
      '붙여넣은 AI 답변을 그대로 읽을 수 있게. 대부분 이걸로 충분합니다';
  @override
  String get presetStripName =>
      '기호 싹 지우기';
  @override
  String get presetStripDesc =>
      '카톡·문자에 보낼 때. 기호도 이모지도 다 걷고 표는 줄 맞춘 글자표로';
  @override
  String get presetMinimalName =>
      '잡티만 털기';
  @override
  String get presetMinimalDesc =>
      '구조는 그대로 두고 눈에 안 보이는 찌꺼기만';
  @override
  String get presetTablesName =>
      '표만 꺼내기';
  @override
  String get presetTablesDesc =>
      '엑셀·구글시트에 바로 붙이려고';
  @override
  String get presetBlogName =>
      '블로그·카페용';
  @override
  String get presetBlogDesc =>
      '링크는 살리고 기호만 없앨 때';

  @override
  String get tidySample => [
        '## 오늘 정리 😊',
        '',
        '**핵심**은 세 가지입니다[1][2].',
        '',
        '- 첫째 항목',
        '- 둘째 항목',
        '',
        '> 인용 한 줄',
        '',
        '[블로그](https://ezlong.com)에 자세히',
        '',
        '| 항목 | 값 |',
        '|---|---|',
        '|매출|120|',
      ].join('\n');

  @override
  String get settingsTitle => '설정';

  @override
  String get menuAppSettings => '앱 설정';

  @override
  String get menuAiKey => 'AI API 키';

  @override
  String get syncTitle => '동기화';
  @override
  String get syncAppleOnly => '애플 기기만';

  @override
  String get syncScopeTitle =>
      '동기화 범위';

  @override
  String get syncScopeShared =>
      '함께 오가는 것 : 메모, 정리 규칙, 수동으로 추가한 바꾸기 규칙, 폴더, 자주 쓰는 AI편집 지시문';

  @override
  String get syncStateOffGdrive => '구글 계정에 다시 로그인해 주세요';

  @override
  String get syncScopePlatformGdrive =>
      '구글 드라이브 창고는 아이폰·아이패드·맥·안드로이드가 함께 씁니다. 이 앱을 깔고 같은 구글 계정으로 들어가면 됩니다';

  @override
  String get syncScopeDevice =>
      '기기마다 따로 : 글자 크기, 줄 간격, 배경, 화면 모드, 정렬 기준';

  @override
  String get syncScopePlatform =>
      '지금 자동 동기화는 애플 기기(아이폰·아이패드·맥)끼리만 됩니다. 안드로이드·윈도우는 메뉴의 백업 내보내기와 불러오기를 쓰세요';

  @override
  String get typographyTitle => '글자와 줄 간격';

  @override
  String get syncScopeNever =>
      'AI API KEY는 어느 창고에도 올라가지 않으니, 기기마다 입력해야 합니다';
  @override
  String get syncWhereTitle =>
      '어디에 둘까';
  @override
  String get syncBackendNone =>
      '동기화 안 함';
  @override
  String get syncBackendNoneSub =>
      '이 기기에만 둡니다';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      '아이폰·아이패드·맥끼리 오갑니다';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      '안드로이드·윈도·웹까지 함께';
  @override
  String get syncSoon =>
      '준비 중';

  @override
  String get driveSignInFailed => '구글 계정에 연결하지 못했습니다';

  @override
  String get driveNeedsSignIn => '구글 계정 연결이 필요합니다';

  @override
  String get driveSignedInAs => '연결됨';
  @override
  String get syncSectionState =>
      '지금 상태';
  @override
  String get syncNowAction =>
      '지금 맞추기';
  @override
  String get syncNowBusy => '맞추는 중…';

  @override
  String get syncLastNever =>
      '아직 한 번도 못 맞췄습니다';
  @override
  String get syncTroubleTitle =>
      '문제가 생기면';
  @override
  String get syncTroubleNote =>
      '동기화는 백업이 아닙니다. 한쪽에서 지우면 모든 곳에서 지워집니다. 중요한 노트는 가끔 파일로 뽑아 두십시오.';
  @override
  String syncLastAt(String when) => '마지막으로 맞춘 때 · $when';

  @override
  String syncStateOn(String where) => '$where에 올려 두고, 이 앱을 설치한 기기에서 같은 메모를 봅니다';

  @override
  String get syncStateOff => '기기 설정에서 iCloud Drive를 켜 주세요';

  @override
  String syncStateSyncing(String where) => '$where와 맞추는 중… 몇 초에서 몇십 초 걸립니다';

  @override
  String get aiKeyNotSynced => '메모는 고른 창고로 모든 기기에 동기화됩니다. 하지만 API 키는 동기화되지 않습니다 — 기기마다 직접 넣어 주세요.';
  @override
  String get aiKeySyncTitle => 'API키도 동기화';
  @override
  String get aiKeySyncSubApple => 'iCloud 키체인으로 옮깁니다. 메모가 가는 길과 다른 길이고, 열쇠를 내 기기만 가지므로 애플도 그 값을 읽지 못합니다.';
  @override
  String get aiKeySyncSubGdrive => '구글 드라이브에 있는 API키 보안은 이용자의 몫입니다.';

  @override
  String get autoTagTitle => '태그 자동으로 붙이기';

  @override
  String get autoTagSub =>
      '글을 고치고 잠시 두면 AI가 태그를 다시 뽑습니다. 태그를 직접 만진 노트는 건드리지 않습니다';

  @override
  String get syncStateSignedOut => '눌러서 방법 보기';

  @override
  String get syncHelpTitle => 'iCloud 켜는 법';

  @override
  String get syncHelpSteps =>
      '1. 설정 앱 > 맨 위의 내 이름 > iCloud 로 갑니다\n2. iCloud Drive가 켜져 있는지 봅니다 — 이게 꺼져 있으면 아무 앱도 동기화되지 않습니다\n3. 아이폰을 잠갔다 풀고, 이 앱으로 돌아와 아래 다시 확인을 누릅니다\n\n확인은 설정 앱이 아니라 파일 앱에서 하십시오. 파일 > iCloud Drive 에 Skyblue Note 폴더가 보이면 준비가 된 것입니다.';

  @override
  String get syncOpenSettings => '설정 앱 열기';

  @override
  String get syncRecheck => '다시 확인';

  @override
  String get syncHelpNote =>
      '방금 앱을 깔았다면 준비에 1~2분이 걸리기도 합니다. 그때는 다시 확인만 눌러 보십시오.';

  @override
  String get sortFilterTooltip => '정렬·필터';

  @override
  String get sortFilterTitle => '정렬과 필터';

  @override
  String get sortLabel => '정렬';

  @override
  String get sortUpdated => '최근 수정순';

  @override
  String get sortCreated => '만든 순';

  @override
  String get sortByTitle => '제목순';

  @override
  String get filterSourceLabel => '출처';

  @override
  String get filterTagLabel => '태그';

  @override
  String get filterAll => '전체';

  @override
  String get filterReset => '초기화';

  @override
  String get selectWord => '선택';

  @override
  String get tagAiNeedKey => '설정에서 API 키를 입력하면 AI 자동 태깅이 가능합니다.';

  @override
  String get toggleListTooltip => '목록 접기 / 펴기';

  @override
  String get aiDetecting => '어느 회사 키인지 확인하고 있습니다…';

  @override
  String get aiErrNoCredits => '키는 멀쩡한데 그 회사 계정에 잔액이 없습니다. 회사 홈페이지에서 결제 수단을 등록하거나 크레딧을 충전해야 합니다. 돈을 안 쓰고 싶으시면 구글 제미나이(AIza…로 시작하는 키)를 넣어 보세요 — 무료 한도가 있습니다.';

  @override
  String get aiErrBadKey => '키가 거절당했습니다. 앞뒤에 공백이나 따옴표가 붙지 않았는지 보시고, 그래도 안 되면 회사 홈페이지에서 새로 발급받으세요.';

  @override
  String get aiErrRateLimit => '지금 요청이 몰려 있습니다. 앱 잘못이 아니니 잠시 뒤에 다시 눌러 주세요.';

  @override
  String get aiErrNoModel => '이 계정에서 그 모델을 쓸 수 없습니다. 아래 \'고급 — 모델 직접 선택\'에서 다른 모델을 골라 보세요.';

  @override
  String get aiErrNetwork => '인터넷에 닿지 못했습니다. 연결을 확인하고 다시 해 주세요.';

  @override
  String get multiSelectStart => '선택 메모 한번에 삭제';

  @override
  String get selectAllTooltip => '전체 선택 / 해제';

  @override
  String get deleteSelected => '선택 삭제';

  @override
  String get deleteSelectedDone => '삭제완료';

  @override
  String get deleteSelectedConfirm => '선택한 메모를 정말로 삭제할까요?';

  @override
  String deleteSelectedBody(int n) => '메모 $n개가 휴지통으로 갑니다. 30일 안에는 되살릴 수 있습니다.';

  @override
  String get trashTitle => '휴지통';

  @override
  String get trashSubtitle => '지운 메모는 30일 동안 보관됩니다';

  @override
  String get trashEmpty => '휴지통이 비어 있습니다';

  @override
  String get trashRestore => '복구';

  @override
  String get trashDeleteNow => '완전히 삭제';

  @override
  String get trashEmptyAll => '비우기';

  @override
  String get trashEmptyConfirm => '휴지통을 비우면 되돌릴 수 없습니다. 비울까요?';

  @override
  String get trashRestored => '복구했습니다';

  @override
  String trashDaysLeftLabel(int days) => '$days일 뒤 완전히 지워집니다';

  @override
  String get exportSectionTitle =>
      '가져오기·내보내기';

  @override
  String get exportSubtitle =>
      '메모는 언제든 꺼낼 수 있습니다. 마크다운으로 나가면 애플 메모·옵시디언·노션 어디로든 들어갑니다.';

  @override
  String get exportNote =>
      '이 메모 내보내기';

  @override
  String get exportAllMd =>
      '메모 전체 내보내기';

  @override
  String get exportAllMdSub =>
      '마크다운 여러 장을 압축 파일 하나로';

  @override
  String get exportBackup =>
      '백업 파일 저장';

  @override
  String get exportBackupSub =>
      '이 앱으로 그대로 되돌릴 수 있는 한 장 (AI 키는 빼고 저장합니다)';

  @override
  String get exportFailed =>
      '내보내기에 실패했습니다';

  @override
  String get printAction =>
      '인쇄';

  @override
  String get exportPdf =>
      'PDF로 내보내기';

  @override
  String get pdfFailed =>
      'PDF를 만들지 못했습니다';

  @override
  String get exportEmpty =>
      '내보낼 메모가 없습니다';

  @override
  String get choosePreset => '정리 방식 고르기';

  @override
  String get importFiles =>
      '파일에서 가져오기';

  @override
  String get importFilesSub =>
      '마크다운·텍스트 파일을 메모로. 백업 파일도 여기서 되돌립니다';

  @override
  String get importAppend =>
      '파일 불러와 본문 이어 붙이기';

  @override
  String get importNone =>
      '가져온 파일이 없습니다';

  @override
  String importDone(int n) => '메모 $n개를 가져왔습니다';

  @override
  String get sourceGuessSuffix => '(추정)';

  @override
  String get splitEmpty => '왼쪽에서 메모를 고르세요';

  @override
  String get historyTitle =>
      '버전 기록';

  @override
  String get historySub =>
      '정리하거나 바꾸기 전의 글로 돌아갈 수 있습니다';

  @override
  String get historyEmpty =>
      '아직 되돌릴 판이 없습니다';

  @override
  String get historyRestore =>
      '되돌리기';

  @override
  String get historyOriginal =>
      '붙여넣은 원본';

  @override
  String get historyWhyTidy => '정리 직전';

  @override
  String get historyWhyAi => 'AI 편집 직전';

  @override
  String get historyWhyReplace => '바꾸기 직전';

  @override
  String get historyWhyRevert => '원본 복귀 직전';

  @override
  String get historyWhyRestore => '되살리기 직전';

  @override
  String get widgetEmpty => '메모가 없습니다';

  @override
  String get widgetAllLocked => '잠긴 메모는 위젯에 나오지 않습니다';

  @override
  String get attachTitle => '첨부';

  @override
  String get attachAdd => '파일 첨부';

  @override
  String get attachRemove => '첨부 지우기';

  @override
  String get attachRemoveBody => '이 기기에서 파일이 지워집니다. 되돌릴 수 없습니다.';

  @override
  String get attachFailed => '첨부하지 못했습니다';

  @override
  String get attachNotHere => '이 파일은 다른 기기에 있습니다';

  @override
  String attachAndMore(int n) => '외 ${n}개';

  @override
  String attachOther(String device, String what) => '첨부파일 : ${device} 노트에 ${what} 가 첨부되어 있음 (해당 기기에서만 확인)';

  @override
  String deviceName(String kind) {
    switch (kind) {
      case 'iphone':
        return '아이폰';
      case 'ipad':
        return '아이패드';
      case 'mac':
        return '맥';
      case 'android':
        return '안드로이드 폰';
      case 'windows':
        return '윈도우 PC';
      case 'web':
        return '웹';
      default:
        return '다른 기기';
    }
  }

  @override
  String historyUnknownTime(int n) => '이전 판 $n';

  @override
  String get selUnitSentence => '문장';

  @override
  String get selUnitLine => '줄';

  @override
  String get selUnitPara => '문단';

  @override
  String get selUnitAll => '전체';

  @override
  String get selStartLeft => '앞을 왼쪽으로';

  @override
  String get selStartRight => '앞을 오른쪽으로';

  @override
  String get selEndLeft => '뒤를 왼쪽으로';

  @override
  String get selEndRight => '뒤를 오른쪽으로';

  @override
  String get selClear => '선택 해제';

  @override
  String get paperTitle => '편집 화면 배경';

  @override
  String get paperSub => '배경과 줄을 한 벌로 고릅니다. 줄 간격은 글자 크기에 맞춰 자동으로 맞습니다.';

  @override
  String get paperNone => '기본';

  @override
  String get paperMoleskine => '몰스킨';

  @override
  String get paperSepia => '세피아';

  @override
  String get paperManuscript => '원고지';

  @override
  String get paperFrost => '서리';

  @override
  String get lockSectionTitle => '잠금';

  @override
  String get lockTitle => '앱 잠금';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? '지문·얼굴 인식이나 화면 잠금으로 앱을 엽니다.'
      : vendor == 'windows'
          ? 'Windows Hello나 기기 암호로 앱을 엽니다.'
          : 'Face ID·Touch ID나 기기 암호로 앱을 엽니다.';

  @override
  String get lockNote => '이 잠금은 남이 내 기기를 집었을 때 화면을 못 열게 하는 것입니다. 기기 안의 파일 자체를 암호로 잠그는 것은 아닙니다.';

  @override
  String get lockDelayTitle => '잠기는 시점';

  @override
  String get lockDelayNow => '바로';

  @override
  String get lockDelay1m => '1분 뒤';

  @override
  String get lockDelay5m => '5분 뒤';

  @override
  String get lockUnlock => '잠금 해제';

  @override
  String get lockLocked => '잠겨 있습니다';

  @override
  String lockUnavailable(String vendor) => vendor == 'android'
      ? '이 기기에서는 지문·얼굴 인식이나 화면 잠금을 쓸 수 없습니다.'
      : vendor == 'windows'
          ? '이 기기에서는 Windows Hello나 기기 암호를 쓸 수 없습니다.'
          : '이 기기에서는 Face ID·Touch ID나 기기 암호를 쓸 수 없습니다.';

  @override
  String get lockReasonOpen => '메모를 열려면 확인이 필요합니다';

  @override
  String get lockReasonOn => '잠금을 켜려면 확인이 필요합니다';

  @override
  String get lockReasonOff => '잠금을 끄려면 확인이 필요합니다';

  @override
  String get noteLock => '이 메모 잠그기';

  @override
  String get noteUnlock => '이 메모 잠금 풀기';

  @override
  String get noteLocked => '잠긴 메모';

  @override
  String get lockReasonNote => '잠긴 메모를 엽니다';

  @override
  String get noteLockDone => '이 메모를 잠갔습니다';

  @override
  String get noteUnlockDone => '이 메모의 잠금을 풀었습니다';

  @override
  String get syncDiagSignedOut => '이 기기가 iCloud에 로그인되어 있지 않습니다. 먼저 로그인해 주십시오.';

  @override
  String get syncDiagNoContainer => '로그인은 되어 있는데, 이 앱에 iCloud 자리가 아직 없습니다. 아래 절차대로 켜 주십시오.';

  @override
  String get syncDiagPreparing => '자리는 받았습니다. 준비가 끝나기를 기다리는 중입니다.';

  @override
  String get syncRecheckWhat => '기기에 iCloud 상태를 처음부터 다시 물어봅니다.';

  @override
  String get syncRecheckOk => 'iCloud가 켜졌습니다';

  @override
  String get syncRecheckStill => '아직 켜지지 않았습니다. 설정에서 켠 뒤 다시 눌러 주십시오. 방금 켰다면 1~2분 뒤에 한 번 더 눌러 보십시오.';

  @override
  String get syncOpenFailed => '설정 앱을 열지 못했습니다. 홈 화면에서 직접 열어 주십시오.';

  @override
  String get syncOpenManual => '설정 앱을 직접 열어 주십시오. 홈 화면 > 설정 > 맨 위 내 이름 > iCloud 입니다.';

  @override
  String get menuFile => '파일';

  @override
  String get menuClose => '닫기';

  @override
  String get menuPrefs => '설정…';

  @override
  String get appliedTitle => '깔끔하게 정리했습니다';

  @override
  String get tidyRulesTitle => '세부 정리 규칙';

  @override
  String get tidyRulesSub =>
      '‘정리’를 누르면 글이 어떻게 바뀔지 정합니다. 여기서 고른 것은 ‘기본 정리’에만 걸립니다 — 나머지 방식은 이름 그대로 합니다.';

  @override
  String get syncOnTitle => '켜짐';

  @override
  String get syncOffTitle => '꺼짐';

  @override
  String get syncSignedOutTitle => '로그인 필요';
  @override
  String get syncHelpTitleGdrive => '구글 드라이브 다시 연결하기';
  @override
  String get syncHelpStepsGdrive => '1. 아래 단추를 눌러 구글 계정을 고릅니다\n2. 드라이브 접근을 허용합니다\n3. 곧바로 맞추기가 시작됩니다';
  @override
  String get syncHelpNoteGdrive => '메모는 드라이브에 그대로 있습니다. 다시 로그인하면 돌아옵니다.';
  @override
  String get syncDiagSignedOutGdrive => '이 기기가 구글 계정에 로그인되어 있지 않습니다.';
  @override
  String get syncSignInGoogle => '구글 계정으로 로그인';
  @override
  String get syncAllowDrive => '드라이브 접근 허용';
  @override
  String get syncDiagPreparingGdrive => '로그인은 되었습니다. 드라이브에서 메모를 받아오는 중입니다.';
  @override
  String get syncRecheckStillGdrive => '아직 다 못 받았습니다. 메모가 많으면 첫 맞추기는 조금 걸립니다 \u2014 창을 닫고 계셔도 계속 받습니다.';

  @override
  String pastedFrom(String src, String date) =>
      '$src에서 $date에 가져옴';

  @override
  String pastedOn(String date) => '$date에 붙여넣음';

  @override
  String staleWarn(int days) =>
      '받은 지 $days일 된 답입니다. 그 사이 모델이 바뀌었을 수 있습니다.';
  @override
  String get settingsSecView => '보기';
  @override
  String get settingsSecTidy => '정리 규칙';
  @override
  String get settingsSecWhen => '정리할 때';
  @override
  String get settingsSecInfo => '정보';
  @override
  String get emphTitle => '굵은 강조 (**텍스트**)';
  @override
  String get emphSub => '40자 초과 문장 전체 강조는 항상 마커만 제거';
  @override
  String get emphQuoteSingle => "작은따옴표 '강조'";
  @override
  String get emphQuoteDouble => '큰따옴표 "강조"';
  @override
  String get removeLabel => '제거';
  @override
  String get keepLabel => '유지';
  @override
  String get hrTitle => '구분선 (---)';
  @override
  String get headingTitle => '제목 (#, ##)';

  @override
  String get quoteTitle => '인용문 (> 텍스트)';
  @override
  String get headingStrip => '텍스트만 남기기';
  @override
  String get headingKeep => '그대로 유지';
  @override
  String get headingPrefix => '■ 기호 붙이기';
  @override
  String get headingBracket => '[대괄호]';
  @override
  String get bulletTitle => '글머리 기호 (-, *)';
  @override
  String get bulletHyphen => '하이픈 -';
  @override
  String get bulletMiddot => '가운뎃점 ·';
  @override
  String get bulletDot => '불릿 •';
  @override
  String get bulletWhite => '흰 불릿 ◦';
  @override
  String get bulletKeep => '원래 기호 유지';
  @override
  String get bulletIndentTitle => '글머리 들여쓰기';
  @override
  String get indent2 => '2칸';
  @override
  String get indent4 => '4칸';
  @override
  String get indentNone => '없음';
  @override
  String get headingPadTitle => '소제목 여백';
  @override
  String get headingPadSub => '위 2줄·아래 1줄, 투명 문자(ㅤ)라 카톡·블로그에서도 유지';
  @override
  String get citationsTitle => '출처 링크 제거';
  @override
  String get citationsSub => '본문의 각주 번호와 맨 아래 \'출처\' 목록을 함께 지웁니다';
  @override
  String get monoEditorTitle => '표를 등폭 글꼴로';
  @override
  String get monoEditorSub => '표와 코드의 칸이 정확히 맞습니다. 줄글은 기기 기본 글꼴 그대로입니다';
  @override
  String get dashListTitle => '대시 나열 목록화';
  @override
  String get dashListSub => '"– a – b – c" 한 줄 나열을 줄 목록으로 분리';
  @override
  String get fillerHeadingTitle => '투명 문자 소제목 정리';
  @override
  String get fillerHeadingSub => 'ㅤ로 감싼 유사 소제목에 여백·제목 규칙 적용';
  @override
  String get aiSectionTitle => 'AI 편집 연결';
  @override
  String get aiSectionDesc =>
      'API 키를 넣으면 "더 간결하게 써줘" 같은 지시를 AI가 처리합니다. 정리는 기기 안 규칙이라 키가 필요 없고, AI 편집만 키를 씁니다.';
  @override
  String get aiKeyHint => 'API 키 (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get menuTidyPreview => '정리 미리보기';
  @override
  String get dividerTip => '구분선';
  @override
  String get syncScroll => '동시 스크롤';
  @override
  String get pasteTipTitle => '붙여넣을 때마다 묻지 않게';
  @override
  String get pasteTipSub => '아이폰이 붙여넣기마다 묻는 것을 한 번에 없앱니다';
  @override
  String get pasteTipBody =>
      '아이폰은 앱이 클립보드를 읽을 때마다 한 번씩 허락을 받습니다. 이 앱은 붙여넣기에서 시작하는 앱이라 그 물음이 유난히 자주 뜹니다.\n\n한 번만 바꾸면 다시 묻지 않습니다.\n\n1. 아래 \'설정 열기\'를 누릅니다\n2. \'다른 앱에서 붙여넣기\'를 누릅니다\n3. \'허용\'을 고릅니다\n\n허용해도 이 앱은 회원님이 붙여넣기 단추를 누른 그 순간에만 클립보드를 읽습니다. 몰래 들여다보지 않습니다.';
  @override
  String get pasteTipLater => '나중에';
  @override
  String get adClose => '광고 닫기';
  @override
  String get noteDuplicate => '복제';
  @override
  String get noteDuplicated => '복제했습니다';
  @override
  String get adSponsored => '후원';
  @override
  String get sponsorTitle => '광고 한 편이 다음 업데이트를 만듭니다';
  @override
  String get sponsorBody =>
      '더 나은 기능과 꾸준한 업데이트를 만드는 데 응원이 필요합니다. 광고 한 편을 끝까지 보시면 오늘 하루는 이 앱에 광고가 나오지 않습니다.';
  @override
  String get sponsorWatch => '광고 보고 후원하기';
  @override
  String get sponsorSkip => '건너뛰기';
  @override
  String get sponsorLoading => '광고 불러오는 중…';
  @override
  String get sponsorFailed => '광고를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
  @override
  String get moreTooltip => '더 보기';
  @override
  String get sponsorGoPremium => '프리미엄으로 광고 없이 쓰기';
  @override
  String get premiumTitle => '프리미엄';
  @override
  String get premiumPitch => '광고 없이, 모든 기기에서';
  @override
  String get premiumPitchSub => '평생 US\$29.99 또는 월 US\$1.99 · 아이폰과 아이패드, 맥까지 한 번에';
  @override
  String get premiumBody => '프리미엄은 광고를 모두 없애고, 아이폰·아이패드·맥 어디서나 제한 없이 쓰게 해 줍니다. 결제는 한 번이면 세 기기 모두에 적용됩니다. 여러분의 응원이 다음 업데이트를 만듭니다.';
  @override
  String get premiumLifetime => '평생 이용권 · US\$29.99';
  @override
  String get premiumMonthly => '월간 구독 · 월 US\$2.99';
  @override
  String get premiumComingSoon => '결제는 스토어 출시 버전에서 활성화됩니다. 조금만 기다려 주세요.';
  @override
  String get limitTitle => '오늘 무료 사용을 다 쓰셨습니다';
  @override
  String limitTidyBody(int n) => '무료로는 하루에 $n번까지 정리할 수 있습니다. 내일 다시 열리고, 프리미엄이면 제한 없이 쓰실 수 있습니다.';
  @override
  String limitWizardBody(int n) =>
      '무료로는 하루에 $n번까지 AI 편집을 쓸 수 있습니다. 내일 다시 열리고, 프리미엄이면 제한 없이 쓰실 수 있습니다.';
  @override
  String get limitSeePremium => '프리미엄 보기';
  @override
  String get premiumYearly => '연간 구독 · 연 US\$14.99';
  @override
  String get premiumLifetimeNote => '출시 기념가 · 정가 US\$39.99';

  @override
  String trialBadge(int days) => '무제한 체험 · $days일 남음';

  @override
  String get trialEndedTitle => '무제한 체험이 끝났습니다';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      '체험 동안 정리 $tidy번, AI 편집 $wiz번 쓰셨습니다. 이제부터 무료로는 하루 정리 $tidyLimit번, AI 편집 $wizLimit번입니다. 프리미엄이면 제한 없이 쓰실 수 있습니다.';
  @override
  String get themeTitle => '화면 모드';
  @override
  String get themeSystem => '기기 설정 따름';
  @override
  String get themeLight => '라이트';
  @override
  String get themeDark => '다크';
  @override
  String get aiKeyVerify => '키 확인';
  @override
  String get aiKeyChecking => '확인 중…';
  @override
  String get aiKeyUnknownFormat => '어느 회사의 키인지 알아내지 못했습니다. 네 회사 모두에 물어봤지만 받아 주지 않았습니다. 키를 다시 복사해 붙여 주세요.';
  @override
  String get aiAdvancedLabel => '고급 — 모델 직접 선택';
  @override
  String get aiManualModelHint => '모델 이름 직접 입력 (예: gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => '자동 선택: $provider · $model';
  @override
  String aiModelsFound(int n) => '사용 가능한 모델 $n개를 확인했습니다.';
  @override
  String aiListFailed(String error) => '모델 목록을 받지 못했습니다($error). 내장 예비 목록으로 동작합니다.';
  @override
  String aiModelSwitched(String model) => '쓰던 모델이 응답하지 않아 $model(으)로 바꿨습니다.';
  @override
  String get rulesSectionTitle => '자동 바꾸기 규칙';
  @override
  String get rulesSectionDesc => '위에서부터 순서대로 적용. 바꾸기에 \\n을 쓰면 줄바꿈. 코드블록 안은 건드리지 않습니다.';
  @override
  String get addRule => '규칙 추가';
  @override
  String get settingsFooter =>
      '설정은 저장 즉시 반영되며, 이후 "정리"를 실행할 때부터 적용됩니다. 이미 정리해 둔 메모는 소급해서 바뀌지 않습니다.';
}
