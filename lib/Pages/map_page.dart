import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:reminders/Pages/profile_page.dart';
import 'package:reminders/Utils/MyDrawer.dart';

import '../Utils/Task.dart';
//import 'package:workmanager/workmanager.dart';

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     var newMap = _MapScreenState();
//     print('tak running');
//     //newMap.gpsRecorder(newMap.noOfHours);
//     return Future.value(true);
//   });
// }

class MapScreen extends StatefulWidget {
  final User user;
  final Position position;

  const MapScreen({
    required this.user,
    required this.position,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late User _currentUser;
  late Position _currentPosition;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  String noOfHours = "1";
  int gpsReadCount = 0;

  @override
  void initState() {
    _currentUser = widget.user;
    _currentPosition = widget.position;
    // Workmanager().initialize(
    //   callbackDispatcher,
    //   isInDebugMode: true,
    // );

    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    final marker = Marker(
      markerId: const MarkerId('place_name'),
      position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
      // icon: BitmapDescriptor.,
      infoWindow: const InfoWindow(
        title: 'title',
        snippet: 'address',
      ),
    );

    setState(() {
      markers[const MarkerId('place_name')] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(user: _currentUser),
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            markers: markers.values.toSet(),
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  LatLng(_currentPosition.latitude, _currentPosition.longitude),
              zoom: 11.0,
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  child: const Text('Save Position'),
                  onPressed: () async {
                    final CollectionReference tasks = FirebaseFirestore.instance
                        .collection('Users')
                        .doc(_currentUser.uid)
                        .collection('Tasks');

                    DateFormat dateFormat = DateFormat("dd-MM-yyyy HH:mm");
                    String date = dateFormat.format(DateTime.now());
                    TaskClass newTask = TaskClass(
                        description:
                            'GPS - ${_currentPosition.latitude}, ${_currentPosition.longitude}',
                        uid: _currentUser.uid,
                        date: date,
                        rating: 0);
                    await tasks.doc().set(newTask.toJson());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(user: _currentUser),
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  child: const Text('Track GPS'),
                  onPressed: () async {
                    hoursDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future hoursDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select the no. of Hours'),
        content: SingleChildScrollView(
          child: RadioDialog(
            noOfHOurs: noOfHours,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
             // Workmanager().registerOneOffTask('1', 'recordGps');
              gpsRecorder(noOfHours);
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }

  gpsRecorder(String hours) async {
    try {
      print('entered gpsRecorder function');
      print('Number of Hours: $noOfHours');

      final CollectionReference tasks = FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.uid)
          .collection('Tasks');

      DateFormat dateFormat = DateFormat("dd-MM-yyyy HH:mm");
      DateFormat timeFormat = DateFormat("HH:mm");
      String date = dateFormat.format(DateTime.now());
      String startTime = timeFormat.format(DateTime.now());
      var docId;

      TaskClass newTask = TaskClass(
          description: 'GPS Tracking start-$startTime',
          uid: _currentUser.uid,
          date: date,
          rating: 0);

      await tasks.add(newTask.toJson()).then((value) => docId = value.id);

      print(docId);
      DocumentReference newDoc = FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.uid)
          .collection('Tasks')
          .doc(docId);

      Timer.periodic(Duration(seconds: 5), (timer) async {
        //change to minutes

        print('Inside Timer');
        gpsReadCount++;

        await _getCurrentPosition();

        newDoc.update(newTask.gpsValues(_currentPosition, gpsReadCount));

        if (gpsReadCount == 12 * int.parse(noOfHours)) {
          print('Killed timer');
          //await Workmanager().cancelAll();
          return timer.cancel();
        }
      });
    } on Exception {
      return Container();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  setHours(String value) {
    noOfHours = value;
  }
}

class RadioDialog extends StatefulWidget {
  final noOfHOurs;

  const RadioDialog({Key? key, this.noOfHOurs}) : super(key: key);

  @override
  State<RadioDialog> createState() => _RadioDialogState();
}

class _RadioDialogState extends State<RadioDialog> {
  String _selectedIndex = '1';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile(
          title: const Text('1 Hour'),
          value: "1",
          groupValue: _selectedIndex,
          onChanged: (value) {
            setState(() {
              _selectedIndex = value.toString();
            });
          },
        ),
        RadioListTile(
          title: const Text('2 Hours'),
          value: "2",
          groupValue: _selectedIndex,
          onChanged: (value) {
            setState(() {
              print(value);
              _selectedIndex = value.toString();
              var screen = _MapScreenState();
              screen.setHours(_selectedIndex);
            });
          },
        ),
        RadioListTile(
          title: const Text('3 Hours'),
          value: "3",
          groupValue: _selectedIndex,
          onChanged: (value) {
            setState(() {
              _selectedIndex = value.toString();
              var screen = _MapScreenState();
              screen.setHours(_selectedIndex);
            });
          },
        ),
        RadioListTile(
          title: const Text('4 Hours'),
          value: "4",
          groupValue: _selectedIndex,
          onChanged: (value) {
            setState(() {
              _selectedIndex = value.toString();
              var screen = _MapScreenState();
              screen.setHours(_selectedIndex);
            });
          },
        ),
      ],
    );
  }
}
