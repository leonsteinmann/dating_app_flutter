import 'package:dating_app_flutter/models/user.dart';
import 'package:dating_app_flutter/services/database.dart';
import 'package:dating_app_flutter/values/colors.dart';
import 'package:dating_app_flutter/values/dimensions.dart';
import 'package:dating_app_flutter/widgets/animations/logo_animation.dart';
import 'package:dating_app_flutter/widgets/provider.dart';
import 'package:dating_app_flutter/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../values/themes.dart';
import 'conversation_request.dart';
import 'profile_Image_pages.dart';

class ProfilePage extends StatefulWidget {
  final idUser;
  final encounter;

  ProfilePage(this.idUser, this.encounter);

  @override
  State createState() {
    return _ProfilePageState(idUser, encounter);
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final _idUser;
  final _encounter;

  late Future<AppUser> user;
  final currFBUser = FirebaseAuth.instance.currentUser!;

  _ProfilePageState(this._idUser, this._encounter);

  @override
  void initState() {
    super.initState();
    user = Database.getAppUser(_idUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: user,
        builder: (BuildContext context, AsyncSnapshot<AppUser> snapshot) {
          final AppUser? user = snapshot.data;
          if (snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: columnElementsPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => OwnProfileImagePage(
                                      snapshot.data!.idUser!,
                                    ),
                              ),
                            );
                          },
                          child: UserProfileImageFutureBuilder(
                            user!.idUser,
                            size: 100.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: columnElementsPadding),
                    Text(
                      snapshot.data!.username!,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: columnElementsPadding),
                    Text(
                      calculateAge().toString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                Consumer<ThemeNotifier>(
                  builder:
                      (context, theme, _) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Begegnung entfernen?'),
                                        content: Text(
                                          'Die Begegnung wird für euch beide entfernt',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('Abbrechen'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _deleteEncounter();
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            child: Text('Okay'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        (theme.themeMode == "dark")
                                            ? darkGray
                                            : lightGray,
                                    borderRadius: BorderRadius.circular(
                                      standardCornerRadius,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "entfernen",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ConversationRequestPage(
                                            encounter: _encounter,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: mainRed,
                                    borderRadius: BorderRadius.circular(
                                      standardCornerRadius,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "anschreiben",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 75),
                        ],
                      ),
                ),
              ],
            );
          } else {
            return Center(
              child: SizedBox.square(
                dimension: 200,
                child: LogoAnimation(200.0, 100.0),
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteEncounter() {
    Database.moveEncounterToPastEncounters(
      _encounter.idEncounter,
      currFBUser.uid,
    );
    Database.moveEncounterToPastEncounters(_encounter.idEncounter, _idUser);
    print("moved Encounter to old encounter list");
  }

  int calculateAge() {
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    DateTime tempDate = new DateTime.fromMicrosecondsSinceEpoch(
      currUser!.birthday!.microsecondsSinceEpoch,
    );
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - tempDate.year;
    int month1 = currentDate.month;
    int month2 = tempDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = tempDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  String buildGenderString() {
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    String _genderString = "";
    switch (currUser!.gender) {
      case "male":
        _genderString = "Männlich";
        break;
      case "female":
        _genderString = "Weiblich";
        break;
      case "nonBinary":
        _genderString = "Divers";
        break;
      default:
        _genderString = "Männlich";
        break;
    }
    return _genderString;
  }

  String buildSearchingGenderString() {
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    String _genderSearchingString = "";
    switch (currUser!.searchingGender) {
      case "men":
        _genderSearchingString = "Männern";
        break;
      case "women":
        _genderSearchingString = "Weiblich";
        break;
      case "any":
        _genderSearchingString = "Jedem";
        break;
      default:
        _genderSearchingString = "Jedem";
        break;
    }
    return _genderSearchingString;
  }
}
