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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
