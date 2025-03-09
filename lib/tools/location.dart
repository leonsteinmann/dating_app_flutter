import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'log.dart';
import 'geohash.dart';

// Callback functions
typedef void PermissionCallback(LocationPermission? permission);
typedef void LocationCallback(Position pos, HashPosition hashPos);

class Location {
  final PermissionCallback? onPermissionUpdate;
  final LocationCallback? onLocationUpdate;
  final GeoHasher geo = GeoHasher();

  Location({this.onPermissionUpdate, this.onLocationUpdate});

  StreamSubscription<Position>? _positionStreamSubscription;

  bool isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription!.isPaused);

  bool gpsEnabled = false;

  LocationPermission? permission;

  // Starts location stream
  void startStream() async {
    if (_positionStreamSubscription == null) {
      log.d("Starting stream");
      _positionStreamSubscription =
          Geolocator.getPositionStream().listen((Position position) {
        String hash =
            geo.encode(position.longitude, position.latitude, precision: 8);
        Map<String, String> neighbors = geo.neighbors(hash);
        HashPosition newPos =
            HashPosition(hashes: neighbors.values.toList(), centerHash: hash);
        onLocationUpdate?.call(position, newPos);
      });
    } else if (_positionStreamSubscription!.isPaused) {
      _positionStreamSubscription!.resume();
    } else {
      log.d("Edge case when resuming.");
      log.d(_positionStreamSubscription);
      log.d(_positionStreamSubscription!.isPaused);
    }
  }

  void stopStream() {
    if (isListening()) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
  }

  void checkPermission() async {
    gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      log.d("GPS was not enabled");
      return;
    }
    permission = await Geolocator.checkPermission();
    log.d("Permission status updated: " + permission.toString());
    onPermissionUpdate?.call(permission);
  }

  void requestPermission() async {
    gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      gpsEnabled = await Geolocator.openLocationSettings();
    }
    if (!gpsEnabled) {
      log.d("GPS was not enabled");
      return;
    }
    permission = await Geolocator.requestPermission();
    log.d("Permission status updated: " + permission.toString());
    onPermissionUpdate?.call(permission);
  }

  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
  }
}

class HashPosition {
  List<String> hashes;
  String centerHash;

  HashPosition({required this.hashes, required this.centerHash});
}
