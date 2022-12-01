import 'package:ecodroid/pages/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

class MapsPage extends StatelessWidget {
  static const String id = 'maps_page';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: mapsPage(),
    );
  }
}

class mapsPage extends StatefulWidget {
  @override
  _mapsPageState createState() => _mapsPageState();
}

class _mapsPageState extends State<mapsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 52, 71, 68),
      // ignore: prefer_const_constructors
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(
              width: 40,
            ),
            Hero(
              tag: 'logo',
              child: SizedBox(
                height: 100.0,
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
            IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, ProfilePage.id);
                },
                icon: const Icon(Icons.person))
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: FireMap(),

        // Center(
        //   child: ButtonDecor(
        //     width: 257,
        //     height: 59,
        //     title: 'Report',
        //     onPressed: () {
        //       Navigator.pushNamed(context, ReportPage.id);
        //     },
        //     colour: const Color.fromARGB(255, 84, 160, 56),
        //   ),
        // ),
      ),
    );
  }
}

class FireMap extends StatefulWidget {
  const FireMap({super.key});

  @override
  State<FireMap> createState() => _FireMapState();
}

class _FireMapState extends State<FireMap> {
  late TextEditingController _latitudeController, _longitudeController;

  // firestore init
  final _firestore = FirebaseFirestore.instance;
  late GeoFlutterFire geo;
  double? poslong, poslat;
  late Stream<List<DocumentSnapshot>> stream;
  final radius = BehaviorSubject<double>.seeded(1.0);
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

    geo = GeoFlutterFire();
    GeoFirePoint center = geo.point(latitude: 20, longitude: 20);
    stream = radius.switchMap((rad) {
      var collectionReference = _firestore.collection('locations');
      return geo.collection(collectionRef: collectionReference).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    });
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    radius.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 576,
              width: 450,
              padding: const EdgeInsets.all(10),
              child: GoogleMap(
                onMapCreated: onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.27774, 85.77761),
                  zoom: 15,
                ),
                myLocationEnabled: true,
                mapType: MapType.hybrid,
                mapToolbarEnabled: true,
                compassEnabled: true,
                markers: Set<Marker>.of(markers.values),
                onCameraMove: (CameraPosition cp) {
                  LatLng center = cp.target;
                  poslong = center.longitude;
                  poslat = center.latitude;
                },
              ),
            ),
            const Positioned(
              top: 273,
              left: 167,
              child: Center(
                child: Icon(
                  size: 30,
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _addPoint(poslat!, poslong!),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 46, 140, 17),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 9),
                      blurRadius: 20,
                      spreadRadius: 3)
                ]),
            child: Row(
              children: const [
                Icon(
                  Icons.pin_drop,
                  color: Colors.white,
                ),
                Text(
                  "Add Sapling Position",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Oswald',
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => _addBluePoint(poslat!, poslong!),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 25, 0, 255),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 9),
                      blurRadius: 20,
                      spreadRadius: 3)
                ]),
            child: Row(
              children: const [
                Icon(
                  Icons.pin_drop,
                  color: Colors.white,
                ),
                Text(
                  "Add Plantation Drive",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Oswald',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
//      _showHome();
      //start listening after map is created
      stream.listen((List<DocumentSnapshot> documentList) {
        _updateMarkers(documentList);
      });
    });
  }

  void _addPoint(double lat, double lng) {
    GeoFirePoint geoFirePoint = geo.point(latitude: lat, longitude: lng);
    _firestore
        .collection('locations')
        .add({'longitude': lng, 'latitude': lat}).then((_) {
      // ignore: avoid_print
      print('added ${geoFirePoint.hash} successfully');
    });
  }

  void _addBluePoint(double lat, double lng) {
    GeoFirePoint geoFirePoint = geo.point(latitude: lat, longitude: lng);
    _firestore
        .collection('plantations')
        .add({'longitude': lng, 'latitude': lat}).then((_) {
      // ignore: avoid_print
      print('added ${geoFirePoint.hash} successfully');
    });
  }

  void _addMarker(double lat, double lng) {
    final id = MarkerId(lat.toString() + lng.toString());
    final marker = Marker(
      markerId: id,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
          title: 'Tree Location', snippet: 'Current Status: Healthy'),
    );

    setState(() {
      markers[id] = marker;
    });
  }

  void _addBlueMarker(double lat, double lng) {
    final id = MarkerId(lat.toString() + lng.toString());
    final marker = Marker(
      markerId: id,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: const InfoWindow(
          title: 'Plantation Drive', snippet: 'Status: Coming Up'),
    );

    setState(() {
      markers[id] = marker;
    });
  }

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('locations');
  final CollectionReference _collectionRef2 =
      FirebaseFirestore.instance.collection('plantations');

  Future<void> _updateMarkers(List<DocumentSnapshot> documentList) async {
    QuerySnapshot querySnapshot = await _collectionRef.get();
    final allData = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    for (int i = 0; i < allData.length; i++) {
      double latitude = allData[i].values.first;
      double longitude = allData[i].values.last;
      _addMarker(latitude, longitude);
    }

    QuerySnapshot querySnapshot2 = await _collectionRef2.get();
    final allData2 = querySnapshot2.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    for (int i = 0; i < allData2.length; i++) {
      double latitude = allData2[i].values.first;
      double longitude = allData2[i].values.last;
      _addBlueMarker(latitude, longitude);
    }
  }
}
