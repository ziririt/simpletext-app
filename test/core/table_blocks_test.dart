import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/table_blocks.dart';
import 'package:simpletext/core/tidy_engine.dart';

// 2026-11-11: 본문 속 가로 스크롤 표 자리 찾기.
void main() {
  const table = '```table\n| 구분 | 값 |\n| --- | --- |\n| 입력 | \$2.00 |\n```';

  test('울타리 하나를 찾고 표를 읽는다', () {
    const text = '앞 글\n$table\n뒤 글';
    final b = findScrollTables(text);
    expect(b.length, 1);
    expect(text.substring(b[0].start, b[0].firstLineEnd), '```table');
    expect(text.substring(b[0].end - 3, b[0].end), '```');
    expect(b[0].grid!.header, ['구분', '값']);
    expect(b[0].grid!.rows.first, ['입력', '\$2.00']);
  });

  test('글 끝에 붙은 표도 찾는다', () {
    final b = findScrollTables(table);
    expect(b.length, 1);
    expect(b[0].end, table.length);
  });

  test('닫히지 않은 울타리는 표가 아니다', () {
    expect(findScrollTables('```table\n| a | b |\n| - | - |'), isEmpty);
  });

  test('다른 코드 울타리 안의 ```table 은 글자다', () {
    const text = '```\n```table\n```\n뒤';
    expect(findScrollTables(text), isEmpty);
  });

  test('안이 표가 아니면 grid 는 null — 카드로 덮지 않는다', () {
    final b = findScrollTables('```table\n그냥 글\n```');
    expect(b.length, 1);
    expect(b[0].grid, isNull);
  });

  test('정리(scroll)로 만든 표를 정리를 다시 돌려도 그대로다', () {
    const raw = '| 구분 | 값 |\n|---|---|\n| 입력 | 2 |\n| 출력 | 10 |';
    final once = tidy(raw, TidyOptions(repairTables: true, wideTables: 'scroll')).text;
    expect(findScrollTables(once).length, 1);
    final twice = tidy(once, TidyOptions(repairTables: true, wideTables: 'scroll')).text;
    expect(twice, once);
    expect(findScrollTables(twice).first.grid!.rows.length, 2);
  });

  test('fit 이름표는 화면 폭 표다', () {
    const text = '```table fit\n| a | b |\n| - | - |\n| 1 | 2 |\n```';
    final b = findScrollTables(text);
    expect(b.single.mode, 'fit');
    expect(findScrollTables(table).single.mode, 'scroll');
  });

  test('정리(fit)도 다시 돌려도 그대로다', () {
    const raw = '| 구분 | 값 |\n|---|---|\n| 입력 | 2 |';
    final once = tidy(raw, TidyOptions(repairTables: true, wideTables: 'fit')).text;
    expect(findScrollTables(once).single.mode, 'fit');
    expect(tidy(once, TidyOptions(repairTables: true, wideTables: 'fit')).text, once);
  });

  test('locateTables: 글자 표의 자리를 찾고, 울타리 안은 안 본다', () {
    const t1 = '| 구분 | 값 |\n|---|---|\n| 입력 | 2 |';
    final text = '앞 글\n$t1\n\n$table\n끝';
    final spots = locateTables(text);
    expect(spots.length, 1);
    expect(text.substring(spots[0].start, spots[0].end), t1);
    expect(spots[0].grid.rows.single, ['입력', '2']);
  });
}
