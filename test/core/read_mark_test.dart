// 스크롤 책갈피의 셈. 화면 없이 숫자만 따진다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/read_mark.dart';

void main() {
  group('스크롤 책갈피', () {
    test('글이 그대로면 픽셀 그대로 돌아간다', () {
      const m = ReadMark(pixels: 1234.5, extent: 4000, at: 1);
      expect(m.offsetIn(4000), 1234.5);
      // 1pt 안쪽 흔들림은 같은 글로 본다.
      expect(m.offsetIn(4000.4), 1234.5);
    });

    test('글이 길어지면 비율로 옮겨 간다', () {
      const m = ReadMark(pixels: 1000, extent: 2000, at: 1);
      expect(m.fraction, 0.5);
      expect(m.offsetIn(6000), 3000);
    });

    test('글이 짧아져도 밖으로 나가지 않는다', () {
      const m = ReadMark(pixels: 1900, extent: 2000, at: 1);
      final v = m.offsetIn(100);
      expect(v <= 100, isTrue);
      expect(v >= 0, isTrue);
    });

    test('양 끝은 0과 100으로 딱 떨어진다', () {
      expect(const ReadMark(pixels: 0, extent: 2000, at: 1).percent, 0);
      expect(const ReadMark(pixels: 2000, extent: 2000, at: 1).percent, 100);
      // 거의 맨 앞인데 0%로 보이면 '안 끼워졌나' 싶다. 1%로 남긴다.
      expect(const ReadMark(pixels: 4, extent: 2000, at: 1).percent, 1);
      // 거의 맨 끝도 마찬가지로 99%.
      expect(const ReadMark(pixels: 1996, extent: 2000, at: 1).percent, 99);
    });

    test('저장했다 되살려도 같은 자리다', () {
      const m = ReadMark(pixels: 812, extent: 3000, at: 172);
      final back = ReadMark.fromJson(m.toJson());
      expect(back, isNotNull);
      expect(back!.pixels, 812);
      expect(back.extent, 3000);
      expect(back.at, 172);
    });

    test('망가진 저장본은 조용히 null — 앱이 안 뜨는 일은 없어야 한다', () {
      expect(ReadMark.fromJson(null), isNull);
      expect(ReadMark.fromJson('책갈피'), isNull);
      expect(ReadMark.fromJson({'p': 'x', 'x': 1}), isNull);
      expect(ReadMark.fromJson({'p': 10}), isNull);
      // 길이가 0인 글에는 끼울 자리가 없다.
      expect(ReadMark.fromJson({'p': 0, 'x': 0}), isNull);
    });

    test('이미 그 자리에 있으면 이어 읽기를 권하지 않는다', () {
      const m = ReadMark(pixels: 1000, extent: 2000, at: 1);
      expect(m.isAt(1000, 2000), isTrue);
      expect(m.isAt(1010, 2000), isTrue);
      expect(m.isAt(1400, 2000), isFalse);
    });
  });
}
