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
          let signedIn = FileManager.default.ubiquityIdentityToken != nil
          let path = documentsPath()
          DispatchQueue.main.async {
            result(["path": path as Any, "signedIn": signedIn])
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
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(true)
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
  private static func documentsPath() -> String? {
    let fm = FileManager.default
    guard fm.ubiquityIdentityToken != nil else { return nil }
    guard let root = fm.url(forUbiquityContainerIdentifier: containerId) else { return nil }
    let docs = root.appendingPathComponent("Documents", isDirectory: true)
    try? fm.createDirectory(at: docs, withIntermediateDirectories: true)
    return docs.path
  }
}
