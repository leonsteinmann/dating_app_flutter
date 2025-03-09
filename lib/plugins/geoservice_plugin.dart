import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GeoService {
  static const _channel = const MethodChannel('de.articlexpressug/geoplugin');
  static const _background = const MethodChannel('de.articlexpressug/geoplugin_background');

  static Future<void> initialize() async {
    final CallbackHandle? callback = PluginUtilities.getCallbackHandle(callbackDispatcher);
    await _channel.invokeMethod('GeoPlugin.initializeService', <dynamic>[callback!.toRawHandle()]);
  }

  static Future<void> promoteToForeground() async => await _background.invokeMethod('GeoService.promoteToForeground');

  static Future<void> demoteToBackground() async => await _background.invokeMethod('GeoService.demoteToBackground');

  static Future<void> startTracking(void Function(List<String> out) callback) async {
    final List<dynamic> args = <dynamic>[
      PluginUtilities.getCallbackHandle(callback)!.toRawHandle()
    ];
    await _channel.invokeMethod('GeoPlugin.startTracking', args);
  }

  static Future<void> stopTracking(void Function(List<String> out) callback) async {
    final List<dynamic> args = <dynamic>[
      PluginUtilities.getCallbackHandle(callback)!.toRawHandle()
    ];
    await _channel.invokeMethod('GeoPlugin.stopTracking', args);
  }

}


void callbackDispatcher() {
  const MethodChannel _backgroundChannel =
  MethodChannel('de.articlexpressug/geoplugin_background');
  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final List<dynamic> args = call.arguments;
    final Function? callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(args[0]));
    assert(callback != null);
    final List<String> triggeringGeofences = args[1].cast<String>();

    callback!(triggeringGeofences);
  });
  _backgroundChannel.invokeMethod('GeoService.initialized');
}