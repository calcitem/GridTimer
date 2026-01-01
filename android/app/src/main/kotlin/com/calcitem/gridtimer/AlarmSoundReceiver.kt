package com.calcitem.gridtimer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.os.Build
import android.util.Log

/**
 * Receives exact alarm broadcasts and starts the foreground alarm sound service.
 *
 * This receiver exists to make alarm playback reliable even when the Flutter
 * process is killed or not running. Relying on notification channel sound alone
 * is not sufficient on some devices/ROMs: it may be silenced or stopped after a
 * short time window.
 */
class AlarmSoundReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_FIRE = "com.calcitem.gridtimer.action.ALARM_SOUND_FIRE"
        const val EXTRA_CHANNEL_ID = "channelId"
        const val EXTRA_SOUND = "sound"
        const val EXTRA_LOOP = "loop"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        if (action != ACTION_FIRE) return

        val loop = intent.getBooleanExtra(EXTRA_LOOP, true)

        try {
            val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID)
            val resolvedSound: String? =
                if (!channelId.isNullOrBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val nm =
                        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val channel = nm.getNotificationChannel(channelId)
                    if (channel != null) {
                        // If the user sets the channel sound to "None", Android reports sound == null.
                        val soundUri = channel.sound
                        soundUri?.toString()
                    } else {
                        null
                    }
                } else {
                    null
                }

            // If we have a channel but it has no sound, respect user's choice: no alarm audio.
            if (!channelId.isNullOrBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val channel = nm.getNotificationChannel(channelId)
                if (channel != null && channel.sound == null) {
                    return
                }
            }

            val soundFallback = intent.getStringExtra(EXTRA_SOUND) ?: "raw"
            val soundToPlay = resolvedSound ?: soundFallback

            AlarmSoundService.start(context, sound = soundToPlay, loop = loop)
        } catch (e: Exception) {
            Log.e("AlarmSoundReceiver", "Failed to start AlarmSoundService: $e")
        }
    }
}
