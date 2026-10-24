package com.example.estate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private var alarm: MediaPlayer? = null
    private val stopHandler = Handler(Looper.getMainLooper())
    private val stopDeadline = Runnable { stopAlarm() }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createAlarmChannel()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "residence/alarms").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "initialize" -> { createAlarmChannel(); result.success(null) }
                    "badge" -> { if ((call.arguments as? Int ?: 0) == 0) (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancelAll(); result.success(null) }
                    "stop" -> { stopAlarm(); result.success(null) }
                    "start" -> {
                        stopAlarm()
                        val bytes = call.arguments as ByteArray
                        val file = File(cacheDir, "sos_alarm.wav")
                        file.writeBytes(bytes)
                        alarm = MediaPlayer().apply {
                            setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                            setDataSource(file.path); isLooping = true; prepare(); start()
                        }
                        stopHandler.postDelayed(stopDeadline, 30000)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { stopAlarm(); result.error("ALARM_ERROR", "Unable to play alarm", null) }
        }
    }
    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val chatChannel = NotificationChannel("residence_chat", "Gatehouse messages", NotificationManager.IMPORTANCE_HIGH)
            chatChannel.description = "Messages between your household and estate security"
            chatChannel.enableVibration(true)
            manager.createNotificationChannel(chatChannel)
            manager.deleteNotificationChannel("residence_sos_v1")
            val reportChannel = NotificationChannel("residence_sos_reports_v1", "Estate SOS reports", NotificationManager.IMPORTANCE_DEFAULT)
            manager.createNotificationChannel(reportChannel)
            val channel = NotificationChannel("residence_sos_live_v2", "Estate SOS alarms", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Distress alarms from members of your estate"
            channel.enableVibration(true)
            channel.vibrationPattern = longArrayOf(0, 600, 250, 600, 250, 600)
            channel.setSound(Uri.parse("android.resource://$packageName/raw/sos_alarm"), AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build())
            manager.createNotificationChannel(channel)
        }
    }
    private fun stopAlarm() { stopHandler.removeCallbacks(stopDeadline); alarm?.stop(); alarm?.release(); alarm = null }
    override fun onDestroy() { stopAlarm(); super.onDestroy() }
}
