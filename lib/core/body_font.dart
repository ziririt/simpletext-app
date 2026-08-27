/// 본문 글꼴 고르개.
///
/// 2026-08-27 밤 소유자 지시 — "글꼴과 글꼴 크기도 됩니다. 다만 글 전체에
/// 적용되는 설정으로요. 편집기 글꼴을 고르고 크기를 키우는 것, 이건
/// 정당하고 사람들이 많이 씁니다."
///
/// ## 왜 셋뿐인가
///
/// **우리가 앱에 싣고 다니는 글꼴만 내놓는다.** 기기의 글꼴 목록을 훑어
/// 늘어놓는 길도 있지만, 그러면 맥에서 고른 글꼴이 아이폰에는 없고,
/// 웹에서는 아예 하나도 없다. 설정은 기기를 넘나드는 값인데 고른 것이
/// 저쪽에서 안 보이면 그건 고장으로 읽힌다.
///
///   기본    기기의 시스템 글꼴. 애플에서는 SF/애플 SD 고딕 네오,
///           안드로이드에서는 로보토/노토, 웹에서는 프리텐다드다.
///   노토    노토 산스 KR. 이미 PDF용으로 싣고 다니던 것이라 무게가
///           하나도 안 는다. 시스템 글꼴과 눈에 띄게 다른 고딕이다.
///   고정폭  D2Coding. 표 정렬용으로 이미 싣고 있다. 한글이 영문의 정확히
///           두 배라 글자가 격자에 맞는다 — 코드와 표를 많이 다루는
///           사람에게는 이것이 본문 글꼴이다.
///
/// 명조(바탕)를 안 넣었다. 우리가 싣고 있는 명조가 없고, 기기 이름에
/// 기대면 애플에서만 되고 안드로이드·웹에서는 아무 일도 안 일어난다.
/// 아무 일도 안 일어나는 설정 항목은 없는 것만 못하다.
library;

const String kBodyFontSystem = 'system';
const String kBodyFontNoto = 'noto';
const String kBodyFontMono = 'mono';

const List<String> kBodyFonts = [
  kBodyFontSystem,
  kBodyFontNoto,
  kBodyFontMono,
];

/// 고른 이름을 실제 글꼴 이름으로. null 이면 지금까지 하던 그대로
/// (테마가 정한 글꼴)이다.
///
/// [webDefault] 는 웹에서 쓰는 기본 글꼴 이름(Pretendard)이다. 웹에서는
/// 기기 글꼴을 못 빌려 오므로 '기본'이 그 이름을 가리켜야 한다.
String? bodyFontFamily(String name, {String? webDefault}) => switch (name) {
      kBodyFontNoto => 'NotoSansKR',
      kBodyFontMono => 'D2Coding',
      _ => webDefault,
    };

/// 모르는 값이 들어오면 기본으로 되돌린다. 옛 저장본이나 남의 기기가
/// 보낸 값이 화면을 빈 글꼴로 만들면 안 된다.
String safeBodyFont(String? name) =>
    kBodyFonts.contains(name) ? name! : kBodyFontSystem;
