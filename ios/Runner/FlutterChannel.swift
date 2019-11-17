import Foundation

class FlutterChannel {
  typealias ChannelHandler = (_ call: FlutterMethodCall, _ result: @escaping FlutterResult) -> Void

  private static let SOUND_CHANNEL = "com.papa.mamma/sound"
  
  private let soundAnalyzer = SoundAnalyzer()
  var controller: FlutterViewController!

  func setup(_ controller: FlutterViewController) {
    self.controller = controller

    setupSoundChannel()
    // Add more channel in here
  }

  private func setupChannel(channel: String, handler: @escaping ChannelHandler) {
    FlutterMethodChannel(name: channel, binaryMessenger: controller.binaryMessenger).setMethodCallHandler(handler)
  }

  private func setupSoundChannel() {
    setupChannel(channel: FlutterChannel.SOUND_CHANNEL) { (call, result) -> Void in
      switch call.method {
      case "record":
        self.record(call, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func record(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let enabled = call.arguments as? Bool else {
      result(FlutterError(code: call.method, message: "Missing argument", details: nil))
      return
    }
    
    self.soundAnalyzer.record(enabled: enabled)
    result(nil)
  }
}
