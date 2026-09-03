import Flutter
import PhotosUI
import UIKit

final class ImagePickerPlugin: NSObject, PHPickerViewControllerDelegate {
  static let channelName = "job_planner/image_picker"

  private var pickResult: FlutterResult?

  static func register(with registry: FlutterPluginRegistry) -> ImagePickerPlugin {
    let plugin = ImagePickerPlugin()
    guard let registrar = registry.registrar(forPlugin: "ImagePickerPlugin") else {
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
    case "pick":
      pick(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pick(result: @escaping FlutterResult) {
    if pickResult != nil {
      result(nil)
      return
    }
    pickResult = result
    DispatchQueue.main.async {
      guard let presenter = Self.presenter() else {
        self.finish(nil)
        return
      }
      var configuration = PHPickerConfiguration()
      configuration.filter = .images
      configuration.selectionLimit = 1
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      presenter.present(picker, animated: true)
    }
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let provider = results.first?.itemProvider else {
      finish(nil)
      return
    }
    guard provider.canLoadObject(ofClass: UIImage.self) else {
      finish(nil)
      return
    }
    provider.loadObject(ofClass: UIImage.self) { object, _ in
      guard let image = object as? UIImage,
            let data = image.jpegData(compressionQuality: 0.92)
      else {
        DispatchQueue.main.async { self.finish(nil) }
        return
      }
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "diary_photo_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
      )
      do {
        try data.write(to: url, options: .atomic)
        DispatchQueue.main.async { self.finish(url.path) }
      } catch {
        DispatchQueue.main.async { self.finish(nil) }
      }
    }
  }

  private func finish(_ value: Any?) {
    let callback = pickResult
    pickResult = nil
    callback?(value)
  }

  private static func presenter() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
    let window = windows.first(where: \.isKeyWindow) ?? windows.first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
