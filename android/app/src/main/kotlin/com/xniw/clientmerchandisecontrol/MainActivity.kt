package com.xniw.clientmerchandisecontrol

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

class MainActivity : FlutterActivity() {
    private var addressDurabilityChannel: MethodChannel? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val appContext = applicationContext
        addressDurabilityChannel = MethodChannel(
            messenger,
            AddressCreationDurability.CHANNEL,
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue(),
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "flush" || call.arguments != null) {
                    result.notImplemented()
                } else {
                    try {
                        val persisted = AddressCreationDurability.flush { name ->
                            // commit attende anche gli apply del plugin nello stesso file.
                            // Il marker non contiene dati del cliente e forza una scrittura.
                            appContext.getSharedPreferences(name, Context.MODE_PRIVATE)
                                .edit()
                                .putLong(AddressCreationDurability.MARKER, System.nanoTime())
                                .commit()
                        }
                        result.success(persisted)
                    } catch (_: Exception) {
                        result.error("address_journal_flush_failed", null, null)
                    }
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DELIVERY_MAP_CONFIGURATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "isConfigured") {
                result.success(isDeliveryMapConfigured())
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        addressDurabilityChannel?.setMethodCallHandler(null)
        addressDurabilityChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

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

    @Suppress("DEPRECATION")
    private fun isDeliveryMapConfigured(): Boolean {
        val metadata = try {
            packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA,
            ).metaData
        } catch (_: PackageManager.NameNotFoundException) {
            return false
        }
        val apiKey = metadata?.getString("com.google.android.geo.API_KEY")
        return !apiKey.isNullOrBlank() && apiKey != "NOT_CONFIGURED"
    }

    private companion object {
        const val DELIVERY_MAP_CONFIGURATION_CHANNEL =
            "com.xniw.clientmerchandisecontrol/delivery_map_configuration"
    }
}
