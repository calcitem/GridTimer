package com.calcitem.gridtimer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val systemSettingsChannelName = "com.calcitem.gridtimer/system_settings"
    private var testRingtone: Ringtone? = null

    /** Check if the device is running MIUI (Xiaomi/Redmi). */
    private fun isMiuiDevice(): Boolean {
        try {
            val clazz = Class.forName("android.os.SystemProperties")
            val getMethod = clazz.getMethod("get", String::class.java)
            val miuiVersion = getMethod.invoke(null, "ro.miui.ui.version.name") as? String
            if (!miuiVersion.isNullOrEmpty()) {
                return true
            }
        } catch (e: Exception) {
            // Ignore reflection errors
        }

        // Fallback: check manufacturer
        return Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true) ||
               Build.MANUFACTURER.equals("Redmi", ignoreCase = true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemSettingsChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNotificationChannelInfo" -> {
                    val channelId = call.argument<String>("channelId")
                    if (channelId.isNullOrBlank()) {
                        result.error("invalid_args", "channelId must not be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        val channel = notificationManager.getNotificationChannel(channelId)

                        val info = HashMap<String, Any?>()
                        info["areNotificationsEnabled"] = notificationManager.areNotificationsEnabled()
                        info["interruptionFilter"] = notificationManager.currentInterruptionFilter
                        info["notificationPolicyAccessGranted"] = notificationManager.isNotificationPolicyAccessGranted

                        if (channel != null) {
                            info["exists"] = true
                            info["id"] = channel.id
                            info["name"] = channel.name?.toString()
                            info["importance"] = channel.importance
                            info["sound"] = channel.sound?.toString()
                            info["vibrationEnabled"] = channel.shouldVibrate()
                            info["soundEnabled"] = channel.importance >= NotificationManager.IMPORTANCE_DEFAULT
                            info["description"] = channel.description
                            info["canBypassDnd"] = channel.canBypassDnd()
                            info["lockscreenVisibility"] = channel.lockscreenVisibility
                            info["audioAttributesUsage"] = channel.audioAttributes?.usage
                            info["audioAttributesContentType"] = channel.audioAttributes?.contentType
                        } else {
                            info["exists"] = false
                        }

                        // Also get audio volume info
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        info["alarmVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
                        info["alarmVolumeMax"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                        info["notificationVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
                        info["notificationVolumeMax"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_NOTIFICATION)
                        info["ringerMode"] = audioManager.ringerMode
                        info["androidSdk"] = Build.VERSION.SDK_INT
                        info["manufacturer"] = Build.MANUFACTURER
                        info["model"] = Build.MODEL

                        result.success(info)
                    } catch (e: Exception) {
                        result.error("get_channel_failed", e.toString(), null)
                    }
                }

                "playSystemTone" -> {
                    val type = call.argument<String>("type") ?: "notification"
                    val toneType = when (type) {
                        "alarm" -> RingtoneManager.TYPE_ALARM
                        else -> RingtoneManager.TYPE_NOTIFICATION
                    }

                    try {
                        val uri: Uri? = RingtoneManager.getDefaultUri(toneType)
                        if (uri == null) {
                            result.error("no_uri", "Default uri is null for type=$type", null)
                            return@setMethodCallHandler
                        }

                        // Stop previous tone first.
                        try {
                            testRingtone?.stop()
                        } catch (_: Exception) {
                            // Ignore.
                        }

                        val ringtone = RingtoneManager.getRingtone(this, uri)
                        if (ringtone == null) {
                            result.error("no_ringtone", "Ringtone is null for uri=$uri", null)
                            return@setMethodCallHandler
                        }

                        testRingtone = ringtone
                        ringtone.play()
                        val info = HashMap<String, Any?>()
                        info["type"] = type
                        info["uri"] = uri.toString()
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("play_failed", e.toString(), null)
                    }
                }

                "stopSystemTone" -> {
                    try {
                        testRingtone?.stop()
                        testRingtone = null
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("stop_failed", e.toString(), null)
                    }
                }

                "nativeShowNotificationTest" -> {
                    val channelId = call.argument<String>("channelId")
                    val usage = call.argument<String>("usage") ?: "notification"
                    val sound = call.argument<String>("sound") ?: "raw"
                    val notificationId = call.argument<Int>("notificationId") ?: 88001

                    if (channelId.isNullOrBlank()) {
                        result.error("invalid_args", "channelId must not be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val importance = NotificationManager.IMPORTANCE_HIGH
                            val channel = android.app.NotificationChannel(
                                channelId,
                                "Native Test ($usage/$sound)",
                                importance
                            )
                            channel.description = "Native test channel created by debug instrumentation"
                            channel.enableVibration(true)

                            val soundUri: Uri? = when (sound) {
                                "defaultNotification" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                                "defaultAlarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                else -> Uri.parse("android.resource://${packageName}/raw/sound")
                            }

                            if (soundUri != null) {
                                val usageValue = when (usage) {
                                    "alarm" -> AudioAttributes.USAGE_ALARM
                                    else -> AudioAttributes.USAGE_NOTIFICATION
                                }
                                val attrs = AudioAttributes.Builder()
                                    .setUsage(usageValue)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build()
                                channel.setSound(soundUri, attrs)
                            }

                            notificationManager.createNotificationChannel(channel)
                        }

                        val builder = NotificationCompat.Builder(this, channelId)
                            .setSmallIcon(R.mipmap.launcher_icon)
                            .setContentTitle("Native Test Notification")
                            .setContentText("Channel=$channelId usage=$usage sound=$sound")
                            .setPriority(NotificationCompat.PRIORITY_MAX)
                            .setCategory(NotificationCompat.CATEGORY_ALARM)
                            .setAutoCancel(true)

                        notificationManager.notify(notificationId, builder.build())

                        val info = HashMap<String, Any?>()
                        info["channelId"] = channelId
                        info["usage"] = usage
                        info["sound"] = sound
                        info["notificationId"] = notificationId
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("native_show_failed", e.toString(), null)
                    }
                }

                "startAlarmSoundService" -> {
                    val sound = call.argument<String>("sound") ?: "raw"
                    val loop = call.argument<Boolean>("loop") ?: true
                    try {
                        AlarmSoundService.start(this, sound = sound, loop = loop)
                        val info = HashMap<String, Any?>()
                        info["started"] = true
                        info["sound"] = sound
                        info["loop"] = loop
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("start_service_failed", e.toString(), null)
                    }
                }

                "stopAlarmSoundService" -> {
                    try {
                        AlarmSoundService.stop(this)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("stop_service_failed", e.toString(), null)
                    }
                }

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
                        // Dart side uses invokeMethod<void>(), so we must return null here.
                        // Otherwise it will trigger a type conversion exception, causing the
                        // appearance of "navigating and immediately returning".
                        result.success(null)
                    } catch (e: Exception) {
                        // Fallback: open the app notification settings page (some OEM ROMs/versions
                        // may not support the channel settings intent).
                        try {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            // Same as above: maintain compatibility with invokeMethod<void>()
                            result.success(null)
                        } catch (e2: Exception) {
                            result.error("open_failed", e2.toString(), null)
                        }
                    }
                }

                "openTtsSettings" -> {
                    // Try multiple methods to open TTS settings, as different Android versions
                    // and OEM ROMs may require different intents
                    val intentsToTry = listOf(
                        // Standard TTS settings action
                        Intent("com.android.settings.TTS_SETTINGS"),
                        // Alternative: TextToSpeech settings activity
                        Intent().apply {
                            action = Intent.ACTION_MAIN
                            setClassName(
                                "com.android.settings",
                                "com.android.settings.Settings\$TextToSpeechSettingsActivity"
                            )
                        },
                        // Xiaomi/MIUI specific
                        Intent().apply {
                            action = Intent.ACTION_MAIN
                            setClassName(
                                "com.android.settings",
                                "com.android.settings.Settings\$AccessibilitySettingsActivity"
                            )
                        },
                        // Final fallback: accessibility settings
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    )

                    var success = false
                    for (intent in intentsToTry) {
                        try {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            success = true
                            break
                        } catch (e: Exception) {
                            // Try next intent
                        }
                    }

                    if (success) {
                        result.success(null)
                    } else {
                        result.error("open_failed", "Could not open TTS settings", null)
                    }
                }

                "isIgnoringBatteryOptimizations" -> {
                    try {
                        // On MIUI, the standard API may not reflect the actual MIUI battery
                        // saver settings. Return null to indicate "unknown" status.
                        if (isMiuiDevice()) {
                            result.success(null)
                        } else {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                            result.success(isIgnoring)
                        }
                    } catch (e: Exception) {
                        // If we can't determine, return null to indicate unknown
                        result.success(null)
                    }
                }

                "isMiuiDevice" -> {
                    result.success(isMiuiDevice())
                }

                "openBatteryOptimizationSettings" -> {
                    // Try multiple intents for battery optimization settings,
                    // including MIUI-specific ones
                    val intentsToTry = mutableListOf<Intent>()

                    // For MIUI devices, try MIUI-specific intents first
                    if (isMiuiDevice()) {
                        // MIUI app battery saver settings (most direct)
                        intentsToTry.add(Intent().apply {
                            setClassName(
                                "com.miui.powerkeeper",
                                "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"
                            )
                            putExtra("package_name", packageName)
                            putExtra("package_label", applicationInfo.loadLabel(packageManager))
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })

                        // MIUI Security Center - Battery settings
                        intentsToTry.add(Intent().apply {
                            setClassName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.autostart.AutoStartManagementActivity"
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })

                        // MIUI Power Keeper main activity
                        intentsToTry.add(Intent().apply {
                            setClassName(
                                "com.miui.powerkeeper",
                                "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity"
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                    }

                    // Standard Android: Request to ignore battery optimizations (shows a dialog)
                    intentsToTry.add(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    // Standard Android: Battery optimization settings list
                    intentsToTry.add(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    // Fallback: App details settings (user can find battery settings there)
                    intentsToTry.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    var success = false
                    var lastError: Exception? = null

                    for (intent in intentsToTry) {
                        try {
                            // Check if there's an activity to handle this intent
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                success = true
                                break
                            }
                        } catch (e: Exception) {
                            lastError = e
                            // Try next intent
                        }
                    }

                    // If resolveActivity didn't find anything, try starting anyway
                    // (some intents work even when resolveActivity returns null)
                    if (!success) {
                        for (intent in intentsToTry) {
                            try {
                                startActivity(intent)
                                success = true
                                break
                            } catch (e: Exception) {
                                lastError = e
                                // Try next intent
                            }
                        }
                    }

                    if (success) {
                        result.success(null)
                    } else {
                        result.error(
                            "open_failed",
                            "Could not open battery optimization settings: ${lastError?.message}",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
