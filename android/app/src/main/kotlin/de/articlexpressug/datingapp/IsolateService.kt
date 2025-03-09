package de.articlexpressug.datingapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine

class IsolateService : Service(){

    private val LOG_TAG = "IsolateService"

    companion object {
        //const for signaling shutdown
        @JvmStatic
        val ACTION_SHUTDOWN = "SHUTDOWN"

        @JvmStatic
        private val WAKELOCK_TAG = "IsolateHolderService::WAKE_LOCK"

        @JvmStatic
        private var backgroundFlutterEngine: FlutterEngine? = null

        @JvmStatic
        fun setBackgroundFlutterEngine(engine: FlutterEngine?) {
            backgroundFlutterEngine = engine
        }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    //displays notification and starts foreground service when created
    override fun onCreate() {
        super.onCreate()
        //ID of notification channel
        var CHANNEL_ID = "geoservice_channel"
        //notification channel
        var channel = NotificationChannel(CHANNEL_ID, "Flutter Geoservice channel", NotificationManager.IMPORTANCE_LOW)
        //reference to icon to display in persistent notification
        val launcherIconId = resources.getIdentifier("ic_launcher", "mipmap", packageName)

        //create notification channel
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)

        //configure notification to display
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Tracking active")
                .setContentText("test")
                .setSmallIcon(launcherIconId)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()

        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
                acquire()
            }
        }
        startForeground(1, notification)
    }

    //called every time the service is started. Also executed when the user clicks on the notification
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(LOG_TAG, "onStartCommand")

        if(intent?.action == ACTION_SHUTDOWN) {
            (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                    if(isHeld()) {
                        release()
                    }
                }
            }
            stopForeground(true)
            stopSelf()
        }

        return START_STICKY
    }
}