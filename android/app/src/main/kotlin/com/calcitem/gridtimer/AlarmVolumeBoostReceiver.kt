package com.calcitem.gridtimer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build

/**
 * Boosts the Android system alarm stream volume at ringing time and restores it later.
 *
 * This receiver is triggered by AlarmManager so it can run on lock screen (and even when the
 * Flutter engine is not running), improving alarm audibility and reliability.
 */
class AlarmVolumeBoostReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_BOOST -> handleBoost(context, intent)
            ACTION_RESTORE -> handleRestore(context)
        }
    }

    private fun handleBoost(context: Context, intent: Intent) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean(KEY_ACTIVE, false)
        if (!isActive) {
            // Save original volume only once for the first boost.
            prefs.edit()
                .putBoolean(KEY_ACTIVE, true)
                .putInt(KEY_ORIGINAL_VOLUME, currentVolume)
                .apply()
        }

        val level = intent.getStringExtra(EXTRA_LEVEL) ?: LEVEL_MIN_AUDIBLE
        val target = when (level) {
            LEVEL_MAX -> maxVolume
            else -> minimumAudibleTarget(maxVolume)
        }

        if (currentVolume < target) {
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, target, /* flags */ 0)
        }

        val restoreAfterMinutes = intent.getIntExtra(EXTRA_RESTORE_AFTER_MINUTES, 10)
        if (restoreAfterMinutes > 0) {
            scheduleRestore(context, restoreAfterMinutes)
        }
    }

    private fun handleRestore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean(KEY_ACTIVE, false)
        if (!isActive) return

        val original = prefs.getInt(KEY_ORIGINAL_VOLUME, -1)
        if (original < 0) {
            // Corrupted state; just clear the flag.
            prefs.edit().remove(KEY_ACTIVE).remove(KEY_ORIGINAL_VOLUME).apply()
            return
        }

        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, original, /* flags */ 0)

        prefs.edit()
            .remove(KEY_ACTIVE)
            .remove(KEY_ORIGINAL_VOLUME)
            .apply()
    }

    private fun scheduleRestore(context: Context, restoreAfterMinutes: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAtMs = System.currentTimeMillis() + restoreAfterMinutes * 60L * 1000L

        val restoreIntent = Intent(context, AlarmVolumeBoostReceiver::class.java).apply {
            action = ACTION_RESTORE
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            RESTORE_REQUEST_CODE,
            restoreIntent,
            pendingIntentFlags(updateCurrent = true),
        )

        // Best-effort: schedule a restore to avoid leaving alarm volume boosted.
        // Prefer exact, but fall back to inexact if exact alarms are restricted.
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                } catch (_: SecurityException) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
                }
            } else {
                try {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
                } catch (_: SecurityException) {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
                }
            }
        } catch (_: Exception) {
            // Ignore: restore is best-effort and can also be done from Flutter when user stops.
        }
    }

    private fun minimumAudibleTarget(maxVolume: Int): Int {
        // Use a conservative "minimum audible" target as half of max volume.
        // This is a compromise between audibility and user comfort.
        val half = (maxVolume + 1) / 2
        return maxOf(1, half)
    }

    private fun pendingIntentFlags(updateCurrent: Boolean): Int {
        var flags = if (updateCurrent) PendingIntent.FLAG_UPDATE_CURRENT else 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    companion object {
        const val ACTION_BOOST = "com.calcitem.gridtimer.ACTION_BOOST_ALARM_VOLUME"
        const val ACTION_RESTORE = "com.calcitem.gridtimer.ACTION_RESTORE_ALARM_VOLUME"

        const val EXTRA_LEVEL = "level"
        const val EXTRA_RESTORE_AFTER_MINUTES = "restoreAfterMinutes"

        const val LEVEL_MIN_AUDIBLE = "minimumAudible"
        const val LEVEL_MAX = "maximum"

        private const val PREFS_NAME = "gt_alarm_volume_boost"
        private const val KEY_ACTIVE = "active"
        private const val KEY_ORIGINAL_VOLUME = "original_alarm_volume"

        private const val RESTORE_REQUEST_CODE = 29999
    }
}
