import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rnt_spots/widgets/goolgle_map/location_handler.dart';

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

  @override
  void initState() {
    super.initState();
    location = Location();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request permission
      final LocationData? locData = await LocationHandler.getCurrentLocation();
      if (locData != null) {
        setState(() {
          currentLocation = locData;
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
      body: GoogleMap(
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
        polylines: Set<Polyline>.of(_createPolylines()),
        onMapCreated: (controller) {
          mapController = controller;
        },
        mapType: currentMapType,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              mapController.animateCamera(CameraUpdate.zoomIn());
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              mapController.animateCamera(CameraUpdate.zoomOut());
            },
            child: Icon(Icons.remove),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                // Toggle between different map types
                currentMapType = currentMapType == MapType.normal
                    ? MapType.satellite
                    : MapType.normal;
              });
            },
            child: Icon(Icons.map),
          ),
        ],
      ),
    );
  }

  List<Polyline> _createPolylines() {
    if (currentLocation != null) {
      return [
        Polyline(
          polylineId: const PolylineId('route_to_marker'),
          points: [
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            LatLng(widget.latitude, widget.longitude),
          ],
          color: Colors.blue,
          width: 3,
        ),
      ];
    }
    return [];
  }
}
