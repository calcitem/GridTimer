package com.calcitem.gridtimer

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
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
import android.view.KeyEvent
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val systemSettingsChannelName = "com.calcitem.gridtimer/system_settings"
    private val volumeKeyEventChannelName = "com.calcitem.gridtimer/volume_key_events"
    private var testRingtone: Ringtone? = null
    private var volumeKeyEventSink: EventChannel.EventSink? = null
    private var lastVolumeKeyEventAtMs: Long = 0L
    private val volumeKeyThrottleMs: Long = 150L

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

    /** Check if the device is running EMUI/HarmonyOS (Honor/Huawei). */
    private fun isHonorHuaweiDevice(): Boolean {
        try {
            val clazz = Class.forName("android.os.SystemProperties")
            val getMethod = clazz.getMethod("get", String::class.java)
            val emuiVersion = getMethod.invoke(null, "ro.build.version.emui") as? String
            if (!emuiVersion.isNullOrEmpty()) {
                return true
            }
            val harmonyVersion = getMethod.invoke(null, "hw_sc.build.platform.version") as? String
            if (!harmonyVersion.isNullOrEmpty()) {
                return true
            }
        } catch (e: Exception) {
            // Ignore reflection errors
        }

        // Fallback: check manufacturer
        return Build.MANUFACTURER.equals("HUAWEI", ignoreCase = true) ||
               Build.MANUFACTURER.equals("HONOR", ignoreCase = true)
    }

    /** Get the device manufacturer category for specific handling. */
    private fun getDeviceManufacturerType(): String {
        return when {
            isMiuiDevice() -> "miui"
            isHonorHuaweiDevice() -> "honor_huawei"
            else -> "standard"
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            volumeKeyEventChannelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                volumeKeyEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                volumeKeyEventSink = null
            }
        })

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

                "scheduleAlarmVolumeBoost" -> {
                    val requestCode = call.argument<Int>("requestCode")
                    val triggerAtAny = call.argument<Any>("triggerAtEpochMs")
                    val level = call.argument<String>("level") ?: AlarmVolumeBoostReceiver.LEVEL_MIN_AUDIBLE
                    val restoreAfterMinutes = call.argument<Int>("restoreAfterMinutes") ?: 10

                    val triggerAtEpochMs = when (triggerAtAny) {
                        is Int -> triggerAtAny.toLong()
                        is Long -> triggerAtAny
                        is Double -> triggerAtAny.toLong()
                        else -> null
                    }

                    if (requestCode == null || triggerAtEpochMs == null) {
                        result.error("invalid_args", "requestCode/triggerAtEpochMs required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmVolumeBoostReceiver::class.java).apply {
                            action = AlarmVolumeBoostReceiver.ACTION_BOOST
                            putExtra(AlarmVolumeBoostReceiver.EXTRA_LEVEL, level)
                            putExtra(AlarmVolumeBoostReceiver.EXTRA_RESTORE_AFTER_MINUTES, restoreAfterMinutes)
                        }

                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            requestCode,
                            intent,
                            pendingIntentFlags(updateCurrent = true),
                        )

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                triggerAtEpochMs,
                                pendingIntent,
                            )
                        } else {
                            alarmManager.setExact(
                                AlarmManager.RTC_WAKEUP,
                                triggerAtEpochMs,
                                pendingIntent,
                            )
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("schedule_failed", e.toString(), null)
                    }
                }

                "cancelAlarmVolumeBoost" -> {
                    val requestCode = call.argument<Int>("requestCode")
                    if (requestCode == null) {
                        result.error("invalid_args", "requestCode required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmVolumeBoostReceiver::class.java).apply {
                            action = AlarmVolumeBoostReceiver.ACTION_BOOST
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            requestCode,
                            intent,
                            pendingIntentFlagsNoCreate(),
                        )
                        if (pendingIntent != null) {
                            alarmManager.cancel(pendingIntent)
                            pendingIntent.cancel()
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("cancel_failed", e.toString(), null)
                    }
                }

                "boostAlarmVolumeNow" -> {
                    val level = call.argument<String>("level") ?: AlarmVolumeBoostReceiver.LEVEL_MIN_AUDIBLE
                    val restoreAfterMinutes = call.argument<Int>("restoreAfterMinutes") ?: 10
                    try {
                        val intent = Intent(this, AlarmVolumeBoostReceiver::class.java).apply {
                            action = AlarmVolumeBoostReceiver.ACTION_BOOST
                            putExtra(AlarmVolumeBoostReceiver.EXTRA_LEVEL, level)
                            putExtra(AlarmVolumeBoostReceiver.EXTRA_RESTORE_AFTER_MINUTES, restoreAfterMinutes)
                        }
                        sendBroadcast(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("boost_failed", e.toString(), null)
                    }
                }

                "restoreAlarmVolumeNow" -> {
                    try {
                        val intent = Intent(this, AlarmVolumeBoostReceiver::class.java).apply {
                            action = AlarmVolumeBoostReceiver.ACTION_RESTORE
                        }
                        sendBroadcast(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("restore_failed", e.toString(), null)
                    }
                }

                "getActiveTimeUpNotificationCount" -> {
                    try {
                        val notificationManager =
                            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val active = notificationManager.activeNotifications
                            val count = active.count { it.id in 1000..1008 }
                            result.success(count)
                        } else {
                            result.success(0)
                        }
                    } catch (_: Exception) {
                        // Unknown. Dart side treats null as "safe to restore".
                        result.success(null)
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

                "getDeviceManufacturerType" -> {
                    result.success(getDeviceManufacturerType())
                }

                "openBatteryOptimizationSettings" -> {
                    // Try multiple intents for battery optimization settings,
                    // with manufacturer-specific optimizations for MIUI, Honor, Huawei, etc.
                    val intentsToTry = mutableListOf<Intent>()
                    val manufacturerType = getDeviceManufacturerType()

                    // Priority 1: Manufacturer-specific battery settings
                    // We skip ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS because it requires 
                    // the high-risk REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission, which often 
                    // leads to Google Play rejection for non-core apps.
                    when (manufacturerType) {
                        "miui" -> {
                            // MIUI-specific battery saver settings
                            intentsToTry.add(Intent().apply {
                                setClassName(
                                    "com.miui.powerkeeper",
                                    "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"
                                )
                                putExtra("package_name", packageName)
                                putExtra("package_label", applicationInfo.loadLabel(packageManager))
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            intentsToTry.add(Intent().apply {
                                action = "miui.intent.action.POWER_SAVE_MODE_SETTING"
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            intentsToTry.add(Intent().apply {
                                setClassName(
                                    "com.miui.powerkeeper",
                                    "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                        }
                        "honor_huawei" -> {
                            // Honor/Huawei EMUI/HarmonyOS specific battery settings
                            // These intents are tested on Honor and Huawei devices
                            
                            // Method 1: Direct to app launch management (most reliable)
                            intentsToTry.add(Intent().apply {
                                setClassName(
                                    "com.huawei.systemmanager",
                                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            // Method 2: Power consumption detail page for this app
                            intentsToTry.add(Intent().apply {
                                setClassName(
                                    "com.huawei.systemmanager",
                                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            // Method 3: App battery optimization detail page
                            intentsToTry.add(Intent().apply {
                                action = "huawei.intent.action.POWER_MANAGER"
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            // Method 4: Protected apps settings (older EMUI versions)
                            intentsToTry.add(Intent().apply {
                                setClassName(
                                    "com.huawei.systemmanager",
                                    "com.huawei.systemmanager.optimize.process.ProtectActivity"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })

                            // Method 5: System manager main page (user can navigate from there)
                            intentsToTry.add(Intent().apply {
                                action = Intent.ACTION_MAIN
                                setClassName(
                                    "com.huawei.systemmanager",
                                    "com.huawei.systemmanager.MainActivity"
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                        }
                    }

                    // Priority 3: Standard Android battery optimization list
                    intentsToTry.add(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    // Priority 4: App details settings (universal fallback)
                    intentsToTry.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    // Priority 5: General settings as last resort
                    intentsToTry.add(Intent(Settings.ACTION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })

                    var success = false
                    var lastError: Exception? = null

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

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> emitVolumeKeyEvent(direction = "up")
                KeyEvent.KEYCODE_VOLUME_DOWN -> emitVolumeKeyEvent(direction = "down")
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun emitVolumeKeyEvent(direction: String) {
        val now = System.currentTimeMillis()
        if (now - lastVolumeKeyEventAtMs < volumeKeyThrottleMs) return
        lastVolumeKeyEventAtMs = now
        volumeKeyEventSink?.success(direction)
    }

    private fun pendingIntentFlags(updateCurrent: Boolean): Int {
        var flags = if (updateCurrent) PendingIntent.FLAG_UPDATE_CURRENT else 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    private fun pendingIntentFlagsNoCreate(): Int {
        var flags = PendingIntent.FLAG_NO_CREATE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }
}
