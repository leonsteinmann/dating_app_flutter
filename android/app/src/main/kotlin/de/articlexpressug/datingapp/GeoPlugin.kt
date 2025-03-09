package de.articlexpressug.datingapp

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.jar.Manifest

class GeoPlugin : MethodChannel.MethodCallHandler, FlutterPlugin, ActivityAware {

    private var mActivity : Activity? = null
    private var mContext : Context? = null
    private var mFusedLocationProviderClient : FusedLocationProviderClient? = null
    private var mLocationRequest : LocationRequest? = null

    companion object {
        @JvmStatic
        private val LOG_TAG = "GeoPlugin"
        @JvmStatic
        private val SMALLEST_DISPLACEMENT_METERS = (10).toFloat()
        @JvmStatic
        val SHARED_PREFERENCES_KEY = "geo_plugin_cache"
        @JvmStatic
        val CALLBACK_HANDLE_KEY = "callback_handle"
        @JvmStatic
        val CALLBACK_DISPATCHER_HANDLE_KEY = "callback_dispatch_handler"
        @JvmStatic
        val PERSISTENT_GEOFENCES_KEY = "persistent_geo"
        @JvmStatic
        val PERSISTENT_GEOFENCES_IDS = "persistent_geo_ids"

        @JvmStatic
        private fun initializeService(context: Context, fusedLocationProviderClient: FusedLocationProviderClient, args: ArrayList<*>?) {
            Log.d(LOG_TAG, "Initializing GeoService")

            //The callback from the callbackdispatcher
            val callbackHandle = args!![0] as Long
            //Store the handle in local storage for persistence
            context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                    .edit()
                    .putLong(CALLBACK_DISPATCHER_HANDLE_KEY, callbackHandle)
                    .apply()
        }

        @JvmStatic
        private fun getPendingIntent(context: Context, callbackHandle: Long): PendingIntent {
            val intent = Intent(context, GeoBroadcastReciever::class.java)
                    .putExtra(CALLBACK_HANDLE_KEY, callbackHandle)
            return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        @JvmStatic
        private fun getLocationRequest() : LocationRequest {
            return LocationRequest.create()
                    .setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
                    .setSmallestDisplacement(SMALLEST_DISPLACEMENT_METERS)
        }

        @JvmStatic
        private fun startTracking(context: Context, fusedLocationProviderClient: FusedLocationProviderClient, args: ArrayList<*>?, result: MethodChannel.Result) {
            //check permission
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && (context.checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_DENIED)) {
                Log.e(LOG_TAG, "Permission needs to be ACCESS_FINE_LOCATION")
                result.error("Insufficient permission", null, null)
            }

            val callbackHandle = args!![0] as Long

            //request updates
            fusedLocationProviderClient.requestLocationUpdates(getLocationRequest(), getPendingIntent(context, callbackHandle)).addOnSuccessListener {
                Log.d(LOG_TAG, "Successfully requested location updates")
                result.success(true)
            }
        }

        @JvmStatic
        private fun stopTracking(context: Context, fusedLocationProviderClient: FusedLocationProviderClient, args: ArrayList<*>?, result: MethodChannel.Result) {
            val callbackHandle = args!![0] as Long

            fusedLocationProviderClient.removeLocationUpdates(getPendingIntent(context, callbackHandle)).addOnSuccessListener {
                Log.d(LOG_TAG, "Successfully stopped location updates")
                result.success(true)
            }
        }

    }

    //When a function on the respective channel is invoked, this is triggered
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments<ArrayList<*>>()
        when(call.method) {
            "GeoPlugin.initializeService" -> {
                //check location permissions before initializing service
                if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    mActivity?.requestPermissions(arrayOf(
                            android.Manifest.permission.ACCESS_FINE_LOCATION,
                            android.Manifest.permission.ACCESS_BACKGROUND_LOCATION), 12312)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    mActivity?.requestPermissions(arrayOf(
                            android.Manifest.permission.ACCESS_FINE_LOCATION
                    ), 12312)
                }

                //INITIALIZE SERVICE
                initializeService(mContext!!, mFusedLocationProviderClient!!, args)
                result.success(true)
            }
            "GeoPlugin.startTracking" -> startTracking(mContext!!, mFusedLocationProviderClient!!, args, result)
            "GeoPlugin.stopTracking" -> stopTracking(mContext!!, mFusedLocationProviderClient!!, args, result)
        }
    }

    //When connected to flutter engine, fill context and FLPclient
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(LOG_TAG, "GeoPlugin attached to Engine")
        mContext = binding.applicationContext
        mFusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(mContext!!)
        val channel = MethodChannel(binding.binaryMessenger, "de.articlexpressug/geoplugin")
        //listing to method calls on this channel
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mContext = null
        mFusedLocationProviderClient = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mActivity = null
    }
}