/// 구글 계정에 붙는 자리 — 토큰을 구해 오는 일만 한다.
///
/// 2026-08-20 새벽. 통로(sync/gdrive_transport.dart)는 어젯밤에 만들어 뒀고,
/// 그 통로가 요구하는 것은 **지금 쓸 수 있는 토큰 하나**뿐이다. 로그인을
/// 통로에 섞지 않은 까닭이 여기서 값을 한다 — 통로는 화면 없이 시험할 수
/// 있고, 로그인은 여기 한 군데에만 있다.
///
/// ## 어느 기기에서 되나
///
/// google_sign_in 은 안드로이드·아이폰·맥·웹을 받는다. **윈도우와 리눅스는
/// 안 받는다.** 그쪽에서 고를 수 있게 두면 눌러도 아무 일이 안 일어나는
/// 단추가 되므로, [supported] 로 잠근다.
///
/// ## 클라이언트 아이디를 코드에 안 적는다
///
/// 저장소가 공개다. 아이디 자체는 비밀이 아니지만(브라우저가 어차피 다
/// 본다), 저장소에 박아 두면 다음 사람이 "여기 적혀 있으니 괜찮구나" 하고
/// 그 옆에 진짜 비밀을 적는다. 그 습관을 만들지 않는다. 빌드할 때 넣는다:
///
///   --dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com
///   --dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com
///
/// 안 넣고 빌드해도 앱은 그냥 돈다. 구글 드라이브만 못 고른다.
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'gdrive_transport.dart' show kDriveScope;

class DriveAuth {
  DriveAuth._();
  static final DriveAuth instance = DriveAuth._();

  /// 안드로이드가 서버 쪽 상대를 알아보는 데 쓰는 값. 웹 클라이언트 아이디다.
  static const String webClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// 아이폰·맥이 쓰는 값. iOS 갈래로 만든 클라이언트 아이디다.
  static const String iosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// 이 기기에서 구글 로그인을 쓸 수 있는가.
  ///
  /// 플러그인이 받는 자리인가, 그리고 그 자리에 맞는 아이디를 넣고
  /// 빌드했는가 — 둘 다 참이어야 한다. 아이디 없이 켜 두면 눌러도 아무
  /// 일이 안 일어나는 단추가 된다.
  static bool get supported {
    if (kIsWeb) return webClientId.isNotEmpty;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // 안드로이드는 서명(SHA-1)으로 알아보므로 아이디가 없어도 로그인
        // 자체는 된다. 다만 serverClientId 가 있어야 토큰이 우리 프로젝트
        // 것이 된다.
        return webClientId.isNotEmpty;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosClientId.isNotEmpty;
      default:
        // 윈도우·리눅스는 플러그인이 안 받는다.
        return false;
    }
  }

  bool _ready = false;
  GoogleSignInAccount? _user;

  bool get signedIn => _user != null;
  String get email => _user?.email ?? '';

  Future<void> _init() async {
    if (_ready) return;
    await GoogleSignIn.instance.initialize(
      clientId: iosClientId.isEmpty ? null : iosClientId,
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
    _ready = true;
  }

  /// 묻지 않고 조용히 붙어 본다. 앱을 켤 때 부른다.
  ///
  /// 실패해도 아무 말 안 한다. 앱을 켤 때마다 "로그인하세요" 창이 뜨는 것은
  /// 동기화가 아니라 검문이다.
  Future<bool> resume() async {
    if (!supported) return false;
    try {
      await _init();
      _user = await GoogleSignIn.instance.attemptLightweightAuthentication();
      return _user != null;
    } catch (_) {
      return false;
    }
  }

  /// 사람에게 물어서 붙는다. 설정에서 '구글 드라이브'를 고를 때만 부른다.
  Future<bool> signIn() async {
    if (!supported) return false;
    try {
      await _init();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        // 웹은 단추 위젯으로만 로그인한다. 그쪽 길은 아직 안 냈다.
        return false;
      }
      _user = await GoogleSignIn.instance.authenticate();
      // 로그인과 권한은 다른 일이다. 붙기만 하고 권한을 안 받으면 토큰이
      // 없어서 다음 동기화가 조용히 아무 일도 안 한다.
      final a = await _user!.authorizationClient
          .authorizeScopes(const <String>[kDriveScope]);
      return a.accessToken.isNotEmpty;
    } catch (_) {
      _user = null;
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _user = null;
  }

  /// 통로가 부르는 자리. 지금 쓸 수 있는 토큰, 없으면 null.
  ///
  /// **여기서는 사람에게 안 묻는다**(promptIfNecessary 를 안 쓴다). 동기화는
  /// 뒤에서 조용히 도는 일이라, 3초마다 도는 그 자리에서 창을 띄우면
  /// 글 쓰다 말고 로그인 창을 보게 된다. 권한이 없으면 이번 차례를 거른다.
  Future<String?> token() async {
    if (!supported) return null;
    try {
      await _init();
      final u = _user;
      if (u == null) return null;
      final a = await u.authorizationClient
          .authorizationForScopes(const <String>[kDriveScope]);
      return a?.accessToken;
    } catch (_) {
      return null;
    }
  }
}
