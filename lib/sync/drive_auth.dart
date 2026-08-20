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

import 'dart:async';

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
  /// 웹 로그인 길이 났는가.
  ///
  /// 2026-08-20 — 웹 빌드를 tool/deploy.sh 안으로 들이면서 클라이언트
  /// 아이디가 처음으로 웹 판에 실렸다. 그 순간 supported 가 참이 되어
  /// 설정에 '구글 드라이브'가 나타났다 — 그런데 눌러도 아무 일이
  /// 안 일어난다.
  ///
  /// 웹은 authenticate() 를 안 받는다(supportsAuthenticate() 가 거짓).
  /// 구글이 그린 단추 위젯으로만 로그인하고, 드라이브 권한도 사람이
  /// 누른 그 자리에서 창을 띄워야 브라우저가 안 막는다. 화면이 하나
  /// 더 필요한 일이지 아이디 한 줄로 되는 일이 아니다.
  ///
  /// 소유자가 바로 앞 지시에서 말했다 — "되는 척 하지 말아라."
  /// 길이 나면 여기 한 곳만 true 로 바꾼다.
  ///
  /// 그때 준비되어 있어야 하는 것이 하나 더 있다: 구글 클라우드 콘솔의
  /// 이 웹 클라이언트에 **승인된 자바스크립트 원본**으로
  /// https://ezlong.com 이 등록되어 있어야 한다. 없으면 단추가 origin
  /// 오류로 뜨지도 않는다.
  static const bool webReady = true;

  static bool get supported {
    if (kIsWeb) return webReady && webClientId.isNotEmpty;
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
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;

  /// 붙었는지가 바뀔 때마다 하나씩 오른다. 화면이 이걸 듣는다.
  ///
  /// 웹에서는 로그인 결과가 **함수의 반환값으로 안 온다.** 구글이 그린
  /// 단추를 누르면 결과가 스트림으로 흘러들어온다. 부르는 쪽이 기다릴
  /// 자리가 없으니, 바뀌었다는 것을 우리가 알려 줘야 한다.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void _mark(GoogleSignInAccount? u) {
    _user = u;
    revision.value++;
  }

  bool get signedIn => _user != null;
  String get email => _user?.email ?? '';

  Future<void> _init() async {
    if (_ready) return;
    // 어느 아이디를 주는가는 **자리마다 다르다.**
    //   웹    — 웹 클라이언트 아이디. 브라우저가 직접 구글에 말을 건다.
    //   애플  — iOS 갈래 아이디. 사파리로 나갔다 돌아오는 길이 그것이다.
    //   안드로이드 — 서명(SHA-1)으로 알아보므로 clientId 는 안 쓰고,
    //          serverClientId 로 '어느 프로젝트 것인가'만 밝힌다.
    //
    // 여태 웹에도 iOS 아이디를 주고 있었다. 웹 판에 아이디 자체가 안
    // 실려 있어서 드러나지 않았을 뿐이다 — 안 도는 코드는 틀려도 조용하다.
    final id = kIsWeb
        ? webClientId
        : (iosClientId.isEmpty ? null : iosClientId);
    // 로그인 소식을 듣는 자리. 웹에서는 이 길이 **유일한** 길이고,
    // 다른 판에서는 있으나 없으나지만 해가 없다 — 같은 코드를 판마다
    // 다르게 두면 웹만 고치는 날 나머지가 어긋난다.
    _events ??= GoogleSignIn.instance.authenticationEvents.listen((e) {
      if (e is GoogleSignInAuthenticationEventSignIn) {
        _mark(e.user);
      } else if (e is GoogleSignInAuthenticationEventSignOut) {
        _mark(null);
      }
    }, onError: (Object _) {});
    await GoogleSignIn.instance.initialize(
      clientId: (id == null || id.isEmpty) ? null : id,
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
      _mark(await GoogleSignIn.instance.attemptLightweightAuthentication());
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
      _mark(await GoogleSignIn.instance.authenticate());
      // 로그인과 권한은 다른 일이다. 붙기만 하고 권한을 안 받으면 토큰이
      // 없어서 다음 동기화가 조용히 아무 일도 안 한다.
      final a = await _user!.authorizationClient
          .authorizeScopes(const <String>[kDriveScope]);
      return a.accessToken.isNotEmpty;
    } catch (_) {
      _mark(null);
      return false;
    }
  }

  /// 드라이브 권한을 받는다 — **사람이 누른 그 자리에서** 불러야 한다.
  ///
  /// 웹에서는 권한 창이 팝업으로 열린다. 로그인 직후 우리가 알아서
  /// 부르면 브라우저가 '사람이 안 눌렀는데 열린 창'으로 보고 막는다.
  /// 그래서 이것만 따로 떼어 단추 하나를 더 뒀다.
  ///
  /// 폰·맥에서는 signIn() 안에서 이미 하므로 부를 일이 없다.
  Future<bool> authorizeDrive() async {
    final u = _user;
    if (u == null) return false;
    try {
      final a = await u.authorizationClient
          .authorizeScopes(const <String>[kDriveScope]);
      final ok = a.accessToken.isNotEmpty;
      if (ok) revision.value++;
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _mark(null);
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
