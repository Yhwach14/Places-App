import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:places_app/screens/map_screen.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(double lat, double lng, String address) onSelectLocation;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  LatLng? _pickedLocation;
  String? _address;
  var _isGettingLocation = false;

  final MapController _mapController = MapController();

  Future<void> _getPrettyAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final String addressData = "${p.street}, ${p.locality}, ${p.country}";

        setState(() {
          _address = addressData;
        });

        widget.onSelectLocation(lat, lng, addressData);
      }
    } catch (e) {
      print("Geocoding Error: $e");
    }
  }

  void _getCurrentLocation() async {
    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      loc.LocationData? locationData;

      locationData = await location.getLocation().timeout(
        const Duration(seconds: 10),
      );

      if (locationData.latitude == null || locationData.longitude == null) {
        throw Exception("Coordinates are null");
      }

      final latLng = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        _pickedLocation = latLng;
      });

      _mapController.move(latLng, 16);
      await _getPrettyAddress(latLng.latitude, latLng.longitude);
    } catch (e) {
      print("Location Debug Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS is warming up. Please tap once more.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _selectOnMap() async {
    final LatLng? selectedLocation = await Navigator.of(
      context,
    ).push<LatLng>(MaterialPageRoute(builder: (ctx) => const MapScreen()));

    if (selectedLocation == null) {
      return;
    }

    setState(() {
      _pickedLocation = selectedLocation;
    });

    _mapController.move(selectedLocation, 16);

    await _getPrettyAddress(
      selectedLocation.latitude,
      selectedLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      _address ?? 'No Location Chosen',
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    } else if (_pickedLocation != null) {
      previewContent = FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _pickedLocation!, initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.astelz.places_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _pickedLocation!,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey.withOpacity(0.5)),
          ),
          child: previewContent,
        ),

        if (_address != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_address!, style: const TextStyle(fontSize: 12)),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Current Location'),
            ),
            TextButton.icon(
              onPressed: _selectOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Select On Map'),
            ),
          ],
        ),
      ],
    );
  }
}
