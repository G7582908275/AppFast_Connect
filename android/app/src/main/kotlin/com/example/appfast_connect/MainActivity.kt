package com.widewired.appfast_connect

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册Flutter VPN插件
        flutterEngine.plugins.add(FlutterVPNPlugin())
    }
}
