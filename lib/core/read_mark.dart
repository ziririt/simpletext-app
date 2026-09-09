/// 스크롤 책갈피 — 긴 글에서 '읽던 자리'를 되찾는 셈.
///
/// 2026-09-09 소유자 요청 — "분량이 긴 문서를 읽을 때 불안한 마음이 있다.
/// 다음에 이어 읽고 싶은데, 이 긴 분량을 어떻게 찾지? 페이지 단위가 아니라
/// 스크롤이니까."
///
/// 종이책은 손가락을 끼우면 그만이다. 스크롤에는 끼울 자리가 없다 — 그것이
/// 불안의 정체다. 쪽 번호가 없으니 '아까 그 자리'를 말할 방법조차 없다.
///
/// 그래서 자리를 숫자 둘로 적는다. **끼울 때의 스크롤 값(pixels)** 과
/// **그때의 글 길이(extent)** 다. 하나만으로는 모자란다.
///   - 픽셀만 적으면: 글자 크기를 키우거나 글을 고치면 엉뚱한 데로 간다.
///   - 비율만 적으면: 글이 그대로여도 반올림 때문에 몇 줄씩 어긋난다.
/// 둘을 같이 적어 두면, 글이 그대로일 때는 픽셀로 정확히 돌아가고 글이
/// 바뀌었을 때만 비율로 옮겨 간다. 아래 [offsetIn] 이 그 판단을 한다.
///
/// **책갈피는 기기마다 따로다.** 메모 안에 넣지 않는다. 넣으면 읽기만 해도
/// 메모가 바뀐 것이 되어 목록 맨 위로 올라오고 동기화가 돈다 — 읽는 일이
/// 쓰는 일로 둔갑한다. 그래서 앱 설정(AppSettings.readMarks)에 둔다.
library;

class ReadMark {
  const ReadMark({
    required this.pixels,
    required this.extent,
    required this.at,
  });

  /// 끼울 때의 스크롤 값.
  final double pixels;

  /// 그때의 최대 스크롤 값. 글이 얼마나 길었는지가 여기 담긴다.
  final double extent;

  /// 끼운 시각(밀리초).
  final int at;

  /// 글 전체에서 몇 쯤인가. 0.0 ~ 1.0.
  double get fraction {
    if (extent <= 0) return 0;
    final f = pixels / extent;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }

  /// 사람에게 보여 줄 값. 62 처럼.
  ///
  /// 맨 끝인데 99%로 보이면 '아직 남았나' 싶고, 맨 앞인데 1%면 '뭔가
  /// 지나쳤나' 싶다. 양 끝만 반올림 대신 딱 떨어지게 둔다.
  int get percent {
    final f = fraction;
    if (f >= 0.999) return 100;
    if (f <= 0.001) return 0;
    final p = (f * 100).round();
    if (p <= 0) return 1;
    if (p >= 100) return 99;
    return p;
  }

  Map<String, dynamic> toJson() => {'p': pixels, 'x': extent, 't': at};

  /// 저장본에서 되살린다. 모양이 아니면 조용히 null — 설정 하나 때문에
  /// 앱이 안 뜨는 일은 없어야 한다.
  static ReadMark? fromJson(Object? j) {
    if (j is! Map) return null;
    final p = j['p'];
    final x = j['x'];
    if (p is! num || x is! num) return null;
    if (p < 0 || x <= 0) return null;
    final t = j['t'];
    return ReadMark(
      pixels: p.toDouble(),
      extent: x.toDouble(),
      at: t is num ? t.toInt() : 0,
    );
  }

  /// 지금 이 글에서 책갈피가 가리키는 자리.
  ///
  /// [maxNow] 는 지금의 최대 스크롤 값이다.
  double offsetIn(double maxNow) {
    if (maxNow <= 0) return 0;
    // 글이 그때와 같으면 픽셀 그대로가 가장 정확하다. 1pt 안쪽 차이는
    // 같은 글로 본다 — 화면 회전이나 반올림으로 그 정도는 늘 흔들린다.
    if ((maxNow - extent).abs() < 1.0) {
      return pixels < 0 ? 0 : (pixels > maxNow ? maxNow : pixels);
    }
    // 글이 바뀌었으면 비율로 옮긴다. 정확하지는 않지만 근처에는 닿는다.
    final v = fraction * maxNow;
    return v < 0 ? 0 : (v > maxNow ? maxNow : v);
  }

  /// 지금 자리가 책갈피와 사실상 같은가. 같으면 '이어 읽기'를 권할 이유가
  /// 없다 — 이미 거기 있다.
  bool isAt(double offsetNow, double maxNow) =>
      (offsetIn(maxNow) - offsetNow).abs() < 24;
}
