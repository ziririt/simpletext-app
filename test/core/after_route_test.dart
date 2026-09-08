// 전환이 끝난 뒤에 일을 시작하는가 (2026-09-09 소유자 신고 '드르르르').
//
// 이 검사가 지키는 것은 한 줄이다 — **미는 동안에는 부르지 않는다.**
// 값이 아니라 타이밍을 보는 검사라, 프레임을 손으로 돌려 가며 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/after_route.dart';

class _Probe extends StatefulWidget {
  const _Probe(this.log);
  final List<String> log;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool armed = false;
  VoidCallback? cancel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (armed) return;
    armed = true;
    cancel = afterRouteSettled(context, () => mounted, () {
      cancel = null;
      widget.log.add('run');
    });
  }

  @override
  void dispose() {
    cancel?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('전환이 끝난 뒤에 시작한다 (2026-09-09)', () {
    testWidgets('미는 동안에는 안 부르고, 끝난 뒤에 한 번 부른다',
        (tester) async {
      final log = <String>[];
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));

      unawaitedPush(ctx, log);
      // 밀기 중간. 아직이다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(log, isEmpty, reason: '미는 도중에 시작하면 프레임이 빠진다');

      // 다 밀린 뒤.
      await tester.pumpAndSettle();
      expect(log, <String>['run']);
    });

    testWidgets('첫 화면처럼 애니메이션이 없으면 곧 부른다', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(MaterialApp(home: _Probe(log)));
      await tester.pump();
      await tester.pump();
      expect(log, <String>['run'],
          reason: '애니메이션이 없는 화면까지 기다리면 광고가 영영 안 뜬다');
    });

    testWidgets('한 번 읽은 상태를 믿지 않는다 (ProxyAnimation 함정)',
        (tester) async {
      // 화면이 만들어지는 순간 ModalRoute.animation 은 아직 진짜 컨트롤러가
      // 아니라 kAlwaysCompleteAnimation 이라 'completed' 라고 답한다.
      // 그 한 번을 믿고 시작하면 미는 도중에 일이 돈다.
      final log = <String>[];
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));
      unawaitedPush(ctx, log);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(log, isEmpty, reason: '두 프레임이 지나도 미는 중이면 아직이다');
      await tester.pumpAndSettle();
      expect(log, <String>['run']);
    });

    testWidgets('화면이 먼저 사라지면 부르지 않는다', (tester) async {
      final log = <String>[];
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));
      unawaitedPush(ctx, log);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();
      expect(log, isEmpty, reason: '사라진 화면의 일을 시작하면 헛돈다');
    });
  });
}

void unawaitedPush(BuildContext ctx, List<String> log) {
  Navigator.of(ctx).push(
    MaterialPageRoute<void>(builder: (_) => _Probe(log)),
  );
}
