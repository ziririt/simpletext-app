import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let started = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // 2026-08-16 — 아이클라우드 다리를 여기서 연결한다.
    //
    // 새 스위프트 파일을 만들지 않은 이유: 새 파일은 Xcode 프로젝트 파일
    // (project.pbxproj)에 등록해야 컴파일되는데, 그 파일은 손으로 건드리다
    // 망가지면 빌드 전체가 죽는 자리다. 2026-08-15에 아이콘 생성 도구가
    // 실제로 이 파일을 망가뜨린 적이 있다. 이미 컴파일되는 파일 안에 넣으면
    // 그 위험이 통째로 사라진다.
    if let controller = window?.rootViewController as? FlutterViewController {
      ICloudBridge.register(messenger: controller.binaryMessenger)
    }
    return started
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// 다트에게 아이클라우드 폴더의 '경로'만 알려 주는 얇은 다리.
///
/// 동기화 로직은 여기 없다. 여기서 하는 일은 셋뿐이다.
///   1) 이 기기의 아이클라우드 폴더가 어디인지 알려 준다(없으면 nil)
///   2) 아직 안 내려받은 파일을 내려받으라고 시스템에 요청한다
///   3) 설정 앱을 열어 준다
///
/// 규칙(무엇을 남기고 무엇을 지울지)은 전부 다트의 core/sync_merge.dart에
/// 있다. 스위프트에 규칙을 두면 아이폰과 맥에 같은 코드를 두 벌 쓰게 되고,
/// 두 벌은 반드시 어긋난다.
enum ICloudBridge {
  /// 애플 개발자 계정에 등록해 둔 컨테이너. 2026-08-16 등록.
  static let containerId = "iCloud.com.ziririt.simpletext"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "skyblue/icloud", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "root":
        // url(forUbiquityContainerIdentifier:)는 느리다. 애플 문서가 주
        // 스레드에서 부르지 말라고 명시한다 — 로그인 상태를 확인하느라
        // 네트워크를 탈 수 있어서다. 여기서 막으면 앱이 켜질 때 멈춘다.
        DispatchQueue.global(qos: .userInitiated).async {
          // 2026-08-16 소유자 신고 — "꺼짐"만 뜨고 뭘 하라는 건지 모르겠다.
          // 맞는 지적이다. '꺼짐'에는 서로 다른 두 가지 원인이 있는데 그걸
          // 구분해서 알려 주지 않으면 사용자가 할 수 있는 일이 없다.
          //   ① 기기가 아이클라우드에 로그인되어 있지 않다
          //   ② 로그인은 됐는데 이 앱의 iCloud Drive 사용이 꺼져 있다
          // 그래서 경로만이 아니라 로그인 여부도 같이 넘긴다.
          // 2026-08-16 — 넘기는 값을 셋으로 늘렸다.
          //
          // 지금까지는 '로그인했는가'와 '경로가 있는가' 둘만 넘겼는데,
          // 경로가 없을 때 그 까닭이 셋이나 된다: 로그인 안 됨 / 이 앱의
          // 아이클라우드가 꺼짐 / 자리는 받았는데 폴더를 못 만듦.
          // 화면에서 "왜 안 되는지"를 정확히 말하려면 갈라서 알아야 한다.
          let fm = FileManager.default
          let signedIn = fm.ubiquityIdentityToken != nil
          let container = fm.url(forUbiquityContainerIdentifier: containerId) != nil
          let (path, err) = documentsInfo()
          DispatchQueue.main.async {
            result([
              "path": path as Any,
              "signedIn": signedIn,
              "container": container,
              "error": err as Any,
            ])
          }
        }
      case "download":
        let args = call.arguments as? [String: Any]
        let paths = args?["paths"] as? [String] ?? []
        DispatchQueue.global(qos: .utility).async {
          for p in paths {
            try? FileManager.default.startDownloadingUbiquitousItem(
              at: URL(fileURLWithPath: p))
          }
          DispatchQueue.main.async { result(true) }
        }
      case "openSettings":
        // 애플이 앱에서 열 수 있게 허용한 유일한 설정 화면은 '이 앱의
        // 설정' 페이지다. iCloud 항목으로 직접 뛰는 주소(prefs:root=CASTLE)는
        // 비공개 API라 심사에서 반려된다 — 그래서 여는 데까지만 해 주고
        // 나머지 길은 화면에서 글로 안내한다.
        // 2026-08-16 소유자 신고 — "눌러도 무반응이다."
        //
        // 열렸는지 안 열렸는지를 우리가 몰랐던 것이 문제였다. 그냥 부르고
        // 무조건 true를 돌려주고 있었으니, 실패해도 화면은 아무 말도 못
        // 한다. 완료 신호를 받아서 그대로 넘긴다 — 실패하면 화면이
        // "직접 열어 주십시오"라고 말할 수 있다.
        // 2026-08-17 — 여기에도 같은 잘못이 있었다. 0.3.38.1에서 넣은
        // canOpenURL 검사가 'app-settings:'에 대해 false를 돌려주는 바람에
        // 열어 보지도 못하고 실패로 끝났다(소유자 화면에 "설정 앱을 열지
        // 못했습니다"가 떴다).
        //
        // canOpenURL은 앱이 질의 목록에 미리 적어 둔 주소가 아니면 무조건
        // 아니라고 답한다. 물어보지 말고 그냥 연다 — 열리면 열리는 것이고,
        // 안 열리면 완료 신호가 알려 준다.
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:]) { ok in
            result(ok)
          }
        } else {
          result(false)
        }
      case "clipboardSource":
        // 붙여넣기 **직후에만** 불린다(다트 쪽 clipboard_source.dart 참고).
        // iOS 16부터 클립보드를 읽으면 확인 창이 뜨는데, 사용자가 방금
        // 붙여넣기를 눌러 글자를 읽어 온 흐름이라 그 창은 이미 지나간 뒤다.
        // 아무 때나 부르면 뜬금없는 확인 창이 뜬다.
        //
        // 여기서 찾는 것은 '어디서 복사했는가' 하나뿐이다. 글자는 이미
        // 플러터가 읽었다.
        var found: String?
        let pb = UIPasteboard.general
        if pb.hasURLs, let u = pb.url {
          found = u.absoluteString
        }
        result(found)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 컨테이너 안의 Documents 폴더. 쓸 수 없는 상태면 nil.
  ///
  /// nil이 되는 경우가 실제로 많다 — 아이클라우드에 로그인하지 않았거나,
  /// 설정에서 이 앱의 iCloud Drive를 껐거나, 자격(entitlement)이 아직
  /// 안 붙은 빌드거나. 그래서 nil은 오류가 아니라 '동기화 꺼짐'이다.
  ///
  /// 앱이 막 켜진 직후에는 준비가 안 되어 nil이 나올 수 있다. 다트 쪽에서
  /// 몇 초 간격으로 몇 번 더 물어본다.
  /// 2026-08-17 — 돌려주는 것을 (경로, 오류) 짝으로 바꿨다.
  ///
  /// 지금까지는 안 되면 그냥 nil이었다. 그래서 화면에서 할 수 있는 말이
  /// "안 됩니다"뿐이었고, 우리는 왜 안 되는지 짐작으로만 좁혀 왔다.
  /// 시스템이 준 오류 문구를 그대로 들고 오면 짐작할 일이 없다.
  private static func documentsInfo() -> (String?, String?) {
    let fm = FileManager.default
    // 2026-08-17 — 여기 문지기가 하나 있었다.
    //
    //     guard fm.ubiquityIdentityToken != nil else { return nil }
    //
    // 소유자 아이폰이 "로그인되어 있지 않습니다"를 띄웠는데 로그인은 되어
    // 있었다. 같은 계정의 맥에 우리 컨테이너 폴더가 실제로 내려와 있었고,
    // 앱 서명에도 iCloud 권한이 제대로 박혀 있었다. 계정도 권한도 되는데
    // 우리 코드가 '안 된다'고 말하고 있었던 것이다.
    //
    // ubiquityIdentityToken은 로그인이 되어 있어도 nil이 나올 수 있다 —
    // iCloud Drive가 꺼져 있거나, 계정 상태를 아직 못 받아 왔거나,
    // 시스템이 아직 이 앱에 알려 줄 준비가 안 됐거나.
    //
    // **되는지 안 되는지는 실제로 폴더를 달라고 해 보고 판단한다.**
    // 경로가 나오면 되는 것이고 안 나오면 안 되는 것이다. 미리 물어보고
    // 지레 포기하지 않는다.
    guard let root = fm.url(forUbiquityContainerIdentifier: containerId) else {
      return (nil, "container-url-nil")
    }
    let docs = root.appendingPathComponent("Documents", isDirectory: true)
    do {
      try fm.createDirectory(at: docs, withIntermediateDirectories: true)
    } catch {
      return (nil, "mkdir: \(error.localizedDescription)")
    }
    return (docs.path, nil)
  }
}
