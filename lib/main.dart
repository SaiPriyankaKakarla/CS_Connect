import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cs_connect_app/login_page_alternative.dart';
import 'package:cs_connect_app/events_page.dart';
import 'package:cs_connect_app/add_event_page.dart';
import 'package:cs_connect_app/my_events_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Override the error widget builder (debug-only).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Return a widget that replaces the red error banner.
    // For example, an empty Container or a small text widget.
    return Container(color: Colors.transparent);
  };

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CS Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPageAlternative(),
      routes: {
        '/events': (context) => const EventsPage(),
        '/addEvent': (context) => const AddEventPage(),
        '/myEvents': (context) => const MyEventsPage(),
      },
    );
  }
}
