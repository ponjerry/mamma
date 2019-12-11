import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let ROOT_CHANNEL_NAME = "com.papa.mamma"

  private let soundChannel = FlutterSoundChannel()
  private let flutterChannel = FlutterChannel()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    FirebaseApp.configure()

    guard let controller: FlutterViewController = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not FlutterViewController")
    }

    flutterChannel.setSubChannel("sound", FlutterSoundChannel())
    flutterChannel.setup(ROOT_CHANNEL_NAME, controller)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
