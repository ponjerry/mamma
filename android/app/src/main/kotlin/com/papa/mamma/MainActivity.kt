package com.papa.mamma

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {

  companion object {
    const val REQUEST_RECORD_AUDIO_PERMISSION = 1111
  }

  private val soundAnalyzer = SoundAnalyzer()
  private var delayingJob: Job? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    if (requestPermissionIfNeeded()) {
      soundAnalyzer.startRecording()
    }

    delayInBackground(TimeUnit.SECONDS.toMillis(10L)) {
      soundAnalyzer.stopRecording()
    }
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

  private fun delayInBackground(delayInMillis: Long, callback: () -> Unit) {
    delayingJob = GlobalScope.launch {
      delay(delayInMillis)
      callback()
    }
  }
}
