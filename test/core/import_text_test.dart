/// 텍스트 파일 가져오기 규칙 테스트.
/// 지키려는 것: **원본을 손대지 않고 들여놓는다.**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/import_text.dart';

void main() {
  group('열 수 있는 파일 고르기', () {
    test('텍스트 계열만 연다', () {
      expect(isTextFileName('메모.md'), isTrue);
      expect(isTextFileName('a.MARKDOWN'), isTrue);
      expect(isTextFileName('b.txt'), isTrue);
      expect(isTextFileName('c.csv'), isTrue);
      expect(isTextFileName('d.json'), isTrue);
    });

    test('바이너리는 안 연다', () {
      // 열면 깨진 글자로 메모가 하나 생기고, 사용자는 그걸 버그로 읽는다.
      expect(isTextFileName('x.png'), isFalse);
      expect(isTextFileName('x.pdf'), isFalse);
      expect(isTextFileName('x.zip'), isFalse);
      expect(isTextFileName('확장자없음'), isFalse);
      expect(isTextFileName('끝에점.'), isFalse);
    });
  });

  group('파일 이름에서 제목', () {
    test('확장자를 뗀다', () {
      expect(titleFromFileName('테슬라 정리.md'), '테슬라 정리');
      expect(titleFromFileName('a.b.txt'), 'a.b');
    });

    test('확장자만 있으면 이름 그대로', () {
      expect(titleFromFileName('.gitignore'), '.gitignore');
    });
  });

  group('앞머리 떼기', () {
    test('우리가 내보낸 파일을 그대로 되읽는다', () {
      const f = '---\n'
          'title: "테슬라 정리"\n'
          'tags: ["투자", "테슬라"]\n'
          'source: "ChatGPT"\n'
          'created: 1970-01-01T00:00:00.000Z\n'
          '---\n'
          '\n'
          '# 테슬라 정리\n'
          '\n'
          '본문입니다.\n';
      final p = parseTextFile('아무거나.md', f);
      expect(p.title, '테슬라 정리');
      expect(p.tags, ['투자', '테슬라']);
      expect(p.source, 'ChatGPT');
      expect(p.body, '본문입니다.');
      // 제목이 본문에도 남아 있으면 두 번 보인다.
      expect(p.body, isNot(contains('# 테슬라 정리')));
    });

    test('태그가 대괄호 없이 와도 읽는다', () {
      const f = '---\ntags: 투자, 테슬라\n---\n본문';
      expect(parseTextFile('a.md', f).tags, ['투자', '테슬라']);
    });

    test('앞머리가 없으면 맨 위 제목을 쓴다', () {
      final p = parseTextFile('파일이름.md', '# 진짜 제목\n\n본문');
      expect(p.title, '진짜 제목');
      expect(p.body, '본문');
    });

    test('제목이 아무 데도 없으면 파일 이름을 쓴다', () {
      final p = parseTextFile('회의록.txt', '그냥 글\n둘째 줄');
      expect(p.title, '회의록');
      expect(p.body, '그냥 글\n둘째 줄');
    });

    test('닫히지 않은 앞머리는 앞머리가 아니다', () {
      // `---`로 시작하지만 안 닫힌 글은 그냥 본문이다. 잘라 먹으면 안 된다.
      const f = '---\n제목처럼 보이지만 안 닫혔다\n계속 본문';
      final p = parseTextFile('a.md', f);
      expect(p.body, contains('안 닫혔다'));
      expect(p.body, contains('계속 본문'));
    });

    test('윈도우 줄바꿈을 정리한다', () {
      final p = parseTextFile('a.txt', '첫 줄\r\n둘째 줄');
      expect(p.body, '첫 줄\n둘째 줄');
    });

    test('마크다운 문법은 벗기지 않는다', () {
      // 들어오자마자 손대면 원본이 사라진다. 정리는 사용자가 누를 때.
      final p = parseTextFile('a.md', '## 소제목\n\n- **굵게**\n- 항목');
      expect(p.body, contains('## 소제목'));
      expect(p.body, contains('**굵게**'));
    });
  });

  group('이어 붙이기', () {
    test('어디서 온 글인지 남긴다', () {
      final b = appendBlock('참고자료.md', '내용');
      expect(b, contains('참고자료.md'));
      expect(b, contains('내용'));
    });

    test('앞에 빈 줄을 둬서 원래 글과 붙지 않게 한다', () {
      expect(appendBlock('a.md', 'x').startsWith('\n\n'), isTrue);
    });
  });
}
