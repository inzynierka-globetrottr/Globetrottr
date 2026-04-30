import 'package:flutter/material.dart';
import 'screens/debug_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Globetrottr',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      initialRoute: '/login', // Start here
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MapScreen(),
        '/debug': (context) => DebugScreen(), // Keep for testing
      },
    );
  }
}