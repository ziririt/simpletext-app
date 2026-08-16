import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 2026-08-16 — 아이클라우드 다리. 아이폰 쪽 AppDelegate.swift와 같은
    // 코드를 두 벌 둔다. 맥과 아이폰은 서로 다른 타깃이라 파일을 공유하려면
    // Xcode 프로젝트 파일을 손봐야 하는데, 그 파일은 망가지면 빌드 전체가
    // 죽는 자리다(2026-08-15에 아이콘 도구가 실제로 망가뜨렸다).
    //
    // 두 벌이라 어긋날 위험이 있지만, 여기 있는 건 '경로를 알려 준다'가
    // 전부다. 규칙은 전부 다트(core/sync_merge.dart)에 있어서 두 벌로
    // 나뉘지 않는다 — 어긋나 봐야 티가 안 나는 곳만 두 벌이라는 뜻이다.
    ICloudBridge.register(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// 다트에게 아이클라우드 폴더의 '경로'만 알려 주는 얇은 다리.
/// (아이폰 쪽 ios/Runner/AppDelegate.swift에 같은 내용이 있다.)
enum ICloudBridge {
  static let containerId = "iCloud.com.ziririt.simpletext"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "skyblue/icloud", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "root":
        // 주 스레드에서 부르면 앱이 켜질 때 멈출 수 있다(애플 문서).
        DispatchQueue.global(qos: .userInitiated).async {
          // '꺼짐'의 원인이 로그인인지 앱 설정인지 구분해서 넘긴다
          // (2026-08-16 소유자 신고: 꺼짐만 뜨면 뭘 해야 할지 모른다).
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
        // 맥에서는 애플 계정 환경설정 창을 바로 열 수 있다.
        if let url = URL(
          string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane")
        {
          NSWorkspace.shared.open(url)
        }
        result(true)
      case "clipboardSource":
        let pb = NSPasteboard.general
        var found: String?
        if let u = pb.string(forType: .URL) {
          found = u
        }
        if found == nil, let h = pb.string(forType: .html) {
          // HTML 조각은 통째로 클 수 있다. 원본 주소는 앞쪽에 있으므로
          // 앞부분만 넘긴다 — 다트로 수 메가바이트를 넘길 이유가 없다.
          found = String(h.prefix(4000))
        }
        result(found)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 쓸 수 없는 상태면 nil — 오류가 아니라 '동기화 꺼짐'이다.
  private static func documentsPath() -> String? {
    let fm = FileManager.default
    guard fm.ubiquityIdentityToken != nil else { return nil }
    guard let root = fm.url(forUbiquityContainerIdentifier: containerId) else { return nil }
    let docs = root.appendingPathComponent("Documents", isDirectory: true)
    try? fm.createDirectory(at: docs, withIntermediateDirectories: true)
    return docs.path
  }
}
