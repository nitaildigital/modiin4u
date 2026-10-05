import UserNotifications

/// Puts the picture into a push notification on iPhone.
///
/// iOS shows a remote notification's picture only if the app attaches it
/// itself, in this small extension that runs as the notification arrives.
/// Firebase passes the picture's address in `fcm_options.image` (set by
/// supabase/functions/push-dispatch, with `mutable-content: 1` so iOS wakes
/// this). It is downloaded and attached; if that fails or runs out of time,
/// the notification is shown as it came, without the picture.
class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var content: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    content = request.content.mutableCopy() as? UNMutableNotificationContent

    guard let content = content,
          let options = content.userInfo["fcm_options"] as? [String: Any],
          let address = options["image"] as? String,
          let url = URL(string: address)
    else {
      deliver()
      return
    }

    URLSession.shared.downloadTask(with: url) { [weak self] downloaded, response, _ in
      defer { self?.deliver() }
      guard let downloaded = downloaded else { return }
      // iOS reads the picture's type from the file's extension.
      let type: String
      switch response?.mimeType {
      case "image/png": type = "png"
      case "image/gif": type = "gif"
      default: type = "jpg"
      }
      let file = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString + "." + type)
      try? FileManager.default.moveItem(at: downloaded, to: file)
      if let picture = try? UNNotificationAttachment(identifier: "image", url: file) {
        content.attachments = [picture]
      }
    }.resume()
  }

  /// iOS allows about 30 seconds; at the end, show what there is.
  override func serviceExtensionTimeWillExpire() {
    deliver()
  }

  /// Hands the notification back to iOS, once.
  private func deliver() {
    guard let handler = contentHandler, let content = content else { return }
    contentHandler = nil
    handler(content)
  }
}
