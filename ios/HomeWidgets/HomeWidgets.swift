import SwiftUI
import WidgetKit

enum WidgetGroup {
  static let id = "group.com.jobplanner.jobPlanner"
  static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

struct ImageEntry: TimelineEntry {
  let date: Date
  let empty: String
  let isDark: Bool
  let smallPath: String?
  let mediumPath: String?
  let largePath: String?
}

struct ImageProvider: TimelineProvider {
  let smallKey: String?
  let mediumKey: String
  let largeKey: String
  let fallbackKey: String?
  let emptyKey: String
  let defaultEmpty: String

  func placeholder(in context: Context) -> ImageEntry {
    ImageEntry(
      date: Date(),
      empty: defaultEmpty,
      isDark: false,
      smallPath: nil,
      mediumPath: nil,
      largePath: nil
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ImageEntry) -> Void) {
    completion(load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ImageEntry>) -> Void) {
    completion(Timeline(entries: [load()], policy: .after(nextMidnight())))
  }

  private func load() -> ImageEntry {
    let data = WidgetGroup.defaults
    return ImageEntry(
      date: Date(),
      empty: data.string(forKey: emptyKey) ?? defaultEmpty,
      isDark: data.bool(forKey: "is_dark"),
      smallPath: smallKey.flatMap { readablePath(data.string(forKey: $0)) },
      mediumPath: readablePath(data.string(forKey: mediumKey)),
      largePath: readablePath(data.string(forKey: largeKey))
        ?? fallbackKey.flatMap { readablePath(data.string(forKey: $0)) }
    )
  }
}

struct FillImageView: View {
  @Environment(\.widgetFamily) private var family
  var entry: ImageEntry

  var body: some View {
    if let path = pathForFamily, let image = UIImage(contentsOfFile: path) {
      Image(uiImage: image)
        .resizable()
        .interpolation(.high)
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .widgetEdgeFill(isDark: entry.isDark)
    } else {
      Text(entry.empty)
        .font(.system(size: 14))
        .foregroundStyle(Color(red: 0.580, green: 0.639, blue: 0.722))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetEdgeFill(isDark: entry.isDark)
    }
  }

  private var pathForFamily: String? {
    switch family {
    case .systemSmall:
      return entry.smallPath ?? entry.mediumPath ?? entry.largePath
    case .systemMedium:
      return entry.mediumPath ?? entry.largePath ?? entry.smallPath
    default:
      return entry.largePath ?? entry.mediumPath ?? entry.smallPath
    }
  }
}

struct TodayWidget: Widget {
  let kind = "TodayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
      TodayWidgetView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("오늘")
    .description("오늘의 일정을 보여줘요")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .systemLarge,
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline,
    ])
  }
}

struct TodayEntry: TimelineEntry {
  let date: Date
  let home: ImageEntry
  let lock: LockEntry
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(
      date: Date(),
      home: ImageEntry(
        date: Date(),
        empty: "오늘 일정이 없어요",
        isDark: false,
        smallPath: nil,
        mediumPath: nil,
        largePath: nil
      ),
      lock: LockEntry(
        date: Date(),
        total: 3,
        remaining: 3,
        items: [
          LockItem(title: "면접 준비", time: "14:00", color: 0xFF3B82F6),
          LockItem(title: "자소서", time: "", color: 0xFF8B5CF6),
          LockItem(title: "코딩테스트", time: "19:00", color: 0xFF22C55E),
        ],
        inline: "오늘 할 일 3개"
      )
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    completion(load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    completion(Timeline(entries: [load()], policy: .after(nextMidnight())))
  }

  private func load() -> TodayEntry {
    let data = WidgetGroup.defaults
    let image = ImageProvider(
      smallKey: "today_image_small",
      mediumKey: "today_image_medium",
      largeKey: "today_image_large",
      fallbackKey: nil,
      emptyKey: "today_empty",
      defaultEmpty: "오늘 일정이 없어요"
    )
    return TodayEntry(date: Date(), home: image.loadForToday(), lock: LockEntry.load())
  }
}

private extension ImageProvider {
  func loadForToday() -> ImageEntry {
    let data = WidgetGroup.defaults
    return ImageEntry(
      date: Date(),
      empty: data.string(forKey: emptyKey) ?? defaultEmpty,
      isDark: data.bool(forKey: "is_dark"),
      smallPath: smallKey.flatMap { readablePath(data.string(forKey: $0)) },
      mediumPath: readablePath(data.string(forKey: mediumKey)),
      largePath: readablePath(data.string(forKey: largeKey))
        ?? fallbackKey.flatMap { readablePath(data.string(forKey: $0)) }
    )
  }
}

struct TodayWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.widgetContentMargins) private var margins
  var entry: TodayEntry

  var body: some View {
    switch family {
    case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
      FillImageView(entry: entry.home)
        .padding(margins.inverted)
    case .accessoryCircular:
      LockCircularView(entry: entry.lock)
        .containerBackground(for: .widget) {
          AccessoryWidgetBackground()
        }
    case .accessoryInline:
      LockInlineView(entry: entry.lock)
    case .accessoryRectangular:
      LockRectangularView(entry: entry.lock)
        .containerBackground(for: .widget) {
          AccessoryWidgetBackground()
        }
    default:
      LockRectangularView(entry: entry.lock)
        .containerBackground(for: .widget) {
          AccessoryWidgetBackground()
        }
    }
  }
}

struct TomorrowWidget: Widget {
  let kind = "TomorrowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImageProvider(
        smallKey: "tomorrow_image_small",
        mediumKey: "tomorrow_image_medium",
        largeKey: "tomorrow_image_large",
        fallbackKey: nil,
        emptyKey: "tomorrow_empty",
        defaultEmpty: "내일 일정이 없어요"
      )
    ) { entry in
      FillImageView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("내일")
    .description("내일의 일정을 보여줘요")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct TodayTomorrowWidget: Widget {
  let kind = "TodayTomorrowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImageProvider(
        smallKey: "today_tomorrow_image_small",
        mediumKey: "today_tomorrow_image_medium",
        largeKey: "today_tomorrow_image_large",
        fallbackKey: nil,
        emptyKey: "today_tomorrow_empty",
        defaultEmpty: "오늘과 내일 일정이 없어요"
      )
    ) { entry in
      FillImageView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("오늘과 내일")
    .description("오늘과 내일의 일정을 보여줘요")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct WeekTimetableWidget: Widget {
  let kind = "WeekTimetableWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImageProvider(
        smallKey: nil,
        mediumKey: "week_timetable_image_medium",
        largeKey: "week_timetable_image_large",
        fallbackKey: "week_timetable_image",
        emptyKey: "week_timetable_empty",
        defaultEmpty: "이번 주 일정이 없어요"
      )
    ) { entry in
      FillImageView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("일주일")
    .description("일주일의 일정을 보여줘요")
    .supportedFamilies([.systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct CompactTodayWidget: Widget {
  let kind = "CompactTodayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImageProvider(
        smallKey: "today_glance_image",
        mediumKey: "today_glance_image",
        largeKey: "today_glance_image",
        fallbackKey: nil,
        emptyKey: "today_glance_empty",
        defaultEmpty: "오늘 일정이 없어요"
      )
    ) { entry in
      FillImageView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("오늘 간단히")
    .description("오늘의 할 일을 간단히 보여줘요")
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct CompactTomorrowWidget: Widget {
  let kind = "CompactTomorrowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: ImageProvider(
        smallKey: "tomorrow_glance_image",
        mediumKey: "tomorrow_glance_image",
        largeKey: "tomorrow_glance_image",
        fallbackKey: nil,
        emptyKey: "tomorrow_glance_empty",
        defaultEmpty: "내일 일정이 없어요"
      )
    ) { entry in
      FillImageView(entry: entry)
        .widgetURL(URL(string: "jobplanner://home"))
    }
    .configurationDisplayName("내일 간단히")
    .description("내일의 할 일을 간단히 보여줘요")
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct LockItem {
  let title: String
  let time: String
  let color: Int
}

struct LockEntry: TimelineEntry {
  let date: Date
  let total: Int
  let remaining: Int
  let items: [LockItem]
  let inline: String

  static func load() -> LockEntry {
    let data = WidgetGroup.defaults
    let items = (0..<3).compactMap { index -> LockItem? in
      let title = data.string(forKey: "lock_item_\(index)_title") ?? ""
      guard !title.isEmpty else { return nil }
      return LockItem(
        title: title,
        time: data.string(forKey: "lock_item_\(index)_time") ?? "",
        color: intValue(data, "lock_item_\(index)_color")
      )
    }
    return LockEntry(
      date: Date(),
      total: intValue(data, "lock_total"),
      remaining: intValue(data, "lock_remaining"),
      items: items,
      inline: data.string(forKey: "lock_inline") ?? "오늘 일정이 없어요"
    )
  }
}

struct LockCircularView: View {
  var entry: LockEntry

  var body: some View {
    let total = max(entry.total, 1)
    let done = min(max(entry.total - entry.remaining, 0), total)
    Gauge(value: Double(done), in: 0...Double(total)) {
      Text("오늘")
    } currentValueLabel: {
      if entry.total > 0 && entry.remaining == 0 {
        Image(systemName: "checkmark")
          .font(.system(size: 18, weight: .bold))
      } else {
        Text("\(entry.remaining)")
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .minimumScaleFactor(0.6)
      }
    }
    .gaugeStyle(.accessoryCircularCapacity)
    .widgetAccentable()
  }
}

struct LockRectangularView: View {
  var entry: LockEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if entry.items.isEmpty {
        Text("일정이 없어요")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      } else {
        ForEach(Array(entry.items.enumerated()), id: \.offset) { _, item in
          LockEventRow(item: item)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetAccentable()
  }
}

struct LockEventRow: View {
  var item: LockItem

  var body: some View {
    HStack(alignment: .center, spacing: 7) {
      Circle()
        .fill(categoryColor(item.color))
        .frame(width: 11, height: 11)
        .widgetAccentable(false)
      if !item.time.isEmpty {
        Text(item.time)
          .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .layoutPriority(1)
      }
      Text(item.title)
        .font(.system(size: 15, weight: .medium))
        .lineLimit(1)
    }
  }
}

struct LockInlineView: View {
  var entry: LockEntry

  var body: some View {
    Label {
      Text(entry.inline)
    } icon: {
      Image(systemName: entry.remaining == 0 && entry.total > 0
        ? "checkmark.circle.fill"
        : "checklist")
    }
    .widgetAccentable()
  }
}

@main
struct HomeWidgetsBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
    TomorrowWidget()
    TodayTomorrowWidget()
    WeekTimetableWidget()
    CompactWidgets()
  }
}

struct CompactWidgets: WidgetBundle {
  var body: some Widget {
    CompactTodayWidget()
    CompactTomorrowWidget()
  }
}

private extension EdgeInsets {
  var inverted: EdgeInsets {
    EdgeInsets(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
  }
}

private extension View {
  @ViewBuilder
  func widgetEdgeFill(isDark: Bool) -> some View {
    let fallback = Color(
      red: isDark ? 0.086 : 1,
      green: isDark ? 0.125 : 1,
      blue: isDark ? 0.196 : 1
    )
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { fallback }
    } else {
      background(fallback)
    }
  }
}

private func readablePath(_ path: String?) -> String? {
  guard let path, !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
    return nil
  }
  return path
}

private func categoryColor(_ argb: Int) -> Color {
  let value = argb == 0 ? 0xFF3B82F6 : argb
  return Color(
    red: Double((value >> 16) & 0xFF) / 255,
    green: Double((value >> 8) & 0xFF) / 255,
    blue: Double(value & 0xFF) / 255
  )
}

private func intValue(_ defaults: UserDefaults, _ key: String) -> Int {
  let raw = defaults.object(forKey: key)
  if let number = raw as? Int { return number }
  if let number = raw as? NSNumber { return number.intValue }
  if let text = raw as? String { return Int(text) ?? 0 }
  return 0
}

private func nextMidnight() -> Date {
  let calendar = Calendar.current
  let start = calendar.startOfDay(for: Date())
  let next = calendar.date(byAdding: .day, value: 1, to: start) ?? Date().addingTimeInterval(86_400)
  return calendar.date(byAdding: .second, value: 8, to: next) ?? next
}
