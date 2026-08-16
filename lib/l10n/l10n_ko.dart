import 'l10n.dart';

/// 한국어 — 원문(소스 오브 트루스). 다른 언어는 이 파일 기준으로 번역한다.
class L10nKo extends L10n {
  const L10nKo();

  @override
  String get localeTag => 'ko';

  @override
  String get appTitle => '심플텍스트';

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
  String get notesLabel => '메모';
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
  String get seedTitle => '심플텍스트에 오신 것을 환영합니다';
  @override
  String get seedTag => '사용법';
  @override
  String get seedBody => [
        '심플텍스트 사용법',
        '',
        '1. ChatGPT나 클로드 답변을 복사한 뒤, "붙여넣고 정리"를 누르세요.',
        '2. 정리 미리보기에서 원본과 결과를 비교하고 "적용"을 누르면 끝.',
        '3. 표가 있는 메모는 "표" 버튼으로 스프레드시트용(TSV) 복사가 가능합니다.',
        '4. 모든 정리는 되돌리기 한 번으로 복구됩니다.',
        '',
        '아래는 일부러 깨뜨린 표입니다. "정리"를 눌러 복구를 확인해 보세요.',
        '',
        '| 종목 | 티커 | 수익률 | 비중',
        '|------|------|--------|',
        '| 애플 | AAPL | +14.2% | 12% |',
        '| 마이크로소프트 | MSFT | +21.5%',
        '| 엔비디아 | NVDA | +48.9% | 22% | 추가셀 |',
        '|테슬라|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => '완료';

  @override
  String get bodyFontSizeTitle => '본문 글자 크기';

  @override
  String get bodyFontSizeSample =>
      '머릿속의 수많은 생각을 Simplicity하게 깔끔히 정돈해 주는 Smart한 작업 공간을 만나보세요. 붙여넣고 정리 한 번이면 Clean하게 끝납니다.';

  @override
  String get wizardNothingToDo => '바꿀 것이 없습니다';

  @override
  String wizardAppliedToast(int count) => '지시 \$count개를 적용했습니다';

  @override
  String get skipPreviewCheck => '앞으로 미리보기 생략';

  @override
  String get previewTitle2 => '정리 전 미리보기';

  @override
  String get previewSub2 => '정리 결과를 먼저 보여 주고 적용할지 묻습니다';
  @override
  String get metaTooltip => '출처·태그';
  @override
  String get pinTooltip => '리스트 상단 고정';
  @override
  String get unpinTooltip => '상단 고정 해제';
  @override
  String get deleteTooltip => '삭제';
  @override
  String get titleHint => '제목(자동)';
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
  String get revertedToast => '이전 버전으로 되돌렸습니다';
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
  String unknownPrefix(String what) => '규칙으로 해석 불가 · $what';
  @override
  String get aiKeyPromo => '설정에 AI API 키를 넣으면 이런 자유 편집 명령도 처리됩니다.';
  @override
  String get aiRunUnknown => '해석 불가 명령을 AI로 실행';
  @override
  String get aiBusyLabel => 'AI 편집 중…';
  @override
  String get aiEmptyResponse => '빈 응답';
  @override
  String aiCallFailed(String error) => 'AI 호출 실패: $error';
  @override
  String get aiApplyResult => 'AI 결과 적용';
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
  String get apply => '적용';

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
      '카톡·문자처럼 서식이 안 되는 곳에 보낼 때';
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
  String get settingsTitle => '설정';

  @override
  String get menuAppSettings => '앱 설정';

  @override
  String get menuAiKey => 'AI API 키';

  @override
  String get syncTitle => '아이클라우드';

  @override
  String get syncStateOn => '켜짐 — 아이폰·아이패드·맥에서 같은 메모를 봅니다';

  @override
  String get syncStateOff => '꺼짐 — 기기 설정에서 아이클라우드 드라이브를 켜 주세요';

  @override
  String get syncStateSyncing => '맞추는 중…';

  @override
  String get aiKeyNotSynced => '메모는 아이클라우드로 모든 기기에 동기화됩니다. 하지만 API 키는 동기화되지 않습니다 — 기기마다 직접 넣어 주세요.';

  @override
  String get syncStateSignedOut => '아이클라우드에 로그인되어 있지 않습니다 — 눌러서 방법 보기';

  @override
  String get syncHelpTitle => '아이클라우드 켜는 법';

  @override
  String get syncHelpSteps =>
      '1. 설정 앱을 엽니다\n2. 맨 위의 내 이름을 누릅니다\n3. iCloud를 누릅니다\n4. 저장된 앱 목록에서 모두 보기를 누릅니다\n5. 목록에서 Skyblue Note를 켭니다\n6. 이 앱으로 돌아와 아래 다시 확인을 누릅니다';

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
      '파일 이어 붙이기';

  @override
  String get importNone =>
      '가져온 파일이 없습니다';

  @override
  String importDone(int n) => '메모 \$n개를 가져왔습니다';

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
  String historyUnknownTime(int n) => '이전 판 \$n';

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
  String pastedFrom(String src, String date) =>
      '\$src에서 \$date에 가져옴';

  @override
  String pastedOn(String date) => '\$date에 붙여넣음';

  @override
  String staleWarn(int days) =>
      '받은 지 \$days일 된 답입니다. 그 사이 모델이 바뀌었을 수 있습니다.';
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
  String get adClose => '광고 닫기';
  @override
  String get sponsorTitle => '광고 한 편이 다음 업데이트를 만듭니다';
  @override
  String get sponsorBody => '더 나은 기능과 꾸준한 업데이트를 만드는 데 응원이 필요합니다. 전면 광고를 하루 한 편 보시면 오늘 하루는 위쪽 배너 없이, 프리미엄을 이용하시면 광고 없이 영원히 쓰실 수 있습니다.';
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
  String limitTidyBody(int n) => '무료로는 하루에 \$n번까지 정리할 수 있습니다. 내일 다시 열리고, 프리미엄이면 제한 없이 쓰실 수 있습니다.';
  @override
  String limitWizardBody(int n) =>
      '무료로는 하루에 \$n번까지 AI 편집을 쓸 수 있습니다. 내일 다시 열리고, 프리미엄이면 제한 없이 쓰실 수 있습니다.';
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
      '체험 동안 정리 \$tidy번, AI 편집 \$wiz번 쓰셨습니다. 이제부터 무료로는 하루 정리 \$tidyLimit번, AI 편집 \$wizLimit번입니다. 프리미엄이면 제한 없이 쓰실 수 있습니다.';
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
  String get aiKeyUnknownFormat => '키 형식을 인식하지 못했습니다. 고급에서 모델을 직접 지정해 주세요.';
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
