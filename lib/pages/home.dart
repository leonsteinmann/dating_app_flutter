import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating_app_flutter/main.dart';
import 'package:dating_app_flutter/values/colors.dart';
import 'package:dating_app_flutter/values/dimensions.dart';
import 'package:dating_app_flutter/widgets/animations/flying_location_pin.dart';
import 'package:dating_app_flutter/widgets/animations/logo_animation.dart';
import 'package:dating_app_flutter/widgets/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geoserviceplugin/geoserviceplugin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import '../services/database.dart';
import '../tools/log.dart';
import '../tools/geohash.dart';
import '../tools/location.dart';
import 'package:geolocator/geolocator.dart';

class Home extends StatefulWidget {
  @override
  State createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final currFBUser = FirebaseAuth.instance.currentUser!;

  Location? location;

  bool _loggedIn = false;
  int precision = 8;
  LocationPermission? _permission;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Position> positionList = <Position>[];
  List<String> encounteredUIDs = <String>[];

  EventChannel? _stream;

  late StreamSubscription<User?> authStateListener;
  late StreamSubscription<dynamic> locationListener;
  StreamSubscription<DatabaseEvent?>? hashCellListener;

  // Firebase Storage Images to download
  Future<List<Map<String, dynamic>>>? _futureStoryImages;
  int countStoryImages = 0;

  // Local Image picked for story upload
  File? _storyImageFile;

  // Pins
  AnimationController? _pinController1;
  AnimationController? _pinController2;
  AnimationController? _pinController3;
  AnimationController? _pinController4;
  AnimationController? _pinController5;
  AnimationController? _pinController6;
  AnimationController? _pinController7;

  void onPermissionUpdated(LocationPermission? permission) {
    setState(() {
      _permission = permission;
    });
  }

  void _addLocationStreamListener() {
    _stream = EventChannel('geoserviceplugin_eventstream');

    locationListener = _stream!.receiveBroadcastStream().listen((location) {
      log.d("onLocation");
      //Create location hash
      var geo = GeoHasher();
      final Map<String, dynamic> locationMap = Map.from(location);
      String centerHash = geo.encode(
        locationMap["longitude"],
        locationMap["latitude"],
        precision: precision,
      );
      final Map<String, String> hashes = geo.neighbors(centerHash);
      final HashPosition hashPos = HashPosition(
        hashes: hashes.values.toList(),
        centerHash: centerHash,
      );
      //Send to RTDB
      if (_loggedIn) {
        onPositionUpdated(hashPos);
      }
    });
  }

  void _removeLocationStreamListener() {
    removePrevHash();
    locationListener.cancel();
    _stream = null;
  }

  void onPositionUpdated(HashPosition hashPos) {
    final locationMode = Provider.of<LocationModeSelector>(
      context,
      listen: false,
    );

    // if user moved to a new cell
    if (hashPos.centerHash != locationMode.prevHash) {
      removePrevHash();
      locationMode.setPrevHash(hashPos.centerHash);
      uploadHashes(hashPos);
      switchCellListener();
      matchUser(hashPos.centerHash);
    } else if (DateTime.now().difference(locationMode.lastUpdate).inSeconds >
        3) {
      uploadHashes(hashPos);
      matchUser(hashPos.centerHash);
      locationMode.setLastUpdate(DateTime.now());
      print("LastUpdate was at: ${locationMode.lastUpdate}");
    }

    // set Timestamp to limit matchUser() if location didn't change
  }

  Future<void> matchUser(String centerHash) async {
    print("Is matching User with CloudFunction");
    final matchUserRequest = FirebaseFunctions.instanceFor(
      region: "europe-west3",
    ).httpsCallable('matchUser');
    final message = {
      'centerHash': centerHash,
      'longitude': location!.geo.decode(centerHash)[0],
      'latitude': location!.geo.decode(centerHash)[1],
    };

    await matchUserRequest(message).then((result) => {print(result)});
  }

  void removePrevHash() {
    final locationMode = Provider.of<LocationModeSelector>(
      context,
      listen: false,
    );
    if (locationMode.prevHash == "") {
      return;
    }
    print("try to delete ${locationMode.prevHash}");
    FirebaseDatabase.instance
        .ref()
        .child("locations")
        .child(locationMode.prevHash)
        .child(currFBUser.uid)
        .remove();
  }

  void uploadHashes(HashPosition hashPos) async {
    if (!_loggedIn) {
      return;
    }
    await FirebaseDatabase.instance
        .ref()
        .child("locations")
        .child(hashPos.centerHash)
        .child(currFBUser.uid)
        .set({"time": 0});
  }

  void switchCellListener() {
    final locationMode = Provider.of<LocationModeSelector>(
      context,
      listen: false,
    );
    if (hashCellListener != null) {
      hashCellListener!.cancel();
      hashCellListener = null;
    }

    log.d("setting up listener");

    hashCellListener = FirebaseDatabase.instance
        .ref()
        .child("locations")
        .child(locationMode.prevHash)
        .onChildAdded
        .listen((DatabaseEvent? event) {
          log.d("event triggered");
          if (event != null) {
            if (event.snapshot.key != FirebaseAuth.instance.currentUser!.uid) {
              encounteredUIDs.add(event.snapshot.key!);
              _showMatchingNotification(event.snapshot.key!);
            }
          }
        });
  }

  void _showMatchingNotification(String matchedName) async {
    const AndroidNotificationDetails and = AndroidNotificationDetails(
      'flutter_datingapp_channel',
      "Datingapp matching notifications",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: and,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Neuer Match',
      'Du hast ' + matchedName + ' getroffen',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  // void _clearRTDB() async {
  //   if (_loggedIn) {
  //     await FirebaseDatabase.instance.ref().child("locations").remove();
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("RTDB cleared"),
  //         duration: Duration(milliseconds: 1000)));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("Please login to call this action"),
  //         duration: Duration(milliseconds: 1000)));
  //   }
  // }

  void _pickStoryImage() async {
    //TODO when picking profile picture, textfield is cleared
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (file != null) {
      final croppedFile = await ImageCropper().cropImage(
        maxHeight: 500,
        maxWidth: 500,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: file.path,
      );
      if (croppedFile != null) {
        setState(() {
          _storyImageFile = File(croppedFile.path);
        });
        _saveStoryImage();
      }
    }
  }

  void _getStoryImages() {
    _futureStoryImages = Database.getStoryImages(currFBUser.uid);
    _getFileLength().then((value) {
      setState(() {
        countStoryImages = value;
      });
    });
  }

  Future<void> _saveStoryImage() async {
    if (_storyImageFile != null) {
      String storyImageId = "${DateTime.now().millisecondsSinceEpoch}";
      await FirebaseStorage.instance
          .ref()
          .child("users/${currFBUser.uid}/story/$storyImageId")
          .putFile(_storyImageFile!)
          .then((result) => {print(result)});
    }
    _getStoryImages();
  }

  void _deleteStoryImage(String path) async {
    await FirebaseStorage.instance.ref().child(path).delete();
    _getStoryImages();
  }

  Future<int> _getFileLength() async {
    return await _futureStoryImages!.then((value) {
      return value.length;
    });
  }

  void startLocationPins() {
    _pinController1!.repeat();
    _pinController2!.repeat();
    _pinController3!.repeat();
    _pinController4!.repeat();
    _pinController5!.repeat();
    _pinController6!.repeat();
    _pinController7!.repeat();
  }

  void stopLocationPins() {
    _pinController1!.reset();
    _pinController2!.reset();
    _pinController3!.reset();
    _pinController4!.reset();
    _pinController5!.reset();
    _pinController6!.reset();
    _pinController7!.reset();
  }

  void registerNotification() async {
    var _messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // TODO: handle the received notifications
    } else {
      print('User declined or has not accepted permission');
    }
  }

  @override
  void initState() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

    Workmanager().registerPeriodicTask(
      "1",
      "updateBackgroundPosition",
      frequency: Duration(minutes: 15),
      inputData: <String, dynamic>{
        'locationModeOn': true,
        'precision': precision,
      },
    );

    location = Location(onPermissionUpdate: onPermissionUpdated);
    location?.checkPermission();
    registerNotification();
    //Subscribe to auth changes
    authStateListener = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user == null) {
        setState(() {
          _loggedIn = false;
        });
      } else {
        setState(() {
          _loggedIn = true;
        });
        _getStoryImages();
      }
    });

    final locationMode = Provider.of<LocationModeSelector>(
      context,
      listen: false,
    );
    if (locationMode.isLocationModeOn) {
      _addLocationStreamListener();
    }

    var initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var initializationSettingsIOs = DarwinInitializationSettings();
    var initSetttings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOs,
    );

    flutterLocalNotificationsPlugin.initialize(initSetttings);

    final themeSelector = Provider.of<LocationModeSelector>(
      context,
      listen: false,
    );
    _pinController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pinController2 = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pinController3 = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    _pinController4 = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _pinController5 = AnimationController(
      duration: const Duration(milliseconds: 7500),
      vsync: this,
    );
    _pinController6 = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );
    _pinController7 = AnimationController(
      duration: const Duration(milliseconds: 3300),
      vsync: this,
    );

    if (themeSelector.isLocationModeOn) {
      startLocationPins();
    }

    super.initState();
  }

  @override
  void dispose() {
    authStateListener.cancel();
    _pinController1!.dispose();
    _pinController2!.dispose();
    _pinController3!.dispose();
    _pinController4!.dispose();
    _pinController5!.dispose();
    _pinController6!.dispose();
    _pinController7!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationMode = Provider.of<LocationModeSelector>(
      context,
      listen: true,
    );
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Pins(
            pinController1: _pinController1,
            pinController2: _pinController2,
            pinController3: _pinController3,
            pinController4: _pinController4,
            pinController5: _pinController5,
            pinController6: _pinController6,
            pinController7: _pinController7,
          ),
          Padding(
            padding: EdgeInsets.all(standardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: standardPadding),
                Row(
                  children: [
                    Text(
                      "Meine Story ($countStoryImages/5)",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                SizedBox(height: standardPadding),
                buildStorySection(context),
                SizedBox(height: standardPadding),
                Row(
                  children: [
                    Text(
                      "Standort Matching",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                SizedBox(height: standardPadding),
                buildMatchingButton(locationMode, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Expanded buildMatchingButton(
    LocationModeSelector locationMode,
    BuildContext context,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (_permission == LocationPermission.denied ||
                  _permission == LocationPermission.deniedForever ||
                  !location!.gpsEnabled) {
                location!.requestPermission();
                return;
              } else if (locationMode.isLocationModeOn) {
                Geoserviceplugin.unsubscribe();
                locationMode.setIsLocationModeOn(false);
                stopLocationPins();
                _removeLocationStreamListener();
              } else {
                Geoserviceplugin.subscribe();
                locationMode.setIsLocationModeOn(true);
                startLocationPins();
                _addLocationStreamListener();
              }
              SystemSound.play(SystemSoundType.click);
              HapticFeedback.mediumImpact();
            },
            child: AnimatedContainer(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                boxShadow:
                    (locationMode.isLocationModeOn)
                        ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.1),
                            offset: Offset(0, 0),
                            blurRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(0, 0),
                            blurRadius: 1,
                          ),
                        ]
                        : [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.1),
                            offset: Offset(-6.0, -6.0),
                            blurRadius: 3.0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(6.0, 6.0),
                            blurRadius: 16.0,
                          ),
                        ],
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(standardCornerRadius),
              ),
              duration: Duration(milliseconds: 200),
              child:
                  (locationMode.isLocationModeOn)
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LogoAnimation(100.0, 50.0),
                          Text(
                            "An",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 100),
                          Text(
                            "Aus",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox buildStorySection(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: [
          (countStoryImages < 5)
              ? GestureDetector(
                onTap: _pickStoryImage,
                child: Container(
                  width: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: mainRed, // Set border color
                      width: 3.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: mainRed),
                      Text(
                        "Story hinzufügen",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
              : Container(),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureStoryImages,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
            ) {
              if (snapshot.hasData && snapshot.data!.length > 0) {
                return ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> image = snapshot.data![index];
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        SizedBox.square(
                          dimension: 200,
                          child: Container(
                            margin: EdgeInsets.all(3),
                            child: Image.network(image['url']),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: mainRed,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Bild löschen?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Abbrechen'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteStoryImage(image['path']);
                                        Navigator.pop(context);
                                      },
                                      child: Text('Okay'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              } else if (snapshot.hasData && snapshot.data!.length == 0) {
                return Container();
              } else {
                return Row(
                  children: [SizedBox(width: 50), LogoAnimation(100.0, 50.0)],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class Pins extends StatelessWidget {
  const Pins({
    Key? key,
    required AnimationController? pinController1,
    required AnimationController? pinController2,
    required AnimationController? pinController3,
    required AnimationController? pinController4,
    required AnimationController? pinController5,
    required AnimationController? pinController6,
    required AnimationController? pinController7,
  }) : _pinController1 = pinController1,
       _pinController2 = pinController2,
       _pinController3 = pinController3,
       _pinController4 = pinController4,
       _pinController5 = pinController5,
       _pinController6 = pinController6,
       _pinController7 = pinController7,
       super(key: key);

  final AnimationController? _pinController1;
  final AnimationController? _pinController2;
  final AnimationController? _pinController3;
  final AnimationController? _pinController4;
  final AnimationController? _pinController5;
  final AnimationController? _pinController6;
  final AnimationController? _pinController7;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController1!,
              xRelativeOffset: 0.2,
              yOffset: 500,
              color: mainRed,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController2!,
              xRelativeOffset: 0.4,
              yOffset: 400,
              color: mainRedDark,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController3!,
              xRelativeOffset: 0.7,
              yOffset: 350,
              color: mainRedLight,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController4!,
              xRelativeOffset: 0.9,
              yOffset: 300,
              color: mainRed,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController5!,
              xRelativeOffset: 0.6,
              yOffset: 300,
              color: mainRed,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController6!,
              xRelativeOffset: 0.3,
              yOffset: 500,
              color: mainRedLight,
            ),
          ],
        ),
        Column(
          children: [
            FlyingLocationPin(
              controller: _pinController7!,
              xRelativeOffset: 0.8,
              yOffset: 300,
              color: mainRed,
            ),
          ],
        ),
      ],
    );
  }
}
