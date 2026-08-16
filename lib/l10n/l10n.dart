/// 심플텍스트 다국어(i18n) 기반.
///
/// 설계 메모 (2026-08-12, 클라우드 세션):
/// - gen-l10n(ARB 코드 생성) 대신 손으로 쓴 클래스 계층을 쓴다.
///   이유: (1) 추상 멤버 강제 덕에 "번역 키 누락"이 컴파일 오류로 잡힌다.
///   (2) 코드 생성 단계가 없어 어떤 환경(클라우드 컨테이너 포함)에서도 소스만으로 완결된다.
///   (3) 노하우 문서 6절의 "빈 값 검사"를 test/l10n/l10n_test.dart가 all 맵으로 전수 검사한다.
/// - 언어 구성(사용자 확정, 2026-08-12): 한/영/일/중간체/중번체/스/포/독/프 — 9개.
///   중국어만 간체·번체로 분리하고 es·pt는 단일 파일로 간다(필요해지면 나중에 분리).
/// - 엔진(tidy_engine.dart)·마법사(wizard.dart)가 만들어내는 리포트 문구는
///   여기서 번역하지 않는다. 엔진은 웹(JS)과 로직 대칭이 제1규칙이라
///   문구 구조 변경은 양쪽 동시 작업이 필요하다. → 로드맵 후속 항목.
/// - 프리셋 이름/설명은 엔진의 Preset.id를 UI 층에서 presetName()/presetDesc()로
///   매핑해 표시한다. 엔진 파일은 건드리지 않는다.
library;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'l10n_de.dart';
import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_fr.dart';
import 'l10n_ja.dart';
import 'l10n_ko.dart';
import 'l10n_pt.dart';
import 'l10n_zh_hans.dart';
import 'l10n_zh_hant.dart';

abstract class L10n {
  const L10n();

  /// 이 번역의 로케일 태그 (검사 도구·디버그용)
  String get localeTag;

  // ---------------- 앱 ----------------
  String get appTitle;

  /// 설정 화면 맨 아래 버전 표시 앞에 붙는 낱말.
  /// 업데이트가 실제로 반영됐는지 이 줄 하나로 확인한다(소유자 요청).
  String get versionLabel;

  // ---------------- 홈 화면 ----------------
  String get homeTitle; // 상단 큰 제목 '메모'
  String get settingsTooltip;
  String get searchHint;
  String get emptyList;
  String get pinnedLabel;
  String get notesLabel;
  String get newNoteTooltip;
  String get pasteAndTidy;
  String get clipboardEmpty;
  String get yesterday;
  String get untitled;
  String get deleteConfirmTitle;
  String get cancel;
  String get delete;

  /// 목록 날짜 (오늘은 시간, 어제는 [yesterday], 그 외 이 포맷)
  String dateShort(int y, int m, int d);

  // ---------------- 시드 메모 ----------------
  String get seedTitle;
  String get seedTag;
  String get seedBody;

  // ---------------- 에디터 ----------------
  String get done;

  /// 상단 툴바의 한 번 누르면 'AI 답변 정리'가 도는 버튼

  /// 설정의 본문 글자 크기
  String get bodyFontSizeTitle;

  /// 크기를 눈으로 맞출 때 쓰는 견본 문장
  String get bodyFontSizeSample;

  /// 마법사에 지시가 비었거나 바꿀 게 없을 때
  String get wizardNothingToDo;

  /// 미리보기 화면의 '앞으로 미리보기 생략' 체크
  String get skipPreviewCheck;

  /// 설정의 미리보기 항목
  String get previewTitle2;
  String get previewSub2;
  String get metaTooltip;
  String get pinTooltip;
  String get unpinTooltip;
  String get deleteTooltip;
  String get titleHint;
  String get sourceNone;
  String get sourceOther;
  String get tagsHint;
  String get tagAiButton;
  String get tagAiWorking;
  String get tagAiNone;
  String get tagAiLocalNote;
  String get tagsBoxHint;
  String get tagRemoveTip;
  String get bodyHint;
  String get noteNotFound;
  String get revertedToast;
  String appliedDone(String summary);

  /// 마법사 지시를 전부 알아들었을 때 띄우는 알림
  String wizardAppliedToast(int count);

  // 키보드 액세서리 바
  String get undoTip;
  String get redoTip;
  String get moveLeftTip;
  String get moveRightTip;
  String get lineStartTip;
  String get lineEndTip;
  String get indentTip;
  String get hideKeyboardTip;

  // 하단 바
  String get tidyAction;
  String get wizardAction;
  String get tableAction;
  String get replaceAction;
  String get copyAction;
  String get undoAction;

  // ---------------- 표 시트 ----------------
  String get noTablesFound;
  String tableInfo(int n, int cols, int rows);
  String get forSpreadsheet;
  String get copiedSpreadsheet;
  String get copiedCsv;
  String get copiedMarkdown;

  // ---------------- 마법사 ----------------
  String get wizardTitle;
  String get wizardHint;
  String get favSaveButton;
  String get favListTitle;
  String get favUse;
  String get favEmpty;
  String get favRemove;
  String get favSavedToast;
  String appliedPrefix(String what);
  String unknownPrefix(String what);
  String get aiKeyPromo;
  String get aiRunUnknown;
  String get aiBusyLabel;
  String get aiEmptyResponse;
  String aiCallFailed(String error);
  String get aiApplyResult;
  String get aiAppliedToast;
  String get close;
  String get interpretApply;

  // ---------------- 바꾸기 ----------------
  String get replaceTitle;
  String get findLabel;
  String get replaceWithLabel;
  String get regexLabel;
  String get saveAsRule;
  String get saveAsRuleSub;
  String get invalidRegex;
  String get noMatches;
  String replacedCount(int count);
  String get savedRuleSuffix;
  String get replaceAllAction;

  // ---------------- 복사 메뉴 ----------------
  String get copyAll;
  String get copiedAll;
  String get tidyCopy;
  String get tidyCopySub;
  String tidyCopied(String summary);
  String get copyTableSpreadsheet;
  String get copiedTableSpreadsheet;

  // ---------------- 미리보기 ----------------
  String previewTitle(String preset);
  String warningPrefix(String warning);
  String get tidyResultLabel;
  String get originalLabel;
  String get apply;

  // ---------------- 프리셋 (엔진 Preset.id → 표시 문자열) ----------------
  String get presetAiName;
  String get presetAiDesc;
  String get presetStripName;
  String get presetStripDesc;
  String get presetMinimalName;
  String get presetMinimalDesc;
  String get presetTablesName;
  String get presetTablesDesc;
  String get presetBlogName;
  String get presetBlogDesc;

  String presetName(String id, String fallback) {
    switch (id) {
      case 'ai':
        return presetAiName;
      case 'strip':
        return presetStripName;
      case 'minimal':
        return presetMinimalName;
      case 'tables':
        return presetTablesName;
      case 'blog':
        return presetBlogName;
    }
    return fallback;
  }

  String presetDesc(String id, String fallback) {
    switch (id) {
      case 'ai':
        return presetAiDesc;
      case 'strip':
        return presetStripDesc;
      case 'minimal':
        return presetMinimalDesc;
      case 'tables':
        return presetTablesDesc;
      case 'blog':
        return presetBlogDesc;
    }
    return fallback;
  }

  // ---------------- 설정 화면 ----------------
  String get settingsTitle;
  String get menuAppSettings;
  String get menuAiKey;
  String get syncTitle;
  String get syncStateOn;
  String get syncStateOff;
  String get syncStateSyncing;
  String get aiKeyNotSynced;
  String get syncStateSignedOut;
  String get syncHelpTitle;
  String get syncHelpSteps;
  String get syncOpenSettings;
  String get syncRecheck;
  String get syncHelpNote;
  String get sortFilterTooltip;
  String get sortFilterTitle;
  String get sortLabel;
  String get sortUpdated;
  String get sortCreated;
  String get sortByTitle;
  String get filterSourceLabel;
  String get filterTagLabel;
  String get filterAll;
  String get filterReset;
  String get trashTitle;
  String get trashSubtitle;
  String get trashEmpty;
  String get trashRestore;
  String get trashDeleteNow;
  String get trashEmptyAll;
  String get trashEmptyConfirm;
  String get trashRestored;
  String trashDaysLeftLabel(int days);
  String get exportSectionTitle;
  String get exportSubtitle;
  String get exportNote;
  String get exportAllMd;
  String get exportAllMdSub;
  String get exportBackup;
  String get exportBackupSub;
  String get exportFailed;
  String get exportEmpty;
  String get choosePreset;
  String get importFiles;
  String get importFilesSub;
  String get importAppend;
  String get importNone;
  String importDone(int n);
  String get sourceGuessSuffix;
  String get splitEmpty;
  String get historyTitle;
  String get historySub;
  String get historyEmpty;
  String get historyRestore;
  String get historyOriginal;
  String historyUnknownTime(int n);
  String get selUnitSentence;
  String get selUnitLine;
  String get selUnitPara;
  String get selUnitAll;
  String get selStartLeft;
  String get selStartRight;
  String get selEndLeft;
  String get selEndRight;
  String get selClear;
  String get paperTitle;
  String get paperSub;
  String get paperNone;
  String get paperMoleskine;
  String get paperSepia;
  String get paperManuscript;
  String get paperGrid;
  String get lockSectionTitle;
  String get lockTitle;
  String get lockSub;
  String get lockNote;
  String get lockDelayTitle;
  String get lockDelayNow;
  String get lockDelay1m;
  String get lockDelay5m;
  String get lockUnlock;
  String get lockLocked;
  String get lockUnavailable;
  String get lockReasonOpen;
  String get lockReasonOn;
  String get lockReasonOff;
  String get syncDiagSignedOut;
  String get syncDiagNoContainer;
  String get syncDiagPreparing;
  String get syncRecheckWhat;
  String get syncRecheckOk;
  String get syncRecheckStill;
  String get syncOpenFailed;
  String get menuFile;
  String get menuClose;
  String pastedFrom(String src, String date);
  String pastedOn(String date);
  String staleWarn(int days);
  String get settingsSecView;
  String get settingsSecTidy;
  String get settingsSecWhen;
  String get settingsSecInfo;
  String get emphTitle;
  String get emphSub;
  String get emphQuoteSingle;
  String get emphQuoteDouble;
  String get removeLabel;
  String get keepLabel;
  String get hrTitle;
  String get headingTitle;
  String get headingStrip;
  String get headingKeep;
  String get headingPrefix;
  String get headingBracket;
  String get bulletTitle;
  String get bulletHyphen;
  String get bulletMiddot;
  String get bulletDot;
  String get bulletWhite;
  String get bulletKeep;
  String get bulletIndentTitle;
  String get indent2;
  String get indent4;
  String get indentNone;
  String get headingPadTitle;
  String get headingPadSub;
  String get citationsTitle;
  String get citationsSub;
  String get monoEditorTitle;
  String get monoEditorSub;
  String get dashListTitle;
  String get dashListSub;
  String get fillerHeadingTitle;
  String get fillerHeadingSub;
  String get aiSectionTitle;
  String get aiSectionDesc;
  String get aiKeyHint;
  String get adClose;
  String get sponsorTitle;
  String get sponsorBody;
  String get sponsorWatch;
  String get sponsorSkip;
  String get sponsorLoading;
  String get sponsorFailed;
  String get moreTooltip;
  String get sponsorGoPremium;
  String get premiumTitle;
  String get premiumPitch;
  String get premiumPitchSub;
  String get premiumBody;
  String get premiumLifetime;
  String get premiumMonthly;
  String get premiumComingSoon;
  String get limitTitle;
  String limitTidyBody(int n);
  String limitWizardBody(int n);
  String get limitSeePremium;
  String get premiumYearly;
  String get premiumLifetimeNote;
  String trialBadge(int days);
  String get trialEndedTitle;
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit);
  String get themeTitle;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get aiKeyVerify;
  String get aiKeyChecking;
  String get aiKeyUnknownFormat;
  String get aiAdvancedLabel;
  String get aiManualModelHint;
  String aiAutoLabel(String provider, String model);
  String aiModelsFound(int n);
  String aiListFailed(String error);
  String aiModelSwitched(String model);
  String get rulesSectionTitle;
  String get rulesSectionDesc;
  String get addRule;
  String get settingsFooter;

  // ---------------- 전수 검사용 맵 ----------------
  /// 모든 매개변수 없는 키를 열거한다. test/l10n/l10n_test.dart가
  /// (1) 값 비어있지 않음 (2) 언어별 키 개수 동일을 검사한다.
  /// 새 getter를 추가하면 반드시 여기에도 추가할 것 — 개수 검사가 지켜준다
  /// (추상 getter는 컴파일러가, 이 맵 누락은 테스트의 개수 비교가 잡는다).
  Map<String, String> get all => {
        'appTitle': appTitle,
        'homeTitle': homeTitle,
        'settingsTooltip': settingsTooltip,
        'searchHint': searchHint,
        'emptyList': emptyList,
        'pinnedLabel': pinnedLabel,
        'notesLabel': notesLabel,
        'newNoteTooltip': newNoteTooltip,
        'pasteAndTidy': pasteAndTidy,
        'clipboardEmpty': clipboardEmpty,
        'yesterday': yesterday,
        'untitled': untitled,
        'deleteConfirmTitle': deleteConfirmTitle,
        'cancel': cancel,
        'delete': delete,
        'seedTitle': seedTitle,
        'seedTag': seedTag,
        'seedBody': seedBody,
        'done': done,
        'bodyFontSizeTitle': bodyFontSizeTitle,
        'bodyFontSizeSample': bodyFontSizeSample,
        'wizardNothingToDo': wizardNothingToDo,
        'skipPreviewCheck': skipPreviewCheck,
        'previewTitle2': previewTitle2,
        'previewSub2': previewSub2,
        'metaTooltip': metaTooltip,
        'pinTooltip': pinTooltip,
        'unpinTooltip': unpinTooltip,
        'deleteTooltip': deleteTooltip,
        'titleHint': titleHint,
        'sourceNone': sourceNone,
        'sourceOther': sourceOther,
        'tagsHint': tagsHint,
        'tagAiButton': tagAiButton,
        'tagAiWorking': tagAiWorking,
        'tagAiNone': tagAiNone,
        'tagAiLocalNote': tagAiLocalNote,
        'tagsBoxHint': tagsBoxHint,
        'tagRemoveTip': tagRemoveTip,
        'bodyHint': bodyHint,
        'noteNotFound': noteNotFound,
        'revertedToast': revertedToast,
        'undoTip': undoTip,
        'redoTip': redoTip,
        'moveLeftTip': moveLeftTip,
        'moveRightTip': moveRightTip,
        'lineStartTip': lineStartTip,
        'lineEndTip': lineEndTip,
        'indentTip': indentTip,
        'hideKeyboardTip': hideKeyboardTip,
        'tidyAction': tidyAction,
        'wizardAction': wizardAction,
        'tableAction': tableAction,
        'replaceAction': replaceAction,
        'copyAction': copyAction,
        'undoAction': undoAction,
        'noTablesFound': noTablesFound,
        'forSpreadsheet': forSpreadsheet,
        'copiedSpreadsheet': copiedSpreadsheet,
        'copiedCsv': copiedCsv,
        'copiedMarkdown': copiedMarkdown,
        'wizardTitle': wizardTitle,
        'wizardHint': wizardHint,
        'favSaveButton': favSaveButton,
        'favListTitle': favListTitle,
        'favUse': favUse,
        'favEmpty': favEmpty,
        'favRemove': favRemove,
        'favSavedToast': favSavedToast,
        'aiKeyPromo': aiKeyPromo,
        'aiRunUnknown': aiRunUnknown,
        'aiBusyLabel': aiBusyLabel,
        'aiEmptyResponse': aiEmptyResponse,
        'aiApplyResult': aiApplyResult,
        'aiAppliedToast': aiAppliedToast,
        'close': close,
        'interpretApply': interpretApply,
        'replaceTitle': replaceTitle,
        'findLabel': findLabel,
        'replaceWithLabel': replaceWithLabel,
        'regexLabel': regexLabel,
        'saveAsRule': saveAsRule,
        'saveAsRuleSub': saveAsRuleSub,
        'invalidRegex': invalidRegex,
        'noMatches': noMatches,
        'savedRuleSuffix': savedRuleSuffix,
        'replaceAllAction': replaceAllAction,
        'copyAll': copyAll,
        'copiedAll': copiedAll,
        'tidyCopy': tidyCopy,
        'tidyCopySub': tidyCopySub,
        'copyTableSpreadsheet': copyTableSpreadsheet,
        'copiedTableSpreadsheet': copiedTableSpreadsheet,
        'tidyResultLabel': tidyResultLabel,
        'originalLabel': originalLabel,
        'apply': apply,
        'presetAiName': presetAiName,
        'presetAiDesc': presetAiDesc,
        'presetStripName': presetStripName,
        'presetStripDesc': presetStripDesc,
        'presetMinimalName': presetMinimalName,
        'presetMinimalDesc': presetMinimalDesc,
        'presetTablesName': presetTablesName,
        'presetTablesDesc': presetTablesDesc,
        'presetBlogName': presetBlogName,
        'presetBlogDesc': presetBlogDesc,
        'settingsTitle': settingsTitle,
        'menuAppSettings': menuAppSettings,
        'menuAiKey': menuAiKey,
        'syncTitle': syncTitle,
        'syncStateOn': syncStateOn,
        'syncStateOff': syncStateOff,
        'syncStateSyncing': syncStateSyncing,
        'aiKeyNotSynced': aiKeyNotSynced,
        'syncStateSignedOut': syncStateSignedOut,
        'syncHelpTitle': syncHelpTitle,
        'syncHelpSteps': syncHelpSteps,
        'syncOpenSettings': syncOpenSettings,
        'syncRecheck': syncRecheck,
        'syncHelpNote': syncHelpNote,
        'sortFilterTooltip': sortFilterTooltip,
        'sortFilterTitle': sortFilterTitle,
        'sortLabel': sortLabel,
        'sortUpdated': sortUpdated,
        'sortCreated': sortCreated,
        'sortByTitle': sortByTitle,
        'filterSourceLabel': filterSourceLabel,
        'filterTagLabel': filterTagLabel,
        'filterAll': filterAll,
        'filterReset': filterReset,
        'trashTitle': trashTitle,
        'trashSubtitle': trashSubtitle,
        'trashEmpty': trashEmpty,
        'trashRestore': trashRestore,
        'trashDeleteNow': trashDeleteNow,
        'trashEmptyAll': trashEmptyAll,
        'trashEmptyConfirm': trashEmptyConfirm,
        'trashRestored': trashRestored,
        'exportSectionTitle': exportSectionTitle,
        'exportSubtitle': exportSubtitle,
        'exportNote': exportNote,
        'exportAllMd': exportAllMd,
        'exportAllMdSub': exportAllMdSub,
        'exportBackup': exportBackup,
        'exportBackupSub': exportBackupSub,
        'exportFailed': exportFailed,
        'exportEmpty': exportEmpty,
        'choosePreset': choosePreset,
        'importFiles': importFiles,
        'importFilesSub': importFilesSub,
        'importAppend': importAppend,
        'sourceGuessSuffix': sourceGuessSuffix,
        'splitEmpty': splitEmpty,
        'historyTitle': historyTitle,
        'historySub': historySub,
        'historyEmpty': historyEmpty,
        'historyRestore': historyRestore,
        'historyOriginal': historyOriginal,
        'selUnitSentence': selUnitSentence,
        'selUnitLine': selUnitLine,
        'selUnitPara': selUnitPara,
        'selUnitAll': selUnitAll,
        'selStartLeft': selStartLeft,
        'selStartRight': selStartRight,
        'selEndLeft': selEndLeft,
        'selEndRight': selEndRight,
        'selClear': selClear,
        'paperTitle': paperTitle,
        'paperSub': paperSub,
        'paperNone': paperNone,
        'paperMoleskine': paperMoleskine,
        'paperSepia': paperSepia,
        'paperManuscript': paperManuscript,
        'paperGrid': paperGrid,
        'lockSectionTitle': lockSectionTitle,
        'lockTitle': lockTitle,
        'lockSub': lockSub,
        'lockNote': lockNote,
        'lockDelayTitle': lockDelayTitle,
        'lockDelayNow': lockDelayNow,
        'lockDelay1m': lockDelay1m,
        'lockDelay5m': lockDelay5m,
        'lockUnlock': lockUnlock,
        'lockLocked': lockLocked,
        'lockUnavailable': lockUnavailable,
        'lockReasonOpen': lockReasonOpen,
        'lockReasonOn': lockReasonOn,
        'lockReasonOff': lockReasonOff,
        'syncDiagSignedOut': syncDiagSignedOut,
        'syncDiagNoContainer': syncDiagNoContainer,
        'syncDiagPreparing': syncDiagPreparing,
        'syncRecheckWhat': syncRecheckWhat,
        'syncRecheckOk': syncRecheckOk,
        'syncRecheckStill': syncRecheckStill,
        'syncOpenFailed': syncOpenFailed,
        'menuFile': menuFile,
        'menuClose': menuClose,
        'importNone': importNone,
        'settingsSecView': settingsSecView,
        'settingsSecTidy': settingsSecTidy,
        'settingsSecWhen': settingsSecWhen,
        'settingsSecInfo': settingsSecInfo,
        'emphTitle': emphTitle,
        'emphSub': emphSub,
        'emphQuoteSingle': emphQuoteSingle,
        'emphQuoteDouble': emphQuoteDouble,
        'removeLabel': removeLabel,
        'keepLabel': keepLabel,
        'hrTitle': hrTitle,
        'headingTitle': headingTitle,
        'headingStrip': headingStrip,
        'headingKeep': headingKeep,
        'headingPrefix': headingPrefix,
        'headingBracket': headingBracket,
        'bulletTitle': bulletTitle,
        'bulletHyphen': bulletHyphen,
        'bulletMiddot': bulletMiddot,
        'bulletDot': bulletDot,
        'bulletWhite': bulletWhite,
        'bulletKeep': bulletKeep,
        'bulletIndentTitle': bulletIndentTitle,
        'indent2': indent2,
        'indent4': indent4,
        'indentNone': indentNone,
        'headingPadTitle': headingPadTitle,
        'headingPadSub': headingPadSub,
        'citationsTitle': citationsTitle,
        'citationsSub': citationsSub,
        'monoEditorTitle': monoEditorTitle,
        'monoEditorSub': monoEditorSub,
        'dashListTitle': dashListTitle,
        'dashListSub': dashListSub,
        'fillerHeadingTitle': fillerHeadingTitle,
        'fillerHeadingSub': fillerHeadingSub,
        'aiSectionTitle': aiSectionTitle,
        'aiSectionDesc': aiSectionDesc,
        'aiKeyHint': aiKeyHint,
        'adClose': adClose,
        'sponsorTitle': sponsorTitle,
        'sponsorBody': sponsorBody,
        'sponsorWatch': sponsorWatch,
        'sponsorSkip': sponsorSkip,
        'sponsorLoading': sponsorLoading,
        'sponsorFailed': sponsorFailed,
        'moreTooltip': moreTooltip,
        'sponsorGoPremium': sponsorGoPremium,
        'premiumTitle': premiumTitle,
        'premiumPitch': premiumPitch,
        'premiumPitchSub': premiumPitchSub,
        'premiumBody': premiumBody,
        'premiumLifetime': premiumLifetime,
        'premiumMonthly': premiumMonthly,
        'premiumComingSoon': premiumComingSoon,
        'limitTitle': limitTitle,
        'limitSeePremium': limitSeePremium,
        'premiumYearly': premiumYearly,
        'premiumLifetimeNote': premiumLifetimeNote,
        'trialEndedTitle': trialEndedTitle,
        'themeTitle': themeTitle,
        'themeSystem': themeSystem,
        'themeLight': themeLight,
        'themeDark': themeDark,
        'aiKeyVerify': aiKeyVerify,
        'aiKeyChecking': aiKeyChecking,
        'aiKeyUnknownFormat': aiKeyUnknownFormat,
        'aiAdvancedLabel': aiAdvancedLabel,
        'aiManualModelHint': aiManualModelHint,
        'rulesSectionTitle': rulesSectionTitle,
        'rulesSectionDesc': rulesSectionDesc,
        'addRule': addRule,
        'settingsFooter': settingsFooter,
        'versionLabel': versionLabel,
      };

  // ---------------- 로케일 해석 ----------------

  static const supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('es'),
    Locale('pt'),
    Locale('de'),
    Locale('fr'),
  ];

  /// 로케일 → 번역. 중국어는 스크립트(Hans/Hant) 우선, 없으면
  /// 지역(TW/HK/MO → 번체)으로 판단. 그 외 미지원 언어는 영어.
  static L10n forLocale(Locale? locale) {
    if (locale == null) return const L10nEn();
    switch (locale.languageCode) {
      case 'ko':
        return const L10nKo();
      case 'en':
        return const L10nEn();
      case 'ja':
        return const L10nJa();
      case 'zh':
        if (locale.scriptCode == 'Hant') return const L10nZhHant();
        if (locale.scriptCode == 'Hans') return const L10nZhHans();
        const hantRegions = {'TW', 'HK', 'MO'};
        if (hantRegions.contains(locale.countryCode)) return const L10nZhHant();
        return const L10nZhHans();
      case 'es':
        return const L10nEs();
      case 'pt':
        return const L10nPt();
      case 'de':
        return const L10nDe();
      case 'fr':
        return const L10nFr();
    }
    return const L10nEn();
  }

  /// 위젯 트리 밖(예: Store의 시드 메모 생성)에서 시스템 로케일로 해석
  static L10n system() => forLocale(PlatformDispatcher.instance.locale);

  static L10n of(BuildContext context) =>
      Localizations.of<L10n>(context, L10n) ?? system();

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// 전체 번역 인스턴스 (검사·테스트용)
  static const List<L10n> allTranslations = [
    L10nKo(),
    L10nEn(),
    L10nJa(),
    L10nZhHans(),
    L10nZhHant(),
    L10nEs(),
    L10nPt(),
    L10nDe(),
    L10nFr(),
  ];
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  bool isSupported(Locale locale) => true; // forLocale이 항상 폴백을 준다

  @override
  Future<L10n> load(Locale locale) => SynchronousFuture(L10n.forLocale(locale));

  @override
  bool shouldReload(_L10nDelegate old) => false;
}
