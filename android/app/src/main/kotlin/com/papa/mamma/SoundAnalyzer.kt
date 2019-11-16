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

class SoundAnalyzer {

  companion object {
    private const val TAG = "SoundAnalyzer"
    private const val SAMPLE_RATE = 44100
  }

  /**
   * List of sampling data which is pair made up of elapsed time in millis and sampled amplitude
   * while recording.
   */
  val audioBuffer = mutableListOf<Pair<Long, Int>>()

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
   *
   * @param clearBuffer If true, clear `audioBuffer`. Default: true
   */
  fun startRecording(clearBuffer: Boolean = true) {
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

    if (clearBuffer) {
      clearBuffer()
    }

    recordingJob = GlobalScope.launch {
      Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)

      val startAt = System.currentTimeMillis()
      val audioBuffer = ShortArray(incomeBufferSize / 2)
      loop@ while (isActive) {
        when (recorder.read(audioBuffer, 0, audioBuffer.size)) {
          AudioRecord.ERROR_INVALID_OPERATION,
          AudioRecord.ERROR,
          AudioRecord.ERROR_BAD_VALUE,
          AudioRecord.ERROR_DEAD_OBJECT -> continue@loop
          else -> {
            val data = Pair(System.currentTimeMillis() - startAt, audioBuffer.sum())
            this@SoundAnalyzer.audioBuffer.add(data)
            Log.d(TAG, "data: $data")
          }
        }
      }
    }
  }

  /**
   * Stop recording.
   */
  fun stopRecording() {
    recordingJob?.cancel()
    recorder.stop()
    recordingJob = null
    Log.d(TAG, "Recording stopped")
  }

  /**
   * Clear `audioBuffer`.
   */
  @Throws(RuntimeException::class)
  fun clearBuffer() {
    if (recordingJob != null) {
      throw RuntimeException("Cannot clear buffer while recording.")
    }

    audioBuffer.clear()
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