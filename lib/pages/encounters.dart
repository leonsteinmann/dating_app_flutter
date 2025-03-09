import 'dart:ui' as ui;
import 'package:datingapp/models/encounter.dart';
import 'package:datingapp/pages/conversation_request.dart';
import 'package:datingapp/pages/profile.dart';
import 'package:datingapp/services/database.dart';
import 'package:datingapp/services/storageManager.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/values/mapsStyle.dart';
import 'package:datingapp/widgets/animations/logo_animation.dart';
import 'package:datingapp/widgets/images.dart';
import 'package:datingapp/widgets/provider.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import 'package:provider/provider.dart';

import '../widgets/storyFutureBuilder.dart';

class EncountersPage extends StatefulWidget {
  @override
  _EncountersPageState createState() => _EncountersPageState();
}

class _EncountersPageState extends State<EncountersPage> {
  // encounters
  List<Encounter> encounterList = [];
  int selectedEncounter = 0;
  Set<Marker> markers = {};
  bool showSelectedEncounter = true;
  bool isLoadingCounters = false;

  // Maps
  GoogleMapController? _mapsController;
  PageController _pageController = PageController();
  ScrollController _listViewController = ScrollController();

  static final CameraPosition _startPosition = CameraPosition(
    target: LatLng(48.135666124, 11.571831046),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getAllEncounters();
  }

  void _onEncounterSelected(int newEncounter) {
    setState(() {
      selectedEncounter = newEncounter;
    });
    //_listViewController.animateTo(encounterList.indexOf(selectedEncounter!)*140, duration: Duration(milliseconds: 500), curve: Curves.ease);
    _onAnimateCamera(LatLng(encounterList[selectedEncounter].geoPoint!.latitude,
        encounterList[selectedEncounter].geoPoint!.longitude));
  }

  void _onAnimateCamera(LatLng position) {
    Timer(Duration(milliseconds: 200), () async {
      await _mapsController!
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        zoom: 15,
        target: position,
      )));
    });
  }

  getPeerUser(List<dynamic> users) {
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    if (users[0] == currUser!.idUser) {
      return users[1];
    } else {
      return users[0];
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final theme = await StorageManager.readData('themeMode');
    if (theme == 'dark') {
      controller.setMapStyle(MapStyle.darkMapStyle);
    } else {
      controller.setMapStyle(MapStyle.lightMapStyle);
    }
    this._mapsController = controller;
  }

  void _getAllEncounters() async {
    print("get all Encounter");
    setState(() {
      isLoadingCounters = true;
    });
    Provider.of<CurrUser>(context, listen: false)
        .updateCurrentUser(FirebaseAuth.instance.currentUser?.uid);
    final currUser = Provider.of<CurrUser>(context, listen: false).currUser;
    List<Encounter> tempEncounters = [];

    for (var id in currUser!.encounters!) {
      Encounter encounter = await Database.getEncounter(id);
      //check if not older than 24h
      if (DateTime.now().difference(encounter.timestamp!.toDate()).inHours <=
          24) {
        tempEncounters.add(encounter);
      } else {
        Database.moveEncounterToPastEncounters(
            encounter.idEncounter, currUser.idUser!);
      }
    }

    if (tempEncounters.length != 0) {
      setState(() {
        encounterList = tempEncounters;
        _onEncounterSelected(0);
      });
      _addMarkers();
    }
    setState(() {
      isLoadingCounters = false;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<BitmapDescriptor> getBitmapDescriptorFromAssetBytes(
      String path, int width) async {
    final Uint8List imageData = await getBytesFromAsset(path, width);
    return BitmapDescriptor.fromBytes(imageData);
  }

  void _addMarkers() async {
    final Set<Marker> tempMarkers = {};
    for (var enc in encounterList) {
      final MarkerId markerId = MarkerId(enc.idEncounter!);
      final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(enc.geoPoint!.latitude, enc.geoPoint!.longitude),
        icon: await getBitmapDescriptorFromAssetBytes(locationPinPath, 100),
        onTap: () {
          _mapsController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(enc.geoPoint!.latitude, enc.geoPoint!.longitude),
              zoom: 15,
            ),
          ));
          _onEncounterSelected(encounterList.indexOf(enc));
        },
      );
      tempMarkers.add(marker);
    }
    setState(() {
      markers = tempMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*floatingActionButton: FloatingActionButton(
        child: Icon(Icons.update, color: Colors.white,),
        onPressed: _getAllEncounters,
        heroTag: "refresh",
      ),*/
      body: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            child: GoogleMap(
              initialCameraPosition: _startPosition,
              markers: markers,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: _onMapCreated,
            ),
          ),
          (isLoadingCounters)
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: LogoAnimation(200.0, 100.0),
                  ))
              : (showSelectedEncounter && encounterList.length > 0)
                  ? _buildCarousel()
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: standardPadding * 2,
                          vertical: standardPadding * 5),
                      child: Center(
                        child: Text(
                          "Oh! hier ist noch nichts!\nSchalte den Standortmodus an, um Leuten zu begegnen",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: MediaQuery.of(context).size.width + 500,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() => _onEncounterSelected(index));
          print(selectedEncounter);
        },
        scrollDirection: Axis.vertical,
        itemCount: encounterList.length,
        itemBuilder: (BuildContext context, int index) {
          return buildEncounterStory(index);
        },
      ),
    );
  }

  Widget buildEncounterStory(int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(
                    getPeerUser(encounterList[index].users!),
                    encounterList[index])));
      },
      child: StoryFutureBuilder(getPeerUser(encounterList[index].users!),
          size: MediaQuery.of(context).size.width),
    );
  }

  Widget buildEncounterListView() {
    return Expanded(
      child: ListView.builder(
        controller: _listViewController,
        shrinkWrap: true,
        itemCount: encounterList.length,
        itemBuilder: (context, index) =>
            buildEncounterEntry(context, encounterList[index]),
      ),
    );
  }

  Widget buildEncounterEntry(BuildContext context, Encounter encounter) {
    return Padding(
      padding: const EdgeInsets.only(
          top: standardPadding, left: standardPadding, right: standardPadding),
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(standardCornerRadius)),
        elevation: standardElevation,
        color: (encounterList[selectedEncounter] == encounter)
            ? Theme.of(context).primaryColorLight
            : Theme.of(context).cardColor,
        child: InkWell(
          onTap: () {
            _onEncounterSelected(encounterList.indexOf(encounter));
          },
          child: Padding(
            padding: const EdgeInsets.all(standardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                  getPeerUser(
                                      encounterList[selectedEncounter].users!),
                                  encounter)));
                    },
                    child: UserProfileImageFutureBuilder(
                      getPeerUser(encounter.users!),
                      profilePictureId: "",
                      size: 50.0,
                    )),
                Padding(
                  padding: EdgeInsets.only(left: standardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      UserProfileNameFutureBuilder(
                        getPeerUser(encounter.users!),
                        textStyle: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        "vor ${DateTime.now().difference(encounter.timestamp!.toDate()).inHours.toString()} Stunden",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            child: Text('Anschreiben'),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ConversationRequestPage(
                                              encounter: encounterList[
                                                  selectedEncounter])));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: mainRed,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                textStyle: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          /*OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationRequestPage(encounter: selectedEncounter!)));
                            },
                            child: const Text("Anschreiben"),
                          ),*/
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
