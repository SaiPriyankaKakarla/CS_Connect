import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';

class RegisteredEventsPage extends StatefulWidget {
  const RegisteredEventsPage({Key? key}) : super(key: key);

  @override
  State<RegisteredEventsPage> createState() => _RegisteredEventsPageState();
}

class _RegisteredEventsPageState extends State<RegisteredEventsPage> {
  List<Map<String, dynamic>> registeredEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRegisteredEvents();
  }

  Future<void> fetchRegisteredEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final regSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('registered_events')
          .get();

      final regIds = regSnapshot.docs.map((doc) => doc.id).toList();
      final List<Map<String, dynamic>> events = [];

      for (String eventId in regIds) {
        final doc = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          events.add(data);
        }
      }

      setState(() {
        registeredEvents = events;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching registered events: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Events'),
        backgroundColor: const Color(0xFF7A5EF7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : registeredEvents.isEmpty
              ? const Center(child: Text('No registered events found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: registeredEvents.length,
                  itemBuilder: (context, index) {
                    final event = registeredEvents[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        title: Text(event['title'] ?? 'No Title',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(eventData: event),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
