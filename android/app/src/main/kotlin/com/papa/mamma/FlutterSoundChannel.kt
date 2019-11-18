package com.papa.mamma

import com.papa.mamma.FlutterSoundChannel.Companion.EVENT_SPEAKING
import com.papa.mamma.FlutterSoundChannel.Companion.METHOD_RECORD
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.Disposable

class FlutterSoundChannel(soundAnalyzer: SoundAnalyzer) : FlutterChannel() {
  companion object {
    const val METHOD_RECORD = "record"
    const val EVENT_SPEAKING = "speaking"
  }

  init {
    setMethodChannel(METHOD_RECORD, FlutterRecordMethodHandler(soundAnalyzer))
    setEventChannel(EVENT_SPEAKING, FlutterSpeakingEventHandler(soundAnalyzer))
  }
}

class FlutterRecordMethodHandler(private val soundAnalyzer: SoundAnalyzer) : MethodChannelHandler {

  override fun handle(args: Any?, result: MethodChannel.Result) {
    val isRecord = args as Boolean?
    if (isRecord == null) {
      result.error(METHOD_RECORD, "FlutterRecordChannelHandler: args cannot be null", null)
      return
    }

    if (isRecord) {
      soundAnalyzer.startRecording()
    } else {
      soundAnalyzer.stopRecording()
    }

    result.success(null)
  }

  override fun dispose() {
    soundAnalyzer.terminate()
  }
}

class FlutterSpeakingEventHandler(private val soundAnalyzer: SoundAnalyzer) : EventChannelHandler {
  lateinit var disposable: Disposable

  override fun handle(args: Any?, eventSink: EventChannel.EventSink?) {
    if (eventSink == null) {
      return
    }

    disposable = soundAnalyzer.audioDataSubject
      .observeOn(AndroidSchedulers.mainThread())
      .subscribe({ audioData ->
        eventSink.success(soundAnalyzer.isSpeaking(audioData))
      }, { error ->
        eventSink.error(EVENT_SPEAKING, error.localizedMessage, null)
      })
  }

  override fun dispose() {
    soundAnalyzer.terminate()
    disposable.dispose()
  }
}