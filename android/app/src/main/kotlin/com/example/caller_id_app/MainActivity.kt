package com.example.caller_id_app

import android.annotation.SuppressLint
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.caller_id_app/device_info"

    @SuppressLint("HardwareIds")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidId") {
                try {
                    val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
                    result.success(androidId)
                } catch (e: Exception) {
                    result.success("")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
