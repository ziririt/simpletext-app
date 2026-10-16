/// 광고를 걷는 화면(AdFreeScope)을 열고 닫을 때 맨 위 띠가 제대로 소식을 받는가.
///
/// 2026-10-17 소유자 — "설정 안의 메뉴를 선택하면 배너가 안 떠야 하는데." 실제로
/// 눌러 보니(맥 통합 시험) 설정 화면이 그려지는 도중에 손들기 수가 오르고, 그 소식을
/// 받은 맨 위 띠가 그 자리에서 다시 그리기를 청해 플러터가 막았다("setState() or
/// markNeedsBuild() called during build"). 스토어 판에서는 오류 대신 **띠가 그 장에서
/// 다시 안 그려질 수 있다.** 이 시험은 그 길을 그대로 밟는다 — 띠는 네비게이터
/// 바깥(앱 껍데기)에, 손들기는 밀어 넣은 화면 안에.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/ads_service.dart';

final _nav = GlobalKey<NavigatorState>();

Widget _app() => MaterialApp(
  navigatorKey: _nav,
  builder: (ctx, child) => Column(
    children: [
      const TopBannerBar(),
      Expanded(child: child!),
    ],
  ),
  home: const Scaffold(body: Text('목록')),
);

Route<void> _route(Widget w) => MaterialPageRoute<void>(builder: (_) => w);

void main() {
  testWidgets('설정을 열면 수가 오르고, 그 아래로 들어가도 유지되고, 닫으면 0', (
    tester,
  ) async {
    final n = AdsService.instance.adFree;
    expect(n.value, 0);
    await tester.pumpWidget(_app());

    // 설정(손들기를 두른 화면)을 연다 — 그리는 도중에 수가 오른다.
    _nav.currentState!.push(
      _route(const AdFreeScope(child: Scaffold(body: Text('설정')))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '그리는 중에 띠를 흔들면 안 된다');
    expect(n.value, 1);

    // 설정 안의 메뉴 — 손들기 없는 아래 화면. 설정이 뒤에 살아 있어 그대로 1.
    _nav.currentState!.push(_route(const Scaffold(body: Text('보기 설정'))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(n.value, 1, reason: '설정 안의 메뉴에서도 띠는 걷혀 있다');

    // 손들기를 두른 아래 화면(규칙 화면처럼)도 겹쳐서 2.
    _nav.currentState!.push(
      _route(const AdFreeScope(child: Scaffold(body: Text('규칙')))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(n.value, 2);

    for (var i = 0; i < 3; i++) {
      _nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(n.value, 0, reason: '설정을 닫으면 띠가 돌아온다');
  });
}
