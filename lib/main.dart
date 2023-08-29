import 'dart:async';

import 'package:location/location.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationData? myCurrentLocation;
  late final GoogleMapController _googleMapController;
  StreamSubscription<LocationData>? _locationSubscription;
  final Location _location = Location();
  List<LatLng> _polylineCoordinates = []; // List to store coordinates
  Polyline _polyline = Polyline(polylineId: PolylineId('user_route'));
  Marker? _userMarker;

  void getMyLocation() async{
    await Location.instance.requestPermission().then((requestpermission){
      print(requestpermission);
    });
    await Location.instance.hasPermission().then((permissionStatus){
      print(permissionStatus);
    });
    myCurrentLocation = await Location.instance.getLocation();
    print(myCurrentLocation);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initalizeMap()async{
    final location = Location();
    /// Create and request location permission
    if(await location.hasPermission() == PermissionStatus.denied){
      await location.requestPermission();
    }

    ///get Current location
     final currentLocation = await location.getLocation();
    /// Animated the map to the current location
    _googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(currentLocation.latitude!, currentLocation.longitude!), 15));

    setState(() {
      myCurrentLocation = currentLocation;
    });
  }
  void _startLocationUpdates() {
    _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
      _updateMarkerPosition(locationData);
      _updatePolyline(locationData);
      _googleMapController?.animateCamera(CameraUpdate.newLatLng(
        LatLng(locationData.latitude!, locationData.longitude!),
      ));
    });
  }

  void _updateMarkerPosition(LocationData locationData) {
    setState(() {
      myCurrentLocation = locationData;

      if (_userMarker == null) {
        _userMarker = Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(locationData.latitude!, locationData.longitude!),
          onTap: () {
          },
        );
      } else {
        _userMarker = _userMarker!.copyWith(
          positionParam: LatLng(locationData.latitude!, locationData.longitude!),
        );
      }
    });

    // Request a re-render of the map to update marker position
    _googleMapController?.moveCamera(CameraUpdate.newLatLng(
      LatLng(locationData.latitude!, locationData.longitude!),
    ));
  }

  void _showInfoWindow(LocationData locationData) {
    final infoWindow = InfoWindow(
      title: 'My Current Location',
      snippet: 'Lat: ${locationData.latitude}, Lng: ${locationData.longitude}',
    );
    _googleMapController?.showMarkerInfoWindow(MarkerId('current_location'));

  }

  void _updatePolyline(LocationData locationData) {
    setState(() {
      _polylineCoordinates.add(LatLng(locationData.latitude!, locationData.longitude!));
      _polyline = Polyline(
        polylineId: PolylineId('user_route'),
        color: Colors.blue,
        points: _polylineCoordinates,
      );
      _googleMapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: _polylineCoordinates.first, northeast: _polylineCoordinates.last),
        100, // Padding value to ensure the polyline is visible
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _initalizeMap();
    _startLocationUpdates();

  }
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goggle Map Screen'),
      ),
      body: Stack(
        children: [
      GoogleMap(
        initialCameraPosition: const CameraPosition(
          zoom: 15,
          bearing: 30,
          tilt: 10,
          target: LatLng(24.250151813382207, 89.92231210838047),
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        trafficEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          print('on map created');
          _googleMapController = controller;
        },
        compassEnabled: true,
        mapType: MapType.normal,
        markers: _userMarker != null ? Set<Marker>.of([_userMarker!]) : {},
        polylines: _polyline != null ? Set<Polyline>.of([_polyline]) : {},
      ),
      myCurrentLocation!= null
          ? Positioned(
        top: 16,
        left: 16,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latitude: ${myCurrentLocation!.latitude}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'Longitude: ${myCurrentLocation!.longitude}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      )
          : SizedBox.shrink(),
      ],
    ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: (){
      //     getMyLocation();
      //   },
      //   child: Icon(Icons.my_location),
      // ),
    );
  }
}

