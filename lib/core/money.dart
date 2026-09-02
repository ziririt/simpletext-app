/// 값 표기 — 순수 함수. 스토어 SDK도 화면 코드도 넣지 않는다(시험으로 고정).
///
/// 여기 있는 것은 하나뿐이다: **연간 값을 '월 얼마'로 바꿔 적는 일.**
/// 2026-09-02 소유자가 보내 온 MindNode 결제 화면에서 가져온 것으로,
/// 연간 카드에 '₩44,000/년' 아래 '₩3,667/월'을 함께 적는다. 사람은 연
/// 사만사천 원과 월 사천사백 원을 머릿속에서 못 견준다 — 같은 단위로
/// 놓아 주어야 비로소 견줄 수 있다.
///
/// 돈이 걸린 자리라 화면에서 빼내 시험으로 묶는다. 나라마다 다른 것이
/// 셋이고, 셋 다 틀리기 쉽다.
///   1) 소수 자리 — 원·엔은 없고 달러·유로는 두 자리다
///   2) 기호 위치 — `$1.99` 는 앞, `1,99 €` 는 뒤다
///   3) 천 단위 구분 — 없으면 44000 이 4만인지 44만인지 눈으로 안 갈린다
///
/// 판정 근거는 **스토어가 준 값 글자**다. 우리가 나라 목록을 들고 있으면
/// 반드시 언젠가 빠진 나라가 생긴다.
library;

/// 천 단위 쉼표. 소수부는 건드리지 않는다.
String groupThousands(String n) {
  final at = n.indexOf(RegExp(r'[.,]'));
  final head = at < 0 ? n : n.substring(0, at);
  final tail = at < 0 ? '' : n.substring(at);
  final neg = head.startsWith('-');
  final digits = neg ? head.substring(1) : head;
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
    b.write(digits[i]);
  }
  return '${neg ? '-' : ''}$b$tail';
}

/// 이 값 글자를 쓰는 나라가 소수 두 자리를 쓰는가.
bool usesDecimals(String shownPrice) =>
    RegExp(r'[.,]\d{2}(?!\d)').hasMatch(shownPrice);

/// 이 값 글자에서 통화 기호가 숫자 **앞**에 오는가.
bool symbolLeads(String shownPrice) =>
    !RegExp(r'^\s*\d').hasMatch(shownPrice);

/// 연간 값을 열둘로 나눈 '월 얼마'. 셈이 안 되면 null.
///
/// [yearlyRaw] 스토어가 준 숫자 값(ProductDetails.rawPrice)
/// [shownPrice] 스토어가 준 값 글자 — 생김새만 빌린다
/// [currencySymbol] 스토어가 준 통화 기호
String? perMonthLabel({
  required double yearlyRaw,
  required String shownPrice,
  required String currencySymbol,
}) {
  if (yearlyRaw <= 0) return null;
  final v = yearlyRaw / 12;
  final body = usesDecimals(shownPrice)
      ? v.toStringAsFixed(2)
      : v.round().toString();
  final grouped = groupThousands(body);
  return symbolLeads(shownPrice)
      ? '$currencySymbol$grouped'
      : '$grouped $currencySymbol';
}
