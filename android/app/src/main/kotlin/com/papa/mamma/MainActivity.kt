package com.papa.mamma

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import android.os.Process
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {

  companion object {
    const val REQUEST_RECORD_AUDIO_PERMISSION = 1111
    const val TAG = "MainActivity"
    const val SAMPLE_RATE = 44100
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
  private var delayingJob: Job? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    startRecording()

    delayInBackground(TimeUnit.SECONDS.toMillis(10L)) {
      stopRecording()
    }
  }

  override fun onStop() {
    super.onStop()
    stopRecording()
  }

  override fun onDestroy() {
    super.onDestroy()

    recorder.release()
  }

  override fun onRequestPermissionsResult(
      requestCode: Int,
      permissions: Array<out String>,
      grantResults: IntArray
  ) {
    if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
      startRecording()
    }
  }

  private fun requestPermissionIfNeeded(): Boolean {
    val permission = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
    return if (permission == PackageManager.PERMISSION_GRANTED) {
      true
    } else {
      ActivityCompat.requestPermissions(
          this,
          arrayOf(Manifest.permission.RECORD_AUDIO),
          REQUEST_RECORD_AUDIO_PERMISSION
      )
      false
    }
  }

  private fun startRecording() {
    Log.d(TAG, "Trying to start recording")
    if (!requestPermissionIfNeeded()) {
      Log.d(TAG, "Cannot start recording: Permission not granted")
      return
    }

    try {
      recorder.startRecording()
    } catch (exception: IllegalStateException) {
      Log.d(TAG, "Cannot start recording: $exception")
    }

    recordingJob = GlobalScope.launch {
      Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)

      val audioBuffer = ShortArray(incomeBufferSize / 2)
      loop@ while (isActive) {
        when (recorder.read(audioBuffer, 0, audioBuffer.size)) {
          AudioRecord.ERROR_INVALID_OPERATION,
          AudioRecord.ERROR,
          AudioRecord.ERROR_BAD_VALUE,
          AudioRecord.ERROR_DEAD_OBJECT -> continue@loop
          else -> Log.d(TAG, "data: ${audioBuffer.sum()}")
        }
      }
    }
  }

  private fun stopRecording() {
    recordingJob?.cancel()
    recorder.stop()

    // Cancel delaying job for force stop.
    delayingJob?.cancel()
    recordingJob = null
    delayingJob = null
    Log.d(TAG, "Recording stopped")
  }

  private fun delayInBackground(delayInMillis: Long, callback: () -> Unit) {
    delayingJob = GlobalScope.launch {
      delay(delayInMillis)
      callback()
    }
  }
}
