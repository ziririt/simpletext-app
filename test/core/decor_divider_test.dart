/// 장식 가로줄 정리 시험 (2026-08-26 소유자 지시 — "'――――' 이런 선도
/// 기본 정리 대상이다").
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/tidy_engine.dart';

void main() {
  test('가로줄(U+2015)은 장식 줄이다', () {
    expect(isDecorDivider('――――'), isTrue);
  });

  test('길게 그린 줄들도 마찬가지 — 엠대시·괘선·겹줄·네모', () {
    expect(isDecorDivider('————'), isTrue);
    expect(isDecorDivider('─────'), isTrue);
    expect(isDecorDivider('═══'), isTrue);
    expect(isDecorDivider('▬▬▬'), isTrue);
  });

  test('두 개짜리는 선이 아니다', () {
    expect(isDecorDivider('――'), isFalse);
  });

  test('섞여 있으면 선이 아니라 문장이다', () {
    expect(isDecorDivider('―—―'), isFalse);
    expect(isDecorDivider('― 여기까지 ―'), isFalse);
  });

  test('물결 셋은 코드 울타리다 — 안 건드린다', () {
    expect(isDecorDivider('~~~'), isFalse);
  });

  test('제목 밑줄과 한글 표정은 건드리지 않는다', () {
    expect(isDecorDivider('===='), isFalse);
    expect(isDecorDivider('ㅡㅡㅡ'), isFalse);
  });

  test('본문 한가운데의 장식 줄은 정리하면 사라진다', () {
    final r = tidy('앞줄\n――――\n뒷줄', TidyOptions());
    expect(r.text.contains('―'), isFalse);
    expect(r.text.contains('앞줄'), isTrue);
    expect(r.text.contains('뒷줄'), isTrue);
  });

  test('마크다운 구분선은 설정을 따른다 — 기본은 그대로 둔다', () {
    final r = tidy('앞줄\n---\n뒷줄', TidyOptions());
    expect(r.text.contains('---'), isTrue);
  });
}
