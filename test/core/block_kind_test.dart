/// 단락 형식 고르개의 셈 시험.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/edit_ops.dart';

void main() {
  group('지금 무슨 형식인가', () {
    test('맨 줄은 본문', () {
      expect(blockKind('사과', 0, 0), kBlockBody);
    });

    test('# 하나면 제목1', () {
      expect(blockKind('# 사과', 0, 0), kBlockH1);
    });

    test('## 둘이면 제목2', () {
      expect(blockKind('## 사과', 0, 0), kBlockH2);
    });

    test('### 셋이면 제목3', () {
      expect(blockKind('### 사과', 0, 0), kBlockH3);
    });

    test('네 개부터는 본문으로 본다 — 목록에 없는 것을 적을 수는 없다', () {
      expect(blockKind('#### 사과', 0, 0), kBlockBody);
    });

    test('인용', () {
      expect(blockKind('> 사과', 0, 0), kBlockQuote);
    });

    test('울타리가 걸리면 코드', () {
      const t = '```\n사과\n```';
      expect(blockKind(t, 0, t.length), kBlockCode);
    });

    test('여러 줄이 섞여 있으면 본문이라고 말한다', () {
      const t = '# 사과\n배';
      expect(blockKind(t, 0, t.length), kBlockBody);
    });

    test('빈 줄은 안 센다', () {
      const t = '## 사과\n\n## 배';
      expect(blockKind(t, 0, t.length), kBlockH2);
    });
  });

  group('형식을 곧장 고른다', () {
    test('본문에서 제목2로', () {
      expect(applyBlock('사과', 0, 0, kBlockH2).text, '## 사과');
    });

    test('제목1에서 제목3으로 — 한 번에 간다', () {
      expect(applyBlock('# 사과', 0, 0, kBlockH3).text, '### 사과');
    });

    test('제목3에서 본문으로 — 세 번 안 누른다', () {
      expect(applyBlock('### 사과', 0, 0, kBlockBody).text, '사과');
    });

    test('겹쳐 붙은 것도 벗긴다', () {
      expect(applyBlock('> ## 사과', 0, 0, kBlockH1).text, '# 사과');
    });

    test('인용에서 본문으로', () {
      expect(applyBlock('> 사과', 0, 0, kBlockBody).text, '사과');
    });

    test('들여쓴 줄은 들여쓰기를 지킨다', () {
      expect(applyBlock('  사과', 0, 0, kBlockQuote).text, '  > 사과');
    });

    test('여러 줄을 한 번에', () {
      const t = '사과\n배';
      expect(applyBlock(t, 0, t.length, kBlockH2).text, '## 사과\n## 배');
    });

    test('빈 줄은 안 건드린다', () {
      const t = '사과\n\n배';
      expect(applyBlock(t, 0, t.length, kBlockH1).text, '# 사과\n\n# 배');
    });

    test('한 줄도 코드는 울타리다 — 홑따옴표가 아니다', () {
      expect(applyBlock('사과', 0, 0, kBlockCode).text, '```\n사과\n```');
    });

    test('제목을 코드로 바꾸면 우물정은 걷힌다', () {
      expect(applyBlock('# 사과', 0, 0, kBlockCode).text, '```\n사과\n```');
    });

    test('코드에서 본문으로 — 울타리가 걷힌다', () {
      const t = '```\n사과\n```';
      expect(applyBlock(t, 0, t.length, kBlockBody).text, '사과');
    });

    test('코드를 다시 골라도 그대로다 — 고르개는 스위치가 아니다', () {
      const t = '```\n사과\n```';
      expect(applyBlock(t, 0, t.length, kBlockCode).text, t);
    });

    test('골라 놓은 자리는 고친 덩이를 그대로 잡는다', () {
      final r = applyBlock('사과', 0, 0, kBlockH1);
      expect(r.text.substring(r.start, r.end), '# 사과');
    });
  });
}
