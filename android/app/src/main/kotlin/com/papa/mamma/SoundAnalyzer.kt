package com.papa.mamma

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Process
import android.util.Log
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.abs

class SoundAnalyzer(private val listener: AudioDataListener) {

  companion object {
    private const val TAG = "SoundAnalyzer"
    // TODO(hyungsun): Make this configurable.
    private const val SAMPLE_RATE = 44100
    // TODO(hyungsun): Make this configurable.
    private const val AMPLITUDE_THRESHOLD = 1500
  }

  interface AudioDataListener {

    /**
     * Called when the recorder starts hearing voice.
     */
    fun onRecordingStart() {}


    /**
     * Called when the recorder stops hearing voice.
     */
    fun onRecordingStop() {}

    /**
     * Called when the recorder is hearing voice.
     *
     * @param rawData The audio data in [AudioFormat.ENCODING_PCM_16BIT].
     * @param size The size of the actual data in `data`.
     */
    fun onAudioDataReceived(rawData: ByteArray, size: Int)
  }

  /**
   * Check if voice is recording.
   *
   * @param rawData The audio data in [AudioFormat.ENCODING_PCM_16BIT].
   * @param size The size of the actual data in `data`.
   */
  fun isSpeaking(rawData: ByteArray, size: Int): Boolean {
    val amplitudes = mutableListOf<Int>()
    for (i in 0 until size - 1 step 2) {
      // NOTE: The buffer has LINEAR16 in little endian.
      var s = rawData[i + 1].toInt()
      if (s < 0)
        s *= -1
      s = s.shl(8)
      s += abs(rawData[i].toInt())
      amplitudes.add(s)
    }
    return amplitudes.average() > AMPLITUDE_THRESHOLD
  }

  private val incomeBufferSize = AudioRecord
      .getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
      .let { size ->
        when (size) {
          AudioRecord.ERROR,
          AudioRecord.ERROR_BAD_VALUE -> SAMPLE_RATE * 2
          else -> size
        }
      }
  private val recorder = AudioRecord(
      MediaRecorder.AudioSource.MIC,
      SAMPLE_RATE,
      AudioFormat.CHANNEL_IN_MONO,
      AudioFormat.ENCODING_PCM_16BIT,
      incomeBufferSize
  )

  private var recordingJob: Job? = null

  /**
   * Start recording in background.
   */
  fun startRecording() {
    if (recordingJob != null) {
      Log.d(TAG, "Abort job: Already recording.")
      return
    }

    Log.d(TAG, "Trying to start recording")

    try {
      recorder.startRecording()
    } catch (exception: IllegalStateException) {
      Log.d(TAG, "Cannot start recording: $exception")
    }

    listener.onRecordingStart()

    recordingJob = GlobalScope.launch {
      Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)

      val audioBuffer = ByteArray(incomeBufferSize / 2)
      loop@ while (isActive) {
        when (val size = recorder.read(audioBuffer, 0, audioBuffer.size)) {
          AudioRecord.ERROR_INVALID_OPERATION,
          AudioRecord.ERROR,
          AudioRecord.ERROR_BAD_VALUE,
          AudioRecord.ERROR_DEAD_OBJECT -> continue@loop
          else -> listener.onAudioDataReceived(audioBuffer, size)
        }
      }
    }
  }

  /**
   * Stop recording.
   */
  fun stopRecording() {
    recordingJob?.cancel()
    try {
      recorder.stop()
    } catch (exception: IllegalStateException) {
      // In case `startRecording` is not called but `stopRecording` is called, do nothing.
    }

    recordingJob = null

    listener.onRecordingStop()
    Log.d(TAG, "Recording stopped")
  }

  /**
   * Terminate [SoundAnalyzer]. After this, [SoundAnalyzer] cannot record.
   * Call this at a point where it's no longer in use such as `onDestroy`.
   */
  fun terminate() {
    stopRecording()
    recorder.release()
  }
}