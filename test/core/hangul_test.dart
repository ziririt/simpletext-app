/// 초성 검색 규칙을 못 박는 테스트.
/// 2026-08-16 — 한국 사용자에게 초성 검색은 기본 기대치다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/hangul.dart';

void main() {
  group('초성 뽑기', () {
    test('음절에서 초성이 나온다', () {
      expect(choseongOf('테'), 'ㅌ');
      expect(choseongOf('슬'), 'ㅅ');
      expect(choseongOf('라'), 'ㄹ');
      expect(choseongOf('가'), 'ㄱ');
      expect(choseongOf('힣'), 'ㅎ');
    });

    test('한글 음절이 아니면 null', () {
      expect(choseongOf('a'), isNull);
      expect(choseongOf('1'), isNull);
      expect(choseongOf(' '), isNull);
      expect(choseongOf(''), isNull);
      // 자음 자체는 이미 초성이라 변환할 게 없다
      expect(choseongOf('ㅌ'), isNull);
    });

    test('겹받침 자모는 초성이 아니다', () {
      // ㄳ·ㄵ 같은 글자는 초성이 될 수 없다. 초성 취급하면 오탐이 는다.
      expect(isChoseongJamo('ㄱ'), isTrue);
      expect(isChoseongJamo('ㄲ'), isTrue);
      expect(isChoseongJamo('ㅎ'), isTrue);
      expect(isChoseongJamo('ㄳ'), isFalse);
      expect(isChoseongJamo('ㅏ'), isFalse);
      expect(isChoseongJamo('a'), isFalse);
    });

    test('문장 전체 초성', () {
      expect(choseongLine('테슬라 주가'), 'ㅌㅅㄹ ㅈㄱ');
      expect(choseongLine('Tesla 주가'), 'Tesla ㅈㄱ');
    });
  });

  group('초성 검색', () {
    test('초성만 쳐도 찾는다', () {
      expect(hangulContains('테슬라 주가 분석', 'ㅌㅅㄹ'), isTrue);
      expect(hangulContains('테슬라 주가 분석', 'ㅈㄱ'), isTrue);
      expect(hangulContains('테슬라 주가 분석', 'ㅂㅅ'), isTrue);
    });

    test('없는 초성은 안 찾는다', () {
      expect(hangulContains('테슬라 주가', 'ㄲㄸ'), isFalse);
      expect(hangulContains('테슬라 주가', 'ㅅㅌㄹ'), isFalse);
    });

    test('초성은 이어져 있어야 한다 — 띄엄띄엄은 안 맞는다', () {
      // 'ㅌㄱ'는 '테...가'처럼 떨어진 자리를 맞추면 안 된다. 그러면
      // 아무 질의나 다 맞아 버려서 검색이 쓸모없어진다.
      expect(hangulContains('테슬라 주가', 'ㅌㄱ'), isFalse);
      expect(hangulContains('테슬라 주가', 'ㅌㅅ'), isTrue);
    });

    test('글자와 초성을 섞어 쳐도 맞는다', () {
      expect(hangulContains('테슬라 주가', '테ㅅㄹ'), isTrue);
      expect(hangulContains('테슬라 주가', 'ㅌ슬라'), isTrue);
    });

    test('평범한 부분일치는 그대로 된다', () {
      expect(hangulContains('테슬라 주가', '슬라'), isTrue);
      expect(hangulContains('Tesla stock', 'tesla'), isTrue);
      expect(hangulContains('Tesla stock', 'TESLA'), isTrue);
      expect(hangulContains('Tesla stock', 'nvidia'), isFalse);
    });

    test('띄어쓰기도 글자로 친다', () {
      expect(hangulContains('테슬라 주가', 'ㅌㅅㄹ ㅈㄱ'), isTrue);
      expect(hangulContains('테슬라주가', 'ㅌㅅㄹ ㅈㄱ'), isFalse);
    });

    test('빈 질의는 언제나 참 — 필터를 안 건 것과 같다', () {
      expect(hangulContains('아무거나', ''), isTrue);
      expect(hangulContains('', ''), isTrue);
      expect(hangulContains('아무거나', '   '), isTrue);
    });

    test('질의가 본문보다 길면 거짓', () {
      expect(hangulContains('가', 'ㄱㄴㄷㄹ'), isFalse);
    });

    test('빈 본문에서는 못 찾는다', () {
      expect(hangulContains('', 'ㄱ'), isFalse);
    });

    test('실제로 쓸 법한 예들', () {
      const body = '엔비디아 실적 발표 요약. 데이터센터 매출이 예상을 넘었다.';
      expect(hangulContains(body, 'ㅇㅂㄷㅇ'), isTrue);
      expect(hangulContains(body, 'ㅅㅈ'), isTrue);
      expect(hangulContains(body, 'ㄷㅇㅌㅅㅌ'), isTrue);
      expect(hangulContains(body, 'ㅁㅊ'), isTrue); // 매출
      expect(hangulContains(body, 'ㅋㅋㅋ'), isFalse);
    });
  });
}
