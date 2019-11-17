import AVFoundation
import RxSwift

class SoundAnalyzer {

  public let recordingEvent = PublishSubject<Data>()
  public let speakingEvent = PublishSubject<Event<Bool>>()

  private var recordingData = Data()
  private var engine: AVAudioEngine?
  private var sampleRate = 44100.0
  private var previousSpeaking = false

  public func record(enabled: Bool) {
    if enabled {
      AVAudioSession.sharedInstance().requestRecordPermission { allowed in
        if allowed {
          self.startRecording()
        } else {
          print("Can't start recording because there is no permission")
        }
      }
    } else {
      stopRecording()
    }
  }

  private func startRecording() {
    do {
      let recordingSession = AVAudioSession.sharedInstance()
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setPreferredSampleRate(16000)
    } catch {
      print("Failed to start record session: \(error.localizedDescription)")
    }

    self.previousSpeaking = false
    let engine = AVAudioEngine()
    // The sound will be sent to GoogleASR using 16-bit PCM(LINEAR16), 16000 Hz.
    let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)
    // Install a tap to get bytes while they are recorded. Buffer size 2048 covers 0.2 second.
    engine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { (buffer, _) in
      guard let channelData = buffer.int16ChannelData else { return }
      
      let data = Data(bytes: channelData[0], count: Int(buffer.frameLength * 2))
      let array = [UInt8](data)
      self.checkIsSpeaking(array)
    }

    do {
      engine.prepare()
      try engine.start()
    } catch {
      print("AVAudioEngine.start() error: \(error.localizedDescription)")
    }
    self.engine = engine
  }
  
  private func checkIsSpeaking(_ byteArray: Array<UInt8>) {
    let count = byteArray.count
    var amplitudes = [Int]()
    
    for i in stride(from: 0, to: count - 1, by: 2) {
      var s = Int(byteArray[i + 1])
      if s < 0 {
        s *= -1
      }
      
      s = s << 8
      s += abs(Int(byteArray[i]))
      amplitudes.append(s)
    }
    
    let average = amplitudes.reduce(0, +) / amplitudes.count
    if average >= 10000 {
      if !self.previousSpeaking {
        speakingEvent.onNext(.next(true))
        self.previousSpeaking = true
      }
    } else {
      if self.previousSpeaking {
        speakingEvent.onNext(.next(false))
        self.previousSpeaking = false
      }
    }
  }

  private func stopRecording() {
    if !recordingData.isEmpty {
      recordingEvent.onNext(recordingData)
      recordingData.removeAll()
    }
    engine?.inputNode.removeTap(onBus: 0)
    engine?.stop()
    engine?.reset()
    engine = nil
  }
}
