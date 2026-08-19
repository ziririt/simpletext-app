// 버전 기록의 곁줄을 끝에서부터 맞춘다 — 앞에서부터 세면 오늘 남긴 시각이
// 몇 달 전 판에 붙는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/history_align.dart';

void main() {
  test('짝이 온전하면 그대로', () {
    final side = [10, 20, 30];
    expect(sideValue(side, 3, 0), 10);
    expect(sideValue(side, 3, 2), 30);
  });

  test('곁줄이 짧으면 뒤부터 맞춘다', () {
    // 옛 판 셋에는 시각이 없고, 새 판 하나에만 있다.
    final side = [99];
    expect(sideValue(side, 4, 3), 99); // 넷째 = 새 판
    expect(sideValue(side, 4, 2), isNull);
    expect(sideValue(side, 4, 0), isNull);
  });

  test('곁줄이 아예 없으면 전부 null', () {
    expect(sideValue(<int>[], 3, 0), isNull);
    expect(sideValue(<int>[], 3, 2), isNull);
  });

  test('곁줄이 더 길면 앞을 버린다', () {
    final side = [1, 2, 3, 4, 5];
    expect(sideValue(side, 2, 0), 4);
    expect(sideValue(side, 2, 1), 5);
  });

  test('범위 밖은 null', () {
    expect(sideValue([1, 2], 2, -1), isNull);
    expect(sideValue([1, 2], 2, 2), isNull);
  });

  test('글자 곁줄도 같다', () {
    expect(sideValue(['revert'], 3, 2), 'revert');
    expect(sideValue(['revert'], 3, 1), isNull);
  });
}
