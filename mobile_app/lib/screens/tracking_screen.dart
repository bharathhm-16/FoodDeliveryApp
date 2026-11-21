import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const TrackingScreen({super.key, required this.orderData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? agentLocation;
  
  // Agent namma location idu (Default aagi restaurant hattira)
  double _agentLat = 19.0760;
  double _agentLng = 72.8777;

  double _parseCoordinate(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    // Modalu agent location ideya illva check maduvudu
    fetchAgentLocation(); 
    // Prathi 5 seconds ge ondsala location update maduvudu
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchAgentLocation();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Screen close aadaga timer stop maduvudu
    super.dispose();
  }

  // Backend inda Agent Location thegoluvudu
  Future<void> fetchAgentLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/orders/${widget.orderData['id']}/agent-location'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['lat'] != null && data['lng'] != null) {
          setState(() {
            agentLocation = data;
            _agentLat = _parseCoordinate(data['lat'], _agentLat);
            _agentLng = _parseCoordinate(data['lng'], _agentLng);
          });
        }
      }
    } catch (e) {
      print("Location fetch error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double restLat = _parseCoordinate(widget.orderData['restaurant']['latitude'], 19.0760);
    final double restLng = _parseCoordinate(widget.orderData['restaurant']['longitude'], 72.8777);
    
    final double custLat = 19.0330; 
    final double custLng = 72.8600;

    final LatLng restaurantLoc = LatLng(restLat, restLng);
    final LatLng customerLoc = LatLng(custLat, custLng);
    final LatLng agentLoc = LatLng(_agentLat, _agentLng);

    return Scaffold(
      appBar: AppBar(
        title: Text("Live Tracking", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
            onPressed: fetchAgentLocation,
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: restaurantLoc,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [restaurantLoc, agentLoc, customerLoc], // Route (Restaurant -> Agent -> Customer)
                    strokeWidth: 4.0,
                    color: const Color(0xFFFF6B35),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Restaurant Marker
                  Marker(
                    point: restaurantLoc,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.store, color: Colors.red, size: 40),
                  ),
                  // Customer Marker
                  Marker(
                    point: customerLoc,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                  ),
                  // Agent Marker (Live Move aagutte)
                  Marker(
                    point: agentLoc,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.delivery_dining, color: Colors.green, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // 2. BOTTOM SHEET (Order Details & Navigation)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order Status", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.orderData['status'],
                          style: GoogleFonts.poppins(color: Colors.orange[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Agent Live Status
                  if (agentLocation != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.green),
                        const SizedBox(width: 10),
                        Text("${agentLocation!['agentName']} is on the way!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text("Phone: ${agentLocation!['agentPhone'] ?? 'N/A'}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ] else ...[
                    Text("Waiting for agent to share location...", style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                  
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: Text("Open Navigation", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                    onPressed: () async {
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$custLat,$custLng');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        throw Exception('Could not launch maps');
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}