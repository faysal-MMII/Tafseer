package dev.faisal.tafseer

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Override the configureFlutterEngine method
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up the MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.channel/info")
            .setMethodCallHandler { call, result ->
                if (call.method == "getAndroidVersion") {
                    result.success(Build.VERSION.RELEASE)
                } else {
                    result.notImplemented()
                }
            }
    }
}
