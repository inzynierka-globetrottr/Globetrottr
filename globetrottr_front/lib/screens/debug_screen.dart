import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../service/location_service.dart';
import '../service/sync_service.dart';
import '../model/pending_point.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final LocationService _locationService = LocationService();
  List<PendingPoint> _points = [];
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _refreshDb();
  }

  Future<void> _refreshDb() async {
    final points = await DatabaseHelper().getPendingPoints();
    setState(() {
      _points = points;
    });
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test GPS & SQLite')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isTracking
                      ? null
                      : () async {
                          try {
                            await _locationService.startTracking();
                            setState(() => _isTracking = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Tracking started!")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                  child: Text('Start GPS'),
                ),
                ElevatedButton(
                  onPressed: !_isTracking
                      ? null
                      : () {
                          _locationService.stopTracking();
                          setState(() => _isTracking = false);
                        },
                  child: Text('Stop GPS'),
                ),
                ElevatedButton(
                  onPressed: _refreshDb,
                  child: Text('Refresh Database'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await DatabaseHelper().clearPendingPoints();
                    _refreshDb();
                  },
                  child: Text(
                    'Clear DB',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sending data to backend..."),
                      ),
                    );

                    await SyncService().syncPendingPoints();

                    await _refreshDb();
                  },
                  child: const Text(
                    'Send (Sync)',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: _points.isEmpty
                ? Center(child: Text("Database is empty."))
                : ListView.builder(
                    itemCount: _points.length,
                    itemBuilder: (context, index) {
                      final p = _points[index];
                      // Formatujemy timestamp na ludzki czas
                      final time = DateTime.fromMillisecondsSinceEpoch(
                        p.timestamp,
                      );
                      return ListTile(
                        leading: CircleAvatar(child: Text('${p.id}')),
                        title: Text(
                          'Lat: ${p.latitude.toStringAsFixed(5)}, Lng: ${p.longitude.toStringAsFixed(5)}',
                        ),
                        subtitle: Text(
                          '${time.hour}:${time.minute}:${time.second}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
