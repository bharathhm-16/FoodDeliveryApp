import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart'; // Hosa GPS Package
import '../main.dart'; 

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  List orders = [];
  bool isLoading = true;
  Timer? _locationTimer; 

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  void dispose() {
    _locationTimer?.cancel(); 
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/agent/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // HOSA: Nijaada GPS Location thegoluvudu
  Future<void> updateLocation(int orderId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      double lat = 19.0760; // Default (Emulator ge)
      double lng = 72.8777;

      // GPS on ideya illva check maduvudu
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (serviceEnabled && permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Nijaada location thegoluvudu
        // ignore: deprecated_member_use
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        lat = position.latitude;
        lng = position.longitude;
      } else {
        Fluttertoast.showToast(msg: "Using default location (GPS off)", backgroundColor: Colors.orange);
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/orders/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'orderId': orderId,
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        print("Real location updated: $lat, $lng");
      }
    } catch (e) {
      print("Location update error: $e");
    }
  }

  // 10 seconds ge ondsala update madalu timer start maduvudu
  void startTracking(int orderId) {
    Fluttertoast.showToast(
      msg: "GPS Location Sharing Started! 📍", 
      backgroundColor: Colors.green, 
      textColor: Colors.white
    );
    
    updateLocation(orderId); 
    
    _locationTimer?.cancel(); 
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      updateLocation(orderId);
    });
  }

  Future<void> markDelivered(int orderId) async {
    _locationTimer?.cancel(); 
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/api/agent/orders/$orderId/deliver'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Order Delivered Successfully! 🎉", backgroundColor: Colors.green, textColor: Colors.white);
        fetchOrders(); 
      } else {
        Fluttertoast.showToast(msg: "Failed to update", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Server Error", backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Delivery Dashboard", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchOrders),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              _locationTimer?.cancel(); 
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No pending deliveries!", style: GoogleFonts.poppins(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Order: ${order['orderNumber']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                                  child: Text(order['status'], style: GoogleFonts.poppins(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.store, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text("Pickup: ${order['restaurant']['name']}", style: GoogleFonts.poppins(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text("Customer: ${order['customer']['fullName']}", style: GoogleFonts.poppins(fontSize: 14)),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  onPressed: () => startTracking(order['id']),
                                  icon: const Icon(Icons.my_location, color: Colors.white, size: 16),
                                  label: const Text("Share GPS", style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  onPressed: () => markDelivered(order['id']),
                                  child: const Text("Mark Delivered", style: TextStyle(color: Colors.white, fontSize: 12)),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}