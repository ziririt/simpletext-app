import UIKit
import SwiftUI

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
/// ## 확인 화면을 두는 이유 (2026-08-18 고침)
///
/// 처음엔 화면을 안 그렸다. "이 앱의 쓸모는 빠름이고, 공유에서 우리를 고른
/// 순간 사용자의 뜻은 이미 정해져 있다"고 적어 뒀다.
///
/// 소유자가 짚었다 — "메모장이나 다른 메모 앱들은 중간에 공유 확인 화면을
/// 거치는데 내 앱은 피드백 메시지만 나온다."
///
/// 애플 메모도, 다른 메모 앱도 다 판을 하나 띄운다. 그게 관성이 아니라
/// 까닭이 있는 것이었다. **바로 삼키면 되돌릴 자리가 없다.** 공유 시트에서
/// 손가락이 미끄러져 우리를 골랐을 때, 잘못 보낸 것을 취소할 곳이 어디에도
/// 없다. 취소할 수 없는 일을 확인 없이 하는 것은 빠른 것이 아니라 위험한
/// 것이다.
///
/// 그리고 확인 화면은 '무엇이 넘어가는지'를 보여 준다. 웹 페이지에서 글을
/// 고를 때 어디까지 잡혔는지는 사실 아무도 정확히 모른다. 미리 보고 아니면
/// 닫는 것 — 이건 지연이 아니라 통제다.
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
    view.backgroundColor = .systemGroupedBackground

    Task {
      let text = (await extractText()) ?? ""
      await MainActor.run { self.mount(text) }
    }
  }

  /// SwiftUI 로 그리는 이유: 이 화면은 머리줄 하나와 카드 둘이 전부다.
  /// UIKit 으로 같은 것을 만들면 제약 조건이 스무 줄 늘어나고, 다크 모드와
  /// 글자 크기 설정을 손으로 따라가야 한다. 최소 iOS 를 15로 올린 덕에
  /// 여기서는 SwiftUI 를 그냥 쓸 수 있다.
  @MainActor
  private func mount(_ text: String) {
    let root = ShareConfirmView(
      text: text,
      onCancel: { [weak self] in self?.cancelRequest() },
      onSave: { [weak self] t in self?.commit(t) })
    let host = UIHostingController(rootView: root)
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    host.didMove(toParent: self)
  }

  /// 닫기는 completeRequest 가 아니라 cancelRequest 다. 둘 다 화면은 사라지지만
  /// 보낸 앱이 받는 답이 다르다 — '했다'와 '안 했다'를 같은 말로 답하면
  /// 저쪽에서 뒷정리를 잘못한다.
  private func cancelRequest() {
    extensionContext?.cancelRequest(
      withError: NSError(domain: "com.ziririt.simpletext.ShareExtension",
                         code: NSUserCancelledError))
  }

  private func commit(_ text: String) {
    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      save(text)
    }
    extensionContext?.completeRequest(returningItems: nil)
  }

  // MARK: - 글 꺼내기

  /// 받을 수 있는 것들. 순서가 곧 우선순위다.
  ///
  /// UTType(iOS 14+) 대신 날문자열을 쓴다. 2026-08-18 에 최소 iOS 를 15로
  /// 올렸으니 이제 UTType 을 써도 되지만 되돌리지 않는다 — 이 값들은
  /// 그 자체로 맞고, 멀쩡한 것을 다시 건드릴 이유가 없다.
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
}

// MARK: - 확인 화면

private struct ShareConfirmView: View {
  let text: String
  let onCancel: () -> Void
  let onSave: (String) -> Void

  @Environment(\.colorScheme) private var scheme

  /// 앱의 하늘색을 그대로 쓴다. 확장이 앱과 다른 색을 쓰면 사용자는 이게
  /// 우리 화면인지 남의 화면인지 알 수 없다 — 공유 시트에서 이름만 보고
  /// 고른 참이라 더 그렇다.
  private var accent: Color {
    scheme == .dark
      ? Color(red: 0x4F / 255.0, green: 0xC3 / 255.0, blue: 0xF7 / 255.0)
      : Color(red: 0x00 / 255.0, green: 0x70 / 255.0, blue: 0xBE / 255.0)
  }

  private var isEmpty: Bool {
    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      content
    }
    .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
  }

  /// 가운데 제목, 왼쪽 닫기, 오른쪽 저장. 애플이 정해 둔 자리라 따른다 —
  /// 여기서 독창적일 이유가 하나도 없다.
  private var header: some View {
    ZStack {
      Text("Skyblue Note")
        .font(.system(size: 17, weight: .semibold))
      HStack {
        Button(action: onCancel) {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.primary)
            .frame(width: 32, height: 32)
            .background(Circle().fill(Color(UIColor.secondarySystemFill)))
        }
        .accessibilityLabel(Loc.close)
        Spacer()
        if !isEmpty {
          Button(action: { onSave(text) }) {
            Text(Loc.save)
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 18)
              .padding(.vertical, 9)
              .background(Capsule().fill(accent))
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var content: some View {
    if isEmpty {
      VStack {
        Spacer()
        Text(Loc.empty)
          .font(.system(size: 16))
          .foregroundColor(.secondary)
        Spacer()
      }
      .frame(maxWidth: .infinity)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text(Loc.saveWhere)
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)

        HStack(spacing: 10) {
          Image(systemName: "square.and.pencil").foregroundColor(accent)
          Text(Loc.newNote).font(.system(size: 17))
          Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14)
          .fill(Color(UIColor.secondarySystemGroupedBackground)))

        Text(Loc.helper)
          .font(.system(size: 13))
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
          .padding(.bottom, 4)

        // 미리 보기. 고칠 수는 없다 — 고치는 자리는 앱이고, 여기서까지
        // 편집을 열면 '어디서 고친 것이 남는가'가 흐려진다.
        ScrollView {
          Text(text)
            .font(.system(size: 16))
            .lineSpacing(5)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(RoundedRectangle(cornerRadius: 14)
          .fill(Color(UIColor.secondarySystemGroupedBackground)))
      }
      .padding(16)
    }
  }
}

// MARK: - 말

/// 확장에는 앱의 l10n 이 안 따라온다(서로 다른 번들이다). 문구가 다섯 개뿐이라
/// .strings 파일 아홉 벌을 두는 대신 여기 표로 둔다. 늘어나면 그때 옮긴다.
private enum Loc {
  private static var lang: String {
    let id = Locale.preferredLanguages.first ?? "en"
    if id.hasPrefix("ko") { return "ko" }
    if id.hasPrefix("ja") { return "ja" }
    if id.hasPrefix("zh") {
      return (id.contains("Hant") || id.contains("TW") || id.contains("HK"))
        ? "zh_hant" : "zh_hans"
    }
    if id.hasPrefix("es") { return "es" }
    if id.hasPrefix("pt") { return "pt" }
    if id.hasPrefix("de") { return "de" }
    if id.hasPrefix("fr") { return "fr" }
    return "en"
  }

  private static func t(_ m: [String: String]) -> String {
    m[lang] ?? m["en"] ?? ""
  }

  static var save: String {
    t([
      "ko": "저장", "en": "Save", "ja": "保存",
      "zh_hans": "保存", "zh_hant": "儲存",
      "es": "Guardar", "pt": "Salvar", "de": "Sichern", "fr": "Enregistrer",
    ])
  }

  static var close: String {
    t([
      "ko": "닫기", "en": "Close", "ja": "閉じる",
      "zh_hans": "关闭", "zh_hant": "關閉",
      "es": "Cerrar", "pt": "Fechar", "de": "Schließen", "fr": "Fermer",
    ])
  }

  static var saveWhere: String {
    t([
      "ko": "다음 위치에 저장", "en": "Save to", "ja": "保存先",
      "zh_hans": "保存到", "zh_hant": "儲存到",
      "es": "Guardar en", "pt": "Salvar em", "de": "Sichern in",
      "fr": "Enregistrer dans",
    ])
  }

  static var newNote: String {
    t([
      "ko": "새 메모", "en": "New note", "ja": "新規メモ",
      "zh_hans": "新备忘录", "zh_hant": "新備忘錄",
      "es": "Nota nueva", "pt": "Nova nota", "de": "Neue Notiz",
      "fr": "Nouvelle note",
    ])
  }

  static var helper: String {
    t([
      "ko": "이 글이 새 메모로 저장됩니다.",
      "en": "This text will be saved as a new note.",
      "ja": "このテキストは新規メモとして保存されます。",
      "zh_hans": "该文本将保存为新的备忘录。",
      "zh_hant": "這段文字將儲存為新的備忘錄。",
      "es": "Este texto se guardará como una nota nueva.",
      "pt": "Este texto será salvo como uma nova nota.",
      "de": "Dieser Text wird als neue Notiz gesichert.",
      "fr": "Ce texte sera enregistré comme une nouvelle note.",
    ])
  }

  static var empty: String {
    t([
      "ko": "가져올 글이 없습니다",
      "en": "Nothing to bring in",
      "ja": "取り込む文章がありません",
      "zh_hans": "没有可导入的内容",
      "zh_hant": "沒有可匯入的內容",
      "es": "No hay nada que importar",
      "pt": "Nada para importar",
      "de": "Nichts zu übernehmen",
      "fr": "Rien à importer",
    ])
  }
}
