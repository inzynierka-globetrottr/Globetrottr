import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../service/location_service.dart';
import '../service/sync_service.dart';
import '../database/database_helper.dart';
import '../model/pending_point.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  bool _isTracking = false;
  bool _mapReady = false;
  List<PendingPoint> _points = [];

  // Track the user's current position separately from SQLite points
  LatLng? _currentPosition;

  // Tip: In a real app, retrieve this from a SecureStorage service
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fetchAndCenterLocation(); // Fetch GPS on load
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _loadInitialData() async {
    final token = await _storage.read(key: 'jwt_token');

    setState(() {
      _jwtToken = token;
    });

    await _refreshDb();
  }

  Future<void> _refreshDb() async {
    final points = await DatabaseHelper().getPendingPoints();
    setState(() {
      _points = points;
    });
  }

  /// Handles permissions and fetches the current GPS location
  Future<void> _fetchAndCenterLocation() async {
    print("DEBUG: _fetchAndCenterLocation button pressed");

    try {
      // 1. Check Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("DEBUG: GPS is turned off on the device.");
        return;
      }

      // 2. Check/Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print("DEBUG: Permission was denied, requesting now...");
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print("DEBUG: User blocked permissions forever. Open Settings.");
        // Optional: Open phone settings automatically
        // await Geolocator.openAppSettings();
        return;
      }

      // 3. Get Position using the NEW LocationSettings
      print("DEBUG: Requesting current position...");
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);
      print("DEBUG: Successfully found location: $currentLatLng");

      if (mounted) {
        setState(() {
          _currentPosition = currentLatLng;
        });
        // Move the map
        _mapController.move(currentLatLng, 15.0);
      }
    } catch (e) {
      print("DEBUG: ERROR IN GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Globetrottr Tracker"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. THE MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(50.07, 19.91), // Fallback center
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                setState(() => _mapReady = true);
              },
              onPositionChanged: (pos, hasGesture) => setState(() {}),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.globetrottr',
              ),
              // Marker Layer for SQLite points
              MarkerLayer(
                markers: _points.map((p) => Marker(
                  point: LatLng(p.latitude, p.longitude),
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                )).toList(),
              ),
              // Marker Layer for Current Position (Distinct Blue Dot)


          if (_currentPosition != null)
            IgnorePointer( // Allows map interaction through the fog
              child: CustomPaint(
                size: Size.infinite,
                painter: FogPainter(_currentPosition, _mapController.camera),
              ),
            ),

          if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
            ],
          ),

          // 2. DRAGGABLE DEBUG PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(child: Container(width: 50, height: 5, color: Colors.grey[300])),
                    const SizedBox(height: 20),

                    // Action Buttons (GPS & Sync)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_isTracking) {
                                _locationService.stopTracking();
                              } else {
                                await _locationService.startTracking();
                                // Optional: Keep map centered while tracking starts
                                _fetchAndCenterLocation();
                              }
                              setState(() => _isTracking = !_isTracking);
                            },
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? "STOP GPS" : "START GPS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_jwtToken != null) {
                                await SyncService().syncPendingPoints(_jwtToken!);
                                await _refreshDb();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No JWT Token found!")),
                                );
                              }
                            },
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text("SYNC"),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    // Local DB Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Local Points: ${_points.length}",
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper().clearPendingPoints();
                            _refreshDb();
                          },
                        )
                      ],
                    ),

                    // List of Points (from Debug Screen)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _points.length,
                      itemBuilder: (context, index) {
                        final p = _points[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text("Lat: ${p.latitude.toStringAsFixed(4)}, Lng: ${p.longitude.toStringAsFixed(4)}"),
                          subtitle: Text("Point ID: ${p.id}"),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Optional: Add a Floating Action Button to snap back to current location
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAndCenterLocation,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blueAccent),
      ),
    );
  }
}

// TODO: move to a new file

class FogPainter extends CustomPainter {
  final LatLng? playerPosition;
  final MapCamera camera; // Use MapCamera instead of MapController
  final double holeRadiusMeters;

  FogPainter(this.playerPosition, this.camera, {this.holeRadiusMeters = 500.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (playerPosition == null) return;

    canvas.saveLayer(Offset.zero & size, Paint());

    final fogPaint = Paint()..color = Colors.black.withOpacity(0.95);
    canvas.drawRect(Offset.zero & size, fogPaint);

    final clearPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final offset = camera.getOffsetFromOrigin(playerPosition!);

    const Distance distanceCalc = Distance();
    final LatLng edgeLatLng = distanceCalc.offset(playerPosition!, holeRadiusMeters, 0);

    final edgeOffset = camera.getOffsetFromOrigin(edgeLatLng);

    final double pixelRadius = (offset - edgeOffset).distance;

    canvas.drawCircle(offset, pixelRadius, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.playerPosition != playerPosition ||
           oldDelegate.camera != camera;
  }
}