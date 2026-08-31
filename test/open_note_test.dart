/// 목록의 '지금 이 메모' 음영이 실제로 따라 움직이는가.
///
/// 2026-08-31 소유자 신고 — 맥·웹에서 처음 연 메모의 음영이 그대로 남고
/// 다른 메모를 눌러도 안 옮겨갔다. 원인은 왼쪽 목록이 const 위젯이라
/// 부모가 다시 그려도 그 아래가 통째로 건너뛰어졌기 때문이다.
///
/// 그래서 이 시험의 핵심은 **자식을 const 로 두는 것**이다. const 를
/// 떼면 이 시험은 고침 없이도 통과해 버려서 아무것도 못 막는다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/main.dart' show OpenNote;

/// 값을 '읽어 가는' 쪽. 반드시 const 로 놓인다.
class _Reader extends StatelessWidget {
  const _Reader();

  @override
  Widget build(BuildContext context) => Text(
        OpenNote.of(context) ?? '(없음)',
        textDirection: TextDirection.ltr,
      );
}

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? id = 'a';

  @override
  Widget build(BuildContext context) => Column(children: [
        OpenNote(id: id, child: const _Reader()),
        TextButton(
          onPressed: () => setState(() => id = 'b'),
          child: const Text('바꾸기', textDirection: TextDirection.ltr),
        ),
      ]);
}

void main() {
  testWidgets('열린 메모가 바뀌면 const 로 놓인 목록도 새 값을 본다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Host())));
    expect(find.text('a'), findsOneWidget);

    await tester.tap(find.text('바꾸기'));
    await tester.pump();

    expect(find.text('b'), findsOneWidget,
        reason: 'const 자식이라 부모 rebuild 만으로는 안 바뀐다 — '
            'OpenNote(InheritedWidget)가 직접 깨워야 한다');
    expect(find.text('a'), findsNothing);
  });

  test('같은 번호면 깨우지 않는다', () {
    const child = SizedBox();
    expect(
      const OpenNote(id: 'a', child: child)
          .updateShouldNotify(const OpenNote(id: 'a', child: child)),
      isFalse,
    );
    expect(
      const OpenNote(id: 'b', child: child)
          .updateShouldNotify(const OpenNote(id: 'a', child: child)),
      isTrue,
    );
  });
}
