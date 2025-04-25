// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cs_connect_app/login_page_alternative.dart';
import 'package:cs_connect_app/events_page.dart';
import 'package:cs_connect_app/add_event_page.dart';
import 'package:cs_connect_app/my_events_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // replace the red “error” screen with transparent container (debug only)
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      Container(color: Colors.transparent);

  // initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CS Connect',
      theme: ThemeData(
        primaryColor: const Color(0xFF7A5EF7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7A5EF7),
          foregroundColor: Colors.white,
        ),
      ),

      //  ↓ instead of LoginPageAlternative, we start at AuthGate ↓
      home: const AuthGate(),

      routes: {
        '/events':   (ctx) => const EventsPage(),
        '/addEvent': (ctx) => const AddEventPage(),
        '/myEvents': (ctx) => const MyEventsPage(),
      },
    );
  }
}

/// Listens to FirebaseAuth; shows Login when signed out,
/// EventsPage when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // if we have a valid user → go to EventsPage
        if (snapshot.hasData) {
          return const EventsPage();
        }

        // otherwise show login
        return const LoginPageAlternative();
      },
    );
  }
}