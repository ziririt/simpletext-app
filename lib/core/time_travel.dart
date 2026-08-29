/// 시간 여행 — 이 글이 지나온 정거장들.
///
/// 2026-08-27 소유자 확정, 후보 5. 전·후 와이프와 결이 같아서 둘을 붙여
/// 놓으면 "이 앱은 글의 과거를 안다"는 하나의 인상이 된다.
///
/// ## 새로 저장할 것이 없다
///
/// 정거장은 이미 노트 안에 있다 — history(이전 판들), historyAt(그때
/// 시각), historyWhy(왜 남았나). 여태 그것을 **목록**으로만 보여 줬다.
/// 목록은 정확하지만 아무 감흥이 없다. 같은 자료를 손잡이 하나로 훑게
/// 하면, 글이 눈앞에서 자라나는 것이 보인다.
///
/// ## 곁줄은 끝에서부터 맞춘다
///
/// history 는 서른을 넘으면 앞을 버리는데 historyAt·historyWhy 는 나중에
/// 생긴 줄이라 더 짧을 수 있다. 앞에서부터 세면 오늘 남긴 시각이 몇 달
/// 전 판에 붙는다. 그 셈은 core/history_align.dart 가 이미 갖고 있으므로
/// 여기서 다시 만들지 않는다 — **한 결정을 두 곳에 쓰면 반드시 한 곳을
/// 빠뜨린다.**
library;

import 'history_align.dart';

/// 여행길의 정거장 하나.
class Stop {
  const Stop({
    required this.text,
    required this.at,
    required this.why,
    required this.now,
  });

  /// 그때의 글.
  final String text;

  /// 그때의 시각(밀리초). 모르면 0 — 곁줄이 없던 옛 저장본이다.
  final int at;

  /// 왜 남았는가의 부호('tidy', 'ai', 'replace', 'revert', 'restore').
  /// 지금 판이면 빈 글자다.
  final String why;

  /// 지금 이 글인가. 길의 마지막 정거장이다.
  final bool now;

  @override
  String toString() => 'Stop(${now ? "now" : why}, ${text.length}자)';
}

/// 오래된 것부터 지금까지. **마지막이 늘 지금**이다.
///
/// 기록이 하나도 없으면 정거장은 하나다. 그때는 화면이 손잡이를 감추면
/// 된다 — 밀 데가 없는 손잡이는 고장으로 읽힌다.
/// [original] 은 붙여넣은 그대로의 글(originalBody)이다.
///
/// 2026-08-29 소유자 지시 — "원본 복귀는 버전 기록별로 복귀할 수 있으니
/// 따로 메뉴에서는 빼도 될 듯." 맞는 말이다. 원본은 이 길의 **첫
/// 정거장**일 뿐이고, 길이 있는데 지름길을 따로 두면 두 곳을 다 지켜야
/// 한다. 기록에 이미 같은 글이 있으면 안 겹쳐 넣는다.
List<Stop> travelStops({
  required List<String> history,
  required List<int> historyAt,
  required List<String> historyWhy,
  required String body,
  required int updatedAt,
  String original = '',
  int originalAt = 0,
}) {
  final out = <Stop>[];
  final org = original.trim();
  if (org.isNotEmpty &&
      org != body.trim() &&
      !history.any((h) => h.trim() == org)) {
    out.add(Stop(text: original, at: originalAt, why: 'original', now: false));
  }
  for (var i = 0; i < history.length; i++) {
    out.add(Stop(
      text: history[i],
      at: sideValue(historyAt, history.length, i) ?? 0,
      why: sideValue(historyWhy, history.length, i) ?? '',
      now: false,
    ));
  }
  out.add(Stop(text: body, at: updatedAt, why: '', now: true));
  return out;
}

/// 손잡이 값(0~1)을 정거장 번호로. 정거장이 하나뿐이면 늘 0이다.
int stopAt(double frac, int count) {
  if (count <= 1) return 0;
  final f = frac < 0 ? 0.0 : (frac > 1 ? 1.0 : frac);
  final i = (f * (count - 1)).round();
  return i < 0 ? 0 : (i >= count ? count - 1 : i);
}

/// 정거장 번호를 손잡이 값으로. 되돌리면 제자리여야 한다.
double fracOf(int i, int count) {
  if (count <= 1) return 1;
  final k = i < 0 ? 0 : (i >= count ? count - 1 : i);
  return k / (count - 1);
}

/// 이 판과 다음 판 사이에 글자가 몇이나 늘거나 줄었는가.
///
/// 부호를 살린다. '줄었다'와 '늘었다'는 다른 사건이고, 이 앱에서는
/// 대개 줄어드는 쪽이 좋은 일이다.
int growth(List<Stop> stops, int i) {
  if (i <= 0 || i >= stops.length) return 0;
  return stops[i].text.length - stops[i - 1].text.length;
}
