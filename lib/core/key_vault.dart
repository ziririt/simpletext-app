/// AI 키를 두는 자리.
///
/// 2026-08-18 소유자 신고 — "앱이 업데이트되서 빌드될 때 마다 ai api키가
/// 리셋되어 매번 입력해줘야한다. 나만 그런건가?"
///
/// 절반은 그렇다. 키는 여태 설정과 함께 앱 안 저장소(SharedPreferences)에
/// 있었다. 앱스토어·테스트플라이트 **업데이트**는 그 저장소를 안 건드리므로
/// 일반 사용자는 안 겪는다. 그런데 개발 중의 설치는 업데이트가 아니라
/// 지우고 새로 까는 것이라, 앱 안에 있던 것은 전부 함께 사라진다.
///
/// 그렇다고 "개발자만 겪는 일"로 넘길 것은 아니다. 비밀을 앱 저장소에 두는
/// 것 자체가 자리를 잘못 고른 것이다. iOS·macOS 에는 그 용도로 만든 자리가
/// 따로 있고, 그 자리는 앱을 지웠다 깔아도 남는다.
///
/// **아이클라우드로는 안 보낸다.** 기기마다 한 번씩 넣는 수고가 남지만,
/// '키는 이 기기를 떠나지 않는다'는 지금까지의 약속을 그대로 지킨다 —
/// 설정 화면도 그렇게 안내하고 있고(aiKeyNotSynced), 내보내기도 키를 빼고
/// 내보낸다(export_service).
///
/// 옵션을 하나도 안 주는 이유: flutter_secure_storage 는 판이 올라갈 때
/// 옵션 이름이 바뀐 적이 있다. read/write/delete 셋은 안 바뀐다. 우리가
/// 필요한 것도 그 셋뿐이라, 안 바뀌는 것만 쓴다.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyVault {
  KeyVault._();

  static const String _k = 'aiKey';
  static const FlutterSecureStorage _s = FlutterSecureStorage();

  /// 없으면 빈 문자열. 키체인이 없는 자리(웹 등)에서도 앱은 떠야 하므로
  /// 실패를 밖으로 던지지 않는다 — 키가 없는 것과 같이 다룬다.
  static Future<String> read() async {
    try {
      return (await _s.read(key: _k)) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 빈 값을 쓰면 지운다. 빈 문자열을 남겨 두면 '지운 것'과 '안 넣은 것'이
  /// 구별되지 않는다.
  static Future<void> write(String v) async {
    try {
      if (v.trim().isEmpty) {
        await _s.delete(key: _k);
      } else {
        await _s.write(key: _k, value: v);
      }
    } catch (_) {}
  }
}
