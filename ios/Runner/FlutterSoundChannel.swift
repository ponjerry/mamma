import Foundation
import RxSwift

class FlutterSoundChannel: FlutterChannel {
  private let soundAnalyzer = SoundAnalyzer()

  override init() {
    super.init()
    setMethodChannel("record", FlutterRecordChannelHandler(soundAnalyzer))
    setEventChannel("speaking", FlutterSpeakingEventHandler(soundAnalyzer))
  }
}

class FlutterRecordChannelHandler: MethodChannelHandler {
  private let soundAnalyzer: SoundAnalyzer
  
  init(_ soundAnalyzer: SoundAnalyzer) {
    self.soundAnalyzer = soundAnalyzer
  }

  func handle(_ args: Any?, _ result: @escaping FlutterResult) throws {
    guard let enabled = args as? Bool else {
      result(FlutterError(code: "record", message: "Missing argument", details: nil))
      return
    }
    
    self.soundAnalyzer.record(enabled: enabled)
    result(nil)
  }
  
  func dispose() {
    soundAnalyzer.record(enabled: false)
  }
}

class FlutterSpeakingEventHandler: EventChannelHandler {
  private let soundAnalyzer: SoundAnalyzer
  private var disposable: Disposable?
  
  init(_ soundAnalyzer: SoundAnalyzer) {
    self.soundAnalyzer = soundAnalyzer
  }

  func handle(_ args: Any?, _ eventSink: FlutterEventSink?) throws {
    guard let eventSink = eventSink else {
      // Channel will be cancelled.
      return
    }

    disposable = soundAnalyzer.speakingEvent.subscribe(onNext: { (event) in
      if let speaking = event.element {
        eventSink(speaking)
      } else if let error = event.error {
        eventSink(FlutterError(error: error))
      }
    }, onError: { (error) in
      eventSink(FlutterError(error: error))
    })
  }

  func dispose() {
    disposable?.dispose()
  }
}
