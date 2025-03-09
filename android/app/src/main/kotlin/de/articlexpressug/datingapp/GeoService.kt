package de.articlexpressug.datingapp

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.util.Log
import androidx.core.app.JobIntentService
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean


//This service gets invoked from the broadcast reciever
class GeoService : MethodChannel.MethodCallHandler, JobIntentService() {
    private val queue = ArrayDeque<LocationResult>()
    private lateinit var mBackgroundChannel: MethodChannel
    private lateinit var mContext: Context

    companion object {
        //Log tag
        @JvmStatic
        private val LOG_TAG = "GeoService"

        //unique IDs for jobs in queue
        @JvmStatic
        private val JOB_ID = UUID.randomUUID().mostSignificantBits.toInt()

        //bool to check if the service has already started, to avoid multiple concurrent initializations
        @JvmStatic
        private var sServiceStarted = AtomicBoolean(false)

        //Store reference to flutter engine
        @JvmStatic
        private var sBackgroundFlutterEngine: FlutterEngine? = null

        @JvmStatic
        private lateinit var sPluginRegistrantCallback: PluginRegistry.PluginRegistrantCallback

        @JvmStatic
        fun enqueueWork(context: Context, work: Intent) {
            enqueueWork(context, GeoService::class.java, JOB_ID, work)
        }

        @JvmStatic
        fun setPluginRegistrant(callback: PluginRegistry.PluginRegistrantCallback) {
            sPluginRegistrantCallback = callback
        }
    }

    //Method invoked when service starts, binds flutter engine
    private fun startGeoService(context: Context) {
        synchronized(sServiceStarted) {
            mContext = context
            if(sBackgroundFlutterEngine == null) {
                //get callbackHandle
                val callbackHandle = context.getSharedPreferences(
                        GeoPlugin.SHARED_PREFERENCES_KEY,
                        Context.MODE_PRIVATE
                )
                        .getLong(GeoPlugin.CALLBACK_DISPATCHER_HANDLE_KEY, 0)
                if(callbackHandle == 0L) {
                    Log.e(LOG_TAG, "Callback not registered")
                    return
                }

                val callbackInfo : FlutterCallbackInformation = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
                if(callbackInfo == null) {
                    Log.e(LOG_TAG, "Could not find callback")
                }
                Log.d(LOG_TAG, "Starting GeoService")

                //Bind engine
                sBackgroundFlutterEngine = FlutterEngine(context)

                val args = DartExecutor.DartCallback(
                        context.assets,
                        FlutterLoader().findAppBundlePath(),
                        callbackInfo
                )

                sBackgroundFlutterEngine!!.dartExecutor.executeDartCallback(args)
                IsolateService.setBackgroundFlutterEngine(sBackgroundFlutterEngine)
            }
        }
        mBackgroundChannel = MethodChannel(sBackgroundFlutterEngine!!.dartExecutor.binaryMessenger, "de.articlexpressug/geoplugin_background")
        mBackgroundChannel.setMethodCallHandler(this)
    }

    override fun onCreate() {
        super.onCreate()
        startGeoService(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method) {
            "GeoService.initialized" -> {
                synchronized(sServiceStarted) {
                    while (!queue.isEmpty()) {
                        mBackgroundChannel.invokeMethod("", queue.remove())
                    }
                    sServiceStarted.set(true)
                }
            }
            "GeoService.promoteToForeground" -> {
                mContext.startForegroundService(Intent(mContext, IsolateService::class.java))
            }
            "GeoService.demoteToBackground" -> {
                val intent = Intent(mContext, IsolateService::class.java)
                intent.action = IsolateService.ACTION_SHUTDOWN
                mContext.startForegroundService(intent)
            }
            else -> result.notImplemented()
        }
        result.success(null)
    }



    //This function gets invoked when an intent with a location is broadcasted
    override fun onHandleWork(intent: Intent) {
        //Extract the callback handle to later call the callback func
        val callbackHandle = intent.getLongExtra(GeoPlugin.CALLBACK_HANDLE_KEY, 0)

        //Extract location information
        val locationResult = LocationResult.extractResult(intent)

        synchronized(sServiceStarted) {
            if(!sServiceStarted.get()) {
                //IsolateService has not finished starting, queue results
                queue.add(locationResult)
            } else {
                Handler(mContext.mainLooper).post {
                    mBackgroundChannel.invokeMethod("", locationResult)
                }
            }
        }

    }


}