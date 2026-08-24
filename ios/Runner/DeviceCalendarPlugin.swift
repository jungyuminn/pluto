import EventKit
import Flutter
import UIKit

final class DeviceCalendarPlugin: NSObject {
  static let channelName = "job_planner/device_calendar"
  private static let maxEvents = 3000

  private let queue = DispatchQueue(label: "job_planner.device_calendar")
  private var store: EKEventStore?

  static func register(with registry: FlutterPluginRegistry) -> DeviceCalendarPlugin {
    let plugin = DeviceCalendarPlugin()
    guard let registrar = registry.registrar(forPlugin: "DeviceCalendarPlugin") else {
      return plugin
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler(plugin.handle)
    return plugin
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(result: result)
    case "openSettings":
      openSettings()
      result(nil)
    case "listCalendars":
      guard hasAccess else {
        result(FlutterError(code: "permission", message: "READ_CALENDAR", details: nil))
        return
      }
      queue.async {
        let store = self.eventStore()
        store.refreshSourcesIfNecessary()
        let items = self.listCalendars(in: store)
        DispatchQueue.main.async { result(items) }
      }
    case "listEvents":
      guard hasAccess else {
        result(FlutterError(code: "permission", message: "READ_CALENDAR", details: nil))
        return
      }
      let arguments = call.arguments as? [String: Any] ?? [:]
      let ids = (arguments["calendarIds"] as? [Any])?.map { "\($0)" } ?? []
      let from = milliseconds(arguments["fromMillis"])
      let to = milliseconds(arguments["toMillis"])
      queue.async {
        let items = self.listEvents(
          in: self.eventStore(),
          calendarIds: ids,
          fromMillis: from,
          toMillis: to
        )
        DispatchQueue.main.async { result(items) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var hasAccess: Bool {
    if #available(iOS 17.0, *) {
      return EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }
    return EKEventStore.authorizationStatus(for: .event) == .authorized
  }

  private func currentStatus() -> String {
    if hasAccess { return "granted" }
    let status = EKEventStore.authorizationStatus(for: .event)
    if status == .notDetermined { return "denied" }
    return "permanentlyDenied"
  }

  private func eventStore() -> EKEventStore {
    if let store { return store }
    let created = EKEventStore()
    store = created
    return created
  }

  private func requestPermission(result: @escaping FlutterResult) {
    if hasAccess {
      result("granted")
      return
    }
    let requester = EKEventStore()
    let finish: (Bool) -> Void = { [weak self] granted in
      guard let self else { return }
      self.queue.async {
        if granted {
          let next = EKEventStore()
          next.refreshSourcesIfNecessary()
          self.store = next
        }
        DispatchQueue.main.async {
          result(granted ? "granted" : self.currentStatus())
        }
      }
    }
    if #available(iOS 17.0, *) {
      requester.requestFullAccessToEvents { granted, _ in
        finish(granted)
      }
    } else {
      requester.requestAccess(to: .event) { granted, _ in
        finish(granted)
      }
    }
  }

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func listCalendars(in store: EKEventStore) -> [[String: Any]] {
    let counts = eventCounts(in: store)
    return store.calendars(for: .event).compactMap { calendar in
      if isExcluded(calendar) { return nil }
      let id = calendar.calendarIdentifier
      return [
        "id": id,
        "name": calendar.title.isEmpty ? "캘린더" : calendar.title,
        "accountName": calendar.source.title,
        "eventCount": counts[id] ?? 0,
      ]
    }
  }

  private func eventCounts(in store: EKEventStore) -> [String: Int] {
    let range = queryRange()
    let calendars = store.calendars(for: .event).filter { !isExcluded($0) }
    if calendars.isEmpty { return [:] }
    var counts: [String: Int] = [:]
    var seen = Set<String>()
    enumerateWindows(from: range.start, to: range.end) { start, end in
      let predicate = store.predicateForEvents(
        withStart: start,
        end: end,
        calendars: calendars
      )
      for event in store.events(matching: predicate) {
        let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty { continue }
        let id = event.calendar?.calendarIdentifier ?? ""
        if id.isEmpty { continue }
        let eventId = event.eventIdentifier ?? event.calendarItemIdentifier
        let key = "\(eventId)|\(event.startDate.timeIntervalSince1970)"
        if !seen.insert(key).inserted { continue }
        counts[id, default: 0] += 1
      }
    }
    return counts
  }

  private func listEvents(
    in store: EKEventStore,
    calendarIds: [String],
    fromMillis: Double,
    toMillis: Double
  ) -> [[String: Any]] {
    if calendarIds.isEmpty || toMillis <= fromMillis { return [] }
    let wanted = Set(calendarIds)
    let calendars = store.calendars(for: .event).filter { wanted.contains($0.calendarIdentifier) }
    if calendars.isEmpty { return [] }
    let start = Date(timeIntervalSince1970: fromMillis / 1000)
    let end = Date(timeIntervalSince1970: toMillis / 1000)
    var items: [[String: Any]] = []
    var seen = Set<String>()
    enumerateWindows(from: start, to: end) { windowStart, windowEnd in
      if items.count >= Self.maxEvents { return }
      let predicate = store.predicateForEvents(
        withStart: windowStart,
        end: windowEnd,
        calendars: calendars
      )
      let events = store.events(matching: predicate).sorted {
        $0.startDate < $1.startDate
      }
      for event in events {
        if items.count >= Self.maxEvents { break }
        let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty { continue }
        let eventId = event.eventIdentifier ?? event.calendarItemIdentifier
        let key = "\(eventId)|\(event.startDate.timeIntervalSince1970)"
        if !seen.insert(key).inserted { continue }
        items.append([
          "eventId": eventId,
          "calendarId": event.calendar?.calendarIdentifier ?? "",
          "title": title,
          "notes": event.notes ?? "",
          "startMillis": millis(event.startDate, allDay: event.isAllDay),
          "endMillis": millis(event.endDate, allDay: event.isAllDay),
          "allDay": event.isAllDay,
        ])
      }
    }
    items.sort {
      let left = $0["startMillis"] as? Int ?? 0
      let right = $1["startMillis"] as? Int ?? 0
      return left < right
    }
    if items.count > Self.maxEvents {
      items = Array(items.prefix(Self.maxEvents))
    }
    return items
  }

  private func queryRange() -> (start: Date, end: Date) {
    var startComponents = DateComponents()
    startComponents.year = 2010
    startComponents.month = 1
    startComponents.day = 1
    let start = Calendar.current.date(from: startComponents) ?? Date.distantPast
    var endComponents = DateComponents()
    endComponents.year = Calendar.current.component(.year, from: Date()) + 5
    endComponents.month = 12
    endComponents.day = 31
    endComponents.hour = 23
    endComponents.minute = 59
    endComponents.second = 59
    let end = Calendar.current.date(from: endComponents) ?? Date.distantFuture
    return (start, end)
  }

  /// EventKit는 한 번에 4년만 가져온다.
  private func enumerateWindows(from start: Date, to end: Date, _ body: (Date, Date) -> Void) {
    var cursor = start
    while cursor < end {
      let rawNext = Calendar.current.date(
        byAdding: DateComponents(year: 3, month: 11),
        to: cursor
      ) ?? end
      let next = min(rawNext, end)
      if next <= cursor { break }
      body(cursor, next)
      cursor = next
    }
  }

  private func milliseconds(_ value: Any?) -> Double {
    if let number = value as? NSNumber { return number.doubleValue }
    if let number = value as? Double { return number }
    if let number = value as? Int { return Double(number) }
    return 0
  }

  /// 종일 일정은 안드로이드와 같이 UTC 자정으로 보내서 Dart 매퍼가 날짜를 맞춘다.
  private func millis(_ date: Date, allDay: Bool) -> Int {
    let value: Date
    if allDay {
      let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
      var utc = Calendar(identifier: .gregorian)
      utc.timeZone = TimeZone(secondsFromGMT: 0)!
      value = utc.date(from: DateComponents(
        timeZone: utc.timeZone,
        year: parts.year,
        month: parts.month,
        day: parts.day
      )) ?? date
    } else {
      value = date
    }
    return Int((value.timeIntervalSince1970 * 1000).rounded())
  }

  private func isExcluded(_ calendar: EKCalendar) -> Bool {
    if calendar.type == .birthday { return true }
    if calendar.source.sourceType == .birthdays { return true }
    let hay = "\(calendar.title) \(calendar.source.title)".lowercased()
    let words = [
      "holiday",
      "holidays",
      "공휴일",
      "국경일",
      "휴일",
      "절기",
      "명절",
      "birthday",
      "birthdays",
      "생일",
      "생신",
      "anniversary",
      "기념일",
      "contacts",
      "연락처",
      "주소록",
    ]
    return words.contains { hay.contains($0) }
  }
}
