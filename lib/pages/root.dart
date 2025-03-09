import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/main.dart';
import 'package:datingapp/pages/login.dart';
import 'package:datingapp/services/database.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/widgets/images.dart';
import 'package:datingapp/values/themes.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:geoserviceplugin/geoserviceplugin.dart';
import '/pages/conversations.dart';
import '/pages/create_user.dart';
import '/pages/home.dart';
import '/pages/encounters.dart';
import '/pages/my_profile.dart';
import '/values/dimensions.dart';
import '/widgets/provider.dart';
import '/tools/log.dart';

class RootPage extends StatefulWidget {
  RootPage({required this.selectedView});

  final int selectedView;

  @override
  _RootPageState createState() => _RootPageState(selectedView: selectedView);
}

class _RootPageState extends State<RootPage> with WidgetsBindingObserver {
  int selectedView;
  bool _geoServiceInitialized = false;

  _RootPageState({required this.selectedView});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGeoService();
    if (FirebaseAuth.instance.currentUser != null) {
      Provider.of<CurrUser>(context, listen: false)
          .updateCurrentUser(FirebaseAuth.instance.currentUser!.uid);
    }

    setupFirebaseMessage();
  }

  Future<void> setupFirebaseMessage() async {
    var androiInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInit = DarwinInitializationSettings();
    var initSetting = InitializationSettings(android: androiInit, iOS: iosInit);
    var fltNotification = FlutterLocalNotificationsPlugin();
    fltNotification.initialize(initSetting);
    handlePushToken();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener

    //FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['event'] == 'conversationMessage') {
      Database.streamConversation(message.data['content']).listen((value) {
        Navigator.pushNamed(
          context,
          '/',
        );
      });
    }
  }

  void _onNavigationItemTapped(int index) {
    if (selectedView != index) {
      setState(() {
        selectedView = index;
      });
    }
  }

  void _initializeGeoService() async {
    bool result = await Geoserviceplugin.startService();
    setState(() {
      _geoServiceInitialized = result;
    });
  }

  void refreshNotificationToken() async {
    var fbUser = FirebaseAuth.instance.currentUser;
    String notificationToken = (await firebaseMessaging.getToken())!;
    if (fbUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .set({"deviceToken": notificationToken});
    }
  }

  void handlePushToken() async {
    if (FirebaseAuth.instance.currentUser != null) {
      // Get the token each time the application loads
      String? token = await FirebaseMessaging.instance.getToken();
      saveTokenToDatabase(token!);
      FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
    }
  }

  void signOut() {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.signOut();
      Timer(Duration(milliseconds: 500), () {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MyApp()),
            (Route<dynamic> route) => false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //callback is only used for moving the service. If the service is not running, skip execution
    if (!_geoServiceInitialized) {
      log.d("GeoService was not initialized on app life cycle change!");
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        //App is moved to background
        if (await Geoserviceplugin.isSubscribed) {
          log.d("Promoting service to foreground");
          Geoserviceplugin.promoteToForeground();
        }
        break;
      case AppLifecycleState.detached:
        //App is terminated (e.g. cleared from multitasking)
        log.d("Detached");
        Geoserviceplugin.stopService();
        break;
      case AppLifecycleState.resumed:
        //App is brought up from background to foreground
        log.d("Demoting service to background");
        Geoserviceplugin.demoteToBackground();
        break;
      default:
        //do not care
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => Scaffold(
        appBar: buildAppBar(theme, context),
        body: Center(
          child: IndexedStack(
            index: selectedView,
            children: allTabs.map<Widget>((Tab tab) {
              return TabView(tab: tab, key: new UniqueKey());
            }).toList(),
          ),
        ),
        /*floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, //specify the location of the FAB
        floatingActionButton: buildFloatingActionButton(context),*/
        bottomNavigationBar: buildBottomAppBar(context),
      ),
    );
  }

  Container buildFloatingActionButton(BuildContext context) {
    return Container(
      height: 70,
      width: 70,
      child: FittedBox(
        child: FloatingActionButton(
          backgroundColor:
              selectedView == 1 ? mainRed : unselectedBottomAppBarColor,
          onPressed: () {
            _onNavigationItemTapped(1);
          },
          child: Container(
            child: Center(
                child: location_pin_custom(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    size: bottomAppBarIconSize)),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(ThemeNotifier themeNotifier, BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: standardPadding),
        child: logo_custom(
          size: 50,
          color: (themeNotifier.themeMode == "dark") ? mainRed : mainRed,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MyProfilePage()));
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Hero(
              tag: "ownProfileImage",
              child: (FirebaseAuth.instance.currentUser != null)
                  ? UserProfileImageFutureBuilder(
                      FirebaseAuth.instance.currentUser!.uid,
                      size: 20.0,
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(defaultUserImagePath),
                    ),
            ),
          ),
        ),
        PopupMenuButton(
          child: Padding(
            padding: const EdgeInsets.only(
                right: standardPadding, bottom: 8.0, top: 8.0),
            child: Icon(Icons.more_vert, color: mainRed),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'darkMode',
              child: Consumer<ThemeNotifier>(
                builder: (context, theme, _) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context, 'darkMode');
                      if (theme.themeMode == 'dark') {
                        theme.setLightMode();
                      } else {
                        theme.setDarkMode();
                      }
                    },
                    child: Text("DarkMode an/aus")),
              ),
            ),
            PopupMenuItem(
              value: 'createUser',
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, 'createUser');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateUserPage()));
                  },
                  child: Text("Profil erstellen")),
            ),
            PopupMenuItem(
              value: 'login',
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, 'login');
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text("SignUp")),
            ),
            PopupMenuItem(
              value: 'signOut',
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, 'signOut');
                    signOut();
                  },
                  child: Text("SignOut")),
            ),
          ],
        ),
      ],
    );
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        //margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              //update the bottom app bar view each time an item is clicked
              onPressed: () {
                _onNavigationItemTapped(0);
              },
              iconSize: bottomAppBarIconSize,
              icon: Icon(
                Icons.explore,
                //darken the icon if it is selected or else give it a different color
                color:
                    selectedView == 0 ? mainRed : unselectedBottomAppBarColor,
              ),
            ),
            IconButton(
              //update the bottom app bar view each time an item is clicked
              onPressed: () {
                _onNavigationItemTapped(1);
              },
              iconSize: bottomAppBarIconSize,
              icon: Icon(
                Icons.person,
                //darken the icon if it is selected or else give it a different color
                color:
                    selectedView == 1 ? mainRed : unselectedBottomAppBarColor,
              ),
            ),
            IconButton(
              onPressed: () {
                _onNavigationItemTapped(2);
              },
              iconSize: bottomAppBarIconSize,
              icon: Icon(
                Icons.question_answer_rounded,
                color:
                    selectedView == 2 ? mainRed : unselectedBottomAppBarColor,
              ),
            ),
          ],
        ),
      ),
      //to add a space between the FAB and BottomAppBar
      shape: CircularNotchedRectangle(),
      //color of the BottomAppBar
      color: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

Future<void> saveTokenToDatabase(String token) async {
  // Assume user is logged in for this example
  String uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'pushToken': token,
  });
}

// Tabbed main page
class Tab {
  const Tab(this.name);
  final tabName name;
}

enum tabName { Encounters, Home, Chat }

const List<Tab> allTabs = <Tab>[
  Tab(tabName.Encounters),
  Tab(tabName.Home),
  Tab(tabName.Chat),
];

class TabView extends StatefulWidget {
  const TabView({required Key key, required this.tab}) : super(key: key);
  final Tab tab;

  @override
  State createState() {
    return _TabViewState();
  }
}

class _TabViewState extends State<TabView> {
  @override
  Widget build(BuildContext context) {
    switch (widget.tab.name) {
      case tabName.Encounters:
        return EncountersPage();
      case tabName.Home:
        return Home();
      case tabName.Chat:
        return ConversationsPage();
      default:
        return Home();
    }
  }
}
