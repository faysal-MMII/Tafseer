import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Use NSClassFromString to access GeneratedPluginRegistrant without bridging header
    if let pluginRegistrantClass = NSClassFromString("GeneratedPluginRegistrant") as? NSObject.Type {
      pluginRegistrantClass.perform(Selector(("registerWithRegistry:")), with: self)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}