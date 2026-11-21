import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../main.dart'; 
import '../screens/add_menu_screen.dart'; // Hosa screen import

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/manager/orders'),
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

  Future<void> updateStatus(int orderId, String newStatus) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/api/manager/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Order Updated to $newStatus 🎉", 
          backgroundColor: Colors.green, 
          textColor: Colors.white
        );
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
        title: Text("Manager Dashboard", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
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
      // HOSA: FLOATING BUTTON ADD MENU GE HOGALU
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMenuItemScreen()),
          ).then((_) => fetchOrders()); // Vapas bandmele refresh maduvudu
        },
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Add Food Item", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No orders yet!", style: GoogleFonts.poppins()))
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
                                Text("₹${order['totalAmount']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFFF6B35))),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Customer: ${order['customer']['fullName']}", style: GoogleFonts.poppins(fontSize: 12)),
                            Text("Items: ${order['items'].length}", style: GoogleFonts.poppins(fontSize: 12)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    order['status'],
                                    style: GoogleFonts.poppins(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                if (order['status'] == 'PLACED')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => updateStatus(order['id'], 'PREPARING'),
                                    child: const Text("Accept & Prepare", style: TextStyle(color: Colors.white)),
                                  )
                                else if (order['status'] == 'PREPARING')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    onPressed: () => updateStatus(order['id'], 'OUT_FOR_DELIVERY'),
                                    child: const Text("Send for Delivery", style: TextStyle(color: Colors.white)),
                                  )
                                else if (order['status'] == 'OUT_FOR_DELIVERY')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () => updateStatus(order['id'], 'DELIVERED'),
                                    child: const Text("Mark Delivered", style: TextStyle(color: Colors.white)),
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