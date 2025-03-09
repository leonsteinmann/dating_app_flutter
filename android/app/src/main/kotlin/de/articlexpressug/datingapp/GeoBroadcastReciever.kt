package de.articlexpressug.datingapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.view.FlutterMain

class GeoBroadcastReciever : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        FlutterMain.startInitialization(context!!)
        FlutterMain.ensureInitializationComplete(context, null)
        GeoService.enqueueWork(context, intent!!)
    }
}