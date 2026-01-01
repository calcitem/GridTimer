package com.calcitem.gridtimer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import android.util.Log
import org.json.JSONObject

/**
 * Foreground service that plays alarm sound in a loop.
 *
 * This is used as a workaround for OEM ROMs (e.g., MIUI) that may silence
 * notification sounds even when channels are configured correctly.
 */
class AlarmSoundService : Service() {
    companion object {
        const val ACTION_START = "com.calcitem.gridtimer.action.ALARM_SOUND_START"
        const val ACTION_STOP = "com.calcitem.gridtimer.action.ALARM_SOUND_STOP"
        const val EXTRA_SOUND = "sound" // "raw"
        const val EXTRA_LOOP = "loop"

        private const val FGS_CHANNEL_ID = "gt.fgs.alarm"
        private const val FGS_NOTIFICATION_ID = 99001

        fun start(context: Context, sound: String, loop: Boolean) {
            val intent = Intent(context, AlarmSoundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_SOUND, sound)
                putExtra(EXTRA_LOOP, loop)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, AlarmSoundService::class.java).apply {
                action = ACTION_STOP
            }
            // Android 15+ enforces that every startForegroundService() call must be followed by
            // Service.startForeground() within a short time window. For STOP we should not
            // trigger a foreground-service start at all; just stop the service if it's running.
            context.stopService(intent)
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var focusGranted: Boolean = false
    private var audioFocusRequest: Any? = null

    private val audioAttrs: AudioAttributes =
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_STOP) {
            debugLog(
                location = "AlarmSoundService:onStartCommand",
                message = "Stop requested",
                data = mapOf(),
                hypothesisId = "SVC"
            )
            stopSelf()
            return START_NOT_STICKY
        }

        // Default start.
        val sound = intent?.getStringExtra(EXTRA_SOUND) ?: "raw"
        val loop = intent?.getBooleanExtra(EXTRA_LOOP, true) ?: true

        debugLog(
            location = "AlarmSoundService:onStartCommand",
            message = "Start requested",
            data = mapOf("sound" to sound, "loop" to loop),
            hypothesisId = "SVC"
        )

        startInForeground()
        requestAlarmAudioFocus()
        startPlayback(sound = sound, loop = loop)

        return START_STICKY
    }

    private fun startInForeground() {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                FGS_CHANNEL_ID,
                "Alarm Playback",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Foreground service for alarm playback"
            channel.setSound(null, null)
            notificationManager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(this, AlarmSoundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            stopFlags
        )

        val notification: Notification =
            NotificationCompat.Builder(this, FGS_CHANNEL_ID)
                .setSmallIcon(R.mipmap.launcher_icon)
                .setContentTitle("GridTimer Alarm")
                .setContentText("Playing alarm sound (foreground service)")
                .setOngoing(true)
                .addAction(
                    NotificationCompat.Action.Builder(
                        0,
                        "Stop",
                        stopPendingIntent
                    ).build()
                )
                .build()

        startForeground(FGS_NOTIFICATION_ID, notification)
    }

    private fun requestAlarmAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        focusGranted = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req =
                    android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(audioAttrs)
                        .setOnAudioFocusChangeListener { }
                        .build()
                audioFocusRequest = req
                audioManager.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    { },
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN
                ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            }
        } catch (_: Exception) {
            false
        }

        debugLog(
            location = "AlarmSoundService:requestAlarmAudioFocus",
            message = "Audio focus result",
            data = mapOf("granted" to focusGranted),
            hypothesisId = "SVC"
        )
    }

    private fun abandonAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req = audioFocusRequest
                if (req is android.media.AudioFocusRequest) {
                    audioManager.abandonAudioFocusRequest(req)
                }
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus { }
            }
        } catch (_: Exception) {
            // Ignore.
        }
        audioFocusRequest = null
        focusGranted = false
    }

    private fun startPlayback(sound: String, loop: Boolean) {
        stopPlayback()
        if (sound != "raw") {
            // Only raw supported for now.
            return
        }

        try {
            val afd = resources.openRawResourceFd(R.raw.sound)
            val mp = MediaPlayer()
            mp.setAudioAttributes(audioAttrs)
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mp.isLooping = loop
            mp.setOnErrorListener { _, _, _ ->
                stopSelf()
                true
            }
            mp.prepare()
            mp.start()
            mediaPlayer = mp

            debugLog(
                location = "AlarmSoundService:startPlayback",
                message = "Playback started",
                data = mapOf("sound" to sound, "loop" to loop),
                hypothesisId = "SVC"
            )
        } catch (_: Exception) {
            debugLog(
                location = "AlarmSoundService:startPlayback",
                message = "Playback failed",
                data = mapOf("sound" to sound),
                hypothesisId = "SVC"
            )
            stopSelf()
        }
    }

    private fun stopPlayback() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
            // Ignore.
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
            // Ignore.
        }
        mediaPlayer = null
    }

    override fun onDestroy() {
        debugLog(
            location = "AlarmSoundService:onDestroy",
            message = "Service destroyed",
            data = mapOf(),
            hypothesisId = "SVC"
        )
        stopPlayback()
        abandonAudioFocus()
        try {
            stopForeground(true)
        } catch (_: Exception) {
            // Ignore.
        }
        super.onDestroy()
    }

    private fun debugLog(
        location: String,
        message: String,
        data: Map<String, Any?>,
        hypothesisId: String
    ) {
        try {
            val obj = JSONObject()
            obj.put("location", location)
            obj.put("message", message)
            obj.put("timestamp", System.currentTimeMillis())
            obj.put("sessionId", "debug-session")
            obj.put("hypothesisId", hypothesisId)
            obj.put("data", JSONObject(data))
            Log.i("AGENT_DEBUG", obj.toString())
        } catch (_: Exception) {
            // Ignore.
        }
    }
}
