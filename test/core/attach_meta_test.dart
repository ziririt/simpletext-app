// 첨부 판정 — 화면을 모르는 값들.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/attach_meta.dart';

Attach a(String name, {int size = 100, String dev = 'iphone', String id = 'x'}) =>
    Attach(id: id, name: name, size: size, addedAt: 0, device: dev);

void main() {
  group('갈래', () {
    test('그림·문서·표·소리·꾸러미', () {
      expect(attachKind('사진.JPG'), kAttachImage);
      expect(attachKind('결산표.pdf'), kAttachPdf);
      expect(attachKind('보고서.hwp'), kAttachDoc);
      expect(attachKind('매출.xlsx'), kAttachSheet);
      expect(attachKind('발표.key'), kAttachSlide);
      expect(attachKind('녹음.m4a'), kAttachAudio);
      expect(attachKind('영상.mov'), kAttachVideo);
      expect(attachKind('묶음.zip'), kAttachArchive);
      expect(attachKind('메모.md'), kAttachText);
    });

    test('모르는 것과 확장자 없는 것은 그냥 파일', () {
      expect(attachKind('무엇.xyz'), kAttachFile);
      expect(attachKind('이름만'), kAttachFile);
      expect(attachKind('점으로끝.'), kAttachFile);
    });

    test('그림만 펼쳐 본다', () {
      expect(attachShowsThumb('a.png'), isTrue);
      expect(attachShowsThumb('a.pdf'), isFalse);
    });
  });

  group('크기', () {
    test('사람이 읽는 꼴', () {
      expect(humanSize(0), '0B');
      expect(humanSize(820), '820B');
      expect(humanSize(1024), '1.0KB');
      expect(humanSize(1536), '1.5KB');
      expect(humanSize(1258291), '1.2MB');
    });

    test('열을 넘으면 소수점을 뗀다', () {
      // 12.3MB 보다 12MB 가 읽기 쉽고, 그 자리에서 소수점은 뜻이 없다.
      expect(humanSize(12 * 1024 * 1024 + 300 * 1024), '12MB');
    });

    test('음수는 0', () => expect(humanSize(-5), '0B'));
  });

  group('이름 줄이기', () {
    test('짧으면 그대로', () {
      expect(shortName('짧다.pdf'), '짧다.pdf');
    });

    test('길면 가운데를 접고 확장자를 남긴다', () {
      // 뒤를 자르면 확장자가 사라져 무엇인지 알 수 없다.
      final s = shortName('2026년_3분기_결산_최종_진짜최종.xlsx', max: 20);
      expect(s.endsWith('.xlsx'), isTrue);
      expect(s.contains('…'), isTrue);
      expect(s.length <= 20, isTrue);
    });

    test('확장자가 터무니없이 길면 그냥 뒤를 자른다', () {
      final s = shortName('가나다라마바사아자차카타파하가나다.확장자가아주긴것',
          max: 12);
      expect(s.length <= 12, isTrue);
    });
  });

  group('다른 기기 것 묶기', () {
    test('내 것은 빠지고 기기별로 묶인다', () {
      final all = [
        a('내것.pdf', dev: 'mac', id: '1'),
        a('폰1.jpg', dev: 'iphone', id: '2'),
        a('폰2.jpg', dev: 'iphone', id: '3'),
        a('패드.pdf', dev: 'ipad', id: '4'),
      ];
      final g = groupOthers(all, 'mac');
      expect(g.keys.toSet(), {'iphone', 'ipad'});
      expect(g['iphone']!.length, 2);
      expect(g['ipad']!.length, 1);
    });

    test('전부 내 것이면 빈 묶음', () {
      expect(groupOthers([a('x.pdf', dev: 'mac')], 'mac'), isEmpty);
    });
  });

  group('안내 줄 나열', () {
    test('하나면 그것만', () {
      expect(othersSummary([a('결산표.pdf', size: 1258291)], '외 2개'),
          '결산표.pdf(1.2MB)');
    });

    test('여럿이면 첫째와 나머지 셈', () {
      expect(
          othersSummary(
              [a('결산표.pdf', size: 1258291, id: '1'), a('b.jpg', id: '2')],
              '외 1개'),
          '결산표.pdf(1.2MB) 외 1개');
    });

    test('없으면 빈 글자', () => expect(othersSummary([], '외 0개'), ''));
  });

  group('저장 형식', () {
    test('오갔다 와도 그대로', () {
      final one = a('결산표.pdf', size: 42, dev: 'ipad', id: 'abc');
      expect(Attach.fromJson(one.toJson()), one);
    });

    test('아이디가 없으면 버린다 — 못 찾을 파일이다', () {
      expect(Attach.fromJson({'name': 'x.pdf'}), isNull);
      expect(Attach.fromJson('글자'), isNull);
      expect(Attach.fromJson(null), isNull);
    });
  });
}
