/// 스크린샷 저장 드라이버.
/// integration_test 쪽에서 takeScreenshot('<로케일>/<이름>')을 부르면
/// 여기서 store/screenshots/<기기>/<로케일>/<이름>.png 로 떨어뜨린다.
///
/// 기기 이름은 환경변수 SHOT_DEVICE 로 받는다 (tool/screenshots.sh가 넣어 준다).
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final device = Platform.environment['SHOT_DEVICE'] ?? 'unknown';
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final path = 'store/screenshots/$device/$name.png';
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('저장: $path');
      return true;
    },
  );
}
