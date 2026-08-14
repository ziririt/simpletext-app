/// 본문에서 태그 후보를 골라내는 순수 함수.
///
/// 2026-08-14 소유자 요청: 편집기에 "태그 AI 자동입력" 버튼을 넣는다.
/// 소유자 확정 사항 — **버튼은 AI 키가 없어도 항상 동작해야 한다.**
/// 키가 있으면 AI가 뽑고, 키가 없거나 호출이 실패하면 이 함수가 대신 뽑는다.
/// 이 앱의 제1원칙이 Local First(AI는 옵션)이므로 이쪽이 원칙에 맞다.
/// 비행기·지하철처럼 네트워크가 없는 곳에서도 버튼이 죽지 않는다.
///
/// 이건 정리 엔진이 아니다. 앱 전용 보조 기능이라 웹(index.html)에 대칭
/// 구현이 없고, HANDOVER 5절의 "엔진은 JS·Dart 양쪽 동시" 규칙 대상이 아니다.
/// 나중에 웹에도 같은 버튼을 넣게 되면 그때 함께 옮기면 된다.
///
/// 방식은 일부러 단순하다(형태소 분석기 없음).
///   1) 제목 + 본문 앞부분만 본다 — 태그는 글 전체의 요약이 아니라 머리말이다
///   2) 조사·어미를 잘라 낸다 ("AI가" → "AI", "인간은" → "인간")
///   3) 흔한 말과 숫자로 시작하는 토큰은 버린다 ("있을까", "2036년", "45%")
///   4) 제목에 나온 말에 가중치를 세 배 준다
library;

/// 조사·어미. **긴 것부터** 잘라야 "에서는"이 "는"으로 잘못 먹히지 않는다.
const List<String> _suffixes = [
  '에서는', '으로는', '에게서', '이라는', '에서의', '으로써', '으로서',
  '이라고', '라면서', '까지도', '부터는',
  '으로', '에게', '에서', '부터', '까지', '처럼', '보다', '만큼', '조차',
  '이나', '거나', '와의', '과의', '들의', '들이', '들은', '들을', '이란', '라는',
  '의', '를', '을', '은', '는', '이', '가', '에', '로', '와', '과', '도', '만', '랑', '께',
];

/// 태그가 되면 곤란한 흔한 말.
const Set<String> _stop = {
  '그리고', '그러나', '하지만', '그래서', '따라서', '또한', '그런데', '즉',
  '있다', '없다', '한다', '된다', '이다', '아니다', '같다', '보다',
  '있는', '없는', '되는', '하는', '같은', '다른', '모든', '어떤', '무엇',
  '있을까', '없을까', '것이다', '때문', '경우', '정도', '부분', '방법', '상황',
  '대한', '통해', '위해', '대해', '관련', '중심', '기준', '이런', '그런', '저런',
  '여기', '거기', '저기', '이것', '그것', '저것', '우리', '당신', '자신',
  '지금', '오늘', '내일', '어제', '현재', '이후', '이전', '동안', '사이',
  '매우', '가장', '다시', '함께', '더욱', '조금', '아주', '너무', '정말',
  '하나', '둘째', '셋째', '첫째', '다음', '이번', '저번',
  'the', 'and', 'for', 'with', 'that', 'this', 'from', 'have', 'has', 'was',
  'are', 'you', 'your', 'not', 'but', 'can', 'will', 'they', 'their', 'its',
  'about', 'into', 'than', 'then', 'when', 'what', 'which', 'been', 'more',
};

String _strip(String w) {
  for (final s in _suffixes) {
    if (w.length > s.length + 1 && w.endsWith(s)) {
      return w.substring(0, w.length - s.length);
    }
  }
  return w;
}

final RegExp _splitter = RegExp(r'[^0-9A-Za-z가-힣]+');
final RegExp _startsDigit = RegExp(r'^[0-9]');

/// [title]과 [body](앞부분만 넘길 것)에서 태그 후보를 [max]개까지 고른다.
List<String> suggestTags(String title, String body, {int max = 5}) {
  final scores = <String, int>{};
  final display = <String, String>{};

  void feed(String text, int weight) {
    for (final raw in text.split(_splitter)) {
      if (raw.isEmpty) continue;
      if (_startsDigit.hasMatch(raw)) continue; // 45, 2036년, 20% 같은 것
      final w = _strip(raw);
      if (w.length < 2 || w.length > 20) continue;
      final key = w.toLowerCase();
      if (_stop.contains(key)) continue;
      scores[key] = (scores[key] ?? 0) + weight;
      // 표기는 처음 본 형태를 쓴다(AI, ChatGPT 같은 대문자 보존)
      display[key] ??= w;
    }
  }

  feed(title, 3);
  feed(body, 1);
  if (scores.isEmpty) return const [];

  final keys = scores.keys.toList()
    ..sort((a, b) {
      final d = scores[b]!.compareTo(scores[a]!);
      if (d != 0) return d;
      final e = b.length.compareTo(a.length);
      if (e != 0) return e;
      return a.compareTo(b);
    });
  return keys.take(max).map((k) => display[k]!).toList();
}
