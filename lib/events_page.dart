import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show sin, cos, sqrt, asin;
import 'package:cs_connect_app/event_detail_page.dart';
import 'package:cs_connect_app/liked_events_page.dart';
import 'package:cs_connect_app/registered_events_page.dart';
import 'package:cs_connect_app/my_events_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool _isLoading = true;
  bool _showNearby = false;
  String _statusMessage = '';
  List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _nearbyEvents = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllEvents();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, '/login'); // Change this route if needed
  }

  Future<void> _fetchAllEvents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('events').get();
      setState(() {
        _allEvents = snapshot.docs;
        _isLoading = false;
        _statusMessage = 'Showing all events';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error fetching events: $e';
      });
    }
  }

  Future<void> _showNearbyEvents() async {
    setState(() {
      _statusMessage = 'Checking location permission...';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Location services are disabled.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Location permission denied.';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'Location permission permanently denied.';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      const double radiusInMiles = 10.0;
      final List<DocumentSnapshot> filtered = [];

      for (final doc in _allEvents) {
        final data = doc.data() as Map<String, dynamic>?;
        final loc = data?['location'];
        final lat = loc?['lat']?.toDouble();
        final lng = loc?['lng']?.toDouble();

        if (lat != null && lng != null) {
          final dist = _calculateDistanceInMiles(
              position.latitude, position.longitude, lat, lng);
          if (dist <= radiusInMiles) filtered.add(doc);
        }
      }

      setState(() {
        _nearbyEvents = filtered;
        _showNearby = true;
        _statusMessage = 'Found ${filtered.length} nearby events.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  double _calculateDistanceInMiles(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 3958.8;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * asin(sqrt(a));
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rawEvents = _showNearby ? _nearbyEvents : _allEvents;
    final eventsToShow = _searchQuery.isEmpty
        ? rawEvents
        : rawEvents.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['title']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false;
          }).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 241, 243),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello👋",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF292D32))),
                          SizedBox(height: 4),
                          Text("There are new events near you!",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 9, 9, 9))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Logout',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search for an event",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusMessage,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  child: eventsToShow.isEmpty
                      ? const Center(
                          child: Text("No events found.",
                              style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: eventsToShow.length,
                          itemBuilder: (context, index) {
                            final doc = eventsToShow[index];
                            final eventData =
                                doc.data() as Map<String, dynamic>? ?? {};
                            eventData['id'] = doc.id;

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                title: Text(eventData['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                        '📍 ${eventData['address'] ?? 'No Address'}'),
                                    Text(
                                        '📅 ${eventData['date'] ?? 'No Date'}    🕒 ${eventData['time'] ?? 'No Time'}'),
                                    const SizedBox(height: 6),
                                    Text(eventData['shortDescription'] ??
                                        'No description.'),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailPage(eventData: eventData),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7A5EF7),
        onPressed: () => Navigator.pushNamed(context, '/addEvent'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          elevation: 10,
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: Icon(_showNearby ? Icons.list : Icons.location_on,
                    color: const Color(0xFF7A5EF7)),
                tooltip: 'Nearby Events',
                onPressed: () {
                  if (!_showNearby) {
                    _showNearbyEvents();
                  } else {
                    setState(() {
                      _showNearby = false;
                      _statusMessage = 'Showing all events';
                    });
                  }
                },
              ),
              const Spacer(),
              IconButton(
                icon:
                    const Icon(Icons.favorite_border, color: Color(0xFF7A5EF7)),
                tooltip: 'Liked Events',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LikedEventsPage()),
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.event_available_outlined,
                    color: Color(0xFF7A5EF7)),
                tooltip: 'Registered Events',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisteredEventsPage()),
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.event_note, color: Color(0xFF7A5EF7)),
                tooltip: 'My Events',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyEventsPage()),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
