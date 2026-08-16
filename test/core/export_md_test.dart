/// 내보내기 형식을 못 박는 테스트.
///
/// 여기서 지키려는 것: **내보낸 파일이 다른 앱에서 열려야 하고, 내보내는
/// 동안 메모가 사라지면 안 된다.**
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/export_md.dart';

void main() {
  group('마크다운 만들기', () {
    test('앞머리와 본문이 나온다', () {
      final md = noteToMarkdown(
        title: '테슬라 정리',
        body: '본문입니다.',
        tags: const ['투자', '테슬라'],
        source: 'ChatGPT',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(md.startsWith('---\n'), isTrue);
      expect(md, contains('title: "테슬라 정리"'));
      expect(md, contains('tags: ["투자", "테슬라"]'));
      expect(md, contains('source: "ChatGPT"'));
      expect(md, contains('# 테슬라 정리'));
      expect(md, contains('본문입니다.'));
    });

    test('제목·태그·출처가 없으면 그 줄을 안 넣는다', () {
      final md = noteToMarkdown(
        title: '',
        body: '그냥 글',
        tags: const [],
        source: '',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(md, isNot(contains('title:')));
      expect(md, isNot(contains('tags:')));
      expect(md, isNot(contains('source:')));
      expect(md, contains('created:'));
      expect(md, contains('그냥 글'));
    });

    test('따옴표가 든 제목도 앞머리를 깨뜨리지 않는다', () {
      final md = noteToMarkdown(
        title: '그가 "맞다"고 했다: 정말로',
        body: 'x',
        tags: const [],
        source: '',
        createdAt: 0,
        updatedAt: 0,
      );
      // 콜론과 따옴표는 YAML을 통째로 깨뜨리는 두 문자다.
      expect(md, contains(r'title: "그가 \"맞다\"고 했다: 정말로"'));
    });

    test('본문이 줄바꿈으로 안 끝나도 파일은 줄바꿈으로 끝난다', () {
      final md = noteToMarkdown(
        title: '',
        body: '끝',
        tags: const [],
        source: '',
        createdAt: 0,
        updatedAt: 0,
      );
      expect(md.endsWith('\n'), isTrue);
    });
  });

  group('파일 이름 다듬기', () {
    test('금지 문자를 없앤다', () {
      expect(safeFileName('a/b\\c:d*e?f"g<h>i|j'), 'abcdefghij');
    });

    test('줄바꿈은 공백이 되고 연속 공백은 하나로', () {
      expect(safeFileName('첫 줄\n둘째  줄'), '첫 줄 둘째 줄');
    });

    test('끝의 점과 공백은 잘라 낸다', () {
      // 윈도우가 이런 이름으로는 파일을 못 만든다.
      expect(safeFileName('보고서...'), '보고서');
      expect(safeFileName('보고서   '), '보고서');
    });

    test('빈 이름이면 기본값', () {
      expect(safeFileName(''), 'note');
      expect(safeFileName('   '), 'note');
      expect(safeFileName('///'), 'note');
      expect(safeFileName('무제', fallback: '무제'), '무제');
    });

    test('너무 길면 자른다', () {
      final long = 'ㄱ' * 200;
      expect(safeFileName(long).length, lessThanOrEqualTo(60));
    });

    test('윈도우 예약어는 그대로 못 쓴다', () {
      expect(safeFileName('CON'), 'CON-');
      expect(safeFileName('nul'), 'nul-');
      expect(safeFileName('console'), 'console');
    });
  });

  group('이름 겹침', () {
    test('겹치면 번호가 붙는다', () {
      final used = <String>{};
      expect(uniqueName('무제', used), '무제');
      expect(uniqueName('무제', used), '무제-2');
      expect(uniqueName('무제', used), '무제-3');
      expect(uniqueName('다른', used), '다른');
    });

    test('이미 번호가 쓰였으면 건너뛴다', () {
      final used = <String>{'무제', '무제-2'};
      expect(uniqueName('무제', used), '무제-3');
    });

    test('겹침 처리가 없으면 내보낼 때 메모가 사라진다', () {
      // 제목 없는 메모 세 개는 파일 이름이 전부 같아진다. 압축을 푸는 쪽이
      // 조용히 하나만 남기면 사용자는 메모를 잃는다 — 가장 나쁜 사고다.
      final used = <String>{};
      final names = [
        uniqueName('note', used),
        uniqueName('note', used),
        uniqueName('note', used),
      ];
      expect(names.toSet().length, 3);
    });
  });
}
