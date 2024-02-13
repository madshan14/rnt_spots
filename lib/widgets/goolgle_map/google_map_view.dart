import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rnt_spots/widgets/goolgle_map/location_handler.dart';
import 'package:http/http.dart' as http;

class GoogleMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String label;

  const GoogleMapView(
      {Key? key,
      required this.latitude,
      required this.longitude,
      required this.label})
      : super(key: key);

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  late GoogleMapController mapController;
  MapType currentMapType = MapType.satellite;
  late Location location;
  LocationData? currentLocation;
  String _selectedMode = 'driving';

  Future<Iterable<Polyline>>? _polylinesFuture;

  @override
  void initState() {
    super.initState();
    location = Location();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final LocationData? locData = await LocationHandler.getCurrentLocation();
      if (locData != null) {
        setState(() {
          currentLocation = locData;
          _polylinesFuture = _createPolylines(_selectedMode);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not get the location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: FutureBuilder<Iterable<Polyline>>(
        future: _polylinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('property_location'),
                  position: LatLng(widget.latitude, widget.longitude),
                  infoWindow: InfoWindow(
                    title: widget.label,
                  ),
                ),
                if (currentLocation != null)
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: LatLng(
                      currentLocation!.latitude!,
                      currentLocation!.longitude!,
                    ),
                    infoWindow: const InfoWindow(
                      title: "Me",
                    ),
                  ),
              },
              polylines: Set<Polyline>.of(snapshot.data!),
              onMapCreated: (controller) {
                mapController = controller;
              },
              mapType: currentMapType,
            );
          } else {
            return const Center(child: Text('No data'));
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              mapController.animateCamera(CameraUpdate.zoomIn());
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              mapController.animateCamera(CameraUpdate.zoomOut());
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                currentMapType = currentMapType == MapType.normal
                    ? MapType.satellite
                    : MapType.normal;
              });
            },
            child: const Icon(Icons.map),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius:
                  BorderRadius.circular(20), // Set the border radius here
            ),
            child: DropdownButton<String>(
              value: _selectedMode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMode = newValue;
                    _polylinesFuture = _createPolylines(_selectedMode);
                  });
                }
              },
              items: <String>['driving', 'walking']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(value),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Future<Iterable<Polyline>> _createPolylines(String mode) async {
    List<Polyline> polylines = [];

    if (currentLocation == null) {
      return polylines;
    }

    final String apiKey = 'AIzaSyAvsq3zk5Ww3SM1rDBPkM7960fXGkaUOcA';

    final String origin =
        '${currentLocation!.latitude},${currentLocation!.longitude}';
    final String destination = '${widget.latitude},${widget.longitude}';

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final routes = decoded['routes'];

      if (routes != null && routes.isNotEmpty) {
        final points = routes[0]['overview_polyline']['points'];
        final decodedPoints = decodePoly(points);
        final List<LatLng> routeCoords = decodedPoints;

        polylines.add(Polyline(
          polylineId: const PolylineId('route_to_marker'),
          points: routeCoords,
          color: Colors.blue,
          width: 3,
        ));
      }
    }

    return polylines;
  }

  List<LatLng> decodePoly(String poly) {
    var list = <LatLng>[];
    int index = 0;
    int len = poly.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      var latlng = LatLng(latitude, longitude);
      list.add(latlng);
    }

    return list;
  }
}
