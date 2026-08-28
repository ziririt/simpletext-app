/// 성좌 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/constellation.dart';

void main() {
  group('낱말 뽑기', () {
    test('두 글자 이상 한글, 세 글자 이상 영문만 센다', () {
      final w = countWords('반도체 가 AI 엔비디아 the chip');
      expect(w.containsKey('반도체'), true);
      expect(w.containsKey('가'), false, reason: '한 글자는 안 센다');
      expect(w.containsKey('엔비디아'), true);
      expect(w.containsKey('chip'), true);
      expect(w.containsKey('ai'), false, reason: '두 글자 영문은 안 센다');
    });

    test('흔한 말은 안 센다', () {
      expect(countWords('그리고 하지만 반도체').keys.toList(), ['반도체']);
    });

    test('영문은 대소문자를 안 가린다', () {
      final w = countWords('Nvidia nvidia NVIDIA');
      expect(w['nvidia'], 3);
    });

    test('앞부분만 본다 — 긴 글 하나가 모두와 닮아 보이면 안 된다', () {
      final long = '${'가나 ' * 10}반도체';
      expect(countWords(long, head: 10).containsKey('반도체'), false);
    });
  });

  group('닮음 재기', () {
    List<Map<String, double>> vecsOf(List<String> texts) {
      final docs = texts.map((t) => countWords(t)).toList();
      final df = docFreq(docs);
      return [for (final d in docs) vectorOf(d, df, docs.length)];
    }

    test('같은 글은 1에 가깝다', () {
      final v = vecsOf(['반도체 엔비디아 실적', '반도체 엔비디아 실적', '금리 국채 물가']);
      expect(cosine(v[0], v[1]) > 0.99, true);
    });

    test('딴 이야기는 0이다', () {
      final v = vecsOf(['반도체 엔비디아 실적', '반도체 엔비디아 실적', '금리 국채 물가']);
      expect(cosine(v[0], v[2]), 0);
    });

    test('한 편에만 나오는 말은 빼고 센다 — 아무와도 안 겹치는 말이다', () {
      final docs = [countWords('반도체 오직여기만'), countWords('반도체 저기만')];
      final df = docFreq(docs);
      final v = vectorOf(docs[0], df, 2);
      expect(v.containsKey('오직여기만'), false);
    });

    test('모든 글에 나오는 말도 뺀다 — 구별해 주는 것이 없다', () {
      final docs = [
        countWords('시장 반도체'),
        countWords('시장 금리'),
        countWords('시장 환율'),
      ];
      final df = docFreq(docs);
      // '시장'이 셋 다에 나온다(문서빈도 100% > 40%)
      expect(vectorOf(docs[0], df, 3).containsKey('시장'), false);
    });

    test('셀 것이 없으면 빈 화살표다 — 죽지 않는다', () {
      expect(vectorOf(countWords('가'), {}, 1), isEmpty);
      expect(cosine(const {}, const {}), 0);
    });
  });

  group('실 잇기', () {
    List<Map<String, double>> v4() {
      final docs = [
        countWords('반도체 엔비디아 실적 매출'),
        countWords('반도체 엔비디아 실적 성장'),
        countWords('금리 국채 물가 상승'),
        countWords('금리 국채 물가 하락'),
      ];
      final df = docFreq(docs);
      return [for (final d in docs) vectorOf(d, df, docs.length)];
    }

    test('닮은 것끼리 이어지고 딴 이야기와는 안 이어진다', () {
      final ls = buildLinks(v4(), threshold: 0.2);
      final pairs = ls.map((l) => '${l.a}${l.b}').toSet();
      expect(pairs.contains('01'), true);
      expect(pairs.contains('23'), true);
      expect(pairs.contains('02'), false);
    });

    test('문턱을 올리면 실이 준다', () {
      expect(buildLinks(v4(), threshold: 0.99).length <=
          buildLinks(v4(), threshold: 0.2).length, true);
    });

    test('한 별의 실 수를 죈다 — 안 죄면 바퀴살이 된다', () {
      final ls = buildLinks(v4(), threshold: 0.0, topPer: 1);
      final deg = <int, int>{};
      for (final l in ls) {
        deg[l.a] = (deg[l.a] ?? 0) + 1;
        deg[l.b] = (deg[l.b] ?? 0) + 1;
      }
      // 한 별이 고른 것은 하나뿐이지만 남이 고른 실이 더 붙을 수는 있다.
      expect(ls.length <= 4, true);
    });

    test('같은 실이 두 번 안 들어간다', () {
      final ls = buildLinks(v4(), threshold: 0.0);
      final seen = ls.map((l) => '${l.a}-${l.b}').toSet();
      expect(seen.length, ls.length);
    });

    test('태그가 같으면 덤이 붙는다', () {
      final v = v4();
      final tags = [
        {'반도체'},
        <String>{},
        {'반도체'},
        <String>{},
      ];
      final plain = buildLinks(v, threshold: 0.0);
      final withTag = buildLinks(v, threshold: 0.0, tags: tags, sameTag: 0.5);
      double wOf(List<Link> ls, int a, int b) =>
          ls.firstWhere((l) => l.a == a && l.b == b, orElse: () => const Link(0, 0, 0)).w;
      expect(wOf(withTag, 0, 2) > wOf(plain, 0, 2), true);
    });

    test('굵기는 1을 안 넘는다', () {
      final v = v4();
      final tags = [{'ㄱ'}, {'ㄱ'}, {'ㄱ'}, {'ㄱ'}];
      for (final l in buildLinks(v, threshold: 0.0, tags: tags, sameTag: 0.9)) {
        expect(l.w <= 1, true);
      }
    });
  });

  group('문턱 고르기', () {
    test('글이 하나면 이을 것이 없다', () {
      expect(pickThreshold([const {}]), 1);
    });

    test('아무것도 안 닮았으면 아무것도 안 잇는다', () {
      final docs = [countWords('반도체 반도체'), countWords('금리 금리')];
      final df = docFreq(docs);
      final v = [for (final d in docs) vectorOf(d, df, 2)];
      expect(pickThreshold(v), 1);
    });

    test('0.12 아래로는 안 내려간다 — 우연히 겹친 낱말로 실을 그리면 거짓말이다', () {
      final docs = List.generate(
          20, (i) => countWords('공통낱말 ${'낱말$i ' * 40}'));
      final df = docFreq(docs);
      final v = [for (final d in docs) vectorOf(d, df, docs.length)];
      expect(pickThreshold(v) >= 0.12, true);
    });
  });

  group('자리 잡기', () {
    test('씨앗이 같으면 그림도 같다 — 열 때마다 바뀌면 지도가 아니다', () {
      final ls = [const Link(0, 1, 0.5), const Link(1, 2, 0.5)];
      final a = layout(3, ls, rounds: 40, seed: 3);
      final b = layout(3, ls, rounds: 40, seed: 3);
      for (var i = 0; i < 3; i++) {
        expect((a[i].x - b[i].x).abs() < 0.0001, true);
        expect((a[i].y - b[i].y).abs() < 0.0001, true);
      }
    });

    test('별 하나는 한가운데', () {
      final p = layout(1, const [], width: 100, height: 200);
      expect(p.single.x, 50);
      expect(p.single.y, 100);
    });

    test('없으면 없는 대로', () {
      expect(layout(0, const []), isEmpty);
    });

    test('화면 밖으로 안 나간다', () {
      for (final p in layout(12, const [], width: 100, height: 100, rounds: 30)) {
        expect(p.x >= 0 && p.x <= 100, true);
        expect(p.y >= 0 && p.y <= 100, true);
      }
    });

    test('이어진 것이 안 이어진 것보다 가깝다', () {
      final ls = [const Link(0, 1, 1.0)];
      final p = layout(3, ls, rounds: 300, seed: 5);
      double d(int a, int b) {
        final dx = p[a].x - p[b].x, dy = p[a].y - p[b].y;
        return dx * dx + dy * dy;
      }
      expect(d(0, 1) < d(0, 2), true);
    });
  });

  group('되펴기', () {
    test('0~1 로 편다', () {
      final p = normalize([Pt(10, 20), Pt(30, 60), Pt(20, 40)]);
      expect(p[0].x, 0);
      expect(p[1].x, 1);
      expect(p[2].x, 0.5);
    });

    test('한 줄로 늘어서도 안 죽는다', () {
      final p = normalize([Pt(5, 1), Pt(5, 9)]);
      expect(p[0].x, 0.5);
      expect(p[1].x, 0.5);
    });

    test('빈 것은 빈 것이다', () {
      expect(normalize([]), isEmpty);
    });
  });

  group('쌍둥이 찾기', () {
    test('거의 같은 글을 집어낸다', () {
      final docs = [
        countWords('반도체 엔비디아 실적 매출'),
        countWords('반도체 엔비디아 실적 매출'),
        countWords('금리 국채 물가'),
      ];
      final df = docFreq(docs);
      final v = [for (final d in docs) vectorOf(d, df, docs.length)];
      final t = twins(v);
      expect(t.length, 1);
      expect(t.first.a, 0);
      expect(t.first.b, 1);
    });
  });
}
