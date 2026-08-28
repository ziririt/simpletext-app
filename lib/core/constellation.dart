/// AI 성좌 — 노트들을 별로 놓고, 닮은 것끼리 실로 잇는다.
///
/// 2026-08-29 소유자 확정. 이 파일은 **셈만** 한다. 그리는 일은 화면이
/// 맡는다(constellation_screen.dart).
///
/// ## 왜 태그로 안 잇나 — 실측이 정했다
///
/// 소유자 노트 110편을 그대로 계산해 봤다.
///
///   태그가 달린 노트          63편
///   서로 다른 태그            232개 (대부분 한 번씩만 쓰였다)
///   태그로 이어지는 쌍        5,995쌍 중 **75쌍**
///   실 하나라도 붙는 노트     110편 중 **40편**
///
/// 일흔 편이 허공에 뜬 점이 된다. 옵시디언의 그물망은 사람이 손으로 걸어
/// 둔 링크를 그리는 것이라 촘촘하지만, 이 앱에는 그 링크가 없다. 태그를
/// 링크 대신 쓰면 별자리가 아니라 **먼지**가 된다.
///
/// ## 그래서 낱말 겹침으로 잇는다
///
/// 제목과 본문 앞부분에서 낱말을 뽑아, 흔한 말은 죽이고 그 글에만 나오는
/// 말에 무게를 준다(TF-IDF). 같은 실측에서:
///
///   문턱 0.30   줄 53개, 붙은 노트 69편
///   문턱 0.25   줄 79개, 붙은 노트 77편
///   문턱 0.20   줄 126개, 붙은 노트 86편
///
/// 0.25 언저리면 110편 중 77편이 그물에 들어온다. **이 셈은 회사를 안
/// 부른다.** 기기 안에서 돌고, 돈이 안 들고, 비행기 안에서도 된다.
///
/// ## 한국어를 형태소로 안 쪼갠다
///
/// 형태소 분석기를 넣으면 앱이 무거워지고, 웹 판에서는 더 그렇다. 두 글자
/// 이상 한글 덩어리로 자르는 조잡한 방법을 쓴다. 조사가 붙은 '반도체가'와
/// '반도체는'이 다른 낱말로 세어지는 손해가 있지만, 실측에서 반도체 글끼리
/// 금리 글끼리 제대로 붙었다. **조잡해도 통하면 통하는 것이다.**
library;

import 'dart:math' as math;

/// 낱말로 안 세는 말들. 어느 글에나 나와서 아무것도 구별해 주지 않는다.
///
/// 짧게 유지한다. 목록으로 막는 것보다 '너무 흔한 말은 자동으로 죽인다'는
/// 규칙(문서빈도 상한)이 더 정직하고 언어를 안 가린다.
const Set<String> kStopWords = {
  '그리고', '그러나', '하지만', '있다', '없다', '위해', '통해', '대한',
  '이런', '저런', '것은', '것이', '수도', '있는', '있습니다', '합니다',
  '대비', '이후', '지난', '오늘', '관련', '경우', '때문', '가장', '다시',
  'the', 'and', 'for', 'that', 'this', 'with', 'from', 'are', 'was',
};

final RegExp _word = RegExp(r'[가-힣]{2,}|[A-Za-z]{3,}');

/// 글 한 편에서 낱말을 뽑아 센다.
///
/// [head] 만큼만 본다. 4만 자짜리 글이 하나 있는데 그걸 통째로 읽으면
/// 그 글 하나가 모두와 닮아 보인다 — 길수록 겹칠 말이 많아서다.
Map<String, int> countWords(String text, {int head = 4000}) {
  final t = text.length > head ? text.substring(0, head) : text;
  final out = <String, int>{};
  for (final m in _word.allMatches(t)) {
    final w = m.group(0)!.toLowerCase();
    if (kStopWords.contains(w)) continue;
    out[w] = (out[w] ?? 0) + 1;
  }
  return out;
}

/// 각 낱말이 몇 편에 나오는가.
Map<String, int> docFreq(List<Map<String, int>> docs) {
  final df = <String, int>{};
  for (final d in docs) {
    for (final w in d.keys) {
      df[w] = (df[w] ?? 0) + 1;
    }
  }
  return df;
}

/// 한 편을 길이 1짜리 화살표로. 흔한 말과 한 편에만 나오는 말은 뺀다.
///
/// 한 편에만 나오는 말을 빼는 까닭: 그 말은 어차피 아무와도 안 겹치므로
/// 셈에 보태는 것이 없고, 화살표만 길게 만들어 다른 말의 무게를 깎는다.
Map<String, double> vectorOf(
  Map<String, int> doc,
  Map<String, int> df,
  int total, {
  double tooCommon = 0.4,
}) {
  final v = <String, double>{};
  for (final e in doc.entries) {
    final n = df[e.key] ?? 0;
    if (n < 2) continue;
    // '너무 흔한 말'은 글이 어느 정도 쌓여야 뜻이 있는 판정이다.
    //
    // 글이 셋인데 둘에 나온다고 흔한 말로 치면(2 > 3×0.4) 남는 낱말이
    // 하나도 없어 모든 글이 서로 딴판이 된다. 시험을 짜다가 걸렸다 —
    // 노트가 몇 편뿐인 새 사용자의 화면이 정확히 그 판이다.
    if (total >= 8 && n > total * tooCommon) continue;
    v[e.key] = (1 + math.log(e.value)) * math.log(total / n);
  }
  var norm = 0.0;
  for (final x in v.values) {
    norm += x * x;
  }
  norm = math.sqrt(norm);
  if (norm == 0) return const {};
  return {for (final e in v.entries) e.key: e.value / norm};
}

/// 두 화살표가 얼마나 같은 쪽을 보는가. 0(딴판)~1(똑같음).
double cosine(Map<String, double> a, Map<String, double> b) {
  // 짧은 쪽을 훑는다. 긴 쪽을 훑으면 헛걸음이 는다.
  if (a.length > b.length) {
    final t = a;
    a = b;
    b = t;
  }
  var s = 0.0;
  for (final e in a.entries) {
    final y = b[e.key];
    if (y != null) s += e.value * y;
  }
  return s;
}

/// 별 둘을 잇는 실 하나.
class Link {
  const Link(this.a, this.b, this.w);
  final int a;
  final int b;

  /// 굵기의 근거. 0~1 남짓.
  final double w;

  @override
  String toString() => 'Link($a-$b, ${w.toStringAsFixed(2)})';
}

/// 이을 만한 것만 골라 잇는다.
///
/// [topPer] 는 한 별이 가질 수 있는 실의 최대 수다. 이걸 안 두면 긴 글
/// 하나가 모두와 이어져 그물이 아니라 **바퀴살**이 된다.
///
/// [sameTag] 는 태그가 같은 쌍에 얹는 덤이다. 태그 혼자로는 부족하지만
/// (위 실측) 보강으로는 정직하다.
List<Link> buildLinks(
  List<Map<String, double>> vecs, {
  required double threshold,
  int topPer = 4,
  List<Set<String>>? tags,
  double sameTag = 0.10,
}) {
  final n = vecs.length;
  final best = List.generate(n, (_) => <Link>[]);
  final all = <String, Link>{};
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      var s = cosine(vecs[i], vecs[j]);
      if (tags != null && i < tags.length && j < tags.length) {
        if (tags[i].intersection(tags[j]).isNotEmpty) s += sameTag;
      }
      if (s < threshold) continue;
      final l = Link(i, j, s > 1 ? 1 : s);
      best[i].add(l);
      best[j].add(l);
    }
  }
  for (var i = 0; i < n; i++) {
    final mine = best[i]..sort((x, y) => y.w.compareTo(x.w));
    for (final l in mine.take(topPer)) {
      all['${l.a}-${l.b}'] = l;
    }
  }
  final out = all.values.toList()..sort((x, y) => y.w.compareTo(x.w));
  return out;
}

/// 문턱을 스스로 고른다 — 별 하나당 실이 [want] 개쯤 되도록.
///
/// 고정값을 박지 않는 까닭: 노트 열 편인 사람과 천 편인 사람의 닮음
/// 분포가 다르다. 열 편짜리에 0.25를 박으면 아무것도 안 이어지고,
/// 천 편짜리에 박으면 화면이 실로 뒤덮인다.
double pickThreshold(List<Map<String, double>> vecs, {double want = 1.6}) {
  final n = vecs.length;
  if (n < 2) return 1;
  final sims = <double>[];
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final s = cosine(vecs[i], vecs[j]);
      if (s > 0.05) sims.add(s);
    }
  }
  if (sims.isEmpty) return 1;
  sims.sort((a, b) => b.compareTo(a));
  final k = (n * want / 2).round().clamp(1, sims.length);
  final t = sims[k - 1];
  // 너무 낮게는 안 내려간다. 0.12 아래는 낱말 두어 개가 우연히 겹친
  // 것이고, 그런 실을 그리면 그물이 거짓말을 한다.
  return t < 0.12 ? 0.12 : t;
}

/// 별 하나의 자리.
class Pt {
  Pt(this.x, this.y);
  double x;
  double y;

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// 서로 밀고 당겨 자리를 잡는다.
///
/// 이어진 것끼리는 당기고(용수철), 모든 별은 서로 민다(전하). 흔한
/// force-directed 셈이다. **씨앗을 받는다** — 같은 노트 묶음은 언제
/// 열어도 같은 그림이어야 한다. 열 때마다 모양이 바뀌면 사람은 그것을
/// 자기 글의 지도로 안 여긴다.
List<Pt> layout(
  int n,
  List<Link> links, {
  double width = 1000,
  double height = 1000,
  int rounds = 300,
  int seed = 7,
}) {
  if (n <= 0) return [];
  final rnd = math.Random(seed);
  final pts = List.generate(
      n, (_) => Pt(rnd.nextDouble() * width, rnd.nextDouble() * height));
  if (n == 1) {
    pts[0] = Pt(width / 2, height / 2);
    return pts;
  }
  final area = width * height;
  final k = math.sqrt(area / n); // 별 사이의 바라는 거리
  var temp = width / 8; // 처음엔 크게 움직이고 점점 잦아든다
  final dx = List.filled(n, 0.0);
  final dy = List.filled(n, 0.0);

  for (var r = 0; r < rounds; r++) {
    for (var i = 0; i < n; i++) {
      dx[i] = 0;
      dy[i] = 0;
    }
    // 밀기
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        var ex = pts[i].x - pts[j].x;
        var ey = pts[i].y - pts[j].y;
        var d = math.sqrt(ex * ex + ey * ey);
        if (d < 0.01) {
          // 완전히 겹치면 밀 방향이 없다. 아주 조금 흔들어 준다.
          ex = (rnd.nextDouble() - 0.5) * 0.1;
          ey = (rnd.nextDouble() - 0.5) * 0.1;
          d = 0.01;
        }
        final f = k * k / d;
        dx[i] += ex / d * f;
        dy[i] += ey / d * f;
        dx[j] -= ex / d * f;
        dy[j] -= ey / d * f;
      }
    }
    // 당기기
    for (final l in links) {
      final ex = pts[l.a].x - pts[l.b].x;
      final ey = pts[l.a].y - pts[l.b].y;
      final d = math.sqrt(ex * ex + ey * ey);
      if (d < 0.01) continue;
      // 굵은 실일수록 세게 당긴다. 닮은 것끼리 더 붙어 무리를 이룬다.
      final f = d * d / k * (0.5 + l.w);
      dx[l.a] -= ex / d * f;
      dy[l.a] -= ey / d * f;
      dx[l.b] += ex / d * f;
      dy[l.b] += ey / d * f;
    }
    for (var i = 0; i < n; i++) {
      final d = math.sqrt(dx[i] * dx[i] + dy[i] * dy[i]);
      if (d < 0.0001) continue;
      final step = d < temp ? d : temp;
      pts[i].x += dx[i] / d * step;
      pts[i].y += dy[i] / d * step;
      pts[i].x = pts[i].x.clamp(0.0, width);
      pts[i].y = pts[i].y.clamp(0.0, height);
    }
    temp *= 0.97;
  }
  return pts;
}

/// 그림이 화면을 꽉 채우도록 자리를 0~1 로 되편다.
///
/// 힘으로 잡은 자리는 한쪽에 몰리기 쉽다. 그대로 그리면 화면 반이 빈다.
List<Pt> normalize(List<Pt> pts) {
  if (pts.isEmpty) return pts;
  var lox = pts.first.x, hix = pts.first.x;
  var loy = pts.first.y, hiy = pts.first.y;
  for (final p in pts) {
    if (p.x < lox) lox = p.x;
    if (p.x > hix) hix = p.x;
    if (p.y < loy) loy = p.y;
    if (p.y > hiy) hiy = p.y;
  }
  final w = hix - lox, h = hiy - loy;
  return [
    for (final p in pts)
      Pt(w < 0.001 ? 0.5 : (p.x - lox) / w, h < 0.001 ? 0.5 : (p.y - loy) / h)
  ];
}

/// 쌍둥이 노트 — 거의 같은 글. 성좌를 만들면 공짜로 딸려 오는 덤이다.
List<Link> twins(List<Map<String, double>> vecs, {double at = 0.92}) {
  final out = <Link>[];
  for (var i = 0; i < vecs.length; i++) {
    for (var j = i + 1; j < vecs.length; j++) {
      final s = cosine(vecs[i], vecs[j]);
      if (s >= at) out.add(Link(i, j, s));
    }
  }
  out.sort((a, b) => b.w.compareTo(a.w));
  return out;
}
