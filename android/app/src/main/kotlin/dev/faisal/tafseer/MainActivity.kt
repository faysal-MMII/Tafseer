package dev.faisal.tafseer

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // This should remove the blue screen
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
