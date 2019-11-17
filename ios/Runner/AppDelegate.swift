import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let soundAnalyzer = SoundAnalyzer()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    soundAnalyzer.record(enabled: true)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
