import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/widgets/images.dart';
import 'package:datingapp/values/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class CreateUserPage extends StatefulWidget {
  @override
  State createState() {
    return _CreateUserPageState();
  }
}

class _CreateUserPageState extends State<CreateUserPage> {
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  final currFBUser = FirebaseAuth.instance.currentUser!;

  PageController pageController = PageController();
  int _currentPage = 1; // Pages 1 - 5
  bool _isCreatingUser = false;

  //Input
  String _username = "";
  File? _profileImageFile;
  Image? _profileImage;
  Timestamp _selectedDate = Timestamp.fromDate(DateTime(1999));
  String _selectedGender = "";
  String _selectedSearchingGender = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> onForwardPressed() async {
    if (_currentPage < 5) {
      FocusScope.of(context).unfocus();
      if (_currentPage == 1 && _username == "") {
        return;
      } else if (_currentPage == 2 && _profileImage == null) {
        return;
      } else if (_currentPage == 3) {
      } else if (_currentPage == 4 && _selectedGender == "") {
        return;
      }
      pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      setState(() {
        _currentPage = _currentPage + 1;
      });
    } else {
      if (_currentPage == 5 && _selectedSearchingGender == "") {
        return;
      } else {
        //final createUserRequest = FirebaseFunctions.instance.httpsCallable('createUser');
        final createUserRequest =
            FirebaseFunctions.instanceFor(region: "europe-west3")
                .httpsCallable('createUser');
        final message = {
          'username': _username,
          'idProfilePicture': _username,
          'gender': _selectedGender,
          'searchingGender': _selectedSearchingGender,
          'birthday': _selectedDate.seconds,
        };
        print(message);
        setState(() {
          _isCreatingUser = true;
        });
        await createUserRequest(message).then((result) => {
              print("triggered createUser"),
              print(result),
            });
        await _saveProfilePicture();
        setState(() {
          _isCreatingUser = false;
        });
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => NavigatorPage()),
            (Route<dynamic> route) => false);
        print("create User");
      }
    }
  }

  void _pickProfilePicture() async {
    //TODO when picking profile picture, textfield is cleared
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (file != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      );
      if (croppedFile != null) {
        setState(() {
          _profileImageFile = File(croppedFile.path);
          _profileImage = Image.file(_profileImageFile!);
        });
        _saveProfilePicture();
      }
    }
  }

  Future<void> _saveProfilePicture() async {
    if (_profileImageFile != null) {
      String profileImageId =
          "${currFBUser.uid}_${DateTime.now().millisecondsSinceEpoch}";
      Directory extStorageDir = await getTemporaryDirectory();

      final userDir = Directory('${extStorageDir.path}/users');
      if (!(await userDir.exists())) {
        await userDir.create();
      }

      final currentUserImageDir =
          Directory('${extStorageDir.path}/users/${currFBUser.uid}');
      final List<FileSystemEntity> userImageDirList =
          currentUserImageDir.listSync();
      for (var entity in userImageDirList) {
        if (entity is File) {
          List<String> imageFilePathParts = entity.path.split("/");
          if (imageFilePathParts.last != profileImageId) {
            entity.delete();
          }
        }
      }
      _profileImageFile!
          .copy("${currentUserImageDir.path}/$profileImageId.jpg");
    }
  }

  _selectDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return buildMaterialDatePicker(context);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return buildCupertinoDatePicker(context);
    }
  }

  /// This builds material date picker in Android
  buildMaterialDatePicker(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      locale: Locale('de', 'DE'),
      context: context,
      initialDate: _selectedDate.toDate(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 6574)),
      initialEntryMode: DatePickerEntryMode.input,
      initialDatePickerMode: DatePickerMode.year,
    ))!;
    if (picked != _selectedDate)
      setState(() {
        _selectedDate = Timestamp.fromDate(picked);
      });
  }

  /// This builds cupertion date picker in iOS
  buildCupertinoDatePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).copyWith().size.height / 3,
            color: Colors.white,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (picked) {
                if (picked != _selectedDate)
                  setState(() {
                    _selectedDate = Timestamp.fromDate(picked);
                  });
              },
              initialDateTime: _selectedDate.toDate(),
              maximumDate: DateTime.now().subtract(Duration(days: 6574)),
              minimumDate: DateTime(
                1900,
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => Scaffold(
          floatingActionButton: FloatingActionButton(
            child: (_isCreatingUser)
                ? CircularProgressIndicator(
                    backgroundColor: lightIconColor,
                  )
                : Icon(Icons.navigate_next),
            onPressed: () {
              if (!_isCreatingUser) {
                onForwardPressed();
              }
            },
          ),
          body: SafeArea(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: PageView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: pageController,
                    children: [
                      createPageUsername(),
                      createPageProfileImage(),
                      createPageBirthday(),
                      createPageGender(),
                      createPageSearchingGender(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        child: SizedBox(
                            width: screenWidth - 40,
                            height: 20,
                            child: Container(
                                color: (theme.themeMode == "dark")
                                    ? darkGray
                                    : lightGray)),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      ClipRRect(
                        child: SizedBox(
                          width: (screenWidth - 40) / 5 * _currentPage,
                          height: 20,
                          child: Container(
                            color: mainRed,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      )
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        IconButton(
                            icon: Icon(Icons.navigate_before_rounded),
                            onPressed: () {
                              if (_currentPage > 1) {
                                pageController.previousPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut);
                                setState(() {
                                  _currentPage = _currentPage - 1;
                                });
                              }
                            }),
                      ],
                    ),
                  ],
                )
              ],
            ),
          )),
    );
  }

  Padding createPageUsername() {
    return Padding(
      padding: const EdgeInsets.only(
          left: standardPadding * 3, right: standardPadding * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wie lautet dein Vorname?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            height: standardPadding,
          ),
          Text(
            "Deinen Namen kannst du später nicht mehr ändern.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(
            height: standardPadding * 2,
          ),
          Material(
            elevation: 5,
            child: TextFormField(
              keyboardType: TextInputType.name,
              autofocus: true,
              initialValue: _username,
              maxLength: 20,
              decoration: InputDecoration(
                fillColor: Theme.of(context).cardColor,
                filled: true,
                hintText: 'Gib deinen Vornamen ein',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              validator: (input) {
                if (input == "") {
                  return 'Bitte gib deinen Vornamen ein.';
                } else {
                  return null;
                }
              },
              onChanged: (input) => _username = input,
            ),
          )
        ],
      ),
    );
  }

  Padding createPageProfileImage() {
    return Padding(
      padding: const EdgeInsets.only(
          left: standardPadding * 3, right: standardPadding * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Füge dein Profilfoto hinzu",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            height: standardPadding,
          ),
          Text(
            "Wähle ein Foto von dir, dass Leute die du getroffen hast dich Wiedererkennen. Das Bild kannst du später ändern.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(
            height: standardPadding * 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      _pickProfilePicture();
                    },
                    child: Hero(
                      tag: "ownProfileImage",
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: (_profileImage != null)
                            ? _profileImage!.image
                            : AssetImage(defaultUserImagePath),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 20,
                      ),
                      color: mainRed,
                      onPressed: () {
                        _pickProfilePicture();
                      },
                    ),
                  )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Padding createPageBirthday() {
    return Padding(
      padding: const EdgeInsets.only(
          left: standardPadding * 3, right: standardPadding * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wann hast du Geburtstag?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            height: standardPadding,
          ),
          Text(
            "Deinen Begegnungen wird nur dein Alter angezeigt, nicht dein Geburtstag.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(
            height: standardPadding * 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "${_selectedDate.toDate().day.toString() + "." + _selectedDate.toDate().month.toString() + "." + _selectedDate.toDate().year.toString()}"
                        .split(' ')[0],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // Refer step 3
                    child: Text(
                      'Datum auswählen',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Padding createPageGender() {
    return Padding(
      padding: const EdgeInsets.only(
          left: standardPadding * 3, right: standardPadding * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wie identifizierst du dich?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            height: standardPadding,
          ),
          Text(
            "Jeder verfällt dem Liebeswahn!",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(
            height: standardPadding * 2,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = "female";
              });
            },
            child: Material(
                elevation: (_selectedGender == 'female') ? 0 : 5,
                color: (_selectedGender == 'female')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Weiblich",
                          style: (_selectedGender == 'female')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          ),
          SizedBox(
            height: standardPadding,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = "male";
              });
            },
            child: Material(
                elevation: (_selectedGender == 'male') ? 0 : 5,
                color: (_selectedGender == 'male')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Männlich",
                          style: (_selectedGender == 'male')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          ),
          SizedBox(
            height: standardPadding,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = "nonBinary";
              });
            },
            child: Material(
                elevation: (_selectedGender == 'nonBinary') ? 0 : 5,
                color: (_selectedGender == 'nonBinary')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Nicht-binär",
                          style: (_selectedGender == 'nonBinary')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          )
        ],
      ),
    );
  }

  Padding createPageSearchingGender() {
    return Padding(
      padding: const EdgeInsets.only(
          left: standardPadding * 3, right: standardPadding * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "An wem bist du interessiert?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            height: standardPadding,
          ),
          Text(
            "Dir werden nur passende Begegnungen angezeigt.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(
            height: standardPadding * 2,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSearchingGender = "women";
              });
            },
            child: Material(
                elevation: (_selectedSearchingGender == 'women') ? 0 : 5,
                color: (_selectedSearchingGender == 'women')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Frauen",
                          style: (_selectedSearchingGender == 'women')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          ),
          SizedBox(
            height: standardPadding,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSearchingGender = "men";
              });
            },
            child: Material(
                elevation: (_selectedSearchingGender == 'men') ? 0 : 5,
                color: (_selectedSearchingGender == 'men')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Männern",
                          style: (_selectedSearchingGender == 'men')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          ),
          SizedBox(
            height: standardPadding,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSearchingGender = "any";
              });
            },
            child: Material(
                elevation: (_selectedSearchingGender == 'any') ? 0 : 5,
                color: (_selectedSearchingGender == 'any')
                    ? mainRed
                    : Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Container(
                        padding: EdgeInsets.all(standardPadding * 2),
                        child: Text(
                          "Jedem",
                          style: (_selectedSearchingGender == 'any')
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.headlineMedium,
                        )),
                  ],
                )),
          )
        ],
      ),
    );
  }
}
