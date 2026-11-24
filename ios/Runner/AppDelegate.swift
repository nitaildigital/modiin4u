import CoreMotion
import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The key comes from Flutter/Maps.xcconfig by way of Info.plist, so it is
    // not in the source.
    var hasMapsKey = false
    if let key = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
       !key.isEmpty {
      GMSServices.provideAPIKey(key)
      hasMapsKey = true
    }

    GeneratedPluginRegistrant.register(with: self)

    // Google's SDK does not leave the map blank without a key — it throws,
    // and the app closes on the first screen with a map (found on the
    // simulator, 5 Oct). So the app asks first, and without a key AppMap
    // draws its pins on a plain background, as the website does without one.
    let mapsKeyKnown = hasMapsKey
    if let registrar = self.registrar(forPlugin: "MapsKey") {
      FlutterMethodChannel(name: "modiin4u/maps", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          if call.method == "hasKey" {
            result(mapsKeyKnown)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
    }

    if let registrar = self.registrar(forPlugin: "MotionSteps") {
      MotionSteps.register(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// The iPhone's own step count, from Core Motion (motion_steps.dart).
///
/// The app read Apple Health until 24 Nov 2026; App Review turned version
/// 1.0 (4) down under Guideline 5.1.1(ix), so the iPhone app now has no
/// HealthKit at all. The motion coprocessor counts whether or not the app is
/// running and keeps the last seven days, so a day's figure can be read back
/// from midnight at any time, and a competition's from its start — nothing
/// resets when the app closes or the phone restarts.
///
/// `modiin4u/motion`:
///   * `status` → {available, distance, auth}: auth is notDetermined,
///     restricted, denied or authorized.
///   * `query` {from, to} (milliseconds since 1970) → {steps, metres}; the
///     first query puts up the Motion & Fitness question.
/// `modiin4u/motion/today`: today's running total from midnight, {day, steps,
/// metres}, `day` being midnight in milliseconds; it starts again at the next
/// midnight.
final class MotionSteps: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private let live = CMPedometer()
  private var sink: FlutterEventSink?
  private var dayStart: Date?
  private var dayChange: NSObjectProtocol?

  static func register(messenger: FlutterBinaryMessenger) {
    let instance = MotionSteps()
    FlutterMethodChannel(name: "modiin4u/motion", binaryMessenger: messenger)
      .setMethodCallHandler(instance.handle)
    FlutterEventChannel(name: "modiin4u/motion/today", binaryMessenger: messenger)
      .setStreamHandler(instance)
    // Kept alive by the channels' handlers, which hold it.
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "status":
      result([
        "available": CMPedometer.isStepCountingAvailable(),
        "distance": CMPedometer.isDistanceAvailable(),
        "auth": Self.authName(CMPedometer.authorizationStatus()),
      ])
    case "query":
      guard let args = call.arguments as? [String: Any],
            let from = (args["from"] as? NSNumber)?.doubleValue,
            let to = (args["to"] as? NSNumber)?.doubleValue else {
        result(FlutterError(code: "args", message: "from and to are required", details: nil))
        return
      }
      guard CMPedometer.isStepCountingAvailable() else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      let start = Date(timeIntervalSince1970: from / 1000)
      let end = Date(timeIntervalSince1970: to / 1000)
      if end <= start {
        result(["steps": 0, "metres": NSNull()])
        return
      }
      pedometer.queryPedometerData(from: start, to: end) { data, error in
        DispatchQueue.main.async {
          if let error = error as NSError? {
            result(FlutterError(code: Self.errorName(error), message: error.localizedDescription, details: nil))
          } else {
            result(Self.figures(data))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    startLive()
    // At midnight the day starts again at zero, at once — not at the first
    // step after it, or yesterday's total would still read as today's
    // (and be saved as today's when the app goes to the background).
    dayChange = NotificationCenter.default.addObserver(
      forName: .NSCalendarDayChanged, object: nil, queue: .main
    ) { [weak self] _ in
      guard let self = self, self.sink != nil else { return }
      self.startLive()
      if let midnight = self.dayStart {
        self.sink?(["day": midnight.timeIntervalSince1970 * 1000, "steps": 0, "metres": NSNull()])
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    live.stopUpdates()
    if let observer = dayChange {
      NotificationCenter.default.removeObserver(observer)
      dayChange = nil
    }
    sink = nil
    dayStart = nil
    return nil
  }

  /// From this midnight. An update after the next midnight still counts from
  /// the old one, so it starts again from the new day instead.
  private func startLive() {
    guard CMPedometer.isStepCountingAvailable() else {
      sink?(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    live.stopUpdates()
    let midnight = Calendar.current.startOfDay(for: Date())
    dayStart = midnight
    live.startUpdates(from: midnight) { [weak self] data, error in
      DispatchQueue.main.async {
        guard let self = self, let sink = self.sink else { return }
        if let error = error as NSError? {
          sink(FlutterError(code: Self.errorName(error), message: error.localizedDescription, details: nil))
          return
        }
        if Calendar.current.startOfDay(for: Date()) != midnight {
          self.startLive()
          return
        }
        var event = Self.figures(data)
        event["day"] = midnight.timeIntervalSince1970 * 1000
        sink(event)
      }
    }
  }

  private static func figures(_ data: CMPedometerData?) -> [String: Any] {
    [
      "steps": data?.numberOfSteps.intValue ?? 0,
      "metres": data?.distance?.doubleValue ?? NSNull(),
    ]
  }

  private static func authName(_ status: CMAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "notDetermined"
    }
  }

  private static func errorName(_ error: NSError) -> String {
    if error.domain == CMErrorDomain {
      switch error.code {
      case Int(CMErrorMotionActivityNotAuthorized.rawValue): return "denied"
      case Int(CMErrorMotionActivityNotAvailable.rawValue): return "unavailable"
      default: break
      }
    }
    return "failed"
  }
}
