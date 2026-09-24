package com.example.ayre_scanner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannel()
    }

    /**
     * Push notifications arrive on this channel (the backend names it in every
     * message, and the manifest makes it the FCM default). Created here, not
     * left to FCM, so it is high-importance: signal alerts should appear as a
     * heads-up notification rather than sit silently in the shade.
     * Creating an existing channel is a no-op, so this is safe on every launch.
     */
    private fun createPushChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            PUSH_CHANNEL_ID,
            "Signals and alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New scanner picks and messages from Ayre"
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private companion object {
        const val PUSH_CHANNEL_ID = "ayre_signals"
    }
}
