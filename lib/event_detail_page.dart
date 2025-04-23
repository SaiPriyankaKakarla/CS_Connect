// event_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailPage({Key? key, required this.eventData}) : super(key: key);

  // Existing like functionality
  Future<bool> checkIfLiked(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_events')
        .doc(eventId)
        .get();
    return doc.exists;
  }

  Future<void> toggleLike(String eventId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final likeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_events')
        .doc(eventId);

    if (isLiked) {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
    } else {
      await likeRef.delete();
    }
  }

  // New: Check if user has registered for the event.
  Future<bool> checkIfRegistered(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_events')
        .doc(eventId)
        .get();
    return doc.exists;
  }

  // New: Toggle registration. If register is true, add the event;
  // otherwise, remove it.
  Future<void> toggleRegistration(String eventId, bool register) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final regRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_events')
        .doc(eventId);

    if (register) {
      // Store any event data you need; here we store the title and a timestamp.
      await regRef.set({
        'title': eventData['title'] ?? 'No Title',
        'registeredAt': FieldValue.serverTimestamp(),
      });
    } else {
      await regRef.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = eventData['title'] ?? 'No Title';
    final String address = eventData['address'] ?? 'No Address';
    final String date = eventData['date'] ?? 'No Date Provided';
    final String time = eventData['time'] ?? 'No Time Provided';
    final String description =
        eventData['description'] ?? 'No description available.';
    final String? imageUrl = eventData['imageUrl'] as String?;
    final Map<String, dynamic>? locationData =
        eventData['location'] as Map<String, dynamic>?;
    final double lat = locationData?['lat']?.toDouble() ?? 0.0;
    final double lng = locationData?['lng']?.toDouble() ?? 0.0;
    final LatLng eventLatLng = LatLng(lat, lng);
    final String eventId = eventData['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF7A5EF7),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Event Image and Details with Like Button
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? imageUrl
                                  : 'https://via.placeholder.com/600x300.png?text=No+Image+Available',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF292D32),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 18, color: Color(0xFF7A5EF7)),
                                    const SizedBox(width: 6),
                                    Text(date,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time,
                                        size: 18, color: Color(0xFF7A5EF7)),
                                    const SizedBox(width: 6),
                                    Text(time,
                                        style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 20, color: Color(0xFF7A5EF7)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(address,
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF292D32),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(description,
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Like Button at top right (existing)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: FutureBuilder<bool>(
                          future: checkIfLiked(eventId),
                          builder: (context, snapshot) {
                            bool isInitiallyLiked = snapshot.data ?? false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                bool isLiked = isInitiallyLiked;
                                return IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.pinkAccent,
                                    size: 28,
                                  ),
                                  onPressed: () async {
                                    setState(() => isLiked = !isLiked);
                                    await toggleLike(eventId, isLiked);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Card 2: Map View
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                size: 18, color: Color(0xFF7A5EF7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Latitude: $lat, Longitude: $lng',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                center: eventLatLng,
                                zoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: const ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.example.csconnect',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 80,
                                      height: 80,
                                      point: eventLatLng,
                                      builder: (ctx) => const Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
                // Registration Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FutureBuilder<bool>(
                    future: checkIfRegistered(eventId),
                    builder: (context, snapshot) {
                      bool isRegistered = snapshot.data ?? false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRegistered
                                  ? Colors.grey
                                  : const Color(0xFF7A5EF7),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: () async {
                              bool newStatus = !isRegistered;
                              await toggleRegistration(eventId, newStatus);
                              setState(() {
                                isRegistered = newStatus;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newStatus
                                      ? 'Registered successfully!'
                                      : 'Unregistered successfully!'),
                                ),
                              );
                            },
                            child: Text(
                              isRegistered ? "Unregister" : "Register",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
