import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  const EventDetailPage({Key? key, required this.eventData}) : super(key: key);

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isLiked = false;
  bool _isRegistered = false;
  bool _needsRefresh = false;

  String get _eventId => widget.eventData['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    _isLiked = await _checkIfDocExists('liked_events');
    _isRegistered = await _checkIfDocExists('registered_events');
    if (mounted) setState(() {});
  }

  Future<bool> _checkIfDocExists(String subCollection) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(subCollection)
        .doc(_eventId)
        .get();
    return doc.exists;
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_events')
        .doc(_eventId);

    if (_isLiked) {
      await ref.set({'likedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
    _needsRefresh = true;
  }

  Future<void> _toggleRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_events')
        .doc(_eventId);

    if (_isRegistered) {
      await ref.set({
        'title': widget.eventData['title'] ?? 'No Title',
        'registeredAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
    _needsRefresh = true;
  }

  void _pop() => Navigator.pop(context, _needsRefresh);

  @override
  Widget build(BuildContext context) {
    final data = widget.eventData;
    final latLng = LatLng(
      (data['location']?['lat'] ?? 0).toDouble(),
      (data['location']?['lng'] ?? 0).toDouble(),
    );

    return WillPopScope(
      onWillPop: () async {
        _pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F0FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7A5EF7),
          title: Text(data['title'] ?? 'Event'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _pop,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Card 1 : banner + details + LIKE button -------------
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
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            (data['imageUrl'] as String?)?.isNotEmpty == true
                                ? data['imageUrl']
                                : 'https://via.placeholder.com/600x300.png?text=No+Image',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? 'No Title',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF292D32))),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: Color(0xFF7A5EF7)),
                                const SizedBox(width: 6),
                                Text(data['date'] ?? '',
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time,
                                    size: 18, color: Color(0xFF7A5EF7)),
                                const SizedBox(width: 6),
                                Text(data['time'] ?? '',
                                    style: const TextStyle(fontSize: 16)),
                              ]),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 20, color: Color(0xFF7A5EF7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(data['address'] ?? '',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Description',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF292D32))),
                              const SizedBox(height: 8),
                              Text(data['description'] ?? '',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 28,
                          color: Colors.pinkAccent,
                        ),
                        onPressed: () async {
                          setState(() => _isLiked = !_isLiked);
                          await _toggleLike();
                        },
                      ),
                    )
                  ],
                ),
              ),

              // --- Card 2: map ----------------------------------------
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(children: [
                        const Icon(Icons.my_location,
                            size: 18, color: Color(0xFF7A5EF7)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                                'Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}',
                                style: const TextStyle(fontSize: 16))),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(center: latLng, zoom: 14),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.example.csconnect',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  width: 80,
                                  height: 80,
                                  point: latLng,
                                  builder: (_) => const Icon(Icons.location_on,
                                      size: 40, color: Colors.red),
                                )
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Register / Unregister button -----------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRegistered ? Colors.grey : const Color(0xFF7A5EF7),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    setState(() => _isRegistered = !_isRegistered);
                    await _toggleRegistration();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(_isRegistered
                            ? 'Registered successfully!'
                            : 'Unregistered successfully!')));
                  },
                  child: Text(_isRegistered ? 'Unregister' : 'Register',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}