import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/table_blocks.dart';
import 'package:simpletext/table_card.dart';

// 2026-11-11: 표 카드는 잰 높이 그대로 그려져야 한다(넘치면 시험이 깨진다).
void main() {
  const text =
      '```table\n| 구분 | 확인해야 할 질문 | 비고 |\n| --- | --- | --- |\n'
      '| 좋은 산업인가 | 앞으로 고객의 지출과 사용량이 늘어나는가 | 첫째 |\n'
      '| 좋은 기업인가 | 그 지출을 경쟁사보다 유리하게 매출과 현금으로 바꾸는가 | 둘째 |\n```';
  testWidgets('그림 표는 화면 폭에 맞게 줄어든다', (t) async {
    final g = findScrollTables(text).single.grid!;
    final lay = measureTableCard(
      g,
      fontSize: 16,
      maxWidth: 200,
      scaler: TextScaler.noScaling,
      image: true,
    );
    expect(lay.scale, lessThan(1));
    expect(lay.gridW * lay.scale, lessThanOrEqualTo(200.5));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: TableCard(
              grid: g,
              layout: lay,
              fontSize: 16,
              ink: Colors.black,
              line: Colors.grey,
            ),
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(TableCard)).height, lay.height);
  });

  for (final fit in [false, true]) {
    testWidgets('카드가 넘치지 않는다 fit=$fit', (t) async {
      final g = findScrollTables(text).single.grid!;
      final lay = measureTableCard(
        g,
        fontSize: 16,
        maxWidth: 360,
        scaler: TextScaler.noScaling,
        fit: fit,
      );
      if (fit) {
        final w =
            lay.colWidths.fold<double>(0, (a, b) => a + b) +
            lay.gap * (lay.colWidths.length - 1);
        expect(w, lessThanOrEqualTo(360));
        expect(lay.colWidths[1], greaterThan(lay.colWidths[2]),
            reason: '글이 긴 칸이 더 넓다');
      }
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: TableCard(
                grid: g,
                layout: lay,
                fontSize: 16,
                ink: Colors.black,
                line: Colors.grey,
                onCopy: () {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(TableCard)).height, lay.height);
    });
  }
}
