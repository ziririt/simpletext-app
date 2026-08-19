//  홈 화면 위젯 (아이폰·아이패드) — 그리기만 한다.
//
//  2026-08-19. 무엇을 그릴지는 다트가 정해서 넘긴다
//  (lib/core/widget_feed.dart). 쓸 말도 다트가 담아 보낸다 — 아홉 언어짜리
//  말 뭉치가 다트·코틀린·스위프트 세 군데로 갈라지면 반드시 어긋난다.
//  덤으로 위젯이 기기 언어가 아니라 앱에서 고른 언어를 따라간다.
//
//  잠긴 메모는 여기까지 오지 않는다. 위젯은 잠금 화면에도 뜨므로 거르는
//  일은 넘기기 전에 끝나 있어야 한다(HANDOVER 8-3절).

import SwiftUI
import WidgetKit

private let kAppGroup = "group.com.ziririt.simpletext"
private let kScheme = "skybluenote"

// MARK: - 자료

struct SBItem: Identifiable, Hashable {
  let id: String
  let title: String
  let preview: String
}

struct SBFeed {
  var title: String
  var empty: String
  var items: [SBItem]
}

/// 앱이 서랍(App Group)에 넣어 둔 글을 읽는다.
///
/// 판 번호를 본다. 앱을 지웠다 깔아도 위젯은 옛 글을 들고 있을 수 있다.
/// 모르는 판이면 아무것도 안 그리는 편이 낫다.
func sbLoadFeed() -> SBFeed {
  let blank = SBFeed(title: "Skyblue Note", empty: "", items: [])
  guard let d = UserDefaults(suiteName: kAppGroup),
    let raw = d.string(forKey: "feed"),
    let data = raw.data(using: .utf8),
    let obj = try? JSONSerialization.jsonObject(with: data),
    let j = obj as? [String: Any],
    (j["v"] as? Int) == 1
  else { return blank }

  var items: [SBItem] = []
  if let arr = j["items"] as? [[String: Any]] {
    for it in arr {
      let id = it["id"] as? String ?? ""
      if id.isEmpty { continue }
      items.append(
        SBItem(
          id: id,
          title: it["title"] as? String ?? "",
          preview: it["preview"] as? String ?? ""))
    }
  }
  return SBFeed(
    title: j["title"] as? String ?? blank.title,
    empty: j["empty"] as? String ?? "",
    items: items)
}

struct SBEntry: TimelineEntry {
  let date: Date
  let feed: SBFeed
}

struct SBProvider: TimelineProvider {
  func placeholder(in context: Context) -> SBEntry {
    SBEntry(
      date: Date(),
      feed: SBFeed(
        title: "Skyblue Note", empty: "",
        items: [
          SBItem(id: "-", title: "테슬라 8월 셋째 주 정리", preview: "실적과 인도량, 그리고 다음 분기"),
          SBItem(id: "-", title: "장 볼 것", preview: "우유 · 사과 · 커피"),
          SBItem(id: "-", title: "읽을 것", preview: "쌓아 둔 글 다섯"),
        ]))
  }

  func getSnapshot(in context: Context, completion: @escaping (SBEntry) -> Void) {
    completion(SBEntry(date: Date(), feed: sbLoadFeed()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SBEntry>) -> Void) {
    // 다음 갱신을 예약하지 않는다(.never). 앱이 메모를 저장할 때마다
    // 직접 부른다 — 시계로 깨우면 배터리만 먹고 얻는 것이 없다.
    completion(Timeline(entries: [SBEntry(date: Date(), feed: sbLoadFeed())], policy: .never))
  }
}

// MARK: - 화면

struct SBWidgetView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family
  let entry: SBEntry

  /// 앱 테마(AppC)의 강조색을 손으로 옮겨 적은 값. 위젯은 플러터가 그리지
  /// 않으므로 테마를 물려받을 수 없다. 앱 색을 바꾸면 여기도 같이 고칠 것
  /// (안드로이드는 res/values/widget_colors.xml).
  private var accent: Color {
    scheme == .dark
      ? Color(red: 0x4F / 255, green: 0xC3 / 255, blue: 0xF7 / 255)
      : Color(red: 0x00 / 255, green: 0x70 / 255, blue: 0xBE / 255)
  }

  private var maxRows: Int { family == .systemLarge ? 6 : 3 }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.feed.title)
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(accent)
          .lineLimit(1)
        Spacer()
        Link(destination: sbURL(host: "new", id: nil)) {
          Image(systemName: "square.and.pencil")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(accent)
        }
      }
      .padding(.bottom, 7)

      if entry.feed.items.isEmpty {
        Spacer()
        Text(entry.feed.empty)
          .font(.system(size: 13))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
        Spacer()
      } else {
        ForEach(Array(entry.feed.items.prefix(maxRows).enumerated()), id: \.offset) { i, it in
          if i > 0 {
            Divider().padding(.vertical, 1)
          }
          Link(destination: sbURL(host: "note", id: it.id)) {
            VStack(alignment: .leading, spacing: 1) {
              Text(it.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
              if !it.preview.isEmpty {
                Text(it.preview)
                  .font(.system(size: 12))
                  .foregroundColor(.secondary)
                  .lineLimit(1)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
          }
        }
        Spacer(minLength: 0)
      }
    }
  }
}

/// 위젯에서 앱으로 들어가는 주소.
///
/// `homeWidget` 이 반드시 붙어야 한다. home_widget 플러그인이 그 열쇠말이
/// 있는 주소만 '위젯에서 온 것'으로 친다(isWidgetUrl). 없으면 앱은 열리되
/// 어느 메모로 가야 하는지 아무도 모른다.
func sbURL(host: String, id: String?) -> URL {
  var s = "\(kScheme)://\(host)?homeWidget=1"
  if let id = id, !id.isEmpty {
    let safe = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? id
    s += "&id=\(safe)"
  }
  return URL(string: s) ?? URL(string: "\(kScheme)://home?homeWidget=1")!
}

// MARK: - 등록

@main
struct SkyblueWidget: Widget {
  // 다트의 WidgetBridge.iosWidget 과 **글자 하나까지 같아야 한다.**
  // 어긋나면 갱신을 불러도 아무 일도 안 일어나고, 오류도 안 난다.
  let kind = "SkyblueWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SBProvider()) { entry in
      if #available(iOS 17.0, *) {
        SBWidgetView(entry: entry)
          .padding(14)
          .containerBackground(.background, for: .widget)
      } else {
        SBWidgetView(entry: entry).padding(14)
      }
    }
    .configurationDisplayName("Skyblue Note")
    .description("최근 메모")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
