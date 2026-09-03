import Flutter
import Foundation

final class ICloudBackupPlugin: NSObject {
  static let channelName = "job_planner/icloud_backup"
  static let containerId = "iCloud.com.jobplanner.jobPlanner"

  private let queue = DispatchQueue(label: "job_planner.icloud_backup")

  static func register(with registry: FlutterPluginRegistry) -> ICloudBackupPlugin {
    let plugin = ICloudBackupPlugin()
    guard let registrar = registry.registrar(forPlugin: "ICloudBackupPlugin") else {
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
    case "save":
      let arguments = call.arguments as? [String: Any] ?? [:]
      guard let fileName = arguments["fileName"] as? String, !fileName.isEmpty else {
        result(FlutterError(code: "invalid", message: "fileName is required", details: nil))
        return
      }
      guard let bytes = argumentBytes(arguments["bytes"]) else {
        result(FlutterError(code: "invalid", message: "bytes are required", details: nil))
        return
      }
      let keep = arguments["keep"] as? Int ?? 3
      let prefix = arguments["prefix"] as? String ?? "잡플래너_백업_"
      queue.async {
        do {
          try self.save(fileName: fileName, bytes: bytes, keep: keep, prefix: prefix)
          DispatchQueue.main.async { result(nil) }
        } catch {
          DispatchQueue.main.async { result(self.flutterError(error)) }
        }
      }
    case "list":
      queue.async {
        do {
          let items = try self.listBackups()
          DispatchQueue.main.async { result(items) }
        } catch {
          DispatchQueue.main.async { result(self.flutterError(error)) }
        }
      }
    case "read":
      let arguments = call.arguments as? [String: Any] ?? [:]
      guard let fileName = arguments["fileName"] as? String, !fileName.isEmpty else {
        result(FlutterError(code: "invalid", message: "fileName is required", details: nil))
        return
      }
      queue.async {
        do {
          let data = try self.read(fileName: fileName)
          DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: data)) }
        } catch {
          DispatchQueue.main.async { result(self.flutterError(error)) }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func save(fileName: String, bytes: Data, keep: Int, prefix: String) throws {
    let documents = try documentsURL()
    let dest = documents.appendingPathComponent(fileName)
    var coordError: NSError?
    var writeError: Error?
    NSFileCoordinator().coordinate(
      writingItemAt: dest,
      options: .forReplacing,
      error: &coordError
    ) { url in
      do {
        try bytes.write(to: url, options: .atomic)
      } catch {
        writeError = error
      }
    }
    if let coordError { throw coordError }
    if let writeError { throw writeError }
    try prune(in: documents, prefix: prefix, keep: keep)
  }

  private func listBackups() throws -> [[String: Any]] {
    _ = try documentsURL()
    if let queried = try? queryCloudBackups(), !queried.isEmpty {
      return queried
    }
    return try listFromDirectory()
  }

  private func listFromDirectory() throws -> [[String: Any]] {
    let documents = try documentsURL()
    try? FileManager.default.startDownloadingUbiquitousItem(at: documents)
    let urls = try FileManager.default.contentsOfDirectory(
      at: documents,
      includingPropertiesForKeys: [
        .contentModificationDateKey,
        .isRegularFileKey,
      ],
      options: [.skipsHiddenFiles]
    )
    var items: [[String: Any]] = []
    for url in urls {
      let name = url.lastPathComponent
      guard name.hasPrefix("잡플래너_백업_"), name.lowercased().hasSuffix(".zip") else { continue }
      let values = try url.resourceValues(forKeys: [
        .isRegularFileKey,
        .contentModificationDateKey,
      ])
      if values.isRegularFile == false { continue }
      let modified = values.contentModificationDate ?? Date()
      items.append([
        "fileName": name,
        "modified": Int(modified.timeIntervalSince1970 * 1000),
      ])
    }
    items.sort {
      let left = $0["modified"] as? Int ?? 0
      let right = $1["modified"] as? Int ?? 0
      return left > right
    }
    return items
  }

  private func queryCloudBackups() throws -> [[String: Any]] {
    let box = MetadataQueryBox()
    let semaphore = DispatchSemaphore(value: 0)
    DispatchQueue.main.async {
      let query = NSMetadataQuery()
      box.query = query
      query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
      query.predicate = NSPredicate(
        format: "%K ENDSWITH[c] %@",
        NSMetadataItemFSNameKey,
        ".zip"
      )
      let finish: () -> Void = {
        guard box.finish() else { return }
        query.disableUpdates()
        query.stop()
        if let token = box.observer {
          NotificationCenter.default.removeObserver(token)
        }
        var items: [[String: Any]] = []
        for index in 0..<query.resultCount {
          guard let item = query.result(at: index) as? NSMetadataItem else { continue }
          guard let name = item.value(forAttribute: NSMetadataItemFSNameKey) as? String else {
            continue
          }
          guard name.hasPrefix("잡플래너_백업_") else { continue }
          let date = item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date
            ?? Date()
          items.append([
            "fileName": name,
            "modified": Int(date.timeIntervalSince1970 * 1000),
          ])
        }
        items.sort {
          let left = $0["modified"] as? Int ?? 0
          let right = $1["modified"] as? Int ?? 0
          return left > right
        }
        box.items = items
        semaphore.signal()
      }
      box.observer = NotificationCenter.default.addObserver(
        forName: .NSMetadataQueryDidFinishGathering,
        object: query,
        queue: .main
      ) { _ in finish() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 8) { finish() }
      if !query.start() {
        guard box.finish() else { return }
        box.error = ICloudBackupError.unavailable
        semaphore.signal()
      }
    }
    _ = semaphore.wait(timeout: .now() + 10)
    if let error = box.error { throw error }
    return box.items ?? []
  }

  private func read(fileName: String) throws -> Data {
    let dest = try documentsURL().appendingPathComponent(fileName)
    try downloadIfNeeded(dest)
    var coordError: NSError?
    var data: Data?
    var readError: Error?
    NSFileCoordinator().coordinate(readingItemAt: dest, options: [], error: &coordError) { url in
      do {
        data = try Data(contentsOf: url)
      } catch {
        readError = error
      }
    }
    if let coordError { throw coordError }
    if let readError { throw readError }
    guard let data else {
      throw ICloudBackupError.missing
    }
    return data
  }

  private func prune(in documents: URL, prefix: String, keep: Int) throws {
    if keep < 1 { return }
    let urls = try FileManager.default.contentsOfDirectory(
      at: documents,
      includingPropertiesForKeys: [.contentModificationDateKey],
      options: [.skipsHiddenFiles]
    )
    let backups = urls.filter {
      let name = $0.lastPathComponent
      return name.hasPrefix(prefix) && name.lowercased().hasSuffix(".zip")
    }
    .sorted { left, right in
      let leftDate = (try? left.resourceValues(forKeys: [.contentModificationDateKey])
        .contentModificationDate) ?? .distantPast
      let rightDate = (try? right.resourceValues(forKeys: [.contentModificationDateKey])
        .contentModificationDate) ?? .distantPast
      return leftDate > rightDate
    }
    for url in backups.dropFirst(keep) {
      var coordError: NSError?
      NSFileCoordinator().coordinate(
        writingItemAt: url,
        options: .forDeleting,
        error: &coordError
      ) { item in
        try? FileManager.default.removeItem(at: item)
      }
    }
  }

  private func documentsURL() throws -> URL {
    guard FileManager.default.ubiquityIdentityToken != nil else {
      throw ICloudBackupError.signedOut
    }
    guard let container = FileManager.default.url(
      forUbiquityContainerIdentifier: Self.containerId
    ) else {
      throw ICloudBackupError.unavailable
    }
    let documents = container.appendingPathComponent("Documents", isDirectory: true)
    try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    return documents
  }

  private func downloadIfNeeded(_ url: URL) throws {
    let values = try url.resourceValues(forKeys: [
      .ubiquitousItemDownloadingStatusKey,
      .ubiquitousItemIsDownloadingKey,
    ])
    if values.ubiquitousItemDownloadingStatus == .current {
      return
    }
    try FileManager.default.startDownloadingUbiquitousItem(at: url)
    let deadline = Date().addingTimeInterval(30)
    while Date() < deadline {
      Thread.sleep(forTimeInterval: 0.2)
      let next = try url.resourceValues(forKeys: [
        .ubiquitousItemDownloadingStatusKey,
        .ubiquitousItemDownloadingErrorKey,
      ])
      if let error = next.ubiquitousItemDownloadingError {
        throw error
      }
      if next.ubiquitousItemDownloadingStatus == .current {
        return
      }
    }
    throw ICloudBackupError.timeout
  }

  private func argumentBytes(_ raw: Any?) -> Data? {
    if let data = raw as? FlutterStandardTypedData {
      return data.data
    }
    if let data = raw as? Data {
      return data
    }
    return nil
  }

  private func flutterError(_ error: Error) -> FlutterError {
    if let backupError = error as? ICloudBackupError {
      return FlutterError(code: backupError.code, message: backupError.message, details: nil)
    }
    let nsError = error as NSError
    return FlutterError(code: "icloud_failed", message: nsError.localizedDescription, details: nil)
  }
}

private enum ICloudBackupError: Error {
  case signedOut
  case unavailable
  case missing
  case timeout

  var code: String {
    switch self {
    case .signedOut: return "signed_out"
    case .unavailable: return "unavailable"
    case .missing: return "missing"
    case .timeout: return "timeout"
    }
  }

  var message: String {
    switch self {
    case .signedOut: return "iCloud is not signed in"
    case .unavailable: return "iCloud container is unavailable"
    case .missing: return "backup file is missing"
    case .timeout: return "iCloud download timed out"
    }
  }
}

private final class MetadataQueryBox {
  var query: NSMetadataQuery?
  var observer: NSObjectProtocol?
  var items: [[String: Any]]?
  var error: Error?
  private var finished = false

  func finish() -> Bool {
    if finished { return false }
    finished = true
    return true
  }
}
