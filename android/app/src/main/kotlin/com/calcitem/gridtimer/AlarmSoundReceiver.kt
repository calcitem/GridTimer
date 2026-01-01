package com.calcitem.gridtimer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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
        const val EXTRA_SOUND = "sound"
        const val EXTRA_LOOP = "loop"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        if (action != ACTION_FIRE) return

        val sound = intent.getStringExtra(EXTRA_SOUND) ?: "raw"
        val loop = intent.getBooleanExtra(EXTRA_LOOP, true)

        try {
            AlarmSoundService.start(context, sound = sound, loop = loop)
        } catch (e: Exception) {
            Log.e("AlarmSoundReceiver", "Failed to start AlarmSoundService: $e")
        }
    }
}

