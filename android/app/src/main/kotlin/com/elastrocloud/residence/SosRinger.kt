package com.elastrocloud.residence

import android.app.ActivityManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import java.time.Instant

/**
 * Rings a live SOS like an incoming call while the app is closed or in the background:
 * a looping (insistent) alarm sound, full-screen over the lock screen, with Respond / Dismiss.
 * It stops when the user acts or when the 30-second siren window ends.
 */
object SosRinger {
    const val CHANNEL = "residence_sos_ring_v3"
    const val ACTION_OPEN = "com.elastrocloud.residence.SOS_OPEN"
    const val ACTION_DISMISS = "com.elastrocloud.residence.SOS_DISMISS"
    const val EXTRA_ALERT = "sos_alert"
    private const val MAX_RING_MS = 30_000L
    private const val NOTIFICATION_ID = 7001

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(CHANNEL, "Estate SOS calls", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Rings like a call when an estate member raises an SOS"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(soundUri(context), AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
        }
        manager(context).createNotificationChannel(channel)
    }

    /** Remaining ring time for a live alert, or null when it must not ring (late, resolved, malformed). */
    fun remainingMs(data: Map<String, String>, now: Long = System.currentTimeMillis()): Long? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null // ponytail: pre-Android 8 keeps the plain notification
        if (data["type"] != "sos_live" || data["status"] == "resolved" || data["alert_id"].isNullOrBlank()) return null
        val expires = runCatching { Instant.parse(data["alarm_expires_at"]).toEpochMilli() }.getOrNull() ?: return null
        val left = expires - now
        return if (left > 0) minOf(left, MAX_RING_MS) else null
    }

    fun ring(context: Context, data: Map<String, String>) {
        val remaining = remainingMs(data) ?: return
        if (isForeground(context)) return // The open app shows its own SOS screen and siren.
        ensureChannel(context)
        val alertId = data.getValue("alert_id")
        val title = data["title"] ?: "Estate SOS"
        val body = data["body"] ?: "${data["sender_name"] ?: "An estate member"} needs help at ${data["house_location"] ?: "their home"}"
        val open = openIntent(context, data)
        val dismiss = PendingIntent.getBroadcast(context, alertId.hashCode(),
            Intent(context, SosDismissReceiver::class.java).setAction(ACTION_DISMISS).putExtra("alert_id", alertId),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, CHANNEL)
            else @Suppress("DEPRECATION") Notification.Builder(context).setPriority(Notification.PRIORITY_MAX).setSound(soundUri(context))
        builder.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title).setContentText(body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true).setAutoCancel(true)
            .setContentIntent(open).setFullScreenIntent(open, true)
            .addAction(Notification.Action.Builder(null, "Respond", open).build())
            .addAction(Notification.Action.Builder(null, "Dismiss", dismiss).build())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) builder.setTimeoutAfter(remaining)
        val notification = builder.build().apply { flags = flags or Notification.FLAG_INSISTENT }
        manager(context).notify(tag(alertId), NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context, alertId: String?) {
        if (!alertId.isNullOrBlank()) manager(context).cancel(tag(alertId), NOTIFICATION_ID)
    }

    private fun openIntent(context: Context, data: Map<String, String>): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).setAction(ACTION_OPEN)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(EXTRA_ALERT, HashMap(data))
        return PendingIntent.getActivity(context, data.getValue("alert_id").hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun isForeground(context: Context): Boolean {
        if ((context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) return false
        val processes = (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).runningAppProcesses ?: return false
        return processes.any { it.processName == context.packageName &&
            it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND }
    }

    private fun tag(alertId: String) = "sos_$alertId"
    private fun soundUri(context: Context) = Uri.parse("android.resource://${context.packageName}/raw/sos_alarm")
    private fun manager(context: Context) = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}

/** Receives every FCM push alongside the Firebase plugin; only live SOS alerts ring. */
class SosPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        if (extras.getString("type") != "sos_live") return
        val data = extras.keySet().filterNot { it.startsWith("google.") || it.startsWith("gcm.") || it == "from" || it == "collapse_key" }
            .mapNotNull { key -> extras.getString(key)?.let { key to it } }.toMap()
        SosRinger.ring(context.applicationContext, data)
    }
}

class SosDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SosRinger.cancel(context, intent.getStringExtra("alert_id"))
    }
}
