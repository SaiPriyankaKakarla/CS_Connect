import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';

class LikedEventsPage extends StatefulWidget {
  const LikedEventsPage({Key? key}) : super(key: key);

  @override
  State<LikedEventsPage> createState() => _LikedEventsPageState();
}

class _LikedEventsPageState extends State<LikedEventsPage> {
  List<Map<String, dynamic>> likedEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print("User is logged in: ${user.uid}");
        fetchLikedEvents(user);
      } else {
        print("User not logged in");
        setState(() => isLoading = false);
      }
    });
  }

  Future<void> fetchLikedEvents(User user) async {
    try {
      print('Fetching liked events for UID: ${user.uid}');
      final likedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('liked_events')
          .get();

      print('Liked IDs: ${likedSnapshot.docs.map((d) => d.id).toList()}');

      final List<Map<String, dynamic>> events = [];

      for (String eventId in likedSnapshot.docs.map((d) => d.id)) {
        final doc = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

        print('Checking event ID: $eventId | Exists: ${doc.exists}');

        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          events.add(data);
        }
      }

      setState(() {
        likedEvents = events;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching liked events: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Events'),
        backgroundColor: const Color(0xFF7A5EF7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : likedEvents.isEmpty
              ? const Center(child: Text('No liked events found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: likedEvents.length,
                  itemBuilder: (context, index) {
                    final event = likedEvents[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        title: Text(
                          event['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('📍 ${event['address'] ?? 'No Address'}'),
                            Text(
                                '📅 ${event['date'] ?? 'No Date'}    🕒 ${event['time'] ?? 'No Time'}'),
                            const SizedBox(height: 6),
                            Text(event['shortDescription'] ??
                                'No description available.'),
                          ],
                        ),
                        onTap: () async {
                          final shouldRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailPage(eventData: event),
                            ),
                          );
                          if (shouldRefresh == true) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              fetchLikedEvents(user);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
