/// 심플텍스트 — Tidy Engine 테스트 (기획서 55~58절 Acceptance Test 포함)
/// 웹 프로토타입 test_engine.js에서 이식. 동일 fixture, 동일 기대값.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tidy_engine.dart';

TidyOptions aiOpts() => buildPresets().firstWhere((p) => p.id == 'ai').opts;

void main() {
  group('Acceptance Tests (기획서 55~58절)', () {
    const at01In = '''### **1. 핵심 요약**

- **Apple**은 최근 AI 전략에서 시장 기대에 미치지 못했다는 평가를 받았다.
- 그러나 과도한 AI CapEx 부담이 없다는 점은 오히려 긍정적이다.

---

| 기업 | AI CapEx 부담 | 시장 반응 |
|---|---:|---|
| Microsoft | 높음 | 긍정적 |
| Meta | 높음 | 부정적 |
| Apple | 낮음 | 혼재 |''';

    const at01Exp = '''1. 핵심 요약

· Apple은 최근 AI 전략에서 시장 기대에 미치지 못했다는 평가를 받았다.
· 그러나 과도한 AI CapEx 부담이 없다는 점은 오히려 긍정적이다.

| 기업 | AI CapEx 부담 | 시장 반응 |
| --- | ---: | --- |
| Microsoft | 높음 | 긍정적 |
| Meta | 높음 | 부정적 |
| Apple | 낮음 | 혼재 |''';

    test('AT01 AI 답변 정리', () {
      expect(tidy(at01In, aiOpts()).text, at01Exp);
    });

    test('AT02 Google Sheets TSV', () {
      final t = extractTables(at01In).tables;
      expect(t.length, 1);
      expect(tableToTSV(t[0]),
          '기업\tAI CapEx 부담\t시장 반응\nMicrosoft\t높음\t긍정적\nMeta\t높음\t부정적\nApple\t낮음\t혼재');
    });

    const at03In = '''| 종목 | 티커 | 수익률 | 비중
|------|------|--------|
| 애플 | AAPL | +14.2% | 12% |
| 마이크로소프트 | MSFT | +21.5%
| 엔비디아 | NVDA | +48.9% | 22% | 추가셀 |
|테슬라|TSLA|-8.3%|8%|''';

    const at03Exp = '''| 종목 | 티커 | 수익률 | 비중 |
| --- | --- | --- | --- |
| 애플 | AAPL | +14.2% | 12% |
| 마이크로소프트 | MSFT | +21.5% | |
| 엔비디아 | NVDA | +48.9% | 22% 추가셀 |
| 테슬라 | TSLA | -8.3% | 8% |''';

    test('AT03 깨진 표 복구', () {
      final r = tidy(at03In, aiOpts());
      expect(r.text, at03Exp);
      expect(r.warnings.any((w) => w.contains('엔비디아') && w.contains('초과 셀 1개 병합')), true);
    });

    test('AT04 코드블록 보호', () {
      const at04In = '''다음 코드를 참고한다.

```python
value = "**not bold**"
table = "A | B"
```

### 결론

**이 코드 자체는 변경하면 안 된다.**''';
      final r = tidy(at04In, aiOpts());
      expect(r.text.contains('value = "**not bold**"'), true);
      expect(r.text.contains('table = "A | B"'), true);
      expect(r.text.contains('```python'), true);
      expect(r.text.contains('결론'), true);
      expect(r.text.contains('### 결론'), false);
      expect(r.text.contains('이 코드 자체는 변경하면 안 된다.'), true);
      expect(r.text.contains('**이 코드'), false);
      expect(r.text.startsWith('다음 코드를 참고한다.'), true);
    });
  });

  group('AI 서두 제거 (보수적)', () {
    test('명확한 케이스 제거', () {
      final r = tidy('네, 요청하신 내용을 정리해드리겠습니다.\n\n## 요약\n\n- 첫째\n- 둘째', aiOpts());
      expect(r.text.startsWith('요약'), true);
    });
    test('오탐 방지 (본문 보존)', () {
      final r = tidy('네이버는 올해 실적이 좋았다.\n\n- 첫째\n- 둘째', aiOpts());
      expect(r.text.startsWith('네이버는 올해 실적이 좋았다.'), true);
    });
  });

  test('Outer fence wrapper 제거', () {
    final r = tidy('```markdown\n# 제목\n\n본문입니다.\n```', aiOpts());
    expect(r.text.startsWith('제목'), true);
  });

  group('Table Export', () {
    final tt = TableGrid(
      header: ['이름', '메모'],
      aligns: ['left', 'left'],
      rows: [
        ['김"철수"', 'a,b'],
        ['<태그>', '줄1'],
      ],
      repaired: false,
    );
    test('CSV RFC4180', () {
      expect(tableToCSV(tt), '이름,메모\r\n"김""철수""","a,b"\r\n<태그>,줄1');
    });
    test('HTML escape', () {
      expect(tableToHTML(tt).contains('&lt;태그&gt;'), true);
    });
  });

  test('이모지·제로폭 제거', () {
    final r = tidy('안녕하세요 😀🚀 테스트​입니다 ✅', aiOpts());
    expect(r.text, '안녕하세요 테스트입니다');
  });

  group('v1.2 사용자 정리 규칙', () {
    const userIn = '''통장의 잔액보다 중요한 것이 **통장으로 들어오는 방향**이 된다.

현금흐름은 바로 그 수도꼭지다.

---

## 부자가 된다는 말보다 '경제적 엔진을 하나 더 만든다'는 표현이 정확하다

- 첫째 항목''';

    test('강조 → 작은따옴표 / 구분선 유지 / 제목 텍스트만', () {
      final r = tidy(userIn, aiOpts().copyWith(emphStyle: 'quoteSingle', hrMode: 'keep'));
      expect(r.text.contains("'통장으로 들어오는 방향'이 된다."), true);
      expect(r.text.split('\n').any((l) => l.trim() == '---'), true);
      expect(r.text.contains('부자가 된다는 말보다'), true);
      expect(r.text.contains('##'), false);
    });
    test('강조 → 큰따옴표', () {
      final r = tidy('**핵심 지표**를 본다', aiOpts().copyWith(emphStyle: 'quoteDouble'));
      expect(r.text.contains('"핵심 지표"를 본다'), true);
    });
    test('강조 유지 모드', () {
      final r = tidy('**핵심**을 본다', aiOpts().copyWith(emphStyle: 'keep'));
      expect(r.text.contains('**핵심**을 본다'), true);
    });
    test('40자 초과 강조는 따옴표 대신 제거', () {
      final longBold = '**${'가' * 50}**';
      final r = tidy(longBold, aiOpts().copyWith(emphStyle: 'quoteSingle'));
      expect(r.text.contains("'"), false);
    });
    test('제목 → ■ 기호', () {
      expect(tidy('## 소제목', aiOpts().copyWith(headingMode: 'prefix', headingSymbol: '■')).text, '■ 소제목');
    });
    test('제목 → [대괄호]', () {
      expect(tidy('## 소제목', aiOpts().copyWith(headingMode: 'bracket')).text, '[소제목]');
    });
    test('제목 유지 모드', () {
      expect(tidy('## **소제목**', aiOpts().copyWith(headingMode: 'keep')).text, '## 소제목');
    });
    test('글머리 → •', () {
      expect(tidy('- 항목', aiOpts().copyWith(bulletChar: '•')).text, '• 항목');
    });
    test('글머리 원래대로', () {
      expect(tidy('- **항목**', aiOpts().copyWith(bulletChar: 'keep')).text, '- 항목');
    });
  });

  group('v1.3 구조 규칙 (사용자 브리핑 fixture)', () {
    test('대시 나열 → 줄 목록', () {
      final r = tidy('– 마소 506.06달러. +1.21% – 아마존 278.09달러. +1.32% – 알파벳 355.84달러. +0.67%', aiOpts());
      expect(r.text, '· 마소 506.06달러. +1.21%\n· 아마존 278.09달러. +1.32%\n· 알파벳 355.84달러. +0.67%');
    });
    test('라벨 + 대시 나열 분리', () {
      final r = tidy('테슬라 – 330.88달러. +0.70%. 시장 약세를 견디고 상승 – 금리 민감 성장주 부담은 잔존', aiOpts());
      expect(r.text, '테슬라\n· 330.88달러. +0.70%. 시장 약세를 견디고 상승\n· 금리 민감 성장주 부담은 잔존');
    });
    test('ㅤ 소제목 + 빈 줄 패딩(기본 모드)', () {
      final r = tidy('ㅤ ㅤ 지수 마감 ㅤ\n– S&P500 7,753.11. -0.06% – 다우 53,975.98. -0.11%', aiOpts());
      expect(r.text, '지수 마감\n\n· S&P500 7,753.11. -0.06%\n· 다우 53,975.98. -0.11%');
    });
    test('ㅤ 소제목에 제목 규칙 연동(■)', () {
      final r = tidy('ㅤ ㅤ 지수 마감 ㅤ\n– S&P500 7,753.11. -0.06% – 다우 53,975.98. -0.11%',
          aiOpts().copyWith(headingMode: 'prefix', headingSymbol: '■'));
      expect(r.text.startsWith('■ 지수 마감'), true);
    });
    test('단일 – 글머리 인식', () {
      expect(tidy('– 공포탐욕지수: 제공 자료에 수치 없음.', aiOpts()).text, '· 공포탐욕지수: 제공 자료에 수치 없음.');
    });
    test('본문 속 단일 대시는 분리 안 함', () {
      final r = tidy('유가와 장기금리 동반 상승 – 그래서 할인율 부담이 커졌다.', aiOpts());
      expect(r.text.contains('\n'), false);
    });
  });

  group('v1.3 사용자 치환 규칙', () {
    test('일반 치환 + 정규식 치환', () {
      final r = tidy('500만원을 투자했다.\n투자는 각자의 판단으로.', aiOpts().copyWith(customRules: [
        const CustomRule(find: '투자는 각자의 판단으로.', replace: '※ 투자 판단의 책임은 각자에게 있습니다.'),
        const CustomRule(find: r'(\d+)만원', replace: r'$1만 원', regex: true),
      ]));
      expect(r.text.contains('※ 투자 판단의 책임은 각자에게 있습니다.'), true);
      expect(r.text.contains('500만 원을'), true);
    });
    test('코드블록 보호', () {
      final r = tidy('본문 value 단어.\n\n```python\nvalue = 1\n```',
          aiOpts().copyWith(customRules: [const CustomRule(find: 'value', replace: 'VALUE')]));
      expect(r.text.contains('VALUE 단어'), true);
      expect(r.text.contains('value = 1'), true);
    });
  });

  group('v1.4 소제목 여백 + 들여쓰기', () {
    final padOpts = aiOpts().copyWith(headingPad: true, bulletIndent: 2);
    const padIn = '''ㅤ ㅤ 지수 마감 ㅤ
– S&P500 7,753.11. -0.06% – 다우 53,975.98. -0.11%
ㅤ ㅤ 핵심 트리거 ㅤ
– 엔비디아 5,000억 달러 규모 AI 인프라 금융 패키지 보도 유입''';
    const padExp = '''지수 마감
ㅤ
  · S&P500 7,753.11. -0.06%
  · 다우 53,975.98. -0.11%
ㅤ
ㅤ
핵심 트리거
ㅤ
  · 엔비디아 5,000억 달러 규모 AI 인프라 금융 패키지 보도 유입''';

    test('소제목 여백 위2/아래1 + 들여쓰기 2칸', () {
      expect(tidy(padIn, padOpts).text, padExp);
    });
    test('## 소제목에도 여백 규칙 적용', () {
      expect(tidy('도입 문장.\n\n## 소제목\n\n- 항목 하나', padOpts).text,
          '도입 문장.\nㅤ\nㅤ\n소제목\nㅤ\n  · 항목 하나');
    });
    test('여백 끔이면 기존 방식', () {
      expect(tidy(padIn, aiOpts()).text.startsWith('지수 마감\n\n· S&P500'), true);
    });
    test('기존 여백 흡수 (4줄/2줄 버그 재현 fixture)', () {
      const preSpaced = '도입 문장.\nㅤ\nㅤ\nㅤ ㅤ 지수 마감 ㅤ\nㅤ\n– S&P500 7,753.11. -0.06% – 다우 53,975.98. -0.11%';
      const exp = '도입 문장.\nㅤ\nㅤ\n지수 마감\nㅤ\n  · S&P500 7,753.11. -0.06%\n  · 다우 53,975.98. -0.11%';
      expect(tidy(preSpaced, padOpts).text, exp);
    });
  });

  group('v1.5.2 들여쓰기 고정', () {
    final optIndent2 = aiOpts().copyWith(bulletChar: '-', bulletIndent: 2);
    test('원본 들여쓰기 무시, 항상 2칸', () {
      expect(tidy('    - 깊이 들여쓴 항목', optIndent2).text, '  - 깊이 들여쓴 항목');
    });
    test('들여쓰기 누적 방지', () {
      expect(tidy('  - 이미 2칸 항목', optIndent2).text, '  - 이미 2칸 항목');
    });
  });

  group('v1.5 출처 블록 제거', () {
    const citeIn = '''미국 증시는 금요일 혼조로 마감했다[1][2]. 밸류에이션 부담 논쟁은 계속된다[3].

[1]: https://apnews.com/article/9d586bdbf1fb230dcf1f915dcaf50858?utm_source=chatgpt.com "How major US stock indexes fared Friday 8/7/2026"
| [2]: https://www.goldmansachs.com/insights/articles/are-us-stock-market-valuations-outpacing-fundamentals?utm_source=chatgpt.com "Are US Stock Market Valuations Outpacing Fundamentals? | Goldman Sachs" |
| --- | --- |
| [3]: https://www.morganstanley.com/insights/articles/2026-market-optimism-and-risks?utm_source=chatgpt.com "Stock Market Outlook 2026: Political Risks Loom | Morgan Stanley" |
| [4]: https://www.jpmorgan.com/insights/global-research/outlook/market-outlook?utm_source=chatgpt.com "2026 Market Outlook | J.P. Morgan Global Research" |''';

    test('출처 블록 전체 제거 + 인라인 [n] 제거', () {
      final r = tidy(citeIn, aiOpts());
      expect(r.text, '미국 증시는 금요일 혼조로 마감했다. 밸류에이션 부담 논쟁은 계속된다.');
      expect(r.summary.contains('출처'), true);
    });
    test('출처 정의 없으면 인라인 [n] 보존', () {
      expect(tidy('계약서 [1]항을 참조하라.', aiOpts()).text, '계약서 [1]항을 참조하라.');
    });
    test('출처 유지 옵션', () {
      final r = tidy(citeIn, aiOpts().copyWith(removeCitations: false));
      expect(r.text.contains('apnews.com'), true);
    });
  });
}
