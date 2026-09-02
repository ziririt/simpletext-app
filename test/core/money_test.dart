/// 값 표기 시험 — core/money.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/money.dart';

void main() {
  group('천 단위 쉼표', () {
    test('세 자리마다 끊는다', () {
      expect(groupThousands('1'), '1');
      expect(groupThousands('999'), '999');
      expect(groupThousands('1000'), '1,000');
      expect(groupThousands('44000'), '44,000');
      expect(groupThousands('1234567'), '1,234,567');
    });
    test('소수부는 건드리지 않는다', () {
      expect(groupThousands('1234.56'), '1,234.56');
      expect(groupThousands('1234,56'), '1,234,56'.replaceFirst(',56', ',56'));
    });
    test('음수도 깨지지 않는다', () {
      expect(groupThousands('-1000'), '-1,000');
    });
  });

  group('나라별 생김새 읽기', () {
    test('소수 두 자리를 쓰는가', () {
      expect(usesDecimals(r'$2.99'), isTrue);
      expect(usesDecimals('1,99 €'), isTrue);
      expect(usesDecimals('₩4,400'), isFalse);
      expect(usesDecimals('¥480'), isFalse);
      // 천 단위 쉼표를 소수로 잘못 읽지 않는다
      expect(usesDecimals('₩44,000'), isFalse);
    });
    test('기호가 앞에 오는가', () {
      expect(symbolLeads(r'$2.99'), isTrue);
      expect(symbolLeads('₩4,400'), isTrue);
      expect(symbolLeads('1,99 €'), isFalse);
      expect(symbolLeads('2,99 zł'), isFalse);
    });
  });

  group('월 환산가', () {
    test('원 — 소수 없이, 쉼표 넣어, 기호 앞에', () {
      expect(
          perMonthLabel(
              yearlyRaw: 44000, shownPrice: '₩44,000', currencySymbol: '₩'),
          '₩3,667');
    });
    test('달러 — 소수 두 자리', () {
      expect(
          perMonthLabel(
              yearlyRaw: 19.99, shownPrice: r'$19.99', currencySymbol: r'$'),
          r'$1.67');
    });
    test('유로 — 기호가 뒤에', () {
      expect(
          perMonthLabel(
              yearlyRaw: 19.99, shownPrice: '19,99 €', currencySymbol: '€'),
          '1.67 €');
    });
    test('값이 0 이하면 셈하지 않는다', () {
      expect(
          perMonthLabel(
              yearlyRaw: 0, shownPrice: '₩0', currencySymbol: '₩'),
          isNull);
    });
  });
}
