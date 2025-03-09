import 'dart:io';

import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/widgets/provider.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'profile_Image_pages.dart';

class MyProfilePage extends StatefulWidget {
  @override
  State createState() {
    return _MyProfilePageState();
  }
}

class _MyProfilePageState extends State<MyProfilePage> {
  final currFBUser = FirebaseAuth.instance.currentUser!;
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currUser = Provider.of<CurrUser>(context, listen: true).currUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mein Profil",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(standardPadding),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  OwnProfileImagePage(currUser!.idUser!)));
                    },
                    child: Hero(
                      tag: "ownProfileImage",
                      child: UserProfileImageFutureBuilder(currUser!.idUser,
                          size: 75.0),
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
          SizedBox(
            height: columnElementsPadding,
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: explanationTextColor,
                    )),
                SizedBox(
                  height: 3,
                ),
                Text(currUser.username!,
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(
                  height: 3,
                ),
              ],
            ),
            subtitle: Text(
              'Wird Nutzern bei einer Begegnung und im Chat angezeigt.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: explanationTextColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.date_range),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alter',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: explanationTextColor,
                    )),
                SizedBox(
                  height: 3,
                ),
                Text(calculateAge().toString(),
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(
                  height: 3,
                ),
              ],
            ),
            subtitle: Text(
              'Wird Nutzern bei einer Begegnung und im Chat angezeigt.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: explanationTextColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 1,
              child: Container(
                color: explanationTextColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.emoji_emotions_rounded),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Geschlechtsidentität',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: explanationTextColor,
                    )),
                SizedBox(
                  height: 3,
                ),
                Text(buildGenderString(),
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(
                  height: 3,
                ),
              ],
            ),
            subtitle: Text(
              'Nicht öffentlich. Wird für die Erstellung von Begegnungen verwendet.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: explanationTextColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_search),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interessiert an',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: explanationTextColor,
                    )),
                SizedBox(
                  height: 3,
                ),
                Text(buildSearchingGenderString(),
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(
                  height: 3,
                ),
              ],
            ),
            subtitle: Text(
              'Nicht öffentlich. Wird für die Erstellung von Begegnungen verwendet.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: explanationTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickProfilePicture() async {
    //TODO when picking profile picture, textfield is cleared
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file != null) {
      final croppedFile = await ImageCropper().cropImage(
        maxHeight: 500,
        maxWidth: 500,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: file.path,
      );
      if (croppedFile != null) {
        setState(() {
          _profileImageFile = File(croppedFile.path);
        });
        _saveProfilePicture();
      }
    }
  }

  Future<void> _saveProfilePicture() async {
    if (_profileImageFile != null) {
      String profileImageId =
          "${currFBUser.uid}_${DateTime.now().millisecondsSinceEpoch}";
      await FirebaseStorage.instance
          .ref()
          .child("users/${currFBUser.uid}/${currFBUser.uid}.jpg")
          .putFile(_profileImageFile!)
          .then((result) => {
                print(result),
              });

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
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OwnProfileImagePage(currFBUser.uid)));
  }

  calculateAge() {
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    DateTime tempDate = new DateTime.fromMicrosecondsSinceEpoch(
        currUser!.birthday!.microsecondsSinceEpoch);
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

  buildGenderString() {
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

  buildSearchingGenderString() {
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
