package com.calcitem.gridtimer

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val systemSettingsChannelName = "com.calcitem.gridtimer/system_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemSettingsChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationChannelSettings" -> {
                    val channelId = call.argument<String>("channelId")
                    if (channelId.isNullOrBlank()) {
                        result.error("invalid_args", "channelId must not be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback: open the app notification settings page (some OEM ROMs/versions
                        // may not support the channel settings intent).
                        try {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("open_failed", e2.toString(), null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}



