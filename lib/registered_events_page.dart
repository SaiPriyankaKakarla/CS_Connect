import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';

class RegisteredEventsPage extends StatelessWidget {
  const RegisteredEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = authSnap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Registered Events')),
            body: const Center(
                child: Text('Please sign in to see your registrations.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Registered Events')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('registered_events')
                .orderBy('registeredAt', descending: true)
                .snapshots(),
            builder: (ctx2, regSnap) {
              if (regSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final regDocs = regSnap.data!.docs;
              if (regDocs.isEmpty) {
                return const Center(child: Text('No registered events found.'));
              }
              final ids = regDocs.map((d) => d.id).toList();

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('events')
                    .where(FieldPath.documentId, whereIn: ids)
                    .get(),
                builder: (ctx3, eventsSnap) {
                  if (eventsSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final events = eventsSnap.data!.docs.map((d) {
                    final m = d.data()! as Map<String, dynamic>;
                    m['id'] = d.id;
                    return m;
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (ctx4, i) {
                      final e = events[i];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(e['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('📍 ${e['address'] ?? ''}'),
                              Text(
                                  '📅 ${e['date'] ?? ''}    🕒 ${e['time'] ?? ''}'),
                              const SizedBox(height: 6),
                              Text(e['shortDescription'] ?? ''),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EventDetailPage(eventData: e)),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
