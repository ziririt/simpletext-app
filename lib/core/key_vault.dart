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

import 'dart:math';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyVault {
  KeyVault._();

  static const String _k = 'aiKey';
  static const String _kDevice = 'deviceKey';
  static const String _kBackend = 'syncBackend';
  static const FlutterSecureStorage _s = FlutterSecureStorage();

  /// 애플 기기인가. 키체인의 '함께 다니는 칸'은 여기에만 있다.
  ///
  /// kIsWeb 을 먼저 보는 까닭: 웹에서 defaultTargetPlatform 은 브라우저를
  /// 돌리는 컴퓨터의 운영체제를 답한다. 맥에서 크롬을 열면 macOS 라고
  /// 하는데, 그 자리에 키체인은 없다.
  static bool get _apple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// 아이클라우드 키체인을 타는 칸.
  ///
  /// 2026-08-20 소유자 지시 — "최소한 아이클라우드는 하자."
  ///
  /// 이 길이 iCloud Drive(메모가 가는 길)보다 나은 까닭은 **종단간
  /// 암호화**다. 열쇠를 사용자의 기기들만 갖는다. 애플 서버에는 열지
  /// 못하는 덩어리만 지나간다. 그래서 '애플을 믿는다'가 아니라 '애플이
  /// 볼 수 있는 구조가 아니다'가 된다.
  ///
  /// accessibility 는 기본값(unlocked)을 그대로 둔다. *_this_device 로
  /// 두면 새 기기로 안 넘어가는데, 그러면 켜 놓고도 안 옮겨진다.
  static const IOSOptions _roamIos = IOSOptions(synchronizable: true);
  static const MacOsOptions _roamMac = MacOsOptions(synchronizable: true);
  static const IOSOptions _hereIos = IOSOptions();
  static const MacOsOptions _hereMac = MacOsOptions();

  /// 없으면 빈 문자열. 키체인이 없는 자리(웹 등)에서도 앱은 떠야 하므로
  /// 실패를 밖으로 던지지 않는다 — 키가 없는 것과 같이 다룬다.
  /// 두 칸을 다 본다. 함께 다니는 칸이 먼저다.
  ///
  /// 키체인은 synchronizable 값이 **찾는 조건의 일부**다. true 로 넣은
  /// 것은 false 로 찾으면 안 나온다 — 같은 이름인데도 없는 것처럼 보인다.
  /// 그래서 스위치를 켜고 끌 때 키가 사라진 것처럼 보이는 사고가 난다.
  ///
  /// 읽을 때 두 칸을 다 보면 그 사고가 원리적으로 안 난다. 스위치가
  /// 지금 어느 쪽인지 **읽는 쪽은 알 필요가 없다** — 아는 곳이 늘면
  /// 어긋날 곳도 는다.
  static Future<String> read() async {
    if (!_apple) {
      try {
        return (await _s.read(key: _k)) ?? '';
      } catch (_) {
        return '';
      }
    }
    for (final roam in const [true, false]) {
      try {
        final got = await _s.read(
          key: _k,
          iOptions: roam ? _roamIos : _hereIos,
          mOptions: roam ? _roamMac : _hereMac,
        );
        if (got != null && got.isNotEmpty) return got;
      } catch (_) {}
    }
    return '';
  }

  /// 이 기기의 이름표. **앱을 지웠다 깔아도 같은 값이 나온다.**
  ///
  /// 2026-08-18 소유자 지시 — "각 기기마다 업데이트하더라도 기기별로
  /// 설정값이 유지되기를 바란다."
  ///
  /// 기기별로 설정을 두려면 '이 기기가 저 기기다'를 알아볼 이름이 있어야
  /// 한다. 그런데 쓸 만한 이름이 마땅치 않다.
  ///   identifierForVendor — 우리 앱을 전부 지우면 새 값이 나온다. 개발
  ///     중에는 매번 바뀌므로 하필 우리가 필요한 순간에 못 쓴다.
  ///   기기 이름(UIDevice.name) — iOS 16부터 별도 자격이 있어야 진짜
  ///     이름을 준다. 없으면 'iPhone' 같은 기종명이라 두 대를 못 가른다.
  ///
  /// 그래서 우리가 직접 만들어 **키체인에** 둔다. 키체인은 앱을 지워도
  /// 남는 자리이고, 우리는 이미 AI 키 때문에 그 자리를 쓰고 있다. 새 창고를
  /// 여는 대신 열려 있는 창고를 쓴다.
  ///
  /// 실패하면 빈 문자열이다. 그때는 기기별 설정을 포기하고 예전처럼 이
  /// 기기 안에만 둔다 — 못 하는 것과 잘못하는 것은 다르다.
  static Future<String> deviceKey() async {
    try {
      final got = await _s.read(key: _kDevice);
      if (got != null && got.isNotEmpty) return got;
      final r = Random.secure();
      final made = List.generate(16, (_) => r.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await _s.write(key: _kDevice, value: made);
      return made;
    } catch (_) {
      return '';
    }
  }

  /// 어느 창고를 쓰기로 했나. **앱을 지웠다 깔아도 남는다.**
  ///
  /// 2026-08-20 — 하루에 여덟 번, 사장님이 고른 '구글 드라이브'가 지워졌다.
  /// 새 판을 기기에 넣을 때마다 앱의 자료 그릇이 새로 파이고 그 안의
  /// SharedPreferences 가 통째로 사라지기 때문이다. 글자 크기와 배경은 구름에서
  /// 되살아나는데 창고 고르기만은 구름에 안 올린다 — 그건 기기마다 다른
  /// 선택이라서다. 그래서 **그것 하나만** 못 돌아왔다.
  ///
  /// 실사용자도 앱을 지웠다 깔면 같은 일을 겪는다. 그리고 안드로이드에서는
  /// 그 순간 동기화가 통째로 멈춘다 — 기본값 icloud 는 안드로이드에서 안 돈다.
  /// **조용히 멈추는 고장은 사용자가 못 알아챈다.**
  ///
  /// 비밀이 아닌 값을 비밀 창고에 두는 것이 어색하긴 하다. 다만 아이폰에서
  /// 앱을 지워도 남는 자리는 여기뿐이고, 우리는 이미 이 창고를 두 가지로
  /// 쓰고 있다(AI 키, 기기 이름표). **새 창고를 여는 대신 열려 있는 창고를
  /// 쓴다** — deviceKey 를 여기 둔 것과 같은 까닭이다.
  static Future<String> readBackend() async {
    try {
      return (await _s.read(key: _kBackend)) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> writeBackend(String v) async {
    try {
      if (v.trim().isEmpty) {
        await _s.delete(key: _kBackend);
      } else {
        await _s.write(key: _kBackend, value: v);
      }
    } catch (_) {}
  }

  /// 빈 값을 쓰면 지운다. 빈 문자열을 남겨 두면 '지운 것'과 '안 넣은 것'이
  /// 구별되지 않는다.
  /// 어느 칸에 쓸지는 **부르는 쪽이 정한다.**
  ///
  /// 창고가 스스로 설정을 들여다보게 만들 수도 있었다. 그러면 설정을
  /// 아는 곳이 두 군데가 된다 — 오늘 열한 번 겪은 그 병이다.
  /// 창고는 시키는 대로만 한다.
  ///
  /// 쓰면서 **반대쪽 칸을 지운다.** 두 칸에 다 남아 있으면 어느 것이
  /// 참인지 알 수 없고, 그런 물건은 반드시 어긋난 뒤에야 발견된다.
  ///
  /// 애플이 아닌 자리에서는 칸이 하나뿐이다. 거기서 '반대쪽을 지운다'를
  /// 그대로 하면 **방금 쓴 것을 지운다** — 안드로이드에서 키가
  /// 사라지는 사고가 정확히 그 모양이다.
  static Future<void> write(String v, {bool roam = false}) async {
    final gone = v.trim().isEmpty;
    if (!_apple) {
      try {
        if (gone) {
          await _s.delete(key: _k);
        } else {
          await _s.write(key: _k, value: v);
        }
      } catch (_) {}
      return;
    }
    try {
      if (gone) {
        // 지울 때는 두 칸을 다 지운다.
        await _s.delete(key: _k, iOptions: _roamIos, mOptions: _roamMac);
        await _s.delete(key: _k, iOptions: _hereIos, mOptions: _hereMac);
        return;
      }
      await _s.write(
        key: _k,
        value: v,
        iOptions: roam ? _roamIos : _hereIos,
        mOptions: roam ? _roamMac : _hereMac,
      );
      await _s.delete(
        key: _k,
        iOptions: roam ? _hereIos : _roamIos,
        mOptions: roam ? _hereMac : _roamMac,
      );
    } catch (_) {}
  }
}
