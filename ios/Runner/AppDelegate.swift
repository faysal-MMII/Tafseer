import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins manually without bridging header
    if let registrar = self.registrar(forPlugin: "GeneratedPluginRegistrant") {
      // This will be handled by Flutter's automatic plugin registration
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
