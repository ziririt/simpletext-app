/// AI 편집 결과의 HTML 걷기(core/ai_clean.dart).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/ai_clean.dart';

void main() {
  test('소유자 신고 그대로 — h3 에 style 이 붙은 것', () {
    const s = '<h3 style="font-family: 제목3;">심리 지표</h3>\n\n  - VIX 14.81, -4.08%.';
    expect(hasHtmlTags(s), isTrue);
    expect(stripHtmlToNote(s), '### 심리 지표\n\n  - VIX 14.81, -4.08%.');
  });
  test('태그가 없으면 그대로 — 부등호 쓴 글을 건드리지 않는다', () {
    const s = 'a < b 이고 <생각> 은 태그가 아니다';
    expect(hasHtmlTags(s), isFalse);
    expect(stripHtmlToNote(s), s);
  });
  test('h1·h2 는 우리 표기로, h4 이상은 제목3 으로', () {
    expect(stripHtmlToNote('<h1>가</h1><h2>나</h2><h5>다</h5>'), '# 가\n## 나\n### 다');
  });
  test('굵게·기울임은 글만 남는다', () {
    expect(stripHtmlToNote('<p><b>굵게</b> 그리고 <em>기울임</em></p>'), '굵게 그리고 기울임');
  });
  test('목록은 대시로, br 은 줄바꿈으로', () {
    expect(stripHtmlToNote('<ul><li>하나</li><li>둘</li></ul>첫줄<br>둘째줄'),
        '- 하나\n- 둘\n첫줄\n둘째줄');
  });
  test('글자 참조를 되돌린다', () {
    expect(stripHtmlToNote('<p>A &amp; B &lt; C</p>'), 'A & B < C');
  });
  test('사람이 시킨 빈 줄은 살린다 — 제목 위 두 줄', () {
    const s = '앞글\n\n\n<h3>소제목</h3>\n뒷글';
    expect(stripHtmlToNote(s), '앞글\n\n\n### 소제목\n뒷글');
  });
  test('style 덩이는 통째로 버린다', () {
    expect(stripHtmlToNote('<style>h3{color:red}</style><h3>제목</h3>본문'), '### 제목\n본문');
  });
}
