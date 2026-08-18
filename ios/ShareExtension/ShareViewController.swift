import UIKit

/// 다른 앱의 '공유'에서 Skyblue Note 를 골랐을 때 실제로 도는 코드.
///
/// 2026-08-18 소유자 지시 — "브라우저에서 글을 보다가 블럭을 씌운 후
/// 보내기 하면 뜨는 앱에도 있으면 좋겠고."
///
/// ## 왜 이게 따로 필요한가
///
/// 파일을 여는 것(Info.plist 의 CFBundleDocumentTypes)과 **글자를 받는
/// 것**은 iOS 에서 아예 다른 길이다. 앞은 plist 한 줄이면 되지만, 뒤는
/// 별도의 앱 확장(App Extension)이 있어야 한다. 공유 시트에 이름을 올릴
/// 수 있는 것은 앱이 아니라 확장이기 때문이다.
///
/// ## 화면을 안 그리는 이유
///
/// 여기서 글을 보여 주고 '저장' 단추를 누르게 할 수도 있다. 그러지
/// 않았다. 이 앱의 쓸모는 **빠름**이고, 공유에서 우리를 고른 순간 사용자의
/// 뜻은 이미 정해져 있다. 한 번 더 확인받는 것은 배려가 아니라 지연이다.
///
/// 대신 아주 짧게 '저장했습니다'만 보여 준다. 아무 말 없이 사라지면
/// 됐는지 안 됐는지를 알 수 없고, 그 불안은 다음번에 이 길을 안 쓰게 만든다.
///
/// ## 글을 앱에게 넘기는 방법
///
/// 확장과 앱은 **서로 다른 프로세스**라 변수로 넘길 수 없다. 애플이 열어
/// 준 유일한 공용 창고가 앱 그룹(App Group)이고, 거기 파일로 놓아 둔다.
/// 앱이 다음에 깨어날 때 그 창고를 비우며 가져간다.
///
/// 확장에서 앱을 직접 여는 방법도 있기는 하다. 응답 사슬을 뒤져 UIApplication
/// 을 찾아내 openURL 을 부르는 것인데, 애플이 열어 준 길이 아니라 심사에서
/// 걸릴 수 있다. **남의 집 뒷문으로 들어가는 편의는 쓰지 않는다.**
class ShareViewController: UIViewController {
  static let appGroup = "group.com.ziririt.simpletext"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    Task {
      let text = await extractText()
      if let t = text, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        save(t)
        await flash(NSLocalizedString("saved", value: "Skyblue Note에 저장했습니다",
                                      comment: ""))
      } else {
        await flash(NSLocalizedString("empty", value: "가져올 글이 없습니다",
                                      comment: ""))
      }
      extensionContext?.completeRequest(returningItems: nil)
    }
  }

  // MARK: - 글 꺼내기

  /// 받을 수 있는 것들. 순서가 곧 우선순위다.
  ///
  /// UTType(iOS 14+) 대신 날문자열을 쓴다. 확장의 최소 버전을 14로 올려서
  /// 피할 수도 있지만, 그러면 iOS 13 기기에서만 공유 시트에 우리가 안 뜬다.
  /// **되는 기기와 안 되는 기기가 갈리는 것**은 사용자에게 설명할 수 없는
  /// 종류의 차이다.
  ///
  /// UTType 이 감싸고 있는 것은 결국 이 문자열들이고, 이 값들은 iOS 13에도
  /// 있으며 앞으로도 안 바뀐다. 감싼 것을 벗기면 버전 문제가 사라진다.
  private static let kinds = [
    "public.plain-text",
    "public.text",
    "public.url",
    "public.file-url",
  ]

  /// 공유로 들어오는 것은 한 가지가 아니다. 고른 글자일 수도, 웹 주소일
  /// 수도, 파일일 수도 있다. 셋 다 받는다 — 사용자에게는 다 '이 글'이다.
  private func extractText() async -> String? {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }
    for item in items {
      for provider in item.attachments ?? [] {
        for kind in Self.kinds {
          if let t = await load(provider, kind) { return t }
        }
      }
    }
    return nil
  }

  private func load(_ provider: NSItemProvider, _ kind: String) async -> String? {
    guard provider.hasItemConformingToTypeIdentifier(kind) else { return nil }
    return await withCheckedContinuation { cont in
      provider.loadItem(forTypeIdentifier: kind, options: nil) { data, _ in
        cont.resume(returning: Self.toText(data))
      }
    }
  }

  private static func toText(_ data: Any?) -> String? {
    if let s = data as? String { return s }
    if let url = data as? URL {
      // 파일이면 읽고, 웹 주소면 주소 자체가 그 사람이 보내려던 것이다.
      if url.isFileURL {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let d = try? Data(contentsOf: url) {
          return String(data: d, encoding: .utf8)
            ?? String(data: d, encoding: .utf16)
            ?? String(data: d, encoding: .isoLatin1)
        }
        return nil
      }
      return url.absoluteString
    }
    if let d = data as? Data { return String(data: d, encoding: .utf8) }
    if let a = data as? NSAttributedString { return a.string }
    return nil
  }

  // MARK: - 창고에 놓기

  /// 파일 이름에 시각을 넣는 이유: 앱을 안 켠 채로 여러 번 보낼 수 있다.
  /// 한 이름을 쓰면 나중 것이 앞엣것을 덮어써서 조용히 사라진다.
  private func save(_ text: String) {
    let fm = FileManager.default
    guard let root = fm.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)
    else { return }
    let box = root.appendingPathComponent("ShareInbox", isDirectory: true)
    try? fm.createDirectory(at: box, withIntermediateDirectories: true)
    let name = String(format: "%.0f-%@.txt", Date().timeIntervalSince1970 * 1000,
                      UUID().uuidString.prefix(6) as CVarArg)
    try? text.write(to: box.appendingPathComponent(name), atomically: true, encoding: .utf8)
  }

  // MARK: - 아주 짧은 알림

  private func flash(_ message: String) async {
    let label = PaddedLabel()
    label.text = message
    label.textColor = .white
    label.backgroundColor = UIColor.black.withAlphaComponent(0.82)
    label.font = .systemFont(ofSize: 15, weight: .semibold)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.layer.cornerRadius = 14
    label.layer.masksToBounds = true
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
    ])
    try? await Task.sleep(nanoseconds: 700_000_000)
  }
}

/// 글자 둘레에 여백을 두는 라벨. UILabel 은 여백을 안 주므로 한 겹 씌운다.
private final class PaddedLabel: UILabel {
  private let inset = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: inset))
  }

  override var intrinsicContentSize: CGSize {
    let s = super.intrinsicContentSize
    return CGSize(width: s.width + inset.left + inset.right,
                  height: s.height + inset.top + inset.bottom)
  }
}
