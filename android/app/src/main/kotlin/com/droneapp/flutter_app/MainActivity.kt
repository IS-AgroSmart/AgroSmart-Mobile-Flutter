package com.droneapp.flutter_app

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import android.os.Environment

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.droneapp.flutter_app/downloads"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->
            when (call.method) {
                "getDownloadsFolder" -> result.success(getDownloadsFolder())
                else -> result.notImplemented()
            }
        }
    }

    private fun getDownloadsFolder(): String {
        return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).getAbsolutePath();
    }
}
