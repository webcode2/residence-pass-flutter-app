package com.elastrocloud.residence

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private var alarm: MediaPlayer? = null
    private val stopHandler = Handler(Looper.getMainLooper())
    private val stopDeadline = Runnable { stopAlarm() }
    private var alarms: MethodChannel? = null
    private val announcementAction = "residence.OPEN_ANNOUNCEMENT"
    private var announcements: MethodChannel? = null
    private var launchAnnouncement: Map<String, String>? = null
    private var launchAlert: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        launchAlert = sosAlert(intent)
        launchAnnouncement = announcementData(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sosAlert(intent)?.let { alarms?.invokeMethod("alertOpened", it) }
        announcementData(intent)?.let {
            announcements?.invokeMethod("opened", it)
        }
    }

    /** Respond from the ringing SOS: show over the lock screen, stop the ring, hand the alert to Flutter. */
    private fun sosAlert(intent: Intent?): Map<String, String>? {
        if (intent?.action != SosRinger.ACTION_OPEN) return null
        @Suppress("UNCHECKED_CAST", "DEPRECATION")
        val alert = intent.getSerializableExtra(SosRinger.EXTRA_ALERT) as? HashMap<String, String> ?: return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) { setShowWhenLocked(true); setTurnScreenOn(true) }
        SosRinger.cancel(this, alert["alert_id"])
        return alert
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createAlarmChannel()
        announcements = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "residence/announcements")
        announcements?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeLaunch" -> { result.success(launchAnnouncement); launchAnnouncement = null }
                "show" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
                            android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        result.success(null)
                    } else {
                        showAnnouncement(call.arguments as Map<*, *>)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        alarms = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "residence/alarms")
        alarms?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "initialize" -> { createAlarmChannel(); result.success(null) }
                    "badge" -> { if ((call.arguments as? Int ?: 0) == 0) clearInboxNotifications(); result.success(null) }
                    "stop" -> { stopAlarm(); result.success(null) }
                    "takeLaunchAlert" -> { result.success(launchAlert); launchAlert = null }
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
    private fun announcementData(intent: Intent?): Map<String, String>? {
        if (intent?.action != announcementAction) return null
        val id = intent.getStringExtra("announcement_id") ?: return null
        val estate = intent.getStringExtra("app_id") ?: return null
        return mapOf("type" to "announcement", "announcement_id" to id, "app_id" to estate)
    }

    private fun showAnnouncement(data: Map<*, *>) {
        val id = data["announcement_id"] as? String ?: return
        val estate = data["app_id"] as? String ?: return
        val urgent = data["category"] in listOf("alert", "security")
        val channel = if (urgent) "residence_announcements_urgent" else "residence_announcements_maintenance"
        val open = Intent(this, MainActivity::class.java).apply {
            action = announcementAction
            this.data = Uri.parse("residence://announcement/$id")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("announcement_id", id)
            putExtra("app_id", estate)
        }
        val tap = PendingIntent.getActivity(this, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val body = data["body"] as? String
        val notice = NotificationCompat.Builder(this, channel)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(data["title"] as? String)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(if (urgent) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_LOW)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify("announcement:$id", 0, notice)
    }

    private fun clearInboxNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        for (notice in manager.activeNotifications) {
            if (notice.tag?.startsWith("announcement:") != true) {
                manager.cancel(notice.tag, notice.id)
            }
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val chatChannel = NotificationChannel("residence_chat", "Gatehouse messages", NotificationManager.IMPORTANCE_HIGH)
            chatChannel.description = "Messages between your household and estate security"
            chatChannel.enableVibration(true)
            manager.createNotificationChannel(chatChannel)
            manager.createNotificationChannel(NotificationChannel(
                "residence_announcements_urgent", "Estate alerts and security", NotificationManager.IMPORTANCE_HIGH
            ))
            manager.createNotificationChannel(NotificationChannel(
                "residence_announcements_maintenance", "Estate maintenance", NotificationManager.IMPORTANCE_LOW
            ))
            manager.deleteNotificationChannel("residence_sos_v1")
            val reportChannel = NotificationChannel("residence_sos_reports_v1", "Estate SOS reports", NotificationManager.IMPORTANCE_DEFAULT)
            manager.createNotificationChannel(reportChannel)
            val channel = NotificationChannel("residence_sos_live_v2", "Estate SOS alarms", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Distress alarms from members of your estate"
            channel.enableVibration(true)
            channel.vibrationPattern = longArrayOf(0, 600, 250, 600, 250, 600)
            channel.setSound(Uri.parse("android.resource://$packageName/raw/sos_alarm"), AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build())
            manager.createNotificationChannel(channel)
            SosRinger.ensureChannel(this)
        }
    }
    private fun stopAlarm() { stopHandler.removeCallbacks(stopDeadline); alarm?.stop(); alarm?.release(); alarm = null }
    override fun onDestroy() { stopAlarm(); super.onDestroy() }
}
