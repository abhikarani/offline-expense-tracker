package com.example.expense_tracker

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        var channel: MethodChannel? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val text = sbn.notification.extras.getCharSequence("android.text")?.toString()
            ?: return

        // Ignore OTPs & promos
        if (text.contains("OTP", true) || text.length < 10) return

        channel?.invokeMethod("onNotification", text)
    }
}
