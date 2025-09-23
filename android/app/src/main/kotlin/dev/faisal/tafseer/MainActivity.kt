package dev.faisal.tafseer

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // This should remove the blue screen
        setTheme(R.style.NormalTheme)
        
        // Enable edge-to-edge display for Android 15+ compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
        
        // Set transparent system bars
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        
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
