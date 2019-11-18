package com.papa.mamma

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.Job

class MainActivity : FlutterActivity() {

  companion object {
    private const val ROOT_CHANNEL_NAME = "com.papa.mamma"
    const val REQUEST_RECORD_AUDIO_PERMISSION = 1111
  }

  private val soundAnalyzer = SoundAnalyzer()
  private var delayingJob: Job? = null
  private val flutterChannel = FlutterChannel()

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    // TODO(hyungsun): Request permission in flutter not native.
    requestPermissionIfNeeded()

    flutterChannel.setSubChannel("sound", FlutterSoundChannel(soundAnalyzer))
    flutterChannel.setup(ROOT_CHANNEL_NAME, flutterView)
  }

  override fun onStop() {
    super.onStop()
    soundAnalyzer.stopRecording()
    delayingJob?.cancel()
    delayingJob = null
  }

  override fun onDestroy() {
    super.onDestroy()

    soundAnalyzer.terminate()
    delayingJob?.cancel()
    delayingJob = null

    flutterChannel.dispose()
  }

  override fun onRequestPermissionsResult(
      requestCode: Int,
      permissions: Array<out String>,
      grantResults: IntArray
  ) {
    if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
      soundAnalyzer.startRecording()
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
}
