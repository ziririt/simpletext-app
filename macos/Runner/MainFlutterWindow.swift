import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// 파일 메뉴의 임자. 아래 주석 참고 — 놓으면 메뉴가 죽는다.
  private var menuBridge: AppMenuBridge?

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

    // 2026-08-17 소유자 신고 — "맥용 앱에서 메뉴 중 '파일'이 아예 없는데?"
    // 우리가 지운 게 아니라 플러터의 맥 틀에 처음부터 없다(문서를 다루지
    // 않는 앱을 전제로 뺐다). 우리는 문서를 다루는 앱이다.
    //
    // 다리를 변수에 붙들어 둔다. 메뉴 항목이 이 객체를 target으로 삼는데,
    // NSMenuItem의 target은 약한 참조라 여기서 안 잡으면 곧 사라지고
    // 메뉴가 회색으로 죽는다.
    menuBridge = AppMenuBridge(
      channel: FlutterMethodChannel(
        name: "skyblue/menu",
        binaryMessenger: flutterViewController.engine.binaryMessenger))

    super.awakeFromNib()
  }
}

/// 맥 상단 메뉴에 '파일'을 끼워 넣는다.
///
/// 2026-08-17 — 플러터의 맥 틀(MainMenu.xib)에는 파일 메뉴가 없다. 앱 ·
/// 편집 · 보기 · 윈도우 · 도움말뿐이다. 맥 사용자에게 파일 메뉴가 없다는
/// 것은 "이 앱은 맥 앱이 아니다"라는 신호나 마찬가지다 — ⌘N도 ⌘O도 안
/// 먹는다는 뜻이니까.
///
/// 플러터의 PlatformMenuBar는 쓰지 않았다. 그건 메뉴 막대를 **통째로**
/// 갈아 끼우기 때문에, 지금 편집 메뉴에 들어 있는 맞춤법 · 대체 · 변환 ·
/// 받아쓰기 · 애플 글쓰기 도구가 전부 사라진다. 파일 메뉴 하나를 얻으려고
/// 열을 잃는 거래다. 그래서 있는 막대에 하나만 끼워 넣는다.
///
/// 글자는 다트가 넘긴다. 아홉 언어 문구를 여기 또 한 벌 두면 반드시
/// 어긋난다 — 이 앱은 이미 아이클라우드 다리에서 두 벌을 겪고 있다.
final class AppMenuBridge: NSObject {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "install",
        let titles = call.arguments as? [String: String]
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      // 메뉴는 반드시 주 스레드에서 손댄다.
      DispatchQueue.main.async {
        self?.install(titles)
        result(true)
      }
    }
  }

  @objc private func fire(_ sender: NSMenuItem) {
    guard let id = sender.representedObject as? String else { return }
    channel.invokeMethod("menu", arguments: id)
  }

  private static let slot = NSUserInterfaceItemIdentifier("skyblueFile")

  private func install(_ t: [String: String]) {
    guard let main = NSApp.mainMenu else { return }
    // 다시 부르면 옛것을 걷어내고 새로 단다. 언어를 바꾸면 다시 부른다.
    if let old = main.items.first(where: { $0.identifier == AppMenuBridge.slot }) {
      main.removeItem(old)
    }

    let menu = NSMenu(title: t["file"] ?? "File")

    func add(_ id: String, _ key: String, _ mask: NSEvent.ModifierFlags = .command) {
      let it = NSMenuItem(
        title: t[id] ?? id, action: #selector(fire(_:)), keyEquivalent: key)
      it.target = self
      it.representedObject = id
      it.keyEquivalentModifierMask = mask
      menu.addItem(it)
    }

    add("new", "n")
    menu.addItem(.separator())
    add("import", "o")
    add("exportMd", "e", [.command, .shift])
    add("backup", "")
    menu.addItem(.separator())
    // 닫기는 우리가 처리하지 않는다. 대상을 비워 두면 맥이 알아서 지금
    // 맨 앞 창에게 보낸다 — 애플이 정해 둔 길이고, 우리가 창을 관리하는
    // 것보다 언제나 낫다.
    menu.addItem(
      NSMenuItem(
        title: t["close"] ?? "Close",
        action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

    // 앱 메뉴의 '설정…'을 잇는다.
    //
    // 2026-08-17 소유자 신고 — "설정이 비활성화되어 있다. 왜?"
    // 플러터의 맥 틀에 그 줄이 이렇게 들어 있다:
    //     <menuItem title="Preferences…" keyEquivalent="," id="..."/>
    // **동작이 아예 없다.** 제목과 단축키만 있고 누르면 무엇을 할지가
    // 비어 있다. 맥은 응답할 사람이 없는 항목을 자동으로 회색 처리하므로,
    // 회색인 것이 버그가 아니라 비워 둔 것이 잘못이었다.
    //
    // 애플이 이 줄을 넣어 둔 것은 '여기에 설정을 이으라'는 자리 표시다.
    // 맥 사용자는 설정을 찾을 때 ⌘,를 먼저 누른다.
    //
    // 제목이 아니라 단축키(,)로 찾는다. 제목은 맥 판이 올라가며 바뀌었고
    // (Preferences… → Settings…) 언어에 따라서도 다르지만, ⌘,는 맥이
    // 생긴 이래 한 번도 안 바뀌었다.
    if let appMenu = main.items.first?.submenu,
      let prefs = appMenu.items.first(where: { $0.keyEquivalent == "," })
    {
      prefs.title = t["settings"] ?? prefs.title
      prefs.target = self
      prefs.action = #selector(fire(_:))
      prefs.representedObject = "settings"
    }

    let holder = NSMenuItem()
    holder.identifier = AppMenuBridge.slot
    holder.submenu = menu
    // 애플 메뉴 다음, 편집 앞. 맥의 관습이 그렇고, 관습을 깨면 사용자가
    // 없는 자리를 뒤진다.
    main.insertItem(holder, at: min(1, main.items.count))
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
          // 아이폰 쪽과 같은 이유로 셋을 넘긴다(AppDelegate.swift 주석 참고).
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
        // 맥에서는 애플 계정 환경설정 창을 바로 열 수 있다.
        // 열렸는지를 그대로 돌려준다(아이폰 쪽과 같은 이유).
        if let url = URL(
          string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane")
        {
          result(NSWorkspace.shared.open(url))
        } else {
          result(false)
        }
      case "clipboardSource":
        // 2026-08-27 밤 — 여기 문지기가 하나 있었다.
        //
        // 주소가 있으면 그것만 돌려주고 **HTML 은 아예 안 봤다.** 그런데
        // 주소와 HTML 은 서로를 밀어낼 이유가 없다. 둘 다 증거다. 주소
        // 하나 있다고 지문 한 뭉치를 버리고 있었던 것이다.
        //
        // 그리고 앞 4000자만 넘겼는데, 그 4000자에 표식이 하나도 없어서
        // 챗지피티를 못 잡았다(core/capture_sig.dart 2판 머리말 참고).
        // 안드로이드와 같은 8000자로 맞춘다.
        let pb = NSPasteboard.general
        var parts: [String] = []
        if let u = pb.string(forType: .URL) {
          parts.append(u)
        }
        if let h = pb.string(forType: .html) {
          parts.append(String(h.prefix(8000)))
        }
        result(parts.isEmpty ? nil : parts.joined(separator: "\n"))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 쓸 수 없는 상태면 nil — 오류가 아니라 '동기화 꺼짐'이다.
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
