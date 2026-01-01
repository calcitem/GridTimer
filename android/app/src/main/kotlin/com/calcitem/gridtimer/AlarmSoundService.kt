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
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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
        const val EXTRA_VIBRATE = "vibrate"

        private const val FGS_CHANNEL_ID = "gt.fgs.alarm"
        private const val FGS_NOTIFICATION_ID = 99001

        fun start(context: Context, sound: String, loop: Boolean, vibrate: Boolean) {
            val intent = Intent(context, AlarmSoundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_SOUND, sound)
                putExtra(EXTRA_LOOP, loop)
                putExtra(EXTRA_VIBRATE, vibrate)
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
    private var ringtone: Ringtone? = null
    private val mainHandler: Handler = Handler(Looper.getMainLooper())
    private var ringtoneMonitor: Runnable? = null
    private var focusGranted: Boolean = false
    private var audioFocusRequest: Any? = null
    private var audioFocusChangeListener: AudioManager.OnAudioFocusChangeListener? = null

    private var resumeOnFocusGain: Boolean = false
    private var ducked: Boolean = false

    private var lastSound: String = "raw"
    private var lastLoop: Boolean = true
    private var lastVibrate: Boolean = false
    private var isVibrating: Boolean = false

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
            stopVibration()
            stopSelf()
            return START_NOT_STICKY
        }

        // Default start.
        val sound = intent?.getStringExtra(EXTRA_SOUND) ?: "raw"
        val loop = intent?.getBooleanExtra(EXTRA_LOOP, true) ?: true
        val vibrate = intent?.getBooleanExtra(EXTRA_VIBRATE, false) ?: false
        lastSound = sound
        lastLoop = loop
        lastVibrate = vibrate

        debugLog(
            location = "AlarmSoundService:onStartCommand",
            message = "Start requested",
            data = mapOf("sound" to sound, "loop" to loop, "vibrate" to vibrate),
            hypothesisId = "SVC"
        )

        startInForeground()
        requestAlarmAudioFocus()
        if (vibrate) {
            startVibration()
        } else {
            stopVibration()
        }
        startPlayback(sound = sound, loop = loop)

        return START_STICKY
    }

    private fun getVibrator(): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm =
                    getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun startVibration() {
        if (isVibrating) return

        val vib = getVibrator() ?: return
        val hasVibrator = try {
            vib.hasVibrator()
        } catch (_: Exception) {
            false
        }
        if (!hasVibrator) return

        // Repeat a simple waveform until the service is stopped.
        // Pattern: vibrate 400ms, pause 250ms, repeat.
        val pattern = longArrayOf(0L, 400L, 250L)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, 0)
                vib.vibrate(effect, audioAttrs)
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(pattern, 0, audioAttrs)
            }
            isVibrating = true
        } catch (e: Exception) {
            debugLog(
                location = "AlarmSoundService:startVibration",
                message = "Failed to start vibration",
                data = mapOf("error" to e.toString()),
                hypothesisId = "SVC"
            )
        }
    }

    private fun stopVibration() {
        if (!isVibrating) return
        val vib = getVibrator()
        try {
            vib?.cancel()
        } catch (_: Exception) {
            // Ignore.
        }
        isVibrating = false
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
        val listener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            handleAudioFocusChange(focusChange)
        }
        audioFocusChangeListener = listener
        focusGranted = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req =
                    android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(audioAttrs)
                        .setOnAudioFocusChangeListener(listener)
                        // Keep playing (duck) instead of auto-pausing on duck events.
                        .setWillPauseWhenDucked(false)
                        // Some OEM ROMs can delay focus; accept delayed grant.
                        .setAcceptsDelayedFocusGain(true)
                        .build()
                audioFocusRequest = req
                audioManager.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    listener,
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
                audioManager.abandonAudioFocus(audioFocusChangeListener)
            }
        } catch (_: Exception) {
            // Ignore.
        }
        audioFocusRequest = null
        audioFocusChangeListener = null
        focusGranted = false
    }

    private fun handleAudioFocusChange(focusChange: Int) {
        // This service exists to provide reliable alarm playback. Short system sounds
        // (e.g., chat notifications) can steal audio focus transiently; we should resume.
        val mp = mediaPlayer
        val rt = ringtone
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                if (ducked) {
                    try {
                        mp?.setVolume(1.0f, 1.0f)
                    } catch (_: Exception) {
                        // Ignore.
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        try {
                            rt?.setVolume(1.0f)
                        } catch (_: Exception) {
                            // Ignore.
                        }
                    }
                    ducked = false
                }
                if (resumeOnFocusGain) {
                    resumeOnFocusGain = false
                    try {
                        if (mp == null && rt == null) {
                            startPlayback(sound = lastSound, loop = lastLoop)
                        } else if (mp != null && !mp.isPlaying) {
                            mp.start()
                        } else if (rt != null && !rt.isPlaying) {
                            rt.play()
                        }
                    } catch (_: Exception) {
                        // As a fallback, rebuild the player.
                        startPlayback(sound = lastSound, loop = lastLoop)
                    }
                }
            }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Pause during the transient focus loss and resume when focus is regained.
                resumeOnFocusGain = true
                try {
                    if (mp != null && mp.isPlaying) {
                        mp.pause()
                    }
                } catch (_: Exception) {
                    // Ignore.
                }
                try {
                    if (rt != null && rt.isPlaying) {
                        rt.stop()
                    }
                } catch (_: Exception) {
                    // Ignore.
                }
            }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Keep playing, but lower the volume briefly.
                ducked = true
                try {
                    mp?.setVolume(0.2f, 0.2f)
                } catch (_: Exception) {
                    // Ignore.
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    try {
                        rt?.setVolume(0.2f)
                    } catch (_: Exception) {
                        // Ignore.
                    }
                }
            }

            AudioManager.AUDIOFOCUS_LOSS -> {
                // Treat as resumable: some OEM ROMs deliver LOSS for short interruptions.
                resumeOnFocusGain = true
                try {
                    if (mp != null && mp.isPlaying) {
                        mp.pause()
                    }
                } catch (_: Exception) {
                    // Ignore.
                }
                try {
                    if (rt != null && rt.isPlaying) {
                        rt.stop()
                    }
                } catch (_: Exception) {
                    // Ignore.
                }
            }
        }
    }

    private fun startPlayback(sound: String, loop: Boolean) {
        stopPlayback()

        val isRaw =
            sound == "raw" ||
                (sound.startsWith("android.resource://") && sound.endsWith("/raw/sound"))

        fun tryStartMediaPlayer(configureDataSource: (MediaPlayer) -> Unit, attempt: String): Boolean {
            val mp = MediaPlayer()
            return try {
                mp.setAudioAttributes(audioAttrs)
                configureDataSource(mp)
                mp.isLooping = loop
                if (!loop) {
                    mp.setOnCompletionListener {
                        stopSelf()
                    }
                }
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
                    data = mapOf(
                        "sound" to sound,
                        "loop" to loop,
                        "engine" to "MediaPlayer",
                        "attempt" to attempt
                    ),
                    hypothesisId = "SVC"
                )
                true
            } catch (e: Exception) {
                try {
                    mp.release()
                } catch (_: Exception) {
                    // Ignore.
                }
                debugLog(
                    location = "AlarmSoundService:startPlayback",
                    message = "MediaPlayer playback failed",
                    data = mapOf(
                        "sound" to sound,
                        "loop" to loop,
                        "attempt" to attempt,
                        "error" to e.toString()
                    ),
                    hypothesisId = "SVC"
                )
                false
            }
        }

        fun tryStartRingtone(uri: Uri): Boolean {
            return try {
                val rt = RingtoneManager.getRingtone(this, uri)
                if (rt == null) {
                    debugLog(
                        location = "AlarmSoundService:startPlayback",
                        message = "Ringtone is null",
                        data = mapOf("sound" to sound, "uri" to uri.toString()),
                        hypothesisId = "SVC"
                    )
                    false
                } else {
                    try {
                        rt.setAudioAttributes(audioAttrs)
                    } catch (_: Exception) {
                        // Ignore.
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        try {
                            rt.isLooping = loop
                        } catch (_: Exception) {
                            // Ignore.
                        }
                    }
                    rt.play()
                    ringtone = rt
                    startRingtoneMonitor(loop = loop)
                    debugLog(
                        location = "AlarmSoundService:startPlayback",
                        message = "Playback started",
                        data = mapOf(
                            "sound" to sound,
                            "loop" to loop,
                            "engine" to "Ringtone",
                            "uri" to uri.toString()
                        ),
                        hypothesisId = "SVC"
                    )
                    true
                }
            } catch (e: Exception) {
                debugLog(
                    location = "AlarmSoundService:startPlayback",
                    message = "Ringtone playback failed",
                    data = mapOf(
                        "sound" to sound,
                        "loop" to loop,
                        "error" to e.toString()
                    ),
                    hypothesisId = "SVC"
                )
                false
            }
        }

        // Attempt 1: bundled raw alarm sound.
        if (isRaw) {
            val started = tryStartMediaPlayer(
                configureDataSource = { mp ->
                    val afd = resources.openRawResourceFd(R.raw.sound)
                    mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                },
                attempt = "raw_resource"
            )
            if (!started) {
                stopSelf()
            }
            return
        }

        // Non-raw: channel sound may be a content:// or file:// Uri depending on ROM/version.
        val uri = Uri.parse(sound)

        // Attempt 2: MediaPlayer with Context + Uri.
        if (tryStartMediaPlayer(configureDataSource = { mp -> mp.setDataSource(this, uri) }, attempt = "context_uri")) {
            return
        }

        // Attempt 3: MediaPlayer with plain file path (some ROMs may persist the sound as a path-like Uri).
        val path: String? =
            when (uri.scheme) {
                null -> sound
                "file" -> uri.path
                else -> null
            }
        if (!path.isNullOrBlank()) {
            if (tryStartMediaPlayer(configureDataSource = { mp -> mp.setDataSource(path) }, attempt = "file_path")) {
                return
            }
        }

        // Attempt 4: Ringtone fallback (often more compatible with notification channel sound Uris).
        if (tryStartRingtone(uri)) {
            return
        }

        // Best-effort fallback: if a custom sound fails to play, fall back to bundled raw sound.
        try {
            startPlayback(sound = "raw", loop = loop)
        } catch (_: Exception) {
            stopSelf()
        }
    }

    private fun stopPlayback() {
        ringtoneMonitor?.let {
            try {
                mainHandler.removeCallbacks(it)
            } catch (_: Exception) {
                // Ignore.
            }
        }
        ringtoneMonitor = null
        try {
            ringtone?.stop()
        } catch (_: Exception) {
            // Ignore.
        }
        ringtone = null
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

    private fun startRingtoneMonitor(loop: Boolean) {
        ringtoneMonitor?.let {
            try {
                mainHandler.removeCallbacks(it)
            } catch (_: Exception) {
                // Ignore.
            }
        }
        ringtoneMonitor = null

        val runnable = object : Runnable {
            override fun run() {
                val rt = ringtone
                if (rt == null) return
                val isPlaying = try {
                    rt.isPlaying
                } catch (_: Exception) {
                    false
                }

                if (!isPlaying) {
                    if (loop && Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                        // Best-effort manual looping on older Android versions without setLooping().
                        try {
                            rt.play()
                        } catch (_: Exception) {
                            stopSelf()
                            return
                        }
                        mainHandler.postDelayed(this, 500)
                        return
                    }

                    // No reliable completion callback for Ringtone. Stop the service when playback ends.
                    stopSelf()
                    return
                }

                mainHandler.postDelayed(this, 500)
            }
        }

        ringtoneMonitor = runnable
        mainHandler.postDelayed(runnable, 500)
    }

    override fun onDestroy() {
        debugLog(
            location = "AlarmSoundService:onDestroy",
            message = "Service destroyed",
            data = mapOf(),
            hypothesisId = "SVC"
        )
        stopVibration()
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
