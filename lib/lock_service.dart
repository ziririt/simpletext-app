/// 얼굴·지문·기기 암호를 묻는 자리.
///
/// 2026-08-16 — 언제 잠글지는 core/lock.dart가 정하고, 여기는 실제로 묻기만
/// 한다. 갈라 놓은 이유는 판단 쪽을 테스트로 못 박기 위해서다. 여기는
/// 기기가 있어야 돌아가는 코드라 단위 테스트가 안 된다.
///
/// 모든 호출을 try로 감싸고 실패를 false로 돌린다. 이 플러그인은 기기와
/// 설정 상태에 따라 던지는 예외가 제각각이다(등록된 생체 정보 없음, 잠금
/// 화면 암호 없음, 지원 안 하는 기기, 너무 여러 번 실패해서 잠김…).
/// 그걸 하나하나 갈라 봐야 사용자에게 할 말은 똑같다 — "확인하지 못했다".
library;

import 'package:local_auth/local_auth.dart';

class LockService {
  LockService._();
  static final LockService instance = LockService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// 이 기기에서 잠금을 쓸 수 있는가.
  ///
  /// 생체 정보만 보지 않고 기기 암호까지 본다(isDeviceSupported). 얼굴을
  /// 등록 안 한 사람도 암호로는 열 수 있어야 하고, 그게 안 되면 잠금을
  /// 켠 순간 앱에 갇힌다.
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// 확인을 요청한다. 성공하면 true.
  ///
  /// [biometricOnly]를 켜지 않는다. 얼굴이 안 될 때(마스크, 어두움, 세 번
  /// 실패) 기기 암호로 넘어갈 길이 없으면 앱을 영영 못 연다. 잠금 기능이
  /// 사용자를 가두는 것보다 나쁜 것은 없다.
  ///
  /// [persistAcrossBackgrounding]은 확인 창이 떠 있는 동안 앱이 뒤로 갔다
  /// 와도 실패로 끝내지 말고 다시 묻게 한다. 이게 없으면 얼굴 확인 중에
  /// 알림 하나만 와도 오류가 난다.
  ///
  /// 2026-08-16 — local_auth 3.x에서 인자 이름이 바뀌었다(옛 stickyAuth,
  /// 그리고 options: 로 감싸던 것이 평평해졌다). 짐작하지 않고 이 맥에
  /// 받아 둔 패키지 원본을 열어 확인했다.
  Future<bool> ask(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
