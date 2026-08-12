package com.xniw.clientmerchandisecontrol

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        mapNotificationDeepLink(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        mapNotificationDeepLink(intent)
        super.onNewIntent(intent)
    }

    private fun mapNotificationDeepLink(intent: Intent) {
        if (intent.data != null) return
        val canonical = CustomerNotificationDeepLinkMapper.canonicalDeepLink(
            intent.getStringExtra("deepLink"),
        ) ?: return
        intent.data = Uri.parse(canonical)
        intent.removeExtra("deepLink")
    }
}
