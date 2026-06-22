import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  final LocationService _locationService = LocationService();
  List<PendingPoint> _points = [];
  bool _isTracking = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _refreshDb();
    _checkSavedToken();
  }

  Future<void> _checkSavedToken() async {
    try {
      final newToken = await ref.read(authServiceProvider).refreshToken();
      if (!mounted) return;

      if (newToken != null) {
        setState(() {
          _jwtToken = newToken;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restored session!')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session restore failed: $e')),
      );
    }
  }

  Future<void> _logout() async {
    _locationService.stopTracking();
    setState(() => _isTracking = false);

    await MapStorage().clearPendingPoints();
    await _refreshDb();
    await ref.read(authServiceProvider).logout();

    if (!mounted) return;

    setState(() {
      _jwtToken = null;
      _usernameController.clear();
      _passwordController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Successfully logout!')));
  }

  Future<void> _refreshDb() async {
    final points = await MapStorage().getPendingPoints();
    if (!mounted) return;
    setState(() {
      _points = points;
    });
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test GPS, SQLite & Auth')),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (only for registration)',
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _jwtToken != null
                        ? 'Status: Logged in'
                        : 'Status: No token',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          try {
                            final request = RegisterRequest(
                              username: _usernameController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                            final token = await ref.read(authServiceProvider).register(request);

                            if (!context.mounted) return;

                            setState(() {
                              _jwtToken = token;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registered and Logged in!'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Registration failed: $e',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Registration',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () async {
                          try {
                            final request = LoginRequest(
                              login: _usernameController.text,
                              password: _passwordController.text,
                            );
                            final token = await ref.read(authServiceProvider).login(request);

                            if (!context.mounted) return;

                            setState(() {
                              _jwtToken = token;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged in')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Login failed: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final token = await ref.read(authServiceProvider).signInWithGoogle();

                            if (!context.mounted) return;

                            if (token != null) {
                              setState(() {
                                _jwtToken = token;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Zalogowano przez Google'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Anulowano logowanie przez Google',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Błąd logowania przez Google: $e',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Login with Google',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _logout,
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isTracking
                            ? null
                            : () async {
                                try {
                                  await _locationService.startTracking();
                                  _locationService.setRecording(true);
                                  if (!context.mounted) return;
                                  setState(() => _isTracking = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tracking started!'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                        child: const Text('Start GPS'),
                      ),
                      ElevatedButton(
                        onPressed: !_isTracking
                            ? null
                            : () {
                                _locationService.stopTracking();
                                setState(() => _isTracking = false);
                              },
                        child: const Text('Stop GPS'),
                      ),
                      ElevatedButton(
                        onPressed: _refreshDb,
                        child: const Text('Refresh DB'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await MapStorage().clearPendingPoints();
                          if (!context.mounted) return;
                          await _refreshDb();
                        },
                        child: const Text(
                          'Clear DB',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        onPressed: () async {
                          if (_jwtToken == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error: Log in first!'),
                              ),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sending data to backend...'),
                            ),
                          );

                          await ref.read(syncServiceProvider).syncPendingPoints();
                          if (!context.mounted) return;
                          await _refreshDb();
                        },
                        child: const Text(
                          'Send (Sync)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            flex: 4,
            child: _points.isEmpty
                ? const Center(child: Text('Database is empty.'))
                : ListView.builder(
                    itemCount: _points.length,
                    itemBuilder: (context, index) {
                      final p = _points[index];
                      final time = DateTime.fromMillisecondsSinceEpoch(
                        p.timestamp,
                      );
                      return ListTile(
                        leading: CircleAvatar(child: Text('${p.id}')),
                        title: Text(
                          'Lat: ${p.latitude.toStringAsFixed(5)}, Lng: ${p.longitude.toStringAsFixed(5)}',
                        ),
                        subtitle: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
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
