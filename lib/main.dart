import 'package:dating_app_flutter/pages/login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'pages/conversations.dart';
import 'pages/root.dart';
import 'values/themes.dart';
import 'widgets/provider.dart';

final firebaseMessaging = FirebaseMessaging.instance;
//final firebaseAnalytics = new FirebaseAnalytics.instanceFor(app: FirebaseApp());

void main() async {
  //Initialize firebase after widget building but before running the flutter app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocationModeSelector>(
          create: (context) => LocationModeSelector(),
        ),
        ChangeNotifierProvider<CurrUser>(create: (context) => CurrUser()),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => new ThemeNotifier(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // input data {locationModeOn; precision}
    switch (task) {
      case "updateBackgroundPosition":
        if (inputData!["locationModeOn"]) {
          // var geo = GeoHasher();
          // Position userLocation = await Geolocator.getCurrentPosition(
          //     desiredAccuracy: LocationAccuracy.high);
          // String centerHash = geo.encode(
          //     userLocation.longitude, userLocation.latitude,
          //     precision: inputData["precision"]);
          // final Map<String, String> hashes = geo.neighbors(centerHash);
          // final HashPosition hashPos = HashPosition(
          //     hashes: hashes.values.toList(), centerHash: centerHash);
          //Send to RTDB
          await FirebaseDatabase.instance
              .ref()
              .child("debug")
              .child(FirebaseAuth.instance.currentUser!.uid)
              .set({"IOS BackgroundLocation": "Yes"});
        }
        print("backgroundTask triggered");
        // Position userLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        break;
    }
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder:
          (context, theme, _) => MaterialApp(
            theme: theme.getTheme(),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [const Locale('de', ''), const Locale('en', '')],
            routes: {
              // When navigating to the "/" route, build the FirstScreen widget.
              '/': (context) => NavigatorPage(),
              // When navigating to the "/second" route, build the SecondScreen widget.
              '/conversations': (context) => ConversationsPage(),
            }, //home: RootPage(),
          ),
    );
  }
}

class NavigatorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          (FirebaseAuth.instance.currentUser == null)
              ? LoginPage()
              : RootPage(selectedView: 1),
    );
  }
}
